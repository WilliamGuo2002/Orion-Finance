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

// MARK: - Aggregated Holding (computed client-side)
struct AggregatedHolding: Identifiable {
    let symbol: String
    let name: String
    let totalShares: Double          // net shares held
    let averageCost: Double          // weighted average purchase price
    let totalCostBasis: Double       // total $ invested (for current shares)
    let currentPrice: Double
    let previousClose: Double
    let transactions: [HoldingTransaction]

    var id: String { symbol }

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
    let value: Double      // total portfolio market value at this point
    let costBasis: Double  // total cost basis (flat line per period)
    let datetime: String   // human-readable date/time for display
}
