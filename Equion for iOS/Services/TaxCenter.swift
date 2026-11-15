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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.accentText)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(AppTheme.accent.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("Tax Assistant"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Text(L("TFSA · RRSP · FHSA room and superficial loss watch"))
                            .font(AppTheme.caption(11))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    Spacer()
                    let count = tax.attentionCount
                    if count > 0 {
                        Label("\(count)", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.warning)
                            .accessibilityLabel(String(format: L("%d items need attention"), count))
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(14)
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

    private var ownerUid: String?

    static let year = Calendar.current.component(.year, from: Date())

    private static let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "America/Toronto")
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

    /// Rebuilds each account's average cost per security from its trade history, finds sales at
    /// a loss in taxable accounts, and checks purchases of the same security in ANY linked account
    /// (TFSA, RRSP… included) within 30 days before or after the sale.
    var superficialLossAlerts: [SuperficialLossAlert] {
        let accounts = accountsById
        let cal = Calendar.current
        let now = Date()
        // This tax year, and at least the last 60 days (a December sale still matters in January).
        let startOfYear = cal.date(from: DateComponents(year: Self.year, month: 1, day: 1)) ?? now
        let lookback = min(startOfYear, cal.date(byAdding: .day, value: -60, to: now) ?? now)

        let trades = activities
            .filter { ["BUY", "SELL", "REI", "SPLIT"].contains($0.type) && ($0.symbol ?? "").isEmpty == false }
            .sorted { ($0.date, $0.type == "SELL" ? 1 : 0) < ($1.date, $1.type == "SELL" ? 1 : 0) }

        // Currently held anywhere (proxy for "still owned at the end of the window").
        let heldNow = Set(BrokerageManager.shared.currentAccounts.flatMap { acct in
            acct.positions.filter { $0.units > 1e-9 }.map { ($0.displaySymbol ?? $0.symbol).uppercased() }
        })

        struct Lot { var units = 0.0; var cost = 0.0 }
        var lots: [String: Lot] = [:]          // "accountId|SYMBOL"
        var alerts: [SuperficialLossAlert] = []

        for t in trades {
            let sym = (t.symbol ?? "").uppercased()
            let key = "\(t.accountId)|\(sym)"
            let units = abs(t.units ?? 0)
            switch t.type {
            case "BUY", "REI":
                let cost = units * (t.price ?? 0) + abs(t.fee ?? 0)
                lots[key, default: Lot()].units += units
                lots[key, default: Lot()].cost += cost
            case "SPLIT":
                // Units change, total cost stays the same.
                lots[key, default: Lot()].units += (t.units ?? 0)
            case "SELL":
                var lot = lots[key, default: Lot()]
                guard lot.units > 1e-9, units > 0 else { continue }
                let sold = min(units, lot.units)
                let avg = lot.cost / lot.units
                let proceeds = sold * (t.price ?? 0) - abs(t.fee ?? 0)
                let gain = proceeds - sold * avg
                lot.cost -= sold * avg
                lot.units -= sold
                lots[key] = lot

                guard gain < -1,
                      let account = accounts[t.accountId], TaxAccountType.of(account).isTaxable,
                      let saleDate = Self.date(t.date), saleDate >= lookback else { continue }
                let start = cal.date(byAdding: .day, value: -30, to: saleDate) ?? saleDate
                let end = cal.date(byAdding: .day, value: 30, to: saleDate) ?? saleDate
                let repurchases: [(account: String, date: Date)] = activities.compactMap { b in
                    guard ["BUY", "REI"].contains(b.type), (b.symbol ?? "").uppercased() == sym,
                          let d = Self.date(b.date), d >= start, d <= end, b.id != t.id else { return nil }
                    // Buys before the sale in the same account are usually the shares being sold.
                    if b.accountId == t.accountId && d < saleDate { return nil }
                    return (accounts[b.accountId]?.name ?? L("Account"), d)
                }
                let status: SuperficialLossAlert.Status = (!repurchases.isEmpty && heldNow.contains(sym)) ? .likelyDenied : .watching
                // Past windows with no repurchase are resolved — nothing to show.
                if status == .watching && end < now { continue }
                alerts.append(SuperficialLossAlert(
                    id: t.id, symbol: sym, saleDate: saleDate, accountName: account.name,
                    loss: -gain, currency: t.currency, windowEnds: end, status: status,
                    repurchases: repurchases
                ))
            default:
                break
            }
        }
        return alerts.sorted { $0.saleDate > $1.saleDate }
    }

    /// Count for badges: over-contributions + superficial-loss alerts.
    var attentionCount: Int {
        contributions.filter { $0.overContributedCAD > 0 }.count + superficialLossAlerts.count
    }
}
