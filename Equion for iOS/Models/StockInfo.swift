import Foundation

struct ChartEntry: Identifiable {
    let id = UUID()
    let index: Int
    let close: Float
    let datetime: String
    /// Shares traded in this bar (0 when the source has none — indices, FX).
    var volume: Double = 0
    /// Bar open / high / low (candlesticks). Fall back to the close when the source omits them.
    var open: Float? = nil
    var high: Float? = nil
    var low: Float? = nil

    var o: Float { open ?? close }
    var h: Float { max(high ?? close, o, close) }
    var l: Float { min(low ?? close, o, close) }
    /// Up bar: closed at or above its open.
    var isUp: Bool { close >= o }
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
