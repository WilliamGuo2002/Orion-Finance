import Foundation
import SwiftUI

// MARK: - Snapshot (single published value = one redraw per update)
struct HoldingsSnapshot: Equatable {
    var aggregated: [AggregatedHolding] = []
    /// Net worth in USD: every linked account (investments at live prices, bank balances,
    /// minus credit lines / mortgages).
    var totalValue: Double = 0
    /// Everything in `totalValue` that isn't a priced position (cash, bank balances, debts…), USD.
    var cashValue: Double = 0
    /// Live value of each linked account in USD, keyed by account id — SnapTrade ids as-is,
    /// Plaid ids via `bankKey(_:)` (debts are negative).
    var accountValues: [String: Double] = [:]
    /// True when a linked account holds CAD (account, cash or positions) → offer the USD/CAD toggle.
    var hasCADExposure = false
    var totalCostBasis: Double = 0
    var totalPnL: Double = 0
    var totalPnLPercent: Double = 0
    var totalDayPnL: Double = 0

    /// All stored amounts are USD; these convert them for display only.
    var displayCurrency: String = "USD"
    var usdToDisplay: Double = 1

    var hasHoldings: Bool { !aggregated.isEmpty || !accountValues.isEmpty }
    static func bankKey(_ accountId: String) -> String { "bank:\(accountId)" }
    /// Market value of positions only (no cash), in USD.
    var positionsValue: Double { totalValue - cashValue }

    /// USD amount → display-currency amount.
    func display(_ usd: Double) -> Double { usd * usdToDisplay }
    /// USD amount → "$1,234.56" / "CA$1,234.56".
    func format(_ usd: Double) -> String { Money.format(display(usd), currency: displayCurrency) }
    var currencySymbol: String { Money.symbol(for: displayCurrency) }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.displayCurrency == rhs.displayCurrency &&
        lhs.usdToDisplay == rhs.usdToDisplay &&
        lhs.totalValue == rhs.totalValue &&
        lhs.cashValue == rhs.cashValue &&
        lhs.accountValues == rhs.accountValues &&
        lhs.hasCADExposure == rhs.hasCADExposure &&
        lhs.totalPnL == rhs.totalPnL &&
        lhs.totalDayPnL == rhs.totalDayPnL &&
        lhs.aggregated.count == rhs.aggregated.count &&
        lhs.aggregated.map(\.id) == rhs.aggregated.map(\.id)
    }
}

/// Net worth from linked accounts (`BrokerageManager`): investment positions at live prices,
/// cash, bank balances and debts. Everything is normalized to USD.
/// Manually entered trades are no longer part of the total (the old data stays in Firestore).
@MainActor
class HoldingsManager: ObservableObject {
    static let shared = HoldingsManager()

    /// Single published snapshot — one objectWillChange per data update
    @Published var snapshot = HoldingsSnapshot()
    @Published var portfolioChart: [PortfolioValueEntry] = []
    @Published var isLoading = false

    /// Internal — not published
    private(set) var transactions: [HoldingTransaction] = []
    /// True once `loadAll()` has completed at least once.
    private(set) var hasLoaded = false
    /// Range the chart was last loaded with, so brokerage changes can redraw it.
    private(set) var chartRange = "1M"
    /// Last good FX rates to USD (e.g. "CAD": 0.72). Kept so one failed fetch doesn't mis-sum.
    private var fxToUSD: [String: Double] = ["USD": 1]

    private init() {}

    // MARK: - Load all (manual transactions + linked brokerages)

    func loadAll() async {
        isLoading = true
        async let brokerages: Void = BrokerageManager.shared.syncIfLinked()
        async let banks: Void = BankManager.shared.syncIfLinked()
        _ = await (brokerages, banks)
        await refreshPrices()
        recordTodaySnapshot()
        hasLoaded = true
        isLoading = false
    }

    /// Recompute totals and chart after a brokerage was connected, removed, or re-synced.
    func reloadAfterBrokerageChange() async {
        await refreshPrices()
        recordTodaySnapshot()
        await loadPortfolioChart(range: chartRange)
    }

    /// Keeps today's point of the real net-worth history current (the server writes it nightly too).
    private func recordTodaySnapshot() {
        guard snapshot.hasHoldings else { return }
        NetWorthHistory.shared.recordToday(totalUSD: snapshot.totalValue, institutions: institutionTotals(snapshot))
    }

    // MARK: - Display currency (USD default, CAD optional)

    /// Switch the currency all portfolio amounts are shown in. Values are re-converted,
    /// prices are not re-fetched (only the FX rate, if needed).
    func setDisplayCurrency(_ currency: String) async {
        SettingsManager.shared.displayCurrency = currency
        if currency != "USD" { await refreshFXRates(for: [currency]) }
        var updated = snapshot
        stampDisplayCurrency(&updated)
        snapshot = updated
    }

    /// Converts an amount in `currency` to USD with the latest known rate.
    func usd(_ amount: Double, from currency: String) -> Double {
        amount * (fxToUSD[currency.uppercased()] ?? 1)
    }

    private func stampDisplayCurrency(_ snap: inout HoldingsSnapshot) {
        let wanted = SettingsManager.shared.displayCurrency
        // No FX rate yet → stay in USD rather than relabel USD numbers as CAD.
        if wanted != "USD", let rate = fxToUSD[wanted], rate > 0 {
            snap.displayCurrency = wanted
            snap.usdToDisplay = 1 / rate
        } else {
            snap.displayCurrency = "USD"
            snap.usdToDisplay = 1
        }
    }

    // MARK: - Add transaction

    func addTransaction(_ tx: HoldingTransaction) {
        transactions.append(tx)
        FirebaseController.shared.addHoldingTransaction(tx)
        Task { await refreshPrices() }
    }

    // MARK: - Delete transaction

    func deleteTransaction(id: String) {
        transactions.removeAll { $0.id == id }
        FirebaseController.shared.deleteHoldingTransaction(id: id)
        Task { await refreshPrices() }
    }

    // MARK: - Get transactions for a specific symbol

    func transactions(for symbol: String) -> [HoldingTransaction] {
        transactions.filter { $0.symbol.uppercased() == symbol.uppercased() }
    }

    // MARK: - Combined position for one symbol (manual + every linked account)

    func aggregatedHolding(for symbol: String) -> AggregatedHolding? {
        let matches = snapshot.aggregated.filter { $0.symbol.uppercased() == symbol.uppercased() }
        // Prefer the manual entry so its transactions stay attached.
        guard let primary = matches.first(where: { !$0.source.isLinked }) ?? matches.first else { return nil }
        guard matches.count > 1 else { return primary }

        let shares = matches.reduce(0) { $0 + $1.totalShares }
        let cost = matches.reduce(0) { $0 + $1.totalCostBasis }
        return AggregatedHolding(
            symbol: primary.symbol,
            name: primary.name,
            totalShares: shares,
            averageCost: shares > 0 ? cost / shares : 0,
            totalCostBasis: cost,
            currentPrice: primary.currentPrice,
            previousClose: primary.previousClose,
            transactions: primary.transactions
        )
    }

    // MARK: - Unique manually held symbols

    var heldSymbols: [String] {
        let symbolSet = Set(transactions.map { $0.symbol.uppercased() })
        return symbolSet.filter { netManualShares(for: $0) > 0.0001 }.sorted()
    }

    private func netManualShares(for symbol: String) -> Double {
        transactions(for: symbol).reduce(0.0) { acc, tx in
            acc + (tx.action == .buy ? tx.shares : -tx.shares)
        }
    }

    private var linkedPositions: [(account: LinkedAccount, position: LinkedPosition)] {
        BrokerageManager.shared.currentAccounts.flatMap { account in
            account.positions.filter { $0.units > 1e-9 }.map { (account, $0) }
        }
    }

    // MARK: - Refresh prices & recompute aggregations

    /// Bank accounts minus any that are already linked through SnapTrade (same institution and
    /// last 4 digits), so linking one institution through both services doesn't count it twice.
    static func dedupedBankAccounts(_ banks: [BankAccount], brokerage: [LinkedAccount]) -> [BankAccount] {
        guard !brokerage.isEmpty else { return banks }
        let bankManager = BankManager.shared
        func firstWord(_ s: String) -> String {
            s.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).first.map(String.init) ?? ""
        }
        return banks.filter { bank in
            guard let mask = bank.mask, !mask.isEmpty else { return true }
            let bankInstitution = firstWord(bankManager.institution(for: bank))
            return !brokerage.contains { acct in
                guard let number = acct.number, number.hasSuffix(mask) else { return false }
                return firstWord(acct.institution) == bankInstitution
            }
        }
    }

    /// Symbols whose Yahoo quote disagreed with the broker's price (wrong listing / currency).
    /// Their broker price is used instead, and the chart leaves them out.
    private var untrustedQuotes: Set<String> = []

    func refreshPrices() async {
        let linked = linkedPositions
        let accounts = BrokerageManager.shared.currentAccounts
        let bankAccounts = Self.dedupedBankAccounts(BankManager.shared.currentAccounts, brokerage: accounts)
        let hasCAD = bankAccounts.contains { $0.currency.uppercased() == "CAD" } || accounts.contains { acct in
            acct.currency.uppercased() == "CAD"
                || acct.cash.contains { $0.currency.uppercased() == "CAD" }
                || acct.positions.contains { $0.currency.uppercased() == "CAD" }
        }
        guard !accounts.isEmpty || !bankAccounts.isEmpty else {
            var empty = HoldingsSnapshot()
            stampDisplayCurrency(&empty)
            snapshot = empty
            portfolioChart = []
            return
        }

        let symbols = Set(linked.map { $0.position.symbol.uppercased() })
        let fxNeeded = Set(linked.map { $0.position.currency.uppercased() })
            .union(accounts.flatMap(\.cash).map { $0.currency.uppercased() })
            .union(accounts.map { $0.currency.uppercased() })
            .union(bankAccounts.map { $0.currency.uppercased() })
            .union([SettingsManager.shared.displayCurrency])
        async let quotesTask = fetchQuotes(Array(symbols))
        async let fxTask: Void = refreshFXRates(for: fxNeeded)
        let quotes = await quotesTask
        await fxTask

        // Investment positions → USD, at live prices
        var newAggregated: [AggregatedHolding] = []
        var positionsUSD: [String: Double] = [:]   // per account
        var untrusted: Set<String> = []
        for (account, pos) in linked {
            let sym = pos.symbol.uppercased()
            let currency = pos.currency.uppercased()
            let fx = fxToUSD[currency] ?? 1
            let brokerPrice = pos.price ?? 0
            let livePrice = quotes[sym]?.price ?? 0
            let livePrev = quotes[sym]?.previousClose ?? 0
            var nativePrice = livePrice > 0 ? livePrice : brokerPrice
            var nativePrev = livePrev > 0 ? livePrev : nativePrice
            // A quote far from the broker's price is probably a different listing or currency.
            if brokerPrice > 0, livePrice > 0, abs(livePrice / brokerPrice - 1) > 0.25 {
                nativePrice = brokerPrice
                nativePrev = brokerPrice
                untrusted.insert(sym)
            }
            if livePrice <= 0 { untrusted.insert(sym) }
            let nativeAvg = pos.averageCost ?? nativePrice

            var agg = AggregatedHolding(
                symbol: sym,
                name: pos.description ?? pos.displaySymbol ?? sym,
                totalShares: pos.units,
                averageCost: nativeAvg * fx,
                totalCostBasis: nativeAvg * fx * pos.units,
                currentPrice: nativePrice * fx,
                previousClose: nativePrev * fx,
                transactions: []
            )
            agg.source = .linked(accountId: account.id, accountName: account.name, institution: account.institution)
            agg.currency = currency
            agg.fxToUSD = fx
            newAggregated.append(agg)
            positionsUSD[account.id, default: 0] += agg.marketValue
        }
        untrustedQuotes = untrusted

        // Each account's live value. Debts count against net worth.
        var accountValues: [String: Double] = [:]
        for account in accounts {
            let net = account.totalValue.map { usd($0, from: account.currency) }
            switch account.accountKind {
            case .investment:
                let cash = account.cash.reduce(0) { $0 + usd($1.amount, from: $1.currency) }
                let live = positionsUSD[account.id, default: 0] + cash
                // Positions we can't price (options…) or a failed load → trust the broker's total.
                let incomplete = (account.unpricedPositions ?? 0) > 0 || account.error != nil
                    || (account.positions.isEmpty && account.cash.isEmpty)
                accountValues[account.id] = (incomplete ? net : nil) ?? live
            case .debt:
                accountValues[account.id] = -abs(net ?? 0)
            case .cash, .other:
                accountValues[account.id] = net ?? 0
            }
        }
        // Bank accounts (Plaid): balances as reported; cards and loans count against net worth.
        for bank in bankAccounts {
            accountValues[HoldingsSnapshot.bankKey(bank.id)] = usd(bank.netValue ?? 0, from: bank.currency)
        }

        // Single atomic update — only ONE objectWillChange fires.
        // P&L is on positions only; the total is the sum of every account.
        let value = newAggregated.reduce(0) { $0 + $1.marketValue }
        let cost = newAggregated.reduce(0) { $0 + $1.totalCostBasis }
        let pnl = value - cost
        let pnlPct = cost > 0 ? (pnl / cost) * 100 : 0
        let dayPnl = newAggregated.reduce(0) { $0 + $1.dayPnL }
        let netWorth = accountValues.values.reduce(0, +)

        var newSnapshot = HoldingsSnapshot(
            aggregated: newAggregated,
            totalValue: netWorth,
            cashValue: netWorth - value,
            accountValues: accountValues,
            hasCADExposure: hasCAD,
            totalCostBasis: cost,
            totalPnL: pnl,
            totalPnLPercent: pnlPct,
            totalDayPnL: dayPnl
        )
        stampDisplayCurrency(&newSnapshot)
        snapshot = newSnapshot
    }

    private func fetchQuotes(_ symbols: [String]) async -> [String: (price: Double, previousClose: Double)] {
        await withTaskGroup(of: (String, Double, Double)?.self) { group in
            for sym in symbols {
                group.addTask {
                    guard let q = try? await APIService.shared.fetchChartAndQuote(symbol: sym) else { return nil }
                    return (sym, q.price, q.previousClose)
                }
            }
            var map: [String: (price: Double, previousClose: Double)] = [:]
            for await result in group {
                if let (sym, price, prev) = result { map[sym] = (price, prev) }
            }
            return map
        }
    }

    private func fetchNames(_ symbols: [String]) async -> [String: String] {
        await withTaskGroup(of: (String, String)?.self) { group in
            for sym in symbols {
                group.addTask {
                    guard let profile = try? await APIService.shared.fetchCompanyProfile(symbol: sym) else { return nil }
                    return (sym, profile.name)
                }
            }
            var map: [String: String] = [:]
            for await result in group {
                if let (sym, name) = result { map[sym] = name }
            }
            return map
        }
    }

    /// Fetches e.g. CADUSD=X from Yahoo. Keeps the last good rate if a fetch fails.
    private func refreshFXRates(for currencies: Set<String>) async {
        let needed = currencies.subtracting(["USD"])
        guard !needed.isEmpty else { return }
        let fresh: [String: Double] = await withTaskGroup(of: (String, Double)?.self) { group in
            for currency in needed {
                group.addTask {
                    guard let quote = try? await APIService.shared.fetchMarketIndex(symbol: "\(currency)USD=X", name: currency),
                          quote.price > 0 else { return nil }
                    return (currency, quote.price)
                }
            }
            var map: [String: Double] = [:]
            for await result in group {
                if let (currency, rate) = result { map[currency] = rate }
            }
            return map
        }
        for (currency, rate) in fresh { fxToUSD[currency] = rate }
    }

    // MARK: - Aggregate helper (average cost basis)

    static func aggregate(symbol: String, name: String, transactions: [HoldingTransaction],
                          currentPrice: Double, previousClose: Double) -> AggregatedHolding {
        var totalShares: Double = 0
        var totalCost: Double = 0

        for tx in transactions {
            if tx.action == .buy {
                totalCost += tx.shares * tx.pricePerShare
                totalShares += tx.shares
            } else {
                let sharesToSell = min(tx.shares, totalShares)
                if totalShares > 0 {
                    let avgCost = totalCost / totalShares
                    totalCost -= sharesToSell * avgCost
                }
                totalShares -= sharesToSell
                totalShares = max(0, totalShares)
                totalCost = max(0, totalCost)
            }
        }

        let avgCost = totalShares > 0 ? totalCost / totalShares : 0

        return AggregatedHolding(
            symbol: symbol,
            name: name,
            totalShares: totalShares,
            averageCost: avgCost,
            totalCostBasis: totalCost,
            currentPrice: currentPrice,
            previousClose: previousClose,
            transactions: transactions
        )
    }

    // MARK: - Portfolio Chart Computation

    func loadPortfolioChart(range: String = "1M") async {
        chartRange = range
        portfolioChart = await computeChart(range: range)
    }

    /// Institution each account belongs to (brokerage or bank name), with that account's USD value.
    /// Same-named institutions from SnapTrade and Plaid are merged.
    func institutionTotals(_ snap: HoldingsSnapshot) -> [String: Double] {
        var totals: [String: Double] = [:]
        for account in BrokerageManager.shared.currentAccounts {
            if let v = snap.accountValues[account.id] { totals[account.institution, default: 0] += v }
        }
        let bank = BankManager.shared
        for account in bank.currentAccounts {
            if let v = snap.accountValues[HoldingsSnapshot.bankKey(account.id)] {
                totals[bank.institution(for: account), default: 0] += v
            }
        }
        return totals
    }

    /// Net-worth series for a range, with a per-institution breakdown on every point.
    /// Not published — the Accounts page keeps its own range independent of home.
    ///
    /// Shape: each institution = its current holdings at historical prices + a "remainder"
    /// (cash, bank balances, debts, unpriced positions). Today the remainder comes from live values;
    /// on past days it comes from the stored daily snapshot, so the line passes exactly through
    /// the real net worth recorded that day. Before the first snapshot, the earliest one is used.
    func computeChart(range: String) async -> [PortfolioValueEntry] {
        let snap = snapshot
        guard snap.hasHoldings else { return [] }
        await NetWorthHistory.shared.loadIfNeeded()
        let history = NetWorthHistory.shared.records

        // USD-weighted units per (institution, symbol). Symbols whose Yahoo series doesn't
        // match the broker are left out (the remainder covers them).
        var shares: [String: [String: Double]] = [:]
        for (account, pos) in linkedPositions where !untrustedQuotes.contains(pos.symbol.uppercased()) {
            let fx = fxToUSD[pos.currency.uppercased()] ?? 1
            shares[account.institution, default: [:]][pos.symbol.uppercased(), default: 0] += pos.units * fx
        }
        let symbols = Set(shares.values.flatMap(\.keys))

        let (yahooRange, yahooInterval) = chartParams(for: range)
        var chartDataMap: [String: [ChartEntry]] = [:]
        await withTaskGroup(of: (String, [ChartEntry])?.self) { group in
            for sym in symbols {
                group.addTask {
                    guard let result = try? await APIService.shared.fetchChartAndQuote(
                        symbol: sym, range: yahooRange, interval: yahooInterval
                    ) else { return nil }
                    return (sym, result.chartData)
                }
            }
            for await result in group {
                if let (sym, data) = result { chartDataMap[sym] = data }
            }
        }

        let parseFmt = DateFormatter()
        parseFmt.dateFormat = "yyyy-MM-dd HH:mm"
        let today = NetWorthHistory.dayKey(Date())

        // Time axis: price bars when there are positions; otherwise the snapshot days in range.
        var points: [(date: Date, day: String)] = []
        if let dateSeries = chartDataMap.values.max(by: { $0.count < $1.count }), !dateSeries.isEmpty {
            points = dateSeries.map { bar in
                let date = parseFmt.date(from: bar.datetime) ?? Date()
                return (date, String(bar.datetime.prefix(10)))
            }
        } else {
            let start = NetWorthHistory.calendar.date(byAdding: .day, value: -Self.rangeDays(range), to: Date()) ?? Date()
            let startKey = NetWorthHistory.dayKey(start)
            points = history.keys.filter { $0 >= startKey && $0 < today }.sorted().map { day in
                (parseFmt.date(from: day + " 12:00") ?? Date(), day)
            }
            if points.isEmpty { points = [(Date(), today)] }
            points.append((Date(), today))
        }
        let count = points.count

        func positionsValue(_ inst: String, at i: Int) -> Double {
            (shares[inst] ?? [:]).reduce(0) { acc, kv in
                guard let data = chartDataMap[kv.key], i < data.count else { return acc }
                return acc + kv.value * Double(data[i].close)
            }
        }

        let totals = institutionTotals(snap)
        // Live remainder (today)
        var liveRemainder: [String: Double] = [:]
        for (inst, total) in totals { liveRemainder[inst] = total - positionsValue(inst, at: count - 1) }

        // Remainder on each past snapshot day: recorded value − holdings at that day's last bar.
        let pastDays = history.keys.filter { $0 < today }.sorted()
        var dayRemainder: [String: [String: Double]] = [:]
        for day in pastDays {
            guard let record = history[day] else { continue }
            let idx = points.lastIndex { $0.day <= day } ?? 0
            var r: [String: Double] = [:]
            for inst in totals.keys {
                if let v = record.institutions[inst] { r[inst] = v - positionsValue(inst, at: idx) }
            }
            dayRemainder[day] = r
        }
        func remainder(_ inst: String, day: String) -> Double {
            guard day < today, !pastDays.isEmpty else { return liveRemainder[inst] ?? 0 }
            // Latest snapshot on or before this day; before history starts, the earliest one.
            let source = pastDays.last { $0 <= day } ?? pastDays[0]
            return dayRemainder[source]?[inst] ?? liveRemainder[inst] ?? 0
        }

        // Anything not attributed to an institution still belongs in the total.
        let unattributed = snap.totalValue - totals.values.reduce(0, +)
        // Unambiguous, localized labels for the scrub readout (HIG Charts: "Jun 6", not "6/6").
        let displayFmt = DateFormatter()
        displayFmt.locale = AppLocale.current
        switch range {
        case "1D":  displayFmt.setLocalizedDateFormatFromTemplate("jmm")
        case "5D":  displayFmt.setLocalizedDateFormatFromTemplate("EEEjmm")
        default:    displayFmt.setLocalizedDateFormatFromTemplate("yMMMd")
        }
        // Cost line chosen so value − cost at the last point equals the header's P&L.
        let costLine = snap.totalValue - snap.totalPnL

        return points.enumerated().map { i, point in
            var breakdown: [String: Double] = [:]
            for inst in totals.keys {
                breakdown[inst] = positionsValue(inst, at: i) + remainder(inst, day: i == count - 1 ? today : point.day)
            }
            let value = breakdown.values.reduce(0, +) + unattributed
            return PortfolioValueEntry(
                index: i, date: point.date, value: value,
                costBasis: costLine, cash: costLine - snap.totalCostBasis,
                datetime: displayFmt.string(from: point.date),
                breakdown: breakdown
            )
        }
    }

    private static func rangeDays(_ range: String) -> Int {
        switch range {
        case "1D": return 1
        case "5D": return 7
        case "1M": return 31
        case "6M": return 183
        default:   return 366
        }
    }

    private func chartParams(for range: String) -> (String, String) {
        switch range {
        case "1D":  return ("1d", "5m")
        case "5D":  return ("5d", "30m")
        case "1M":  return ("1mo", "1d")
        case "6M":  return ("6mo", "1d")
        case "YTD": return ("ytd", "1d")
        case "1Y":  return ("1y", "1wk")
        case "ALL": return ("max", "1mo")
        default:    return ("1mo", "1d")
        }
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
