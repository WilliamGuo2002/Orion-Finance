import Foundation

// MARK: - Asset Type Detection & Metadata
// Yahoo Finance symbol conventions:
//   Stocks:      AAPL, MSFT, GOOGL
//   Crypto:      BTC-USD, ETH-USD, SOL-USD
//   Metals:      GC=F (gold), SI=F (silver), PL=F (platinum)
//   Commodities: CL=F (oil), NG=F (gas)
//   Forex:       CADCNY=X, EURUSD=X, GBPJPY=X

enum AssetType: String {
    case stock = "Stock"
    case crypto = "Crypto"
    case metal = "Metal"
    case commodity = "Commodity"
    case forex = "Forex"

    var icon: String {
        switch self {
        case .stock:     return "building.2"
        case .crypto:    return "bitcoinsign.circle"
        case .metal:     return "diamond"
        case .commodity: return "drop.halffull"
        case .forex:     return "arrow.left.arrow.right.circle"
        }
    }

    var label: String {
        switch self {
        case .stock:     return L("Stocks")
        case .crypto:    return L("Crypto")
        case .metal:     return L("Metals")
        case .commodity: return L("Commodity")
        case .forex:     return L("Forex")
        }
    }
}

// MARK: - Asset Metadata

struct AssetMeta {
    let symbol: String
    let name: String
    let type: AssetType
    let emoji: String    // small visual identifier

    /// Detect asset type from Yahoo Finance symbol format
    static func assetType(for symbol: String) -> AssetType {
        let s = symbol.uppercased()

        // Forex: ends with =X and base is a known currency pair
        if s.hasSuffix("=X") {
            let base = String(s.dropLast(2))
            if knownForexPairs[base] != nil || isForexPattern(base) {
                return .forex
            }
        }

        // Crypto: ends with -USD/-EUR etc.
        if s.contains("-") {
            let parts = s.components(separatedBy: "-")
            if parts.count == 2, currencyCodes.contains(parts[1]) {
                return .crypto
            }
        }

        // Metals & Commodities futures: ends with =F
        if knownMetals.keys.contains(s) { return .metal }
        if knownCommodities.keys.contains(s) { return .commodity }

        return .stock
    }

    /// Check if a string looks like a 6-char forex pair (e.g. CADCNY, EURUSD)
    private static func isForexPattern(_ base: String) -> Bool {
        guard base.count == 6 else { return false }
        let from = String(base.prefix(3))
        let to = String(base.suffix(3))
        return currencyCodes.contains(from) && currencyCodes.contains(to)
    }

    /// Get display name for a symbol (from built-in dictionary)
    static func displayName(for symbol: String) -> String? {
        let s = symbol.uppercased()
        // Forex
        if s.hasSuffix("=X") {
            let base = String(s.dropLast(2))
            if let name = knownForexPairs[base] { return name }
            if isForexPattern(base) {
                let from = String(base.prefix(3))
                let to = String(base.suffix(3))
                let fromName = currencyNames[from] ?? from
                let toName = currencyNames[to] ?? to
                return "\(fromName) / \(toName)"
            }
        }
        // Crypto
        if let name = knownCrypto[s.components(separatedBy: "-").first ?? ""] { return name }
        // Metals & Commodities
        if let name = knownMetals[s] { return name }
        if let name = knownCommodities[s] { return name }
        return nil
    }

    /// Get asset meta if it's a known non-stock asset
    static func knownAsset(for symbol: String) -> AssetMeta? {
        let s = symbol.uppercased()
        let base = s.components(separatedBy: "-").first ?? s

        // Forex
        if s.hasSuffix("=X") {
            let pairBase = String(s.dropLast(2))
            if let name = knownForexPairs[pairBase] {
                return AssetMeta(symbol: s, name: name, type: .forex, emoji: "¤")
            }
            if isForexPattern(pairBase) {
                let from = String(pairBase.prefix(3))
                let to = String(pairBase.suffix(3))
                let fromName = currencyNames[from] ?? from
                let toName = currencyNames[to] ?? to
                return AssetMeta(symbol: s, name: "\(fromName) / \(toName)", type: .forex, emoji: "¤")
            }
        }

        // Crypto
        if let name = knownCrypto[base] {
            let emoji: String
            switch base {
            case "BTC": emoji = "₿"
            case "ETH": emoji = "Ξ"
            default: emoji = "◆"
            }
            return AssetMeta(symbol: s.contains("-") ? s : "\(base)-USD", name: name, type: .crypto, emoji: emoji)
        }

        // Metals
        if let name = knownMetals[s] {
            return AssetMeta(symbol: s, name: name, type: .metal, emoji: "◈")
        }

        // Commodities
        if let name = knownCommodities[s] {
            return AssetMeta(symbol: s, name: name, type: .commodity, emoji: "◇")
        }

        return nil
    }

    /// Build a Yahoo Finance forex symbol from two currency codes
    static func forexSymbol(from: String, to: String) -> String {
        "\(from.uppercased())\(to.uppercased())=X"
    }

    /// Extract currency pair from a forex symbol (e.g. "CADCNY=X" → ("CAD", "CNY"))
    static func forexPair(from symbol: String) -> (from: String, to: String)? {
        let s = symbol.uppercased()
        guard s.hasSuffix("=X") else { return nil }
        let base = String(s.dropLast(2))
        guard base.count == 6 else { return nil }
        return (String(base.prefix(3)), String(base.suffix(3)))
    }

    // MARK: - Popular Assets (for quick-add UI)

    static let popularCrypto: [AssetMeta] = [
        AssetMeta(symbol: "BTC-USD", name: "Bitcoin", type: .crypto, emoji: "₿"),
        AssetMeta(symbol: "ETH-USD", name: "Ethereum", type: .crypto, emoji: "Ξ"),
        AssetMeta(symbol: "SOL-USD", name: "Solana", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "BNB-USD", name: "BNB", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "XRP-USD", name: "XRP", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "ADA-USD", name: "Cardano", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "DOGE-USD", name: "Dogecoin", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "AVAX-USD", name: "Avalanche", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "DOT-USD", name: "Polkadot", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "MATIC-USD", name: "Polygon", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "LINK-USD", name: "Chainlink", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "UNI7083-USD", name: "Uniswap", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "SHIB-USD", name: "Shiba Inu", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "LTC-USD", name: "Litecoin", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "ATOM-USD", name: "Cosmos", type: .crypto, emoji: "◆"),
        AssetMeta(symbol: "SUI20947-USD", name: "Sui", type: .crypto, emoji: "◆"),
    ]

    static let popularMetals: [AssetMeta] = [
        AssetMeta(symbol: "GC=F", name: "Gold Futures", type: .metal, emoji: "◈"),
        AssetMeta(symbol: "SI=F", name: "Silver Futures", type: .metal, emoji: "◈"),
        AssetMeta(symbol: "PL=F", name: "Platinum Futures", type: .metal, emoji: "◈"),
        AssetMeta(symbol: "PA=F", name: "Palladium Futures", type: .metal, emoji: "◈"),
        AssetMeta(symbol: "HG=F", name: "Copper Futures", type: .metal, emoji: "◈"),
    ]

    static let popularCommodities: [AssetMeta] = [
        AssetMeta(symbol: "CL=F", name: "Crude Oil WTI", type: .commodity, emoji: "◇"),
        AssetMeta(symbol: "BZ=F", name: "Brent Crude Oil", type: .commodity, emoji: "◇"),
        AssetMeta(symbol: "NG=F", name: "Natural Gas", type: .commodity, emoji: "◇"),
        AssetMeta(symbol: "ZC=F", name: "Corn Futures", type: .commodity, emoji: "◇"),
        AssetMeta(symbol: "ZW=F", name: "Wheat Futures", type: .commodity, emoji: "◇"),
    ]

    static let popularForex: [AssetMeta] = [
        AssetMeta(symbol: "USDCNY=X", name: "US Dollar / Chinese Yuan", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "CADCNY=X", name: "Canadian Dollar / Chinese Yuan", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "EURUSD=X", name: "Euro / US Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "GBPUSD=X", name: "British Pound / US Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDJPY=X", name: "US Dollar / Japanese Yen", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDCAD=X", name: "US Dollar / Canadian Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "AUDUSD=X", name: "Australian Dollar / US Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDCHF=X", name: "US Dollar / Swiss Franc", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "NZDUSD=X", name: "New Zealand Dollar / US Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDSGD=X", name: "US Dollar / Singapore Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDHKD=X", name: "US Dollar / Hong Kong Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDTWD=X", name: "US Dollar / Taiwan Dollar", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDKRW=X", name: "US Dollar / Korean Won", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "USDINR=X", name: "US Dollar / Indian Rupee", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "EURGBP=X", name: "Euro / British Pound", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "EURJPY=X", name: "Euro / Japanese Yen", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "GBPJPY=X", name: "British Pound / Japanese Yen", type: .forex, emoji: "¤"),
        AssetMeta(symbol: "CADJPY=X", name: "Canadian Dollar / Japanese Yen", type: .forex, emoji: "¤"),
    ]

    static let popularStocks: [AssetMeta] = [
        AssetMeta(symbol: "AAPL", name: "Apple", type: .stock, emoji: ""),
        AssetMeta(symbol: "MSFT", name: "Microsoft", type: .stock, emoji: ""),
        AssetMeta(symbol: "GOOGL", name: "Alphabet", type: .stock, emoji: ""),
        AssetMeta(symbol: "AMZN", name: "Amazon", type: .stock, emoji: ""),
        AssetMeta(symbol: "NVDA", name: "NVIDIA", type: .stock, emoji: ""),
        AssetMeta(symbol: "TSLA", name: "Tesla", type: .stock, emoji: ""),
        AssetMeta(symbol: "META", name: "Meta Platforms", type: .stock, emoji: ""),
        AssetMeta(symbol: "TSM", name: "TSMC", type: .stock, emoji: ""),
        AssetMeta(symbol: "V", name: "Visa", type: .stock, emoji: ""),
        AssetMeta(symbol: "JPM", name: "JPMorgan Chase", type: .stock, emoji: ""),
    ]

    // MARK: - Known Asset Dictionaries

    private static let knownCrypto: [String: String] = [
        "BTC": "Bitcoin", "ETH": "Ethereum", "SOL": "Solana",
        "BNB": "BNB", "XRP": "XRP", "ADA": "Cardano",
        "DOGE": "Dogecoin", "AVAX": "Avalanche", "DOT": "Polkadot",
        "MATIC": "Polygon", "LINK": "Chainlink", "UNI7083": "Uniswap",
        "SHIB": "Shiba Inu", "LTC": "Litecoin", "ATOM": "Cosmos",
        "FIL": "Filecoin", "NEAR": "NEAR Protocol", "APT21794": "Aptos",
        "ARB11841": "Arbitrum", "OP": "Optimism", "SUI20947": "Sui",
        "PEPE24478": "Pepe", "IMX10603": "Immutable X", "AAVE": "Aave",
        "MKR": "Maker", "RUNE": "THORChain", "INJ": "Injective",
        "TIA22861": "Celestia", "SEI": "Sei", "ALGO": "Algorand",
        "HBAR": "Hedera", "VET": "VeChain", "SAND": "The Sandbox",
        "MANA": "Decentraland", "AXS": "Axie Infinity", "CRO": "Cronos",
        "FTM": "Fantom", "EGLD": "MultiversX", "THETA": "Theta Network",
    ]

    private static let knownMetals: [String: String] = [
        "GC=F": "Gold Futures", "SI=F": "Silver Futures",
        "PL=F": "Platinum Futures", "PA=F": "Palladium Futures",
        "HG=F": "Copper Futures",
    ]

    private static let knownCommodities: [String: String] = [
        "CL=F": "Crude Oil WTI", "BZ=F": "Brent Crude Oil",
        "NG=F": "Natural Gas", "ZC=F": "Corn Futures",
        "ZW=F": "Wheat Futures", "ZS=F": "Soybean Futures",
        "KC=F": "Coffee Futures", "CC=F": "Cocoa Futures",
        "CT=F": "Cotton Futures", "SB=F": "Sugar Futures",
    ]

    /// Pre-built forex pair names for the popular list
    private static let knownForexPairs: [String: String] = [
        "USDCNY": "US Dollar / Chinese Yuan",
        "CADCNY": "Canadian Dollar / Chinese Yuan",
        "EURUSD": "Euro / US Dollar",
        "GBPUSD": "British Pound / US Dollar",
        "USDJPY": "US Dollar / Japanese Yen",
        "USDCAD": "US Dollar / Canadian Dollar",
        "AUDUSD": "Australian Dollar / US Dollar",
        "USDCHF": "US Dollar / Swiss Franc",
        "NZDUSD": "New Zealand Dollar / US Dollar",
        "USDSGD": "US Dollar / Singapore Dollar",
        "USDHKD": "US Dollar / Hong Kong Dollar",
        "USDTWD": "US Dollar / Taiwan Dollar",
        "USDKRW": "US Dollar / Korean Won",
        "USDINR": "US Dollar / Indian Rupee",
        "EURGBP": "Euro / British Pound",
        "EURJPY": "Euro / Japanese Yen",
        "GBPJPY": "British Pound / Japanese Yen",
        "CADJPY": "Canadian Dollar / Japanese Yen",
        "EURCNY": "Euro / Chinese Yuan",
        "GBPCNY": "British Pound / Chinese Yuan",
        "JPYCNY": "Japanese Yen / Chinese Yuan",
        "AUDCNY": "Australian Dollar / Chinese Yuan",
        "HKDCNY": "Hong Kong Dollar / Chinese Yuan",
    ]

    /// ISO 4217 currency codes (major currencies)
    static let currencyCodes: Set<String> = [
        "USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD", "CHF",
        "NZD", "SGD", "HKD", "TWD", "KRW", "INR", "MXN", "BRL",
        "ZAR", "NOK", "SEK", "DKK", "PLN", "THB", "IDR", "MYR",
        "PHP", "CZK", "HUF", "ILS", "TRY", "RUB", "AED", "SAR",
    ]

    /// Currency code → full name
    static let currencyNames: [String: String] = [
        "USD": "US Dollar", "EUR": "Euro", "GBP": "British Pound",
        "JPY": "Japanese Yen", "CNY": "Chinese Yuan", "CAD": "Canadian Dollar",
        "AUD": "Australian Dollar", "CHF": "Swiss Franc", "NZD": "New Zealand Dollar",
        "SGD": "Singapore Dollar", "HKD": "Hong Kong Dollar", "TWD": "Taiwan Dollar",
        "KRW": "Korean Won", "INR": "Indian Rupee", "MXN": "Mexican Peso",
        "BRL": "Brazilian Real", "ZAR": "South African Rand",
        "NOK": "Norwegian Krone", "SEK": "Swedish Krona", "DKK": "Danish Krone",
        "PLN": "Polish Zloty", "THB": "Thai Baht", "IDR": "Indonesian Rupiah",
        "MYR": "Malaysian Ringgit", "PHP": "Philippine Peso",
        "TRY": "Turkish Lira", "RUB": "Russian Ruble",
        "AED": "UAE Dirham", "SAR": "Saudi Riyal",
    ]

    /// Currency code → symbol character
    static let currencySymbols: [String: String] = [
        "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥", "CNY": "¥",
        "CAD": "C$", "AUD": "A$", "CHF": "Fr", "NZD": "NZ$",
        "SGD": "S$", "HKD": "HK$", "TWD": "NT$", "KRW": "₩",
        "INR": "₹", "MXN": "MX$", "BRL": "R$", "THB": "฿",
        "TRY": "₺", "RUB": "₽", "AED": "د.إ", "SAR": "﷼",
    ]
}
