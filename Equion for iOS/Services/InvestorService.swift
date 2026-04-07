import Foundation

class InvestorService {
    static let shared = InvestorService()
    private init() {}

    private let userAgent = "OrionFinance/1.0 (orion@finance.app)"

    // MARK: - Famous investors with SEC CIK numbers
    static let investors: [FamousInvestor] = [
        FamousInvestor(id: "buffett", name: "Warren Buffett", fund: "Berkshire Hathaway", cik: "1067983", description: "The Oracle of Omaha"),
        FamousInvestor(id: "burry", name: "Michael Burry", fund: "Scion Asset Management", cik: "1649339", description: "The Big Short"),
        FamousInvestor(id: "ackman", name: "Bill Ackman", fund: "Pershing Square Capital", cik: "1336528", description: "Activist Investor"),
        FamousInvestor(id: "dalio", name: "Ray Dalio", fund: "Bridgewater Associates", cik: "1350694", description: "Principles"),
        FamousInvestor(id: "soros", name: "George Soros", fund: "Soros Fund Management", cik: "1029160", description: "The Man Who Broke the Bank of England"),
        FamousInvestor(id: "druckenmiller", name: "Stanley Druckenmiller", fund: "Duquesne Family Office", cik: "1536411", description: "Macro Legend"),
        FamousInvestor(id: "tepper", name: "David Tepper", fund: "Appaloosa Management", cik: "1656456", description: "Distressed Debt King"),
    ]

    // MARK: - In-memory + disk cache (24 hours)
    private var memoryCache: [String: (portfolio: InvestorPortfolio, date: Date)] = [:]

    func fetchPortfolio(for investor: FamousInvestor) async throws -> InvestorPortfolio {
        // Check memory cache
        if let cached = memoryCache[investor.cik],
           Date().timeIntervalSince(cached.date) < 86400 {
            return cached.portfolio
        }

        // Check disk cache
        if let diskCached = loadFromDisk(cik: investor.cik) {
            memoryCache[investor.cik] = (diskCached, Date())
            return diskCached
        }

        // Fetch from SEC EDGAR
        let portfolio = try await fetchFromEDGAR(cik: investor.cik)
        memoryCache[investor.cik] = (portfolio, Date())
        saveToDisk(cik: investor.cik, portfolio: portfolio)
        return portfolio
    }

    // MARK: - Disk Cache
    private func cacheURL(for cik: String) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDir.appendingPathComponent("investor_\(cik).json")
    }

    private func timestampURL(for cik: String) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDir.appendingPathComponent("investor_\(cik)_ts.txt")
    }

    private func loadFromDisk(cik: String) -> InvestorPortfolio? {
        let tsURL = timestampURL(for: cik)
        let dataURL = cacheURL(for: cik)

        guard let tsStr = try? String(contentsOf: tsURL, encoding: .utf8),
              let ts = Double(tsStr),
              Date().timeIntervalSince1970 - ts < 86400,
              let data = try? Data(contentsOf: dataURL),
              let portfolio = try? JSONDecoder().decode(InvestorPortfolio.self, from: data) else {
            return nil
        }
        return portfolio
    }

    private func saveToDisk(cik: String, portfolio: InvestorPortfolio) {
        guard let data = try? JSONEncoder().encode(portfolio) else { return }
        try? data.write(to: cacheURL(for: cik))
        try? String(Date().timeIntervalSince1970).write(to: timestampURL(for: cik), atomically: true, encoding: .utf8)
    }

    // MARK: - SEC EDGAR Fetch
    private func edgarRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }

    private func fetchFromEDGAR(cik: String) async throws -> InvestorPortfolio {
        let paddedCIK = String(repeating: "0", count: max(0, 10 - cik.count)) + cik

        // Step 1: Get submissions to find latest 13F-HR filing
        let subURL = URL(string: "https://data.sec.gov/submissions/CIK\(paddedCIK).json")!
        let (subData, _) = try await URLSession.shared.data(for: edgarRequest(url: subURL))
        let subJSON = try JSONSerialization.jsonObject(with: subData) as? [String: Any] ?? [:]

        guard let filings = subJSON["filings"] as? [String: Any],
              let recent = filings["recent"] as? [String: Any],
              let forms = recent["form"] as? [String],
              let accessions = recent["accessionNumber"] as? [String],
              let dates = recent["filingDate"] as? [String] else {
            throw APIService.APIError.invalidData
        }

        guard let idx = forms.firstIndex(where: { $0.contains("13F") }) else {
            throw APIService.APIError.apiError("No 13F filing found for this investor")
        }

        let accession = accessions[idx]
        let filingDate = dates[idx]
        let accessionNoDashes = accession.replacingOccurrences(of: "-", with: "")

        // Step 2: Get filing index to find the XML info table
        let indexURL = URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accessionNoDashes)/index.json")!
        let (indexData, _) = try await URLSession.shared.data(for: edgarRequest(url: indexURL))
        let indexJSON = try JSONSerialization.jsonObject(with: indexData) as? [String: Any] ?? [:]

        guard let directory = indexJSON["directory"] as? [String: Any],
              let items = directory["item"] as? [[String: Any]] else {
            throw APIService.APIError.invalidData
        }

        // Find XML document (prefer "infotable" or similar)
        let xmlFiles = items.compactMap { item -> String? in
            guard let name = item["name"] as? String,
                  name.lowercased().hasSuffix(".xml") else { return nil }
            return name
        }

        guard let xmlFilename = xmlFiles.first(where: { $0.lowercased().contains("info") })
                ?? xmlFiles.first(where: { !$0.lowercased().contains("primary") && !$0.lowercased().contains("R") })
                ?? xmlFiles.first else {
            throw APIService.APIError.apiError("No info table XML found in filing")
        }

        // Step 3: Fetch and parse the XML
        let xmlURL = URL(string: "https://www.sec.gov/Archives/edgar/data/\(cik)/\(accessionNoDashes)/\(xmlFilename)")!
        var xmlReq = URLRequest(url: xmlURL)
        xmlReq.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (xmlData, _) = try await URLSession.shared.data(for: xmlReq)

        let rawHoldings = ThirteenFXMLParser().parse(data: xmlData)

        // Aggregate holdings by CUSIP (same company may appear multiple times)
        var aggregated: [String: (name: String, cusip: String, value: Double, shares: Int)] = [:]
        for h in rawHoldings {
            let key = h.cusip
            if let existing = aggregated[key] {
                aggregated[key] = (h.name, h.cusip, existing.value + h.value, existing.shares + h.shares)
            } else {
                aggregated[key] = (h.name, h.cusip, h.value, h.shares)
            }
        }

        let totalValue = aggregated.values.reduce(0) { $0 + $1.value }
        let holdings = aggregated.values
            .map { InvestorHolding(name: $0.name, cusip: $0.cusip, value: $0.value, shares: $0.shares, percentage: totalValue > 0 ? ($0.value / totalValue) * 100 : 0) }
            .sorted { $0.value > $1.value }

        return InvestorPortfolio(filingDate: filingDate, holdings: holdings, totalValue: totalValue)
    }
}

// MARK: - 13F XML Parser
private class ThirteenFXMLParser: NSObject, XMLParserDelegate {
    private var holdings: [InvestorHolding] = []
    private var currentElement = ""
    private var currentName = ""
    private var currentCusip = ""
    private var currentValue = ""
    private var currentShares = ""
    private var inEntry = false

    func parse(data: Data) -> [InvestorHolding] {
        holdings = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.parse()
        return holdings
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let local = elementName.components(separatedBy: ":").last ?? elementName
        currentElement = local

        if local == "infoTable" {
            inEntry = true
            currentName = ""
            currentCusip = ""
            currentValue = ""
            currentShares = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inEntry else { return }
        switch currentElement.components(separatedBy: ":").last ?? currentElement {
        case "nameOfIssuer": currentName += string
        case "cusip":        currentCusip += string
        case "value":        currentValue += string
        case "sshPrnamt":    currentShares += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let local = elementName.components(separatedBy: ":").last ?? elementName

        if local == "infoTable" && inEntry {
            let trimName = currentName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimShares = currentShares.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimCusip = currentCusip.trimmingCharacters(in: .whitespacesAndNewlines)

            if let value = Double(trimValue), !trimName.isEmpty {
                let shares = Int(trimShares) ?? 0
                holdings.append(InvestorHolding(
                    name: trimName,
                    cusip: trimCusip,
                    value: value * 1000, // SEC reports in thousands
                    shares: shares,
                    percentage: 0
                ))
            }
            inEntry = false
        }
        currentElement = ""
    }
}
