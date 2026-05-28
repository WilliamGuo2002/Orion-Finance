import Foundation

/// Full quote data from Finnhub
struct StockQuote {
    let price: Double          // c - current price
    let change: Double         // d - change
    let changePercent: Double  // dp - percent change
    let high: Double           // h - day high
    let low: Double            // l - day low
    let open: Double           // o - open
    let previousClose: Double  // pc - previous close
    let timestamp: Int         // t - unix timestamp
}

/// Analyst recommendation data from Finnhub
struct RecommendationTrend {
    let strongBuy: Int
    let buy: Int
    let hold: Int
    let sell: Int
    let strongSell: Int
    var total: Int { strongBuy + buy + hold + sell + strongSell }
}

/// Company profile data from Finnhub
struct CompanyProfile {
    let name: String
    let ticker: String
    let logoURL: String?
    let industry: String
    let marketCap: Double
    let employeeTotal: Int
    let description: String
    let exchange: String
    let ipo: String
    let weburl: String
    let country: String
}

/// Peer company with quote
struct PeerStock: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double
}

/// Fundamental metrics from Finnhub basic financials
struct FundamentalMetrics {
    let peRatio: Double?          // Price/Earnings (TTM)
    let pbRatio: Double?          // Price/Book
    let epsGrowth: Double?        // EPS growth (TTM YoY %)
    let revenueGrowth: Double?    // Revenue growth (TTM YoY %)
    let dividendYield: Double?    // Annual dividend yield %
    let beta: Double?             // Beta
    let debtToEquity: Double?     // D/E ratio
    let roe: Double?              // Return on equity (TTM %)
    let grossMargin: Double?      // Gross margin (TTM %)
    let operatingMargin: Double?  // Operating margin (TTM %)
}

/// AI-generated structured decision dashboard
struct AIDecisionDashboard {
    let rating: String            // "Buy", "Watch", "Sell"
    let score: Int                // 0-100
    let summary: String           // 1-sentence conclusion
    let entryPrice: Double?       // Suggested entry price
    let stopLoss: Double?         // Suggested stop-loss
    let targetPrice: Double?      // Suggested target price
    let bullPoints: [String]      // Positive catalysts
    let bearPoints: [String]      // Risk factors
    let sentiment: Double         // -1.0 (bearish) to +1.0 (bullish)
    let sentimentLabel: String    // "Very Bearish" ... "Very Bullish"
    let actionGuide: String       // Beginner-friendly action guide
}

/// Market mover (gainer, loser, or most active)
struct MarketMover: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double
    let volume: Int
}

// =========================================
// MARK: - Thread-Safe Cache
// =========================================

/// Actor-isolated cache to prevent data races from concurrent TaskGroup access
private actor APICache {
    var charts: [String: (entries: [ChartEntry], fetchedAt: Date)] = [:]
    var yahooQuotes: [String: (price: Double, previousClose: Double, fetchedAt: Date)] = [:]
    var profiles: [String: (name: String, logoURL: String?, fetchedAt: Date)] = [:]
    var indices: [String: (index: MarketIndex, fetchedAt: Date)] = [:]
    var fullQuotes: [String: (quote: StockQuote, fetchedAt: Date)] = [:]
    var aiDashboards: [String: (dashboard: AIDecisionDashboard, fetchedAt: Date)] = [:]
    var fundamentals: [String: (metrics: FundamentalMetrics, fetchedAt: Date)] = [:]

    // Chart cache
    func getChart(_ key: String) -> (entries: [ChartEntry], fetchedAt: Date)? { charts[key] }
    func setChart(_ key: String, entries: [ChartEntry]) { charts[key] = (entries: entries, fetchedAt: Date()) }

    // Yahoo quote cache
    func getQuote(_ key: String) -> (price: Double, previousClose: Double, fetchedAt: Date)? { yahooQuotes[key] }
    func setQuote(_ key: String, price: Double, previousClose: Double) { yahooQuotes[key] = (price, previousClose, Date()) }

    // Profile cache
    func getProfile(_ key: String) -> (name: String, logoURL: String?, fetchedAt: Date)? { profiles[key] }
    func setProfile(_ key: String, name: String, logoURL: String?) { profiles[key] = (name, logoURL, Date()) }

    // Index cache
    func getIndex(_ key: String) -> (index: MarketIndex, fetchedAt: Date)? { indices[key] }
    func setIndex(_ key: String, index: MarketIndex) { indices[key] = (index: index, fetchedAt: Date()) }

    // Full quote cache
    func getFullQuote(_ key: String) -> (quote: StockQuote, fetchedAt: Date)? { fullQuotes[key] }
    func setFullQuote(_ key: String, quote: StockQuote) { fullQuotes[key] = (quote: quote, fetchedAt: Date()) }

    // AI dashboard cache (1h TTL)
    func getAIDashboard(_ key: String) -> (dashboard: AIDecisionDashboard, fetchedAt: Date)? { aiDashboards[key] }
    func setAIDashboard(_ key: String, dashboard: AIDecisionDashboard) { aiDashboards[key] = (dashboard, Date()) }

    // Fundamentals cache (4h TTL)
    func getFundamentals(_ key: String) -> (metrics: FundamentalMetrics, fetchedAt: Date)? { fundamentals[key] }
    func setFundamentals(_ key: String, metrics: FundamentalMetrics) { fundamentals[key] = (metrics, Date()) }

    func clearAll() {
        charts.removeAll(); yahooQuotes.removeAll(); profiles.removeAll()
        indices.removeAll(); fullQuotes.removeAll()
        aiDashboards.removeAll(); fundamentals.removeAll()
    }
    func clearVolatile() {
        charts.removeAll(); yahooQuotes.removeAll()
        indices.removeAll(); fullQuotes.removeAll()
    }
}

class APIService {
    static let shared = APIService()
    private init() {}

    /// Thread-safe cache (actor-isolated, no data races)
    private let cache = APICache()

    // MARK: - Shared URLSession with short timeout
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    // MARK: - Market Hours Detection

    /// Check if US stock market is currently open (Mon-Fri 9:30 AM - 4:00 PM ET)
    private var isMarketOpen: Bool {
        let now = Date()
        guard let et = TimeZone(identifier: "America/New_York") else { return false }
        var cal = Calendar.current
        cal.timeZone = et
        let weekday = cal.component(.weekday, from: now) // 1=Sun, 7=Sat
        guard (2...6).contains(weekday) else { return false }
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        return totalMinutes >= 570 && totalMinutes < 960 // 9:30=570, 16:00=960
    }

    /// Adaptive cache TTL based on market hours and data type
    private func chartTTL(range: String) -> TimeInterval {
        if isMarketOpen {
            switch range {
            case "1d":            return 60
            case "5d":            return 120
            case "1mo":           return 300
            default:              return 600
            }
        } else {
            switch range {
            case "1d", "5d":      return 900
            default:              return 3600
            }
        }
    }

    private var quoteTTL: TimeInterval { isMarketOpen ? 30 : 600 }
    private var fullQuoteTTL: TimeInterval { isMarketOpen ? 30 : 600 }
    private let profileTTL: TimeInterval = 86400
    private var indexTTL: TimeInterval { isMarketOpen ? 120 : 900 }

    // =========================================
    // MARK: - Yahoo Finance: Chart Data + Quote
    // =========================================

    func fetchChartData(symbol: String, range: String = "5d", interval: String = "30m") async throws -> [ChartEntry] {
        let upperSymbol = symbol.uppercased()
        let cacheKey = "\(upperSymbol)|\(range)|\(interval)"
        let ttl = chartTTL(range: range)

        // 1. Check cache (thread-safe via actor)
        if let cached = await cache.getChart(cacheKey),
           Date().timeIntervalSince(cached.fetchedAt) < ttl {
            return cached.entries
        }

        // 2. Build Yahoo Finance URL
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?range=\(range)&interval=\(interval)&includePrePost=false") else {
            throw APIError.invalidData
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        // 3. Fetch with timeout
        let (data, response) = try await session.data(for: request)

        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            print("[Yahoo] HTTP \(httpResp.statusCode) for \(upperSymbol)")
            if let cached = await cache.getChart(cacheKey) { return cached.entries }
            throw APIError.apiError("Yahoo Finance HTTP \(httpResp.statusCode)")
        }

        // 4. Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let chart = json["chart"] as? [String: Any] else {
            throw APIError.invalidData
        }

        if let error = chart["error"] as? [String: Any] {
            let desc = error["description"] as? String ?? "Unknown Yahoo Finance error"
            print("[Yahoo] API error for \(upperSymbol): \(desc)")
            if let cached = await cache.getChart(cacheKey) { return cached.entries }
            throw APIError.apiError(desc)
        }

        guard let results = chart["result"] as? [[String: Any]],
              let result = results.first else {
            throw APIError.invalidData
        }

        // 5. Extract quote meta (free bonus from chart call)
        let meta = result["meta"] as? [String: Any] ?? [:]
        let price = meta["regularMarketPrice"] as? Double ?? 0
        let prevClose = meta["previousClose"] as? Double
            ?? meta["chartPreviousClose"] as? Double ?? 0

        if price > 0 {
            await cache.setQuote(upperSymbol, price: price, previousClose: prevClose)
        }

        // 6. Parse chart entries
        guard let timestamps = result["timestamp"] as? [Int],
              let indicators = result["indicators"] as? [String: Any],
              let quoteArr = indicators["quote"] as? [[String: Any]],
              let quoteData = quoteArr.first,
              let closes = quoteData["close"] as? [Any] else {
            if let cached = await cache.getChart(cacheKey) { return cached.entries }
            throw APIError.apiError("No chart data available for \(upperSymbol)")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")

        var entries: [ChartEntry] = []
        for (i, ts) in timestamps.enumerated() {
            guard i < closes.count else { break }
            if let close = closes[i] as? Double, close > 0 {
                let date = Date(timeIntervalSince1970: TimeInterval(ts))
                entries.append(ChartEntry(
                    index: entries.count,
                    close: Float(close),
                    datetime: dateFormatter.string(from: date)
                ))
            }
        }

        guard !entries.isEmpty else {
            if let cached = await cache.getChart(cacheKey) { return cached.entries }
            throw APIError.apiError("No chart data available for \(upperSymbol)")
        }

        // 7. Cache (thread-safe)
        await cache.setChart(cacheKey, entries: entries)
        print("[Yahoo] Loaded \(entries.count) points for \(upperSymbol) (\(range)/\(interval))")

        return entries
    }

    // =========================================
    // MARK: - Combined Chart + Quote (Watchlist)
    // =========================================

    func fetchChartAndQuote(symbol: String, range: String = "5d", interval: String = "30m") async throws -> (chartData: [ChartEntry], price: Double, previousClose: Double) {
        let entries = try await fetchChartData(symbol: symbol, range: range, interval: interval)
        let upper = symbol.uppercased()

        if let cached = await cache.getQuote(upper) {
            return (entries, cached.price, cached.previousClose)
        }

        let lastClose = Double(entries.last?.close ?? 0)
        let firstClose = Double(entries.first?.close ?? Float(lastClose))
        return (entries, lastClose, firstClose)
    }

    // =========================================
    // MARK: - Market Indices (Yahoo Finance)
    // =========================================

    func fetchMarketIndex(symbol: String, name: String) async throws -> MarketIndex {
        let cacheKey = symbol.uppercased()

        if let cached = await cache.getIndex(cacheKey),
           Date().timeIntervalSince(cached.fetchedAt) < indexTTL {
            return cached.index
        }

        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?range=1d&interval=5m&includePrePost=false") else {
            throw APIError.invalidData
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let result = results.first,
              let meta = result["meta"] as? [String: Any],
              let price = meta["regularMarketPrice"] as? Double else {
            if let cached = await cache.getIndex(cacheKey) { return cached.index }
            throw APIError.invalidData
        }

        let prevClose = meta["previousClose"] as? Double
            ?? meta["chartPreviousClose"] as? Double ?? price

        let changePercent = prevClose != 0 ? ((price - prevClose) / prevClose) * 100 : 0
        let index = MarketIndex(name: name, price: price, changePercent: changePercent)

        await cache.setIndex(cacheKey, index: index)
        return index
    }

    // =========================================
    // MARK: - Stock Quote (Yahoo cache → Finnhub)
    // =========================================

    func fetchStockQuote(symbol: String) async throws -> (price: Double, previousClose: Double) {
        let upper = symbol.uppercased()

        if let cached = await cache.getQuote(upper),
           Date().timeIntervalSince(cached.fetchedAt) < quoteTTL {
            return (cached.price, cached.previousClose)
        }

        do {
            let result = try await fetchChartAndQuote(symbol: symbol, range: "1d", interval: "5m")
            return (result.price, result.previousClose)
        } catch {
            let q = try await fetchFullQuote(symbol: symbol)
            return (q.price, q.previousClose)
        }
    }

    func fetchFullQuote(symbol: String) async throws -> StockQuote {
        let upper = symbol.uppercased()

        if let cached = await cache.getFullQuote(upper),
           Date().timeIntervalSince(cached.fetchedAt) < fullQuoteTTL {
            return cached.quote
        }

        let url = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(symbol)&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let c = json["c"] as? Double,
              let pc = json["pc"] as? Double else {
            throw APIError.invalidData
        }

        let quote = StockQuote(
            price: c,
            change: json["d"] as? Double ?? 0,
            changePercent: json["dp"] as? Double ?? 0,
            high: json["h"] as? Double ?? 0,
            low: json["l"] as? Double ?? 0,
            open: json["o"] as? Double ?? 0,
            previousClose: pc,
            timestamp: json["t"] as? Int ?? 0
        )

        await cache.setFullQuote(upper, quote: quote)
        return quote
    }

    // =========================================
    // MARK: - Company Profile (Finnhub, 24h cache)
    // =========================================

    func fetchCompanyProfile(symbol: String) async throws -> (name: String, logoURL: String?) {
        let upper = symbol.uppercased()

        // Check cache first
        if let cached = await cache.getProfile(upper),
           Date().timeIntervalSince(cached.fetchedAt) < profileTTL {
            return (cached.name, cached.logoURL)
        }

        // For crypto / metals / commodities — use built-in metadata (Finnhub doesn't cover these)
        if let asset = AssetMeta.knownAsset(for: symbol) {
            await cache.setProfile(upper, name: asset.name, logoURL: nil)
            return (asset.name, nil)
        }

        // For stocks — fetch from Finnhub
        let url = URL(string: "https://finnhub.io/api/v1/stock/profile2?symbol=\(symbol)&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let name = json["name"] as? String ?? symbol
        let logo = json["logo"] as? String

        await cache.setProfile(upper, name: name, logoURL: logo)
        return (name, logo)
    }

    // =========================================
    // MARK: - 52-Week Range (Finnhub Basic Financials)
    // =========================================

    func fetchWeek52Range(symbol: String) async throws -> (high: Double, low: Double) {
        let url = URL(string: "https://finnhub.io/api/v1/stock/metric?symbol=\(symbol)&metric=all&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let metric = json["metric"] as? [String: Any],
              let high = metric["52WeekHigh"] as? Double,
              let low = metric["52WeekLow"] as? Double else {
            throw APIError.invalidData
        }
        return (high, low)
    }

    func fetchFullCompanyProfile(symbol: String) async throws -> CompanyProfile {
        let url = URL(string: "https://finnhub.io/api/v1/stock/profile2?symbol=\(symbol)&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        let name = json["name"] as? String ?? symbol
        let logo = json["logo"] as? String
        await cache.setProfile(symbol.uppercased(), name: name, logoURL: logo)

        return CompanyProfile(
            name: name,
            ticker: json["ticker"] as? String ?? symbol,
            logoURL: logo,
            industry: json["finnhubIndustry"] as? String ?? "",
            marketCap: json["marketCapitalization"] as? Double ?? 0,
            employeeTotal: json["employeeTotal"] as? Int ?? 0,
            description: "",
            exchange: json["exchange"] as? String ?? "",
            ipo: json["ipo"] as? String ?? "",
            weburl: json["weburl"] as? String ?? "",
            country: json["country"] as? String ?? ""
        )
    }

    // =========================================
    // MARK: - Yahoo Finance: Market Movers
    // =========================================

    /// Fetch day gainers, losers, or most-active from Yahoo Finance screener
    /// scrId: "day_gainers", "day_losers", "most_actives"
    func fetchMarketMovers(scrId: String, count: Int = 6) async throws -> [MarketMover] {
        let urlStr = "https://query1.finance.yahoo.com/v1/finance/screener/predefined/saved?scrIds=\(scrId)&count=\(count)"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let finance = json?["finance"] as? [String: Any]
        let results = (finance?["result"] as? [[String: Any]])?.first
        let quotes = results?["quotes"] as? [[String: Any]] ?? []

        return quotes.compactMap { q in
            guard let symbol = q["symbol"] as? String,
                  let price = q["regularMarketPrice"] as? Double,
                  let changePercent = q["regularMarketChangePercent"] as? Double else { return nil }
            let name = q["shortName"] as? String ?? q["longName"] as? String ?? symbol
            let volume = q["regularMarketVolume"] as? Int ?? 0
            return MarketMover(
                symbol: symbol,
                name: name,
                price: price,
                changePercent: changePercent,
                volume: volume
            )
        }
    }

    // =========================================
    // MARK: - News (Finnhub)
    // =========================================

    func fetchNews() async throws -> [NewsItem] {
        let url = URL(string: "https://finnhub.io/api/v1/news?category=general&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([NewsItem].self, from: data)
    }

    func fetchCompanyNews(symbol: String) async throws -> [NewsItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let to = formatter.string(from: Date())
        let from = formatter.string(from: Calendar.current.date(byAdding: .day, value: -14, to: Date())!)
        let url = URL(string: "https://finnhub.io/api/v1/company-news?symbol=\(symbol)&from=\(from)&to=\(to)&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([NewsItem].self, from: data)
    }

    // =========================================
    // MARK: - Earnings Calendar (Finnhub)
    // =========================================

    struct EarningsEvent: Identifiable {
        let id = UUID()
        let symbol: String
        let date: String      // "YYYY-MM-DD"
        let epsEstimate: Double?
        let epsActual: Double?
        let revenueEstimate: Double?
        let revenueActual: Double?
        let hour: String      // "bmo" (before market open), "amc" (after market close), ""
    }

    func fetchEarningsCalendar(symbol: String) async throws -> [EarningsEvent] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let from = formatter.string(from: Date())
        let to = formatter.string(from: Calendar.current.date(byAdding: .month, value: 3, to: Date())!)
        let url = URL(string: "https://finnhub.io/api/v1/calendar/earnings?symbol=\(symbol)&from=\(from)&to=\(to)&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let earnings = json["earningsCalendar"] as? [[String: Any]] ?? []

        return earnings.compactMap { e in
            guard let date = e["date"] as? String else { return nil }
            return EarningsEvent(
                symbol: e["symbol"] as? String ?? symbol,
                date: date,
                epsEstimate: e["epsEstimate"] as? Double,
                epsActual: e["epsActual"] as? Double,
                revenueEstimate: e["revenueEstimate"] as? Double,
                revenueActual: e["revenueActual"] as? Double,
                hour: e["hour"] as? String ?? ""
            )
        }
    }

    // =========================================
    // MARK: - Recommendations & Peers (Finnhub)
    // =========================================

    func fetchRecommendation(symbol: String) async throws -> RecommendationTrend {
        let url = URL(string: "https://finnhub.io/api/v1/stock/recommendation?symbol=\(symbol)&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        guard let latest = arr.first else {
            return RecommendationTrend(strongBuy: 0, buy: 0, hold: 0, sell: 0, strongSell: 0)
        }
        return RecommendationTrend(
            strongBuy: latest["strongBuy"] as? Int ?? 0,
            buy: latest["buy"] as? Int ?? 0,
            hold: latest["hold"] as? Int ?? 0,
            sell: latest["sell"] as? Int ?? 0,
            strongSell: latest["strongSell"] as? Int ?? 0
        )
    }

    func fetchPeers(symbol: String) async throws -> [PeerStock] {
        let url = URL(string: "https://finnhub.io/api/v1/stock/peers?symbol=\(symbol)&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let symbols = (try JSONSerialization.jsonObject(with: data) as? [String] ?? [])
            .filter { $0 != symbol }
            .prefix(8)

        var peers: [PeerStock] = []
        for peerSymbol in symbols {
            do {
                let (price, prevClose) = try await fetchStockQuote(symbol: peerSymbol)
                let profile = try? await fetchCompanyProfile(symbol: peerSymbol)
                let changePercent = prevClose != 0 ? ((price - prevClose) / prevClose) * 100 : 0
                peers.append(PeerStock(
                    symbol: peerSymbol,
                    name: profile?.name ?? peerSymbol,
                    price: price,
                    changePercent: changePercent
                ))
            } catch {
                continue
            }
        }
        return peers
    }

    // =========================================
    // MARK: - Cache Management
    // =========================================

    func clearAllCaches() async {
        await cache.clearAll()
    }

    func clearVolatileCaches() async {
        await cache.clearVolatile()
    }

    // =========================================
    // MARK: - Gemini AI Chat
    // =========================================

    private func buildSystemPrompt(language: String? = nil) -> String {
        if let lang = language {
            return """
                You are Orion, an AI financial assistant built into the Orion Finance app. \
                When users greet you or ask who you are, introduce yourself as Orion. \
                You specialize in stock market analysis, investment advice, and financial news. \
                Be concise, helpful, and professional. You can answer general questions too. \
                Always keep the name "Orion" and "Orion Finance" unchanged regardless of language. \
                Respond in \(lang).
                """
        } else {
            return """
                You are Orion, an AI financial assistant built into the Orion Finance app. \
                When users greet you or ask who you are, introduce yourself as Orion. \
                You specialize in stock market analysis, investment advice, and financial news. \
                Be concise, helpful, and professional. You can answer general questions too. \
                Always keep the name "Orion" and "Orion Finance" unchanged regardless of language. \
                Detect the language the user is writing in, and always reply in that same language.
                """
        }
    }

    func sendGeminiMessage(text: String, language: String? = nil, maxRetries: Int = 3) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(APIKeys.gemini)")!

        let systemPrompt = buildSystemPrompt(language: language)
        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                ["role": "user", "parts": [["text": text]]]
            ]
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        for attempt in 0..<maxRetries {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            if let statusCode = httpResponse?.statusCode, statusCode == 429 {
                let waitSeconds = UInt64((attempt + 1) * 5)
                print("Gemini API rate limited, retrying in \(waitSeconds)s (attempt \(attempt + 1)/\(maxRetries))")
                try await Task.sleep(nanoseconds: waitSeconds * 1_000_000_000)
                continue
            }

            if let statusCode = httpResponse?.statusCode, statusCode != 200 {
                let errorMsg = json["error"] as? [String: Any]
                let message = errorMsg?["message"] as? String ?? "Unknown error"
                print("Gemini API error (\(statusCode)): \(message)")
                throw APIError.apiError("Gemini API (\(statusCode)): \(message)")
            }

            guard let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let reply = parts.first?["text"] as? String else {
                print("Gemini API unexpected response: \(json)")
                throw APIError.invalidData
            }
            return reply
        }

        throw APIError.apiError("Gemini API: Rate limit exceeded after \(maxRetries) retries. Please try again later.")
    }

    func sendGeminiMultimodal(text: String, imageData: Data?, fileText: String?, language: String? = nil, maxRetries: Int = 3) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(APIKeys.gemini)")!

        let systemPrompt = buildSystemPrompt(language: language)

        var parts: [[String: Any]] = []

        var fullText = text
        if let fileText = fileText {
            fullText += "\n\n[File content]:\n\(fileText)"
        }
        parts.append(["text": fullText])

        if let imageData = imageData {
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": imageData.base64EncodedString()
                ]
            ])
        }

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                ["role": "user", "parts": parts]
            ]
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        for attempt in 0..<maxRetries {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            if let statusCode = httpResponse?.statusCode, statusCode == 429 {
                let waitSeconds = UInt64((attempt + 1) * 5)
                try await Task.sleep(nanoseconds: waitSeconds * 1_000_000_000)
                continue
            }

            if let statusCode = httpResponse?.statusCode, statusCode != 200 {
                let errorMsg = json["error"] as? [String: Any]
                let message = errorMsg?["message"] as? String ?? "Unknown error"
                throw APIError.apiError("Gemini API (\(statusCode)): \(message)")
            }

            guard let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let respParts = content["parts"] as? [[String: Any]],
                  let reply = respParts.first?["text"] as? String else {
                throw APIError.invalidData
            }
            return reply
        }

        throw APIError.apiError("Gemini API: Rate limit exceeded after \(maxRetries) retries.")
    }

    // =========================================
    // MARK: - Fundamental Metrics (Finnhub)
    // =========================================

    func fetchFundamentalMetrics(symbol: String) async throws -> FundamentalMetrics {
        let upper = symbol.uppercased()
        // Cache: 4 hours
        if let cached = await cache.getFundamentals(upper),
           Date().timeIntervalSince(cached.fetchedAt) < 14400 {
            return cached.metrics
        }
        let url = URL(string: "https://finnhub.io/api/v1/stock/metric?symbol=\(symbol)&metric=all&token=\(APIKeys.finnhub)")!
        let (data, _) = try await session.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let m = json["metric"] as? [String: Any] ?? [:]
        let result = FundamentalMetrics(
            peRatio: m["peBasicExclExtraTTM"] as? Double ?? m["peTTM"] as? Double,
            pbRatio: m["pbQuarterly"] as? Double ?? m["pbAnnual"] as? Double,
            epsGrowth: m["epsGrowthTTMYoy"] as? Double,
            revenueGrowth: m["revenueGrowthTTMYoy"] as? Double,
            dividendYield: m["dividendYieldIndicatedAnnual"] as? Double,
            beta: m["beta"] as? Double,
            debtToEquity: m["totalDebt/totalEquityQuarterly"] as? Double,
            roe: m["roeTTM"] as? Double,
            grossMargin: m["grossMarginTTM"] as? Double,
            operatingMargin: m["operatingMarginTTM"] as? Double
        )
        await cache.setFundamentals(upper, metrics: result)
        return result
    }

    // =========================================
    // MARK: - AI Decision Dashboard (Gemini)
    // =========================================

    /// Build the prompt and data context for AI dashboard (shared by cached and streaming paths)
    private func buildDashboardPrompt(symbol: String, name: String, price: Double, quote: StockQuote?, metrics: FundamentalMetrics?, news: [NewsItem]) -> String {
        let lang = SettingsManager.shared.appLanguage
        let newsBlock = news.prefix(8).map { "- \($0.headline)" }.joined(separator: "\n")

        var dataContext = "\(name) (\(symbol))\n"
        if let q = quote {
            dataContext += "Current: $\(String(format: "%.2f", q.price)), Change: \(String(format: "%.2f%%", q.changePercent))\n"
            dataContext += "Day Range: $\(String(format: "%.2f", q.low)) - $\(String(format: "%.2f", q.high)), Prev Close: $\(String(format: "%.2f", q.previousClose))\n"
        } else {
            dataContext += "Current price: $\(String(format: "%.2f", price))\n"
        }
        if let m = metrics {
            var items: [String] = []
            if let pe = m.peRatio { items.append("P/E: \(String(format: "%.1f", pe))") }
            if let pb = m.pbRatio { items.append("P/B: \(String(format: "%.1f", pb))") }
            if let eps = m.epsGrowth { items.append("EPS Growth: \(String(format: "%.1f%%", eps))") }
            if let rev = m.revenueGrowth { items.append("Revenue Growth: \(String(format: "%.1f%%", rev))") }
            if let dy = m.dividendYield { items.append("Div Yield: \(String(format: "%.2f%%", dy))") }
            if let b = m.beta { items.append("Beta: \(String(format: "%.2f", b))") }
            if let roe = m.roe { items.append("ROE: \(String(format: "%.1f%%", roe))") }
            if !items.isEmpty { dataContext += "Fundamentals: \(items.joined(separator: ", "))\n" }
        }
        dataContext += "Recent News:\n\(newsBlock)\n"

        return """
        Analyze this stock and return ONLY valid JSON (no markdown, no code fences):

        \(dataContext)

        Return this exact JSON structure:
        {
          "rating": "Buy" or "Watch" or "Sell",
          "score": 0-100 integer,
          "summary": "one-sentence investment conclusion",
          "entryPrice": number or null,
          "stopLoss": number or null,
          "targetPrice": number or null,
          "bullPoints": ["point1", "point2", "point3"],
          "bearPoints": ["point1", "point2", "point3"],
          "sentiment": -1.0 to 1.0 float,
          "sentimentLabel": "Very Bearish"/"Bearish"/"Neutral"/"Bullish"/"Very Bullish",
          "actionGuide": "2-3 sentence beginner-friendly action guide"
        }

        Rules:
        - score: 0-30 = Sell zone, 31-60 = Watch zone, 61-100 = Buy zone
        - entryPrice/stopLoss/targetPrice: realistic prices based on technical levels, null if unclear
        - bullPoints/bearPoints: 2-4 concise points each
        - sentiment: weighted average of news sentiment, technical trend, and fundamental health
        - rating MUST be exactly one of: "Buy", "Watch", "Sell" (always English)
        - sentimentLabel MUST be one of: "Very Bearish", "Bearish", "Neutral", "Bullish", "Very Bullish" (always English)
        - summary, bullPoints, bearPoints, actionGuide should be in \(lang)
        - actionGuide: Write for a COMPLETE beginner. Use concrete dollar amounts as examples (e.g. "if you have $1000 budget..."). Explain what to do if the price goes up or down. No jargon. 2-3 sentences max. Tailor advice to the user's risk profile: \(SettingsManager.shared.riskProfile.isEmpty ? "unknown (assume moderate)" : SettingsManager.shared.riskProfile).
        - ONLY return the JSON object, nothing else
        """
    }

    /// Parse a complete JSON string into AIDecisionDashboard
    private func parseDashboardJSON(_ text: String) -> AIDecisionDashboard? {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return AIDecisionDashboard(
            rating: json["rating"] as? String ?? "Watch",
            score: json["score"] as? Int ?? 50,
            summary: json["summary"] as? String ?? "",
            entryPrice: json["entryPrice"] as? Double,
            stopLoss: json["stopLoss"] as? Double,
            targetPrice: json["targetPrice"] as? Double,
            bullPoints: json["bullPoints"] as? [String] ?? [],
            bearPoints: json["bearPoints"] as? [String] ?? [],
            sentiment: json["sentiment"] as? Double ?? 0,
            sentimentLabel: json["sentimentLabel"] as? String ?? "Neutral",
            actionGuide: json["actionGuide"] as? String ?? ""
        )
    }

    /// Parse incomplete/streaming JSON by extracting available fields with regex
    private func parsePartialDashboardJSON(_ text: String) -> AIDecisionDashboard? {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Try complete parse first
        if let full = parseDashboardJSON(cleaned) { return full }

        // Need at least rating to show anything
        guard let rating = extractString(from: cleaned, key: "rating") else { return nil }

        return AIDecisionDashboard(
            rating: rating,
            score: extractInt(from: cleaned, key: "score") ?? 50,
            summary: extractString(from: cleaned, key: "summary") ?? "",
            entryPrice: extractDouble(from: cleaned, key: "entryPrice"),
            stopLoss: extractDouble(from: cleaned, key: "stopLoss"),
            targetPrice: extractDouble(from: cleaned, key: "targetPrice"),
            bullPoints: extractStringArray(from: cleaned, key: "bullPoints"),
            bearPoints: extractStringArray(from: cleaned, key: "bearPoints"),
            sentiment: extractDouble(from: cleaned, key: "sentiment") ?? 0,
            sentimentLabel: extractString(from: cleaned, key: "sentimentLabel") ?? "Neutral",
            actionGuide: extractString(from: cleaned, key: "actionGuide") ?? ""
        )
    }

    // MARK: - Partial JSON field extractors
    private func extractString(from text: String, key: String) -> String? {
        // Match "key": "value"
        guard let range = text.range(of: "\"\(key)\"\\s*:\\s*\"", options: .regularExpression) else { return nil }
        let after = text[range.upperBound...]
        guard let endQuote = after.firstIndex(of: "\"") else {
            // String still being streamed — return what we have
            return String(after).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(after[..<endQuote])
    }

    private func extractInt(from text: String, key: String) -> Int? {
        guard let range = text.range(of: "\"\(key)\"\\s*:\\s*", options: .regularExpression) else { return nil }
        let after = text[range.upperBound...]
        let numStr = after.prefix(while: { $0.isNumber || $0 == "-" })
        return Int(numStr)
    }

    private func extractDouble(from text: String, key: String) -> Double? {
        guard let range = text.range(of: "\"\(key)\"\\s*:\\s*", options: .regularExpression) else { return nil }
        let after = text[range.upperBound...]
        if after.hasPrefix("null") { return nil }
        let numStr = after.prefix(while: { $0.isNumber || $0 == "." || $0 == "-" })
        return Double(numStr)
    }

    private func extractStringArray(from text: String, key: String) -> [String] {
        guard let range = text.range(of: "\"\(key)\"\\s*:\\s*\\[", options: .regularExpression) else { return [] }
        let after = String(text[range.upperBound...])
        // Find all complete quoted strings in the array
        var results: [String] = []
        let pattern = try? NSRegularExpression(pattern: "\"((?:[^\"\\\\]|\\\\.)*)\"", options: [])
        let matches = pattern?.matches(in: after, options: [], range: NSRange(after.startIndex..., in: after)) ?? []
        for match in matches {
            if let r = Range(match.range(at: 1), in: after) {
                let value = String(after[r])
                // Stop if we've hit the closing bracket
                if let bracketPos = after.firstIndex(of: "]"),
                   let matchStart = Range(match.range, in: after)?.lowerBound,
                   matchStart > bracketPos { break }
                results.append(value)
            }
        }
        return results
    }

    /// Non-streaming fetch (used for cache check + fallback)
    func fetchAIDecisionDashboard(symbol: String, name: String, price: Double, quote: StockQuote?, metrics: FundamentalMetrics?, news: [NewsItem]) async throws -> AIDecisionDashboard {
        let upper = symbol.uppercased()
        if let cached = await cache.getAIDashboard(upper),
           Date().timeIntervalSince(cached.fetchedAt) < 3600 {
            return cached.dashboard
        }
        let prompt = buildDashboardPrompt(symbol: symbol, name: name, price: price, quote: quote, metrics: metrics, news: news)
        let reply = try await sendGeminiMessage(text: prompt, language: "English")
        guard let dashboard = parseDashboardJSON(reply) else { throw APIError.invalidData }
        await cache.setAIDashboard(upper, dashboard: dashboard)
        return dashboard
    }

    /// Streaming fetch — calls `onUpdate` with partial dashboard as chunks arrive
    func streamAIDecisionDashboard(
        symbol: String, name: String, price: Double,
        quote: StockQuote?, metrics: FundamentalMetrics?, news: [NewsItem],
        onUpdate: @escaping (AIDecisionDashboard) -> Void
    ) async throws -> AIDecisionDashboard {
        let upper = symbol.uppercased()
        // Cache check
        if let cached = await cache.getAIDashboard(upper),
           Date().timeIntervalSince(cached.fetchedAt) < 3600 {
            onUpdate(cached.dashboard)
            return cached.dashboard
        }

        let prompt = buildDashboardPrompt(symbol: symbol, name: name, price: price, quote: quote, metrics: metrics, news: news)
        let systemPrompt = buildSystemPrompt(language: "English")

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse&key=\(APIKeys.gemini)")!
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": prompt]]]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (stream, response) = try await URLSession.shared.bytes(for: request)
        let http = response as? HTTPURLResponse
        guard let http = http, http.statusCode == 200 else {
            let dashboard = try await fetchAIDecisionDashboard(symbol: symbol, name: name, price: price, quote: quote, metrics: metrics, news: news)
            onUpdate(dashboard)
            return dashboard
        }

        var accumulated = ""

        for try await line in stream.lines {
            // SSE format: "data: {...}"
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            guard let chunkData = jsonStr.data(using: .utf8),
                  let chunkJSON = try? JSONSerialization.jsonObject(with: chunkData) as? [String: Any],
                  let candidates = chunkJSON["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else { continue }

            accumulated += text

            // Parse partial JSON — extract whatever fields are available so far
            if let partial = parsePartialDashboardJSON(accumulated) {
                await MainActor.run { onUpdate(partial) }
            }
        }

        // Final parse — try complete first, then partial
        guard let dashboard = parseDashboardJSON(accumulated) ?? parsePartialDashboardJSON(accumulated) else {
            throw APIError.invalidData
        }
        await cache.setAIDashboard(upper, dashboard: dashboard)
        await MainActor.run { onUpdate(dashboard) }
        return dashboard
    }

    func fetchAIAnalysis(symbol: String, name: String, tone: String) async throws -> (headlines: String, analysis: String) {
        let news = try await fetchCompanyNews(symbol: symbol)
        let topNews = news.prefix(5)
        let newsBlock = topNews.map { "- \($0.headline)" }.joined(separator: "\n")
        let headlinesText = "Recent related news:\n\(newsBlock)\n"

        let lang = SettingsManager.shared.appLanguage
        var prompt = "\(name) (\(symbol)) recent news:\n\(newsBlock)\nPlease provide a concise investment suggestion (100-200 words) based on the above. Respond in \(lang)."
        switch tone {
        case "conservative":
            prompt += "\nPlease give a conservative investment suggestion."
        case "aggressive":
            prompt += "\nPlease give an aggressive investment suggestion."
        default:
            break
        }

        let analysis = try await sendGeminiMessage(text: prompt, language: lang)
        return (headlinesText, analysis)
    }

    // MARK: - Metric Explanation (AI)

    func fetchMetricExplanation(metric: String, value: String, symbol: String, name: String) async throws -> String {
        let lang = SettingsManager.shared.appLanguage
        let prompt = """
        Explain the financial metric "\(metric)" for the stock \(name) (\(symbol)).
        The current value is: \(value).

        Rules:
        - Write for a complete beginner who has ZERO knowledge of investing or finance.
        - Use plain, everyday language. No jargon.
        - First explain what this metric means in one simple sentence (like explaining to a 15-year-old).
        - Then explain whether this specific value (\(value)) is good, bad, or neutral for this stock, and compare to typical values in its industry if possible.
        - Give a practical takeaway: what should a beginner understand from this number?
        - Keep the entire response under 100 words.
        - Respond in \(lang).
        """
        return try await sendGeminiMessage(text: prompt, language: lang)
    }

    enum APIError: LocalizedError {
        case invalidData
        case apiError(String)
        var errorDescription: String? {
            switch self {
            case .invalidData: return "Invalid data received from API"
            case .apiError(let msg): return msg
            }
        }
    }
}
