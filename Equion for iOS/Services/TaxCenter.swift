import Foundation
import SwiftUI
import FirebaseAuth

// MARK: - Activities (mirror snaptradeactivities in firebase/functions/src/index.ts)

struct BrokerActivity: Decodable, Identifiable, Hashable {
    let id: String
    let accountId: String
    /// BUY, SELL, REI, CONTRIBUTION, WITHDRAWAL, TRANSFER, EXTERNAL_ASSET_TRANSFER_IN/OUT, SPLIT
    let type: String
    let date: String          // YYYY-MM-DD
    let symbol: String?
    let units: Double?
    let price: Double?
    let amount: Double?
    let currency: String
    let fee: Double?
}

private struct ActivitiesResponse: Decodable { let activities: [BrokerActivity] }

// MARK: - Account tax types

enum TaxAccountType: String, CaseIterable, Identifiable {
    case tfsa, rrsp, fhsa, resp, retirementIncome, taxable, unknown
    var id: String { rawValue }

    var title: String {
        switch self {
        case .tfsa: return "TFSA"
        case .rrsp: return "RRSP"
        case .fhsa: return "FHSA"
        case .resp: return "RESP"
        case .retirementIncome: return "RRIF / LIRA"
        case .taxable: return L("Non-registered")
        case .unknown: return L("Other")
        }
    }

    /// Losses only count for tax in taxable accounts.
    var isTaxable: Bool { self == .taxable || self == .unknown }

    /// Account types with contribution room the app can track.
    static let withRoom: [TaxAccountType] = [.tfsa, .rrsp, .fhsa]

    /// Best effort from the institution's account type / name (e.g. "TFSA", "RRSP", "Non-registered").
    static func of(_ account: LinkedAccount) -> TaxAccountType {
        let text = "\(account.rawType ?? "") \(account.name)".uppercased()
        if text.contains("FHSA") || text.contains("FIRST HOME") { return .fhsa }
        if text.contains("TFSA") || text.contains("TAX-FREE") || text.contains("TAX FREE") { return .tfsa }
        if text.contains("RRIF") || text.contains("LIRA") || text.contains("LIF") || text.contains("LOCKED") { return .retirementIncome }
        if text.contains("RRSP") || text.contains("RSP") || text.contains("RETIREMENT SAVINGS") { return .rrsp }
        if text.contains("RESP") || text.contains("EDUCATION") { return .resp }
        if ["NON-REGISTERED", "NON REGISTERED", "NONREGISTERED", "PERSONAL", "CASH", "MARGIN", "INDIVIDUAL", "JOINT", "CRYPTO"]
            .contains(where: { text.contains($0) }) { return .taxable }
        return .unknown
    }
}

// MARK: - Results

struct ContributionSummary: Identifiable {
    let type: TaxAccountType
    let year: Int
    let contributedCAD: Double
    let withdrawnCAD: Double
    /// User-entered room from CRA My Account (nil until set).
    let roomCAD: Double?

    var id: String { type.rawValue }
    var remainingCAD: Double? { roomCAD.map { $0 - contributedCAD } }

    /// CRA tolerates a $2,000 RRSP over-contribution; TFSA and FHSA have no buffer.
    var penaltyBuffer: Double { type == .rrsp ? 2000 : 0 }
    var overContributedCAD: Double {
        guard let remaining = remainingCAD else { return 0 }
        return max(0, -remaining - penaltyBuffer)
    }
}

struct SuperficialLossAlert: Identifiable {
    enum Status { case watching, likelyDenied }
    let id: String
    let symbol: String
    let saleDate: Date
    let accountName: String
    let loss: Double                 // positive number, in `currency`
    let currency: String
    /// Repurchase window ends (sale + 30 days).
    let windowEnds: Date
    let status: Status
    /// Purchases of the same security within ±30 days, across all accounts.
    let repurchases: [(account: String, date: Date)]
}

// MARK: - Entry card

/// Accounts-page entry to the Tax Assistant, with a count of things needing attention.
struct TaxAssistantCard: View {
    @ObservedObject private var tax = TaxCenter.shared
    @ObservedObject private var brokerage = BrokerageManager.shared

    var body: some View {
        if !brokerage.currentAccounts.isEmpty {
            NavigationLink {
                TaxCenterView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(.callout, weight: .semibold))
                        .foregroundColor(AppTheme.accentText)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(AppTheme.accent.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("Tax Assistant"))
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Text(L("Room, cost basis, capital gains and superficial losses"))
                            .font(AppTheme.caption(11))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    Spacer()
                    let count = tax.attentionCount
                    if count > 0 {
                        Label("\(count)", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundColor(AppTheme.warning)
                            .accessibilityLabel(String(format: L("%d items need attention"), count))
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(16)
                .themeCardSurface()
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
            .task { await tax.load() }
        }
    }
}

// MARK: - Tax Center

/// Canadian registered-account helpers built from read-only broker data:
/// TFSA / RRSP / FHSA contributions this year vs. the room the user entered, and a
/// cross-account superficial-loss watch. Information only — not tax advice.
@MainActor
final class TaxCenter: ObservableObject {
    static let shared = TaxCenter()
    private init() {}

    @Published private(set) var activities: [BrokerActivity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    @Published private(set) var loadedAt: Date?
    @Published private var roomVersion = 0   // bumps when the user edits room
    /// Cost bases and capital gains, rebuilt after each load (and when a transfer cost is entered).
    @Published private(set) var acb: ACBReport?
    @Published private(set) var isBuildingACB = false

    private var ownerUid: String?

    static let year = Calendar.current.component(.year, from: Date())

    private static let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        // Calendar days, shown in the device's zone: parsing in another zone shifted them a day west of Toronto.
        f.timeZone = .current
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    static func date(_ s: String) -> Date? { dayFmt.date(from: String(s.prefix(10))) }

    func load(force: Bool = false) async {
        let uid = Auth.auth().currentUser?.uid
        if ownerUid != uid { activities = []; loadedAt = nil; ownerUid = uid }
        guard uid != nil, BrokerageManager.shared.hasLinkedBefore || !BrokerageManager.shared.connections.isEmpty else { return }
        if !force, let loadedAt, Date().timeIntervalSince(loadedAt) < 600 { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let res = try await CloudFunctions.call("snaptradeactivities", as: ActivitiesResponse.self)
            activities = res.activities
            loadedAt = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        await rebuildACB()
    }

    // MARK: Cost basis

    func rebuildACB() async {
        guard !activities.isEmpty else { acb = nil; return }
        isBuildingACB = true
        defer { isBuildingACB = false }
        let accounts = BrokerageManager.shared.currentAccounts
        let types = Dictionary(accounts.map { ($0.id, TaxAccountType.of($0)) }, uniquingKeysWith: { a, _ in a })
        let currencies = Set(activities.map { $0.currency.uppercased() })
        // Live rate as a last resort (flagged as estimated in the results).
        let live: [String: Double] = Dictionary(uniqueKeysWithValues: currencies.map { ($0, cad(1, from: $0)) })
        let fx = await HistoricalFX.shared.table(for: currencies) { live[$0] }

        func held(_ include: (LinkedAccount) -> Bool) -> [String: Double] {
            var out: [String: Double] = [:]
            for a in accounts where include(a) {
                for p in a.positions where p.units > 1e-9 {
                    out[(p.displaySymbol ?? p.symbol).uppercased(), default: 0] += p.units
                }
            }
            return out
        }
        let input = ACBInput(
            activities: activities,
            accountTypes: types,
            accountNames: Dictionary(accounts.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a }),
            heldNowAnywhere: held { _ in true },
            heldNowTaxable: held { TaxAccountType.of($0).isTaxable },
            transferCosts: transferCosts,
            today: ACBEngine.dayString(Date()),
            rate: { fx.quote($0, $1) }
        )
        acb = ACBEngine.compute(input)
    }

    /// Non-registered accounts whose trades feed the cost bases (shown so the user can check).
    var taxableAccountNames: [String] {
        BrokerageManager.shared.currentAccounts.filter { TaxAccountType.of($0).isTaxable }.map(\.name)
    }

    /// Market value in CAD of what's held in non-registered accounts, per symbol.
    var taxableMarketValueCAD: [String: Double] {
        var out: [String: Double] = [:]
        for a in BrokerageManager.shared.currentAccounts where TaxAccountType.of(a).isTaxable {
            for p in a.positions where p.units > 1e-9 {
                guard let price = p.price else { continue }
                out[(p.displaySymbol ?? p.symbol).uppercased(), default: 0] += cad(p.units * price, from: p.currency)
            }
        }
        return out
    }

    // MARK: Transfer-in costs (entered by the user; stored on device)

    private var transferCostKey: String? {
        Auth.auth().currentUser.map { "acbTransferCosts_" + $0.uid }
    }

    var transferCosts: [String: Double] {
        guard let key = transferCostKey else { return [:] }
        return UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
    }

    /// Splits `totalCAD` across the transfer-ins of one security by units.
    func setTransferCost(totalCAD: Double?, for issue: ACBIssue) async {
        guard let key = transferCostKey else { return }
        var costs = transferCosts
        let ids = Set(issue.activityIds)
        let rows = activities.filter { ids.contains($0.id) }
        let totalUnits = rows.reduce(0) { $0 + abs($1.units ?? 0) }
        for r in rows {
            if let totalCAD, totalUnits > 0 { costs[r.id] = totalCAD * abs(r.units ?? 0) / totalUnits }
            else { costs[r.id] = nil }
        }
        UserDefaults.standard.set(costs, forKey: key)
        await rebuildACB()
    }

    // MARK: Room (entered by the user from CRA My Account; stored on device)

    private func roomKey(_ type: TaxAccountType) -> String? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return "taxRoom_" + uid + "_" + String(Self.year) + "_" + type.rawValue
    }

    func room(for type: TaxAccountType) -> Double? {
        _ = roomVersion
        guard let key = roomKey(type), UserDefaults.standard.object(forKey: key) != nil else { return nil }
        return UserDefaults.standard.double(forKey: key)
    }

    func setRoom(_ value: Double?, for type: TaxAccountType) {
        guard let key = roomKey(type) else { return }
        if let value { UserDefaults.standard.set(value, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
        roomVersion += 1
    }

    // MARK: Accounts

    private var accountsById: [String: LinkedAccount] {
        Dictionary(BrokerageManager.shared.currentAccounts.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }

    /// Registered types the user actually has (only these get a contribution card).
    var heldTypes: [TaxAccountType] {
        let types = Set(BrokerageManager.shared.currentAccounts.map(TaxAccountType.of))
        return TaxAccountType.withRoom.filter(types.contains)
    }

    private func cad(_ amount: Double, from currency: String) -> Double {
        let mgr = HoldingsManager.shared
        let usdPerCad = mgr.usd(1, from: "CAD")
        return usdPerCad > 0 ? mgr.usd(amount, from: currency) / usdPerCad : amount
    }

    // MARK: Contributions

    var contributions: [ContributionSummary] {
        let accounts = accountsById
        let yearPrefix = "\(Self.year)-"
        return heldTypes.map { type in
            let rows = activities.filter { a in
                a.date.hasPrefix(yearPrefix) && accounts[a.accountId].map(TaxAccountType.of) == type
            }
            let contributed = rows.filter { $0.type == "CONTRIBUTION" }
                .reduce(0) { $0 + cad(abs($1.amount ?? 0), from: $1.currency) }
            let withdrawn = rows.filter { $0.type == "WITHDRAWAL" }
                .reduce(0) { $0 + cad(abs($1.amount ?? 0), from: $1.currency) }
            return ContributionSummary(type: type, year: Self.year, contributedCAD: contributed,
                                       withdrawnCAD: withdrawn, roomCAD: room(for: type))
        }
    }

    // MARK: Superficial loss

    /// Losses in non-registered accounts (pooled cost, in CAD) from this tax year and at least the
    /// last 60 days, with repurchases of the same security in ANY linked account within ±30 days.
    var superficialLossAlerts: [SuperficialLossAlert] {
        guard let acb else { return [] }
        let cal = Calendar.current
        let now = Date()
        let startOfYear = cal.date(from: DateComponents(year: Self.year, month: 1, day: 1)) ?? now
        let lookback = ACBEngine.dayString(min(startOfYear, cal.date(byAdding: .day, value: -60, to: now) ?? now))
        let today = ACBEngine.dayString(now)
        return acb.dispositions.compactMap { d in
            guard d.gainCAD < -1, d.day >= lookback,
                  let saleDate = Self.date(d.day), let windowEnds = Self.date(d.windowEndDay) else { return nil }
            let status: SuperficialLossAlert.Status = d.deniedLossCAD > 0.005 ? .likelyDenied : .watching
            // Past windows with nothing denied are resolved — nothing to show.
            if status == .watching && d.windowEndDay < today { return nil }
            return SuperficialLossAlert(
                id: d.id, symbol: d.symbol, saleDate: saleDate, accountName: d.accountName,
                loss: -d.gainCAD, currency: "CAD", windowEnds: windowEnds, status: status,
                repurchases: d.repurchases.compactMap { r in Self.date(r.day).map { (r.account, $0) } }
            )
        }
        .sorted { $0.saleDate > $1.saleDate }
    }

    /// Count for badges: over-contributions + superficial-loss alerts.
    var attentionCount: Int {
        contributions.filter { $0.overContributedCAD > 0 }.count + superficialLossAlerts.count
    }
}
