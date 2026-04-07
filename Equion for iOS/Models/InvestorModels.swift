import Foundation

struct FamousInvestor: Identifiable {
    let id: String
    let name: String
    let fund: String
    let cik: String
    let description: String
}

struct InvestorHolding: Identifiable, Codable {
    var id = UUID()
    let name: String
    let cusip: String
    let value: Double       // in dollars
    let shares: Int
    var percentage: Double  // of total portfolio
}

struct InvestorPortfolio: Codable {
    let filingDate: String
    let holdings: [InvestorHolding]
    let totalValue: Double
}
