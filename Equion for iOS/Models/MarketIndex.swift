import Foundation

struct MarketIndex: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let changePercent: Double
}
