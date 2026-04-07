import Foundation
import Combine

// MARK: - Interest Category
struct InterestCategory: Identifiable, Hashable {
    let id: String
    let name: String          // English key (for L())
    let icon: String          // SF Symbol
    let color: String         // Color identifier
    let description: String   // Short English description key

    static let all: [InterestCategory] = [
        // Stock sectors
        InterestCategory(id: "tech",        name: "Technology",       icon: "laptopcomputer",           color: "blue",   description: "Apple, Microsoft, NVIDIA..."),
        InterestCategory(id: "finance",     name: "Finance",          icon: "banknote",                 color: "green",  description: "JPMorgan, Goldman Sachs..."),
        InterestCategory(id: "healthcare",  name: "Healthcare",       icon: "heart.text.square",        color: "red",    description: "Pfizer, UnitedHealth..."),
        InterestCategory(id: "energy",      name: "Energy",           icon: "bolt.fill",                color: "orange", description: "ExxonMobil, Chevron..."),
        InterestCategory(id: "consumer",    name: "Consumer",         icon: "cart.fill",                color: "purple", description: "Amazon, Tesla, Nike..."),
        InterestCategory(id: "realestate",  name: "Real Estate",      icon: "building.2.fill",          color: "brown",  description: "REITs, Realty Income..."),
        InterestCategory(id: "industrial",  name: "Industrial",       icon: "gearshape.2.fill",         color: "gray",   description: "Boeing, Caterpillar..."),
        InterestCategory(id: "telecom",     name: "Telecom",          icon: "antenna.radiowaves.left.and.right", color: "teal", description: "AT&T, Verizon..."),
        // Non-stock categories
        InterestCategory(id: "crypto",      name: "Cryptocurrency",   icon: "bitcoinsign.circle.fill",  color: "orange", description: "Bitcoin, Ethereum, Solana..."),
        InterestCategory(id: "metals",      name: "Precious Metals",  icon: "diamond.fill",             color: "yellow", description: "Gold, Silver, Platinum..."),
        InterestCategory(id: "commodities", name: "Commodities",      icon: "drop.halffull",            color: "brown",  description: "Oil, Natural Gas, Wheat..."),
        InterestCategory(id: "forex",       name: "Forex",            icon: "arrow.left.arrow.right",   color: "blue",   description: "EUR/USD, GBP/JPY..."),
        InterestCategory(id: "etf",         name: "ETFs & Index",     icon: "chart.pie.fill",           color: "indigo", description: "SPY, QQQ, VOO..."),
        InterestCategory(id: "dividend",    name: "Dividends",        icon: "dollarsign.circle.fill", color: "green", description: "High-yield stocks..."),
    ]

    /// Recommended Yahoo Finance symbols for each category
    static let recommendedSymbols: [String: [(symbol: String, name: String)]] = [
        "tech": [
            ("AAPL", "Apple"), ("MSFT", "Microsoft"), ("NVDA", "NVIDIA"),
            ("GOOGL", "Alphabet"), ("META", "Meta"), ("TSM", "TSMC"),
            ("AVGO", "Broadcom"), ("AMD", "AMD"), ("CRM", "Salesforce"), ("INTC", "Intel")
        ],
        "finance": [
            ("JPM", "JPMorgan Chase"), ("V", "Visa"), ("MA", "Mastercard"),
            ("BAC", "Bank of America"), ("GS", "Goldman Sachs"), ("MS", "Morgan Stanley"),
            ("BLK", "BlackRock"), ("SCHW", "Charles Schwab"), ("AXP", "Amex"), ("C", "Citigroup")
        ],
        "healthcare": [
            ("UNH", "UnitedHealth"), ("JNJ", "Johnson & Johnson"), ("LLY", "Eli Lilly"),
            ("PFE", "Pfizer"), ("ABBV", "AbbVie"), ("MRK", "Merck"),
            ("TMO", "Thermo Fisher"), ("ABT", "Abbott"), ("DHR", "Danaher"), ("BMY", "Bristol-Myers")
        ],
        "energy": [
            ("XOM", "ExxonMobil"), ("CVX", "Chevron"), ("COP", "ConocoPhillips"),
            ("SLB", "Schlumberger"), ("EOG", "EOG Resources"), ("MPC", "Marathon Petroleum"),
            ("OXY", "Occidental"), ("PSX", "Phillips 66"), ("VLO", "Valero"), ("HAL", "Halliburton")
        ],
        "consumer": [
            ("AMZN", "Amazon"), ("TSLA", "Tesla"), ("NKE", "Nike"),
            ("MCD", "McDonald's"), ("SBUX", "Starbucks"), ("HD", "Home Depot"),
            ("COST", "Costco"), ("WMT", "Walmart"), ("PG", "Procter & Gamble"), ("KO", "Coca-Cola")
        ],
        "realestate": [
            ("O", "Realty Income"), ("AMT", "American Tower"), ("PLD", "Prologis"),
            ("CCI", "Crown Castle"), ("EQIX", "Equinix"), ("SPG", "Simon Property"),
            ("PSA", "Public Storage"), ("DLR", "Digital Realty"), ("WELL", "Welltower"), ("AVB", "AvalonBay")
        ],
        "industrial": [
            ("BA", "Boeing"), ("CAT", "Caterpillar"), ("HON", "Honeywell"),
            ("UPS", "UPS"), ("GE", "GE Aerospace"), ("RTX", "RTX Corp"),
            ("LMT", "Lockheed Martin"), ("DE", "John Deere"), ("MMM", "3M"), ("FDX", "FedEx")
        ],
        "telecom": [
            ("T", "AT&T"), ("VZ", "Verizon"), ("TMUS", "T-Mobile"),
            ("CMCSA", "Comcast"), ("DIS", "Walt Disney"), ("NFLX", "Netflix"),
            ("CHTR", "Charter"), ("WBD", "Warner Bros"), ("PARA", "Paramount"), ("FOX", "Fox Corp")
        ],
        "crypto": [
            ("BTC-USD", "Bitcoin"), ("ETH-USD", "Ethereum"), ("SOL-USD", "Solana"),
            ("BNB-USD", "BNB"), ("XRP-USD", "XRP"), ("ADA-USD", "Cardano"),
            ("DOGE-USD", "Dogecoin"), ("AVAX-USD", "Avalanche"), ("DOT-USD", "Polkadot"), ("LINK-USD", "Chainlink")
        ],
        "metals": [
            ("GC=F", "Gold"), ("SI=F", "Silver"), ("PL=F", "Platinum"),
            ("PA=F", "Palladium"), ("HG=F", "Copper")
        ],
        "commodities": [
            ("CL=F", "Crude Oil WTI"), ("BZ=F", "Brent Crude"), ("NG=F", "Natural Gas"),
            ("ZC=F", "Corn"), ("ZW=F", "Wheat"), ("ZS=F", "Soybeans"),
            ("KC=F", "Coffee"), ("SB=F", "Sugar"), ("CT=F", "Cotton"), ("CC=F", "Cocoa")
        ],
        "forex": [
            ("EURUSD=X", "EUR/USD"), ("GBPUSD=X", "GBP/USD"), ("USDJPY=X", "USD/JPY"),
            ("USDCAD=X", "USD/CAD"), ("AUDUSD=X", "AUD/USD"), ("USDCNY=X", "USD/CNY"),
            ("CADCNY=X", "CAD/CNY"), ("GBPJPY=X", "GBP/JPY"), ("EURGBP=X", "EUR/GBP"), ("NZDUSD=X", "NZD/USD")
        ],
        "etf": [
            ("SPY", "S&P 500 ETF"), ("QQQ", "NASDAQ 100 ETF"), ("VOO", "Vanguard S&P 500"),
            ("IWM", "Russell 2000 ETF"), ("DIA", "Dow Jones ETF"), ("VTI", "Total Stock Market"),
            ("ARKK", "ARK Innovation"), ("XLF", "Financials ETF"), ("XLK", "Technology ETF"), ("VGT", "Vanguard IT")
        ],
        "dividend": [
            ("O", "Realty Income"), ("KO", "Coca-Cola"), ("JNJ", "J&J"),
            ("PEP", "PepsiCo"), ("PG", "Procter & Gamble"), ("VZ", "Verizon"),
            ("T", "AT&T"), ("XOM", "ExxonMobil"), ("ABBV", "AbbVie"), ("MO", "Altria")
        ],
    ]
}

// MARK: - Interests Manager
class InterestsManager: ObservableObject {
    static let shared = InterestsManager()

    @Published var selectedInterests: Set<String> = [] {
        didSet { saveLocal() }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedInterestsOnboarding") }
    }

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedInterestsOnboarding")
        if let saved = UserDefaults.standard.array(forKey: "userInterests") as? [String] {
            self.selectedInterests = Set(saved)
        }
    }

    private func saveLocal() {
        UserDefaults.standard.set(Array(selectedInterests), forKey: "userInterests")
    }

    /// Save to Firestore for cross-device sync
    func syncToFirestore() {
        FirebaseController.shared.saveUserInterests(Array(selectedInterests))
    }

    /// Load from Firestore (e.g., on fresh install)
    func loadFromFirestore() async {
        let interests = await FirebaseController.shared.getUserInterests()
        if !interests.isEmpty {
            await MainActor.run {
                selectedInterests = Set(interests)
                if !interests.isEmpty {
                    hasCompletedOnboarding = true
                }
            }
        }
    }

    /// Get recommended symbols based on selected interests
    func recommendedSymbols(excluding existingSymbols: Set<String>) -> [(symbol: String, name: String, categoryId: String)] {
        var results: [(symbol: String, name: String, categoryId: String)] = []
        var seen = Set<String>()

        for interest in selectedInterests {
            guard let symbols = InterestCategory.recommendedSymbols[interest] else { continue }
            for s in symbols {
                let upper = s.symbol.uppercased()
                if !existingSymbols.contains(upper) && !seen.contains(upper) {
                    results.append((s.symbol, s.name, interest))
                    seen.insert(upper)
                }
            }
        }

        // Shuffle to keep it fresh, but deterministic per day
        let seed = Calendar.current.component(.day, from: Date())
        var rng = SeededRNG(seed: UInt64(seed))
        results.shuffle(using: &rng)

        return results
    }
}

// Simple seeded RNG for daily-consistent shuffle
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
