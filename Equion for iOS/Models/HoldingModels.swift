import Foundation

// MARK: - Holding Transaction (stored in Firestore)
struct HoldingTransaction: Identifiable, Codable {
    var id: String = UUID().uuidString
    let symbol: String
    let action: HoldingAction   // buy or sell
    let shares: Double
    let pricePerShare: Double
    let date: Date
    let createdAt: Date

    var totalValue: Double { shares * pricePerShare }

    enum HoldingAction: String, Codable {
        case buy, sell
    }
}

// MARK: - Holding Source
/// Where a holding comes from: typed in by the user, or synced from a linked brokerage account.
enum HoldingSource: Hashable {
    case manual
    case linked(accountId: String, accountName: String, institution: String)

    var key: String {
        switch self {
        case .manual: return "manual"
        case .linked(let accountId, _, _): return "linked:\(accountId)"
        }
    }

    var isLinked: Bool { if case .linked = self { return true } else { return false } }
}

// MARK: - Aggregated Holding (computed client-side)
/// All money values (averageCost, totalCostBasis, prices) are in USD — the app's display currency.
/// `currency` / `fxToUSD` keep the native currency so lists can show e.g. CA$ values.
struct AggregatedHolding: Identifiable {
    let symbol: String
    let name: String
    let totalShares: Double          // net shares held
    let averageCost: Double          // weighted average purchase price
    let totalCostBasis: Double       // total $ invested (for current shares)
    let currentPrice: Double
    let previousClose: Double
    let transactions: [HoldingTransaction]
    var source: HoldingSource = .manual
    var currency: String = "USD"     // native quote currency
    var fxToUSD: Double = 1          // native × fxToUSD = USD

    /// Unique per source, so the same ticker can appear in several accounts.
    var id: String { "\(source.key)|\(symbol)" }

    /// Market value in the holding's native currency.
    var nativeMarketValue: Double { fxToUSD > 0 ? marketValue / fxToUSD : marketValue }

    /// Total market value of position
    var marketValue: Double { totalShares * currentPrice }

    /// Total unrealised P&L (absolute)
    var totalPnL: Double { marketValue - totalCostBasis }

    /// Total unrealised P&L (percent)
    var totalPnLPercent: Double {
        guard totalCostBasis > 0 else { return 0 }
        return (totalPnL / totalCostBasis) * 100
    }

    /// Today's P&L (absolute)
    var dayPnL: Double {
        guard previousClose > 0 else { return 0 }
        return totalShares * (currentPrice - previousClose)
    }

    /// Today's P&L (percent)
    var dayPnLPercent: Double {
        guard previousClose > 0 else { return 0 }
        return ((currentPrice - previousClose) / previousClose) * 100
    }
}

// MARK: - Portfolio Value Entry (for chart)
struct PortfolioValueEntry: Identifiable {
    let id = UUID()
    let index: Int
    let date: Date
    let value: Double      // total portfolio value at this point (positions + cash)
    let costBasis: Double  // total cost basis + cash (flat line per period)
    var cash: Double = 0   // linked-account cash included in both of the above
    let datetime: String   // human-readable date/time for display
    /// Value per institution (brokerage / bank name), USD. Sums to `value`.
    var breakdown: [String: Double] = [:]
}
