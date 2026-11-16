import Foundation

struct ChartEntry: Identifiable {
    let id = UUID()
    let index: Int
    let close: Float
    let datetime: String
    /// Shares traded in this bar (0 when the source has none — indices, FX).
    var volume: Double = 0
}

struct StockComment: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let text: String
    let timestamp: Date
}

struct StockInfo: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double
    var chartData: [ChartEntry]
    var logoURL: String?
    var swiped: Bool = false
}
