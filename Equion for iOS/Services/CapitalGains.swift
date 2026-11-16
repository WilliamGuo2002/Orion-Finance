import Foundation

// MARK: - Adjusted cost base (ACB) and capital gains, the CRA way
//
// Rules implemented (information only, not tax advice):
// - Identical securities are pooled across ALL of a person's non-registered accounts — one average
//   cost per security, not one per broker (brokers can only see their own account).
// - Everything is in Canadian dollars: each purchase at the Bank of Canada rate on its trade date,
//   each sale at the rate on its sale date.
// - Commissions are added to the cost of a purchase and reported as outlays on a sale.
// - Superficial losses: a loss is denied in proportion to min(sold, bought in ±30 days, held 30 days
//   after) / sold, counting purchases in ANY account (TFSA/RRSP included). A denied loss is added to
//   the cost of the repurchased shares when they sit in a non-registered account; in a registered
//   account it is lost.
// - Registered accounts (TFSA, RRSP, FHSA, RESP, RRIF/LIRA) have no capital gains and are left out.

/// CAD per one unit of a currency on a date. `exact` is false when the rate had to be estimated.
struct FXQuote: Equatable {
    let cadPerUnit: Double
    let exact: Bool
}

struct ACBInput {
    let activities: [BrokerActivity]
    /// accountId → tax type. Accounts missing here are treated as taxable (unknown).
    let accountTypes: [String: TaxAccountType]
    let accountNames: [String: String]
    /// SYMBOL → units held now, across every linked account (any type).
    let heldNowAnywhere: [String: Double]
    /// SYMBOL → units held now in non-registered accounts.
    let heldNowTaxable: [String: Double]
    /// activity id → cost in CAD the user entered for a transfer-in whose cost the broker doesn't know.
    let transferCosts: [String: Double]
    /// Today, "YYYY-MM-DD" (injectable for tests).
    let today: String
    let rate: (_ currency: String, _ day: String) -> FXQuote
}

struct ACBIssue: Hashable {
    enum Kind: Hashable { case transferInWithoutCost, soldMoreThanHistory, unitsMismatch, estimatedFX }
    let kind: Kind
    /// Transfer-in activities that need a cost (for `.transferInWithoutCost`).
    var activityIds: [String] = []
    var units: Double = 0
}

struct ACBPosition: Identifiable {
    var id: String { symbol }
    let symbol: String
    let units: Double
    let acbCAD: Double
    var acbPerUnit: Double { units > 1e-9 ? acbCAD / units : 0 }
    let issues: [ACBIssue]
}

struct Disposition: Identifiable {
    let id: String
    let symbol: String
    let day: String
    let accountName: String
    let units: Double
    let proceedsCAD: Double
    let acbCAD: Double
    let outlaysCAD: Double
    /// Before superficial-loss rules.
    let gainCAD: Double
    /// Portion of a loss CRA denies (positive), 0 if none.
    let deniedLossCAD: Double
    let currency: String
    let fx: FXQuote
    /// Cost history for this security is incomplete, so the gain may be wrong.
    let incomplete: Bool
    let windowEndDay: String
    let repurchases: [(account: String, day: String)]

    /// What counts for tax.
    var reportableGainCAD: Double { gainCAD + deniedLossCAD }
    var year: Int { Int(day.prefix(4)) ?? 0 }
}

struct CapitalGainsSummary {
    let year: Int
    let dispositions: [Disposition]
    var proceeds: Double { dispositions.reduce(0) { $0 + $1.proceedsCAD } }
    var acb: Double { dispositions.reduce(0) { $0 + $1.acbCAD } }
    var outlays: Double { dispositions.reduce(0) { $0 + $1.outlaysCAD } }
    var gains: Double { dispositions.filter { $0.reportableGainCAD > 0 }.reduce(0) { $0 + $1.reportableGainCAD } }
    var losses: Double { dispositions.filter { $0.reportableGainCAD < 0 }.reduce(0) { $0 - $1.reportableGainCAD } }
    var denied: Double { dispositions.reduce(0) { $0 + $1.deniedLossCAD } }
    var net: Double { gains - losses }
    /// At the 50% inclusion rate. A net loss isn't taxable; it can be carried back 3 or forward indefinitely.
    var taxablePortion: Double { max(0, net) * 0.5 }
    var hasIncomplete: Bool { dispositions.contains { $0.incomplete } }
}

struct ACBReport {
    let positions: [ACBPosition]
    let dispositions: [Disposition]
    let usedEstimatedFX: Bool

    var years: [Int] { Array(Set(dispositions.map(\.year))).sorted(by: >) }
    func summary(_ year: Int) -> CapitalGainsSummary {
        CapitalGainsSummary(year: year, dispositions: dispositions.filter { $0.year == year }.sorted { $0.day > $1.day })
    }
}

enum ACBEngine {
    private static let tradeTypes: Set<String> = ["BUY", "SELL", "REI", "SPLIT", "EXTERNAL_ASSET_TRANSFER_IN", "EXTERNAL_ASSET_TRANSFER_OUT"]
    private static let acquireTypes: Set<String> = ["BUY", "REI", "EXTERNAL_ASSET_TRANSFER_IN"]

    static func compute(_ input: ACBInput) -> ACBReport {
        let trades = input.activities
            .filter { tradeTypes.contains($0.type) && !($0.symbol ?? "").isEmpty }
            // Same day: acquisitions before dispositions (no intraday times available).
            .sorted { ($0.date, order($0.type), $0.id) < ($1.date, order($1.type), $1.id) }

        // Iterate: a denied loss raises the cost of later shares, which can change later gains
        // (and so later denials). Converges in a pass or two in practice.
        var adjustments: [Adjustment] = []
        var result = run(trades, input: input, adjustments: [])
        for _ in 0..<4 {
            let next = denials(result.dispositions, trades: trades, input: input)
            if next == adjustments { break }
            adjustments = next
            result = run(trades, input: input, adjustments: adjustments)
        }
        // Attach the final denials to the dispositions.
        let deniedById = Dictionary(adjustments.map { ($0.dispositionId, $0) }, uniquingKeysWith: { a, _ in a })
        let dispositions = result.dispositions.map { d -> Disposition in
            let adj = deniedById[d.id]
            return Disposition(id: d.id, symbol: d.symbol, day: d.day, accountName: d.accountName, units: d.units,
                               proceedsCAD: d.proceedsCAD, acbCAD: d.acbCAD, outlaysCAD: d.outlaysCAD,
                               gainCAD: d.gainCAD, deniedLossCAD: adj?.denied ?? 0, currency: d.currency, fx: d.fx,
                               incomplete: d.incomplete, windowEndDay: d.windowEndDay,
                               repurchases: repurchases(of: d, trades: trades, input: input).map { ($0.account, $0.day) })
        }
        return ACBReport(positions: result.positions, dispositions: dispositions, usedEstimatedFX: result.estimatedFX)
    }

    // MARK: One pass over the trade history

    private struct Adjustment: Equatable {
        let dispositionId: String
        let symbol: String
        let day: String            // when the denied loss is added to the pool
        let denied: Double         // whole denied loss
        let addedToPool: Double    // part that goes into a non-registered pool's cost
    }

    private struct Pool { var units = 0.0; var acb = 0.0; var issues: [ACBIssue] = [] }

    private static func order(_ type: String) -> Int {
        switch type {
        case "SPLIT": return 0
        case "BUY", "REI", "EXTERNAL_ASSET_TRANSFER_IN": return 1
        default: return 2
        }
    }

    private static func isTaxable(_ accountId: String, _ input: ACBInput) -> Bool {
        (input.accountTypes[accountId] ?? .unknown).isTaxable
    }

    private static func run(_ trades: [BrokerActivity], input: ACBInput, adjustments: [Adjustment])
        -> (positions: [ACBPosition], dispositions: [Disposition], estimatedFX: Bool) {
        var pools: [String: Pool] = [:]
        var dispositions: [Disposition] = []
        var estimated = false
        var pending = adjustments.sorted { $0.day < $1.day }

        func applyAdjustments(through day: String) {
            while let first = pending.first, first.day <= day {
                pools[first.symbol, default: Pool()].acb += first.addedToPool
                pending.removeFirst()
            }
        }

        for t in trades {
            applyAdjustments(through: t.date)
            guard isTaxable(t.accountId, input) else { continue }
            let sym = (t.symbol ?? "").uppercased()
            let units = abs(t.units ?? 0)
            let fx = t.currency.uppercased() == "CAD" ? FXQuote(cadPerUnit: 1, exact: true) : input.rate(t.currency, t.date)
            if !fx.exact { estimated = true }
            let fee = abs(t.fee ?? 0) * fx.cadPerUnit
            var pool = pools[sym, default: Pool()]

            switch t.type {
            case "BUY", "REI":
                let gross = (t.price ?? 0) > 0 ? units * (t.price ?? 0) : max(abs(t.amount ?? 0) - abs(t.fee ?? 0), 0)
                pool.units += units
                pool.acb += gross * fx.cadPerUnit + fee
            case "EXTERNAL_ASSET_TRANSFER_IN":
                pool.units += units
                if let cost = input.transferCosts[t.id] {
                    pool.acb += cost
                } else if let price = t.price, price > 0 {
                    pool.acb += units * price * fx.cadPerUnit
                } else {
                    addIssue(&pool, .transferInWithoutCost, activityId: t.id, units: units)
                }
            case "EXTERNAL_ASSET_TRANSFER_OUT":
                // Moving shares to another of your own accounts isn't a sale; the cost leaves with them.
                let moved = min(units, pool.units)
                if pool.units > 1e-9 { pool.acb -= pool.acb * moved / pool.units }
                pool.units -= moved
            case "SPLIT":
                pool.units += (t.units ?? 0)        // cost unchanged
            case "SELL":
                guard units > 0 else { break }
                let incompleteBefore = pool.issues.contains { $0.kind == .transferInWithoutCost }
                var incomplete = incompleteBefore
                if units > pool.units + 1e-6 {
                    addIssue(&pool, .soldMoreThanHistory)
                    incomplete = true
                }
                let covered = min(units, pool.units)
                let acbSold = pool.units > 1e-9 ? pool.acb * covered / pool.units : 0
                pool.acb -= acbSold
                pool.units -= covered
                let gross = (t.price ?? 0) > 0 ? units * (t.price ?? 0) : abs(t.amount ?? 0) + abs(t.fee ?? 0)
                let proceeds = gross * fx.cadPerUnit
                dispositions.append(Disposition(
                    id: t.id, symbol: sym, day: t.date, accountName: input.accountNames[t.accountId] ?? L("Account"),
                    units: units, proceedsCAD: proceeds, acbCAD: acbSold, outlaysCAD: fee,
                    gainCAD: proceeds - acbSold - fee, deniedLossCAD: 0, currency: t.currency, fx: fx,
                    incomplete: incomplete, windowEndDay: shift(t.date, days: 30), repurchases: []))
            default:
                break
            }
            if pool.units < 1e-9 { pool.units = 0; if abs(pool.acb) < 0.005 { pool.acb = 0 } }
            pools[sym] = pool
        }
        applyAdjustments(through: "9999-12-31")

        // Reconcile with what's actually held now.
        let symbols = Set(pools.keys).union(input.heldNowTaxable.keys.map { $0.uppercased() })
        let positions: [ACBPosition] = symbols.compactMap { sym in
            var pool = pools[sym, default: Pool()]
            let held = input.heldNowTaxable[sym] ?? 0
            guard pool.units > 1e-6 || held > 1e-6 else { return nil }
            // Only reconcile when holdings actually loaded (an empty map means "unknown", not "zero").
            if !input.heldNowTaxable.isEmpty, abs(held - pool.units) > max(1e-4, held * 1e-4) {
                addIssue(&pool, .unitsMismatch, units: held)
            }
            return ACBPosition(symbol: sym, units: held > 1e-6 ? held : pool.units, acbCAD: pool.acb, issues: pool.issues)
        }
        .sorted { $0.symbol < $1.symbol }
        return (positions, dispositions, estimated)
    }

    private static func addIssue(_ pool: inout Pool, _ kind: ACBIssue.Kind, activityId: String? = nil, units: Double = 0) {
        if let i = pool.issues.firstIndex(where: { $0.kind == kind }) {
            if let activityId { pool.issues[i].activityIds.append(activityId) }
            pool.issues[i].units += units
        } else {
            pool.issues.append(ACBIssue(kind: kind, activityIds: activityId.map { [$0] } ?? [], units: units))
        }
    }

    // MARK: Superficial losses

    private struct Repurchase { let account: String; let day: String; let units: Double; let taxable: Bool }

    private static func repurchases(of d: Disposition, trades: [BrokerActivity], input: ACBInput) -> [Repurchase] {
        let start = shift(d.day, days: -30)
        return trades.compactMap { b in
            guard acquireTypes.contains(b.type), (b.symbol ?? "").uppercased() == d.symbol,
                  b.date >= start, b.date <= d.windowEndDay, b.id != d.id else { return nil }
            return Repurchase(account: input.accountNames[b.accountId] ?? L("Account"), day: b.date,
                              units: abs(b.units ?? 0), taxable: isTaxable(b.accountId, input))
        }
    }

    /// Units held across ALL accounts at the end of a day (or now, for days not reached yet).
    private static func unitsHeld(_ symbol: String, atEndOf day: String, trades: [BrokerActivity], input: ACBInput) -> Double {
        if day >= input.today { return input.heldNowAnywhere[symbol] ?? 0 }
        return trades.reduce(0.0) { sum, t in
            guard (t.symbol ?? "").uppercased() == symbol, t.date <= day else { return sum }
            let u = abs(t.units ?? 0)
            switch t.type {
            case "BUY", "REI", "EXTERNAL_ASSET_TRANSFER_IN": return sum + u
            case "SELL", "EXTERNAL_ASSET_TRANSFER_OUT": return sum - u
            case "SPLIT": return sum + (t.units ?? 0)
            default: return sum
            }
        }
    }

    private static func denials(_ dispositions: [Disposition], trades: [BrokerActivity], input: ACBInput) -> [Adjustment] {
        dispositions.compactMap { d in
            guard d.gainCAD < -0.005 else { return nil }
            let buys = repurchases(of: d, trades: trades, input: input)
            let bought = buys.reduce(0) { $0 + $1.units }
            guard bought > 0 else { return nil }
            let heldAfter = max(0, unitsHeld(d.symbol, atEndOf: d.windowEndDay, trades: trades, input: input))
            let fraction = min(d.units, bought, heldAfter) / d.units
            guard fraction > 0 else { return nil }
            let denied = -d.gainCAD * fraction
            let taxableBought = buys.filter(\.taxable).reduce(0) { $0 + $1.units }
            // Added to the cost of the substituted shares, once they're in the pool.
            let lastTaxableBuy = buys.filter(\.taxable).map(\.day).max() ?? d.day
            return Adjustment(dispositionId: d.id, symbol: d.symbol, day: max(d.day, lastTaxableBuy),
                              denied: round2(denied), addedToPool: round2(denied * taxableBought / bought))
        }
    }

    // MARK: Helpers

    private static let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(identifier: "America/Toronto")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func shift(_ day: String, days: Int) -> String {
        guard let d = dayFmt.date(from: String(day.prefix(10))),
              let s = Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: d) else { return day }
        return dayFmt.string(from: s)
    }

    static func dayString(_ date: Date) -> String { dayFmt.string(from: date) }

    private static func round2(_ x: Double) -> Double { (x * 100).rounded() / 100 }

    // MARK: CSV (Schedule 3 working paper)

    static func csv(_ s: CapitalGainsSummary) -> String {
        func q(_ x: String) -> String { "\"" + x.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        func n(_ x: Double) -> String { String(format: "%.2f", x) }
        var rows = ["Date,Security,Units,Proceeds (CAD),ACB (CAD),Outlays (CAD),Gain or loss (CAD),Denied superficial loss (CAD),Reportable (CAD),Currency,CAD per unit (Bank of Canada),Account,Notes"]
        for d in s.dispositions.sorted(by: { $0.day < $1.day }) {
            var notes: [String] = []
            if d.incomplete { notes.append("cost history incomplete") }
            if !d.fx.exact { notes.append("exchange rate estimated") }
            rows.append([d.day, q(d.symbol), String(format: "%g", d.units), n(d.proceedsCAD), n(d.acbCAD), n(d.outlaysCAD),
                         n(d.gainCAD), n(d.deniedLossCAD), n(d.reportableGainCAD), d.currency,
                         String(format: "%.4f", d.fx.cadPerUnit), q(d.accountName), q(notes.joined(separator: "; "))].joined(separator: ","))
        }
        rows.append("")
        rows.append("Total proceeds,\(n(s.proceeds))")
        rows.append("Total ACB,\(n(s.acb))")
        rows.append("Total outlays,\(n(s.outlays))")
        rows.append("Net capital gain (loss),\(n(s.net))")
        rows.append("Taxable capital gain at 50% inclusion,\(n(s.taxablePortion))")
        rows.append("")
        rows.append(q("Prepared by Orion Finance from linked brokerage history. Information only, not tax advice. Verify against your T5008 slips and records."))
        return rows.joined(separator: "\n")
    }
}

// MARK: - Bank of Canada daily exchange rates

/// Daily rates from the Bank of Canada Valet API (public, no key) — the source CRA accepts.
/// Series start in 2017; earlier trades use the first available rate and are flagged as estimated.
/// Cached on disk for a day.
actor HistoricalFX {
    static let shared = HistoricalFX()

    struct Table {
        /// currency → [(day, CAD per unit)] sorted by day
        let series: [String: [(day: String, rate: Double)]]
        let fallback: (String) -> Double?

        func quote(_ currency: String, _ day: String) -> FXQuote {
            let cur = currency.uppercased()
            if cur == "CAD" { return FXQuote(cadPerUnit: 1, exact: true) }
            if let obs = series[cur], !obs.isEmpty {
                // Last observation on or before the day (weekends and holidays use the prior business day).
                var lo = 0, hi = obs.count - 1, found = -1
                while lo <= hi {
                    let mid = (lo + hi) / 2
                    if obs[mid].day <= day { found = mid; lo = mid + 1 } else { hi = mid - 1 }
                }
                if found >= 0 {
                    let gap = ACBEngine.shift(obs[found].day, days: 7) >= day
                    return FXQuote(cadPerUnit: obs[found].rate, exact: gap)
                }
                return FXQuote(cadPerUnit: obs[0].rate, exact: false)
            }
            return FXQuote(cadPerUnit: fallback(cur) ?? 1, exact: false)
        }
    }

    private var cache: [String: [(day: String, rate: Double)]] = [:]

    func table(for currencies: Set<String>, fallback: @escaping @Sendable (String) -> Double?) async -> Table {
        for cur in currencies.map({ $0.uppercased() }) where cur != "CAD" && cache[cur] == nil {
            if let obs = await load(cur) { cache[cur] = obs }
        }
        return Table(series: cache, fallback: fallback)
    }

    private func cacheURL(_ cur: String) -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("boc_fx_\(cur).json")
    }

    private struct Stored: Codable { let fetchedAt: Date; let days: [String]; let rates: [Double] }

    private func load(_ cur: String) async -> [(day: String, rate: Double)]? {
        if let url = cacheURL(cur), let data = try? Data(contentsOf: url),
           let s = try? JSONDecoder().decode(Stored.self, from: data),
           Date().timeIntervalSince(s.fetchedAt) < 86_400 {
            return Array(zip(s.days, s.rates)).map { (day: $0.0, rate: $0.1) }
        }
        guard let url = URL(string: "https://www.bankofcanada.ca/valet/observations/FX\(cur)CAD/json?start_date=2017-01-01"),
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let observations = json["observations"] as? [[String: Any]] else { return nil }
        let key = "FX\(cur)CAD"
        let obs: [(day: String, rate: Double)] = observations.compactMap { o in
            guard let d = o["d"] as? String, let v = (o[key] as? [String: Any])?["v"] as? String, let r = Double(v) else { return nil }
            return (d, r)
        }.sorted { $0.day < $1.day }
        guard !obs.isEmpty else { return nil }
        if let url = cacheURL(cur) {
            let stored = Stored(fetchedAt: Date(), days: obs.map(\.day), rates: obs.map(\.rate))
            try? JSONEncoder().encode(stored).write(to: url)
        }
        return obs
    }
}
