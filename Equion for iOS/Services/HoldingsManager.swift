import Foundation
import SwiftUI

// MARK: - Snapshot (single published value = one redraw per update)
struct HoldingsSnapshot: Equatable {
    var aggregated: [AggregatedHolding] = []
    var totalValue: Double = 0
    var totalCostBasis: Double = 0
    var totalPnL: Double = 0
    var totalPnLPercent: Double = 0
    var totalDayPnL: Double = 0

    var hasHoldings: Bool { !aggregated.isEmpty }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.totalValue == rhs.totalValue &&
        lhs.totalPnL == rhs.totalPnL &&
        lhs.totalDayPnL == rhs.totalDayPnL &&
        lhs.aggregated.count == rhs.aggregated.count &&
        lhs.aggregated.map(\.symbol) == rhs.aggregated.map(\.symbol)
    }
}

@MainActor
class HoldingsManager: ObservableObject {
    static let shared = HoldingsManager()

    /// Single published snapshot — one objectWillChange per data update
    @Published var snapshot = HoldingsSnapshot()
    @Published var portfolioChart: [PortfolioValueEntry] = []
    @Published var isLoading = false

    /// Internal — not published
    private(set) var transactions: [HoldingTransaction] = []

    private init() {}

    // MARK: - Load all transactions from Firestore

    func loadAll() async {
        isLoading = true
        transactions = await FirebaseController.shared.getAllHoldings()
        await refreshPrices()
        isLoading = false
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

    // MARK: - Aggregate for a single symbol (with live price)

    func aggregatedHolding(for symbol: String) -> AggregatedHolding? {
        snapshot.aggregated.first { $0.symbol.uppercased() == symbol.uppercased() }
    }

    // MARK: - Unique held symbols

    var heldSymbols: [String] {
        let symbolSet = Set(transactions.map { $0.symbol.uppercased() })
        return symbolSet.filter { sym in
            let txs = transactions.filter { $0.symbol.uppercased() == sym }
            let net = txs.reduce(0.0) { acc, tx in
                acc + (tx.action == .buy ? tx.shares : -tx.shares)
            }
            return net > 0.0001
        }.sorted()
    }

    // MARK: - Refresh prices & recompute aggregations

    func refreshPrices() async {
        let symbols = heldSymbols
        guard !symbols.isEmpty else {
            snapshot = HoldingsSnapshot()
            portfolioChart = []
            return
        }

        // Fetch current prices for all held symbols concurrently
        var priceMap: [String: (price: Double, prevClose: Double, name: String)] = [:]

        await withTaskGroup(of: (String, Double, Double, String)?.self) { group in
            for sym in symbols {
                group.addTask {
                    do {
                        let chartQuote = try await APIService.shared.fetchChartAndQuote(symbol: sym)
                        let prof = try await APIService.shared.fetchCompanyProfile(symbol: sym)
                        return (sym, chartQuote.price, chartQuote.previousClose, prof.name)
                    } catch {
                        return nil
                    }
                }
            }
            for await result in group {
                if let (sym, price, prevClose, name) = result {
                    priceMap[sym.uppercased()] = (price, prevClose, name)
                }
            }
        }

        // Build aggregated holdings
        var newAggregated: [AggregatedHolding] = []
        for sym in symbols {
            let txs = transactions.filter { $0.symbol.uppercased() == sym }
            let info = priceMap[sym] ?? (0, 0, sym)
            let agg = Self.aggregate(symbol: sym, name: info.name, transactions: txs,
                                     currentPrice: info.price, previousClose: info.prevClose)
            if agg.totalShares > 0.0001 {
                newAggregated.append(agg)
            }
        }

        // Single atomic update — only ONE objectWillChange fires
        let value = newAggregated.reduce(0) { $0 + $1.marketValue }
        let cost = newAggregated.reduce(0) { $0 + $1.totalCostBasis }
        let pnl = value - cost
        let pnlPct = cost > 0 ? (pnl / cost) * 100 : 0
        let dayPnl = newAggregated.reduce(0) { $0 + $1.dayPnL }

        snapshot = HoldingsSnapshot(
            aggregated: newAggregated,
            totalValue: value,
            totalCostBasis: cost,
            totalPnL: pnl,
            totalPnLPercent: pnlPct,
            totalDayPnL: dayPnl
        )
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
        let symbols = heldSymbols
        guard !symbols.isEmpty else {
            portfolioChart = []
            return
        }

        let (yahooRange, yahooInterval) = chartParams(for: range)

        var chartDataMap: [String: [ChartEntry]] = [:]

        await withTaskGroup(of: (String, [ChartEntry])?.self) { group in
            for sym in symbols {
                group.addTask {
                    do {
                        let result = try await APIService.shared.fetchChartAndQuote(
                            symbol: sym, range: yahooRange, interval: yahooInterval
                        )
                        return (sym.uppercased(), result.chartData)
                    } catch {
                        return nil
                    }
                }
            }
            for await result in group {
                if let (sym, data) = result {
                    chartDataMap[sym] = data
                }
            }
        }

        guard let maxCount = chartDataMap.values.map({ $0.count }).max(), maxCount > 0 else {
            portfolioChart = []
            return
        }

        // Compute total cost basis (constant for the chart period)
        let totalCost = snapshot.totalCostBasis

        var entries: [PortfolioValueEntry] = []
        let parseFmt = DateFormatter()
        parseFmt.dateFormat = "yyyy-MM-dd HH:mm"
        let displayFmt = DateFormatter()
        // Adjust display format based on range
        switch range {
        case "1D":  displayFmt.dateFormat = "h:mm a"
        case "5D":  displayFmt.dateFormat = "EEE h:mm a"
        default:    displayFmt.dateFormat = "MMM d, yyyy"
        }

        for i in 0..<maxCount {
            var totalVal: Double = 0
            for sym in symbols {
                let txs = transactions.filter { $0.symbol.uppercased() == sym }
                let netShares = txs.reduce(0.0) { acc, tx in
                    acc + (tx.action == .buy ? tx.shares : -tx.shares)
                }
                guard netShares > 0 else { continue }

                if let chartData = chartDataMap[sym], i < chartData.count {
                    totalVal += netShares * Double(chartData[i].close)
                }
            }

            let rawDateStr = chartDataMap.values.first?[safe: i]?.datetime ?? ""
            let date = parseFmt.date(from: rawDateStr) ?? Date()
            let displayStr = displayFmt.string(from: date)

            entries.append(PortfolioValueEntry(
                index: i, date: date, value: totalVal,
                costBasis: totalCost, datetime: displayStr
            ))
        }

        portfolioChart = entries
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
