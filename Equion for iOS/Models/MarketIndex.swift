import Foundation

/// A market gauge shown in the home header. The free data source gives ETF prices (SPY, QQQ, DIA),
/// so `symbol` is what's displayed — never an index name next to an ETF price.
struct MarketIndex: Identifiable {
    var id: String { symbol }
    let symbol: String
    /// Descriptive name, e.g. "S&P 500 ETF" — used for VoiceOver and secondary text.
    let name: String
    let price: Double
    let changePercent: Double
    /// Time of the last regular-session trade.
    var asOf: Date? = nil
}
