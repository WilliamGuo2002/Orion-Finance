import SwiftUI
import Charts
import TipKit
import PhotosUI

struct StockDetailView: View {
    let symbol: String
    let name: String

    @State private var chartEntries: [ChartEntry] = []
    @State private var currentPrice: Double = 0
    @State private var priceLoaded = false
    @State private var quote: StockQuote?
    @State private var selectedInterval = "1D"
    @Namespace private var intervalAnimation
    @State private var isLoadingChart = false
    @State private var chartError: String?

    // Touch interaction
    @State private var selectedEntry: ChartEntry?
    @State private var showMarker = false


    // Scroll tracking
    @State private var headerVisible = true
    /// Scroll offset for the pinned price + chart (compact layout).
    @State private var parallax = ChartParallax()

    // New module data
    @State private var recommendation: RecommendationTrend?
    @State private var companyNews: [NewsItem] = []
    @State private var peers: [PeerStock] = []
    @State private var companyProfile: CompanyProfile?
    @State private var comments: [StockComment] = []
    @State private var week52High: Double?
    @State private var week52Low: Double?
    @State private var fundamentals: FundamentalMetrics?
    @State private var aiDashboard: AIDecisionDashboard?
    @State private var isLoadingDashboard = false

    // Earnings
    @State private var upcomingEarnings: [APIService.EarningsEvent] = []

    // Metric explanation
    @State private var showMetricExplanation = false
    @State private var metricKey = ""          // English key, e.g. "P/E"
    @State private var metricValue = ""
    @State private var metricAIText = ""
    @State private var isLoadingMetricAI = false
    @State private var metricAIFailed = false

    // AI is opt-in: nothing is sent (and no consent sheet appears) until the user asks.
    @ObservedObject private var aiConsent = AIConsent.shared
    @State private var aiDashboardFailed = false

    private enum PeerAddState { case adding, added, failed }
    @State private var modulesLoaded = false
    @State private var showAllMetrics = false
    @State private var peerAddState: [String: PeerAddState] = [:]

    // Holdings
    @State private var showTransactionSheet = false

    // Bottom action bar
    @State private var inWatchlist = false
    @State private var showPaperTrade = false
    @State private var showCompare = false
    @State private var holdingAgg: AggregatedHolding?
    @State private var holdingTransactions: [HoldingTransaction] = []

    private let intervals = ["1D", "5D", "1M", "6M", "YTD", "1Y", "ALL"]

    // MARK: - Computed properties
    /// Latest price: the quote when loaded, else the last chart bar.
    private var latestPrice: Double? {
        if priceLoaded, currentPrice > 0 { return currentPrice }
        return chartEntries.last.map { Double($0.close) }
    }

    /// What changes are measured from: previous close for 1D, the first bar for longer ranges.
    private var changeReference: Double? {
        if selectedInterval == "1D", let pc = quote?.previousClose, pc > 0 { return pc }
        return chartEntries.first.map { Double($0.close) }
    }

    private static let barTimeParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = AppLocale.easternTime
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// "3:55 PM", "Thu 3:30 PM" or "Nov 13, 2026" for a scrubbed bar, in the app's language (ET).
    private func scrubTimeText(_ raw: String) -> String {
        guard let date = Self.barTimeParser.date(from: raw) else { return raw }
        let f = DateFormatter()
        f.locale = AppLocale.current
        f.timeZone = AppLocale.easternTime
        switch selectedInterval {
        case "1D": f.setLocalizedDateFormatFromTemplate("jmm")
        case "5D": f.setLocalizedDateFormatFromTemplate("EEEjmm")
        default:   f.setLocalizedDateFormatFromTemplate("yMMMd")
        }
        return f.string(from: date) + (selectedInterval == "1D" || selectedInterval == "5D" ? " ET" : "")
    }

    /// Change over the selected range. 1D is measured from the previous close (same as every
    /// other screen); longer ranges from the first bar of the range.
    private var intervalChange: PriceChange? {
        guard let last = latestPrice else { return nil }
        if selectedInterval == "1D", let pc = quote?.previousClose, pc > 0 {
            return PriceChange(price: last, reference: pc)
        }
        guard let first = chartEntries.first else { return nil }
        return PriceChange(price: last, reference: Double(first.close))
    }

    private var marketSession: MarketSession {
        switch MarketClock.session() {
        case .open: return .open
        case .preMarket: return .preMarket
        case .afterHours: return .afterHours
        case .holiday: return .holiday
        case .closed, .weekend: return .closed
        }
    }

    private enum MarketSession { case open, preMarket, afterHours, closed, holiday }

    /// Session label plus the time of the price shown — the last trade, not "now".
    /// On a Sunday this reads "Closed · Fri, Nov 13, 4:00 PM ET", never a Sunday time.
    private var marketStatusText: String {
        let label: String
        switch marketSession {
        case .open:        label = L("Open")
        case .preMarket:   label = L("Pre-Market")
        case .afterHours:  label = L("After-Hours")
        case .closed:      label = L("Closed")
        case .holiday:     label = "\(L("Holiday")) · \(L("Closed"))"
        }
        guard let ts = quote?.timestamp, ts > 0 else { return label }
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        var style = Date.FormatStyle(date: .omitted, time: .shortened, locale: AppLocale.current, timeZone: AppLocale.easternTime)
        if marketSession != .open || !Calendar.current.isDateInToday(date) {
            style = Date.FormatStyle(locale: AppLocale.current, timeZone: AppLocale.easternTime)
                .weekday(.abbreviated).month(.abbreviated).day().hour().minute()
        }
        return "\(label) · \(date.formatted(style)) ET"
    }

    private var extendedHoursChange: (price: Double, change: Double, percent: Double)? {
        guard let q = quote else { return nil }
        switch marketSession {
        case .preMarket, .afterHours:
            guard let ch = PriceChange(price: q.price, reference: q.previousClose) else { return nil }
            return (q.price, ch.amount, ch.percent)
        default: return nil
        }
    }

    private var priceString: String {
        priceLoaded ? String(format: "%.2f", currentPrice) : "000.00"
    }

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    /// Wide layout: iPad OR iPhone landscape
    private var isWide: Bool { hSize == .regular || vSize == .compact }
    /// Chart height adapts to screen size
    private var chartHeight: CGFloat { isWide ? 300 : 250 }

    // MARK: - Body
    var body: some View {
        Group {
            if isWide {
                wideBody
            } else {
                compactBody
            }
        }
        .background(AppTheme.background)
        .coordinateSpace(name: "scroll")
        // A detail page owns the bottom edge: the tab bar steps aside for this page's own actions.
        .toolbar(.hidden, for: .tabBar)
        .bottomActionBar {
            StockActionBar(
                symbol: symbol,
                name: name,
                isStock: isStock,
                inWatchlist: $inWatchlist,
                onPaperTrade: { showPaperTrade = true },
                onCompare: { showCompare = true }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                toolbarHeader.opacity(headerVisible ? 0 : 1)
            }
        }
        .task {
            // Everything in parallel; modules are revealed together when they're all back.
            async let chart: () = loadChart()
            async let quote: () = loadQuote()
            async let modules: () = loadAllModules()
            _ = await (chart, quote, modules)
            withAnimation(Motion.standard) { modulesLoaded = true }
            // AI snapshot only runs automatically for users who already opted in; everyone else
            // sees an opt-in button (no consent sheet on page open).
            if isStock && aiConsent.granted { await loadAIDashboard() }
        }
        .sheet(isPresented: $showMetricExplanation) {
            metricExplanationSheet
        }
        .sheet(isPresented: $showPaperTrade) {
            PaperTradeSheet(mode: .buy, initialSymbol: symbol, initialName: name) { sym, nm, shares, price in
                PaperPortfolioManager.shared.buy(symbol: sym, name: nm, shares: shares, price: price)
            }
        }
        .sheet(isPresented: $showCompare) {
            StockCompareView(symbolA: symbol, nameA: name)
        }
        .task {
            let symbols = await FirebaseController.shared.getWatchlistSymbols()
            inWatchlist = symbols.contains { $0.uppercased() == symbol.uppercased() }
        }
        .sheet(isPresented: $showTransactionSheet) {
            TransactionEntrySheet(symbol: symbol, name: name, currentPrice: currentPrice) {
                Task { await loadHoldings() }
            }
        }
    }

    // MARK: - Metric Explanation Sheet
    /// Static definition first (instant, no AI). The company-specific AI explanation is opt-in.
    private var metricExplanationSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L(metricKey))
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        Text(metricValue)
                            .font(.system(.title3, weight: .semibold).monospacedDigit())
                            .foregroundColor(AppTheme.primaryText)
                    }

                    if let definition = MetricGlossary.definition(for: metricKey) {
                        Text(definition)
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label(String(format: L("For %@"), symbol), systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.secondaryText)

                        if isLoadingMetricAI {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text(L("Asking Orion…"))
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        } else if !metricAIText.isEmpty {
                            Text(metricAIText)
                                .font(.body)
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if metricAIFailed {
                            HStack {
                                Text(L("Couldn't load an explanation right now."))
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText)
                                Spacer()
                                Button(L("Retry")) { Task { await loadMetricAI() } }
                                    .font(.subheadline.weight(.semibold))
                            }
                        } else {
                            Button {
                                Task {
                                    if await aiConsent.request() { await loadMetricAI() }
                                }
                            } label: {
                                Text(String(format: L("Explain %@ for %@ with Orion AI"), L(metricKey), symbol))
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(AppTheme.accentText)
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func loadMetricAI() async {
        isLoadingMetricAI = true
        metricAIFailed = false
        do {
            metricAIText = try await APIService.shared.fetchMetricExplanation(
                metric: L(metricKey), value: metricValue, symbol: symbol, name: name
            )
        } catch {
            metricAIFailed = !(error is AIConsent.ConsentError)
        }
        isLoadingMetricAI = false
    }

    // MARK: - Compact (iPhone portrait)
    /// Modules in reading order. They are revealed together once loaded (placeholders hold the
    /// space meanwhile), so nothing pops in and pushes the page around.
    @ViewBuilder
    private var moduleStack: some View {
        if modulesLoaded {
            keyDataModule
            aiDashboardModule
            earningsModule
            predictionsModule
            newsModule
            peersModule
            companyInfoModule
            commentsLink
        } else {
            ModulePlaceholder(height: 180)
            ModulePlaceholder(height: 140)
        }
    }

    private var compactBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Price + chart stay pinned; everything below slides up over them (as on home).
                // The range picker pins with them, so it never floats loose over the chart line.
                PinnedHero(parallax: parallax, height: chartHeight + 190) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                            .padding(.bottom, 8)
                        chartSection
                        intervalSelector
                            .padding(.bottom, 8)
                    }
                }
                .zIndex(0)

                VStack(alignment: .leading, spacing: 0) {
                    // Holdings (if user owns this asset)
                    holdingsModule

                    VStack(spacing: AppTheme.moduleSpacing) {
                        moduleStack
                    }
                    .padding(.top, 16)
                    .transition(.opacity)

                    Spacer(minLength: 24)
                }
                .environment(\.glassCards, true)
                .zIndex(1)
            }
            .padding(.top, 8)
        }
        // The compact title pill appears once the cards have climbed over the price.
        .trackingParallax(parallax) { offset in
            let visible = offset < chartHeight + 40
            if visible != headerVisible {
                withAnimation(Motion.tap) { headerVisible = visible }
            }
        }
    }

    // MARK: - Wide (iPad / landscape)
    private var wideBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.moduleSpacing) {
                headerSection
                chartSection
                intervalSelector
                holdingsModule

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: AppTheme.moduleSpacing) {
                        if modulesLoaded {
                            keyDataModule
                            aiDashboardModule
                            earningsModule
                            predictionsModule
                        } else {
                            ModulePlaceholder(height: 180)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: AppTheme.moduleSpacing) {
                        if modulesLoaded {
                            newsModule
                            peersModule
                            companyInfoModule
                            commentsLink
                        } else {
                            ModulePlaceholder(height: 180)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 24)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Module wrapper
    @ViewBuilder
    private func moduleCard<Content: View>(_ title: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AccentSectionTitle(L(title), icon: icon)
            Divider()
                .overlay(AppTheme.border.opacity(0.4))
            content()
        }
        .padding(AppTheme.cardPadding)
        .themeCardSurface()
        .padding(.horizontal, 16)
    }

    // ============================
    // MARK: - Module 1: Key Data (price facts + fundamentals, merged)
    // ============================
    /// Six facts up front; the remaining fundamentals one tap away. Ranges are neutral — a 52-week
    /// high isn't "good" and a low isn't "bad".
    @ViewBuilder
    private var keyDataModule: some View {
        let f = fundamentals
        let primary: [(key: String, value: String, tappable: Bool)] = {
            var rows: [(String, String, Bool)] = []
            if let q = quote {
                rows.append(("Previous Close", String(format: "$%.2f", q.previousClose), false))
                rows.append(("Open Price", String(format: "$%.2f", q.open), false))
            }
            if let pe = f?.peRatio { rows.append(("P/E", String(format: "%.1f", pe), true)) }
            if let dy = f?.dividendYield { rows.append(("Div Yield", String(format: "%.2f%%", dy), true)) }
            if let beta = f?.beta { rows.append(("Beta", String(format: "%.2f", beta), true)) }
            if let rev = f?.revenueGrowth { rows.append(("Revenue Growth", String(format: "%+.1f%%", rev), true)) }
            return rows.map { (key: $0.0, value: $0.1, tappable: $0.2) }
        }()
        let more: [(key: String, value: String)] = {
            guard let f else { return [] }
            var rows: [(String, String)] = []
            if let pb = f.pbRatio { rows.append(("P/B", String(format: "%.1f", pb))) }
            if let eps = f.epsGrowth { rows.append(("EPS Growth", String(format: "%+.1f%%", eps))) }
            if let roe = f.roe { rows.append(("ROE", String(format: "%.1f%%", roe))) }
            if let de = f.debtToEquity { rows.append(("D/E", String(format: "%.1f", de))) }
            if let gm = f.grossMargin { rows.append(("Gross Margin", String(format: "%.1f%%", gm))) }
            if let om = f.operatingMargin { rows.append(("Op Margin", String(format: "%.1f%%", om))) }
            return rows.map { (key: $0.0, value: $0.1) }
        }()

        if !primary.isEmpty {
            moduleCard("Key Data") {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 12) {
                    ForEach(primary, id: \.key) { row in
                        if row.tappable {
                            fundamentalRow(row.key, value: row.value)
                        } else {
                            factRow(L(row.key), value: row.value)
                        }
                    }
                    if showAllMetrics {
                        ForEach(more, id: \.key) { row in
                            fundamentalRow(row.key, value: row.value)
                        }
                    }
                }

                if let q = quote, q.high > q.low {
                    rangeBar(title: L("Day Range"), low: q.low, high: q.high, value: q.price)
                }
                if let h = week52High, let l = week52Low, h > l, let q = quote {
                    rangeBar(title: L("52W Range"), low: l, high: h, value: q.price)
                }

                if !more.isEmpty {
                    Button {
                        withAnimation(Motion.standard) { showAllMetrics.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showAllMetrics ? L("Fewer metrics") : L("All metrics"))
                            Image(systemName: showAllMetrics ? "chevron.up" : "chevron.down")
                                .imageScale(.small)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.accentText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func factRow(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.footnote)
                .foregroundColor(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundColor(AppTheme.primaryText)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// Low–high range with the current price marked. Neutral track; labels in secondary ink.
    private func rangeBar(title: String, low: Double, high: Double, value: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(String(format: "$%.2f", low))
                Spacer()
                Text(title)
                Spacer()
                Text(String(format: "$%.2f", high))
            }
            .font(.caption.monospacedDigit())
            .foregroundColor(AppTheme.secondaryText)
            GeometryReader { geo in
                let pct = max(0, min(1, (value - low) / (high - low)))
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.subtleFill).frame(height: 4)
                    Circle()
                        .fill(AppTheme.primaryText)
                        .frame(width: 10, height: 10)
                        .offset(x: geo.size.width * pct - 5)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 12)
        }
        .padding(.top, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: L("%@: %@ to %@, now %@"), title,
                                   String(format: "$%.2f", low), String(format: "$%.2f", high), String(format: "$%.2f", value)))
    }

    // ================================
    // MARK: - Module 2: Predictions
    // ================================
    @ViewBuilder
    private var predictionsModule: some View {
        if let rec = recommendation, rec.total > 0 {
            moduleCard("Analyst Recommendations", icon: "hand.thumbsup") {
                let total = Double(rec.total)
                let items: [(String, Int, Color)] = [
                    (L("Strong Buy"), rec.strongBuy, AppTheme.positive),
                    (L("Buy"), rec.buy, AppTheme.positive.opacity(0.6)),
                    (L("Hold"), rec.hold, AppTheme.accent),
                    (L("Sell"), rec.sell, AppTheme.negative.opacity(0.6)),
                    (L("Strong Sell"), rec.strongSell, AppTheme.negative)
                ]

                ForEach(items, id: \.0) { label, count, color in
                    let pct = Double(count) / total
                    HStack(spacing: 8) {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 80, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppTheme.subtleFill).frame(height: 8)
                                Capsule().fill(color).frame(width: geo.size.width * pct, height: 8)
                            }
                        }
                        .frame(height: 8)
                        Text(String(format: "%.0f%%", pct * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.primaryText)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
    }

    // ========================
    // MARK: - Module 3: News
    // ========================
    @ViewBuilder
    private var newsModule: some View {
        if !companyNews.isEmpty {
            moduleCard("Related News", icon: "newspaper") {
                ForEach(companyNews.prefix(3)) { item in
                    NavigationLink(destination: NewsDetailView(url: item.url)) {
                        HStack(spacing: 12) {
                            RemoteImage(url: item.image.flatMap(URL.init(string:)), cornerRadius: 10) {
                                RoundedRectangle(cornerRadius: 10).fill(AppTheme.subtleFill)
                                    .overlay(Image(systemName: "newspaper").font(.caption).foregroundColor(AppTheme.secondaryText))
                            }
                            .frame(width: 56, height: 42)
                            Text(item.headline)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if item.id != companyNews.prefix(3).last?.id {
                        Divider()
                            .overlay(AppTheme.border.opacity(0.3))
                            .padding(.leading, 32)
                    }
                }
                if companyNews.count > 3 {
                    NavigationLink {
                        CompanyNewsListView(title: symbol, items: companyNews)
                    } label: {
                        Text(String(format: L("See all %d stories"), companyNews.count))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.accentText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Comments live on their own page; the detail page just links to them.
    private var commentsLink: some View {
        NavigationLink {
            AllCommentsView(symbol: symbol)
        } label: {
            HStack {
                Text(L("Comments"))
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                if !comments.isEmpty {
                    Text("\(comments.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.tertiaryText)
            }
            .padding(.horizontal, AppTheme.cardPadding)
            .frame(minHeight: 52)
            .themeCardSurface()
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    // ====================================
    // MARK: - Module 5: Similar Companies
    // ====================================
    @ViewBuilder
    private var peersModule: some View {
        if !peers.isEmpty {
            moduleCard("Similar Companies", icon: "building.2") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(peers) { peer in
                            peerCard(peer)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func peerCard(_ peer: PeerStock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(peer.symbol)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
            Text(peer.name)
                .font(AppTheme.caption(11))
                .foregroundColor(AppTheme.secondaryText)
                .lineLimit(1)

            Spacer(minLength: 2)

            Text(String(format: "$%.2f", peer.price))
                .font(AppTheme.number(14))
                .foregroundColor(AppTheme.primaryText)
            ChangeBadge(value: peer.changePercent, size: .compact)

            Spacer(minLength: 2)

            peerAddButton(peer.symbol)
        }
        .frame(width: 128)
        .padding(12)
        .themeCardSurface()
    }

    /// Add-to-watchlist for a peer: shows progress, then a checkmark; errors stay visible on the card.
    @ViewBuilder
    private func peerAddButton(_ peerSymbol: String) -> some View {
        let state = peerAddState[peerSymbol]
        Button {
            guard state == nil || state == .failed else { return }
            peerAddState[peerSymbol] = .adding
            Task {
                do {
                    try await FirebaseController.shared.addToWatchlist(symbol: peerSymbol)
                    peerAddState[peerSymbol] = .added
                    Haptic.success()
                } catch {
                    peerAddState[peerSymbol] = .failed
                    Haptic.error()
                }
            }
        } label: {
            HStack(spacing: 4) {
                switch state {
                case .adding: ProgressView().controlSize(.mini)
                case .added: Image(systemName: "checkmark")
                case .failed: Image(systemName: "arrow.clockwise")
                case nil: Image(systemName: "plus")
                }
                Text(state == .added ? L("Added") : state == .failed ? L("Retry") : L("Add"))
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(state == .added ? AppTheme.secondaryText : AppTheme.accent)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(Capsule().fill(state == .added ? AppTheme.subtleFill : AppTheme.accent.opacity(0.12)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(state == .adding || state == .added)
        .accessibilityLabel(state == .added ? String(format: L("%@ added to watchlist"), peerSymbol)
                                            : String(format: L("Add %@ to watchlist"), peerSymbol))
    }

    // ==================================
    // MARK: - Module 7: Company Info
    // ==================================
    @ViewBuilder
    private var companyInfoModule: some View {
        if let profile = companyProfile {
            moduleCard("Company Info", icon: "info.circle") {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(L("Company"), profile.name)
                    infoRow(L("Industry"), profile.industry)
                    infoRow(L("Exchange"), profile.exchange)
                    infoRow(L("Country"), profile.country)
                    if profile.employeeTotal > 0 {
                        infoRow(L("Employees"), formatLargeNumber(Double(profile.employeeTotal)))
                    }
                    if profile.marketCap > 0 {
                        infoRow(L("Market Cap"), formatMarketCap(profile.marketCap))
                    }
                    if !profile.ipo.isEmpty {
                        infoRow(L("IPO Date"), profile.ipo)
                    }
                    if !profile.weburl.isEmpty {
                        HStack {
                            Text(L("Website"))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                            Link(profile.weburl.replacingOccurrences(of: "https://", with: ""), destination: URL(string: profile.weburl) ?? URL(string: "https://google.com")!)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formatMarketCap(_ cap: Double) -> String {
        // Finnhub marketCap is in millions
        if cap >= 1000000 { return String(format: "$%.2fT", cap / 1000000) }
        if cap >= 1000 { return String(format: "$%.2fB", cap / 1000) }
        return String(format: "$%.1fM", cap)
    }

    private func formatLargeNumber(_ n: Double) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", n / 1_000_000) }
        if n >= 1_000 { return String(format: "%.0fK", n / 1_000) }
        return String(format: "%.0f", n)
    }

    // ==============================
    // MARK: - AI Decision Dashboard
    // ==============================
    @ViewBuilder
    private var aiDashboardModule: some View {
        moduleCard("AI Research Snapshot", icon: "sparkles") {
            if let d = aiDashboard {
                // ── Rating + Score Row ──
                HStack(spacing: 12) {
                    // Rating badge
                    Text(L(d.rating))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(ratingColor(d.rating))
                        )

                    // Score ring
                    ZStack {
                        Circle()
                            .stroke(AppTheme.subtleFill, lineWidth: 4)
                            .frame(width: 48, height: 48)
                        Circle()
                            .trim(from: 0, to: CGFloat(d.score) / 100.0)
                            .stroke(ratingColor(d.rating), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(-90))
                        Text("\(d.score)")
                            .font(AppTheme.number(16, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                    }

                    // Summary
                    Text(d.summary)
                        .font(.system(.footnote))
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Price targets removed: specific entry / stop / target prices read as trading advice.
                if false, d.entryPrice != nil || d.stopLoss != nil || d.targetPrice != nil {
                    HStack(spacing: 0) {
                        if let entry = d.entryPrice {
                            priceTargetItem(L("Entry"), value: entry, color: AppTheme.accent)
                        }
                        if let stop = d.stopLoss {
                            priceTargetItem(L("Stop Loss"), value: stop, color: AppTheme.negative)
                        }
                        if let target = d.targetPrice {
                            priceTargetItem(L("Target"), value: target, color: AppTheme.positive)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.subtleFill.opacity(0.5))
                    )
                }

                // ── Sentiment Gauge ──
                VStack(spacing: 8) {
                    HStack {
                        Text(L("Market Sentiment"))
                            .font(.system(.caption))
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                        Text(L(d.sentimentLabel))
                            .font(.system(.caption, weight: .semibold))
                            .foregroundColor(sentimentColor(d.sentiment))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Gradient bar
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.negative, AppTheme.negative.opacity(0.5), AppTheme.accent.opacity(0.3), AppTheme.positive.opacity(0.5), AppTheme.positive],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 6)
                            // Indicator dot
                            let pct = (d.sentiment + 1.0) / 2.0  // map -1...1 to 0...1
                            Circle()
                                .fill(.white)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().fill(sentimentColor(d.sentiment)).frame(width: 8, height: 8))
                                .offset(x: geo.size.width * CGFloat(max(0, min(1, pct))) - 7)
                        }
                    }
                    .frame(height: 14)
                }

                // ── Bull / Bear Points ──
                HStack(alignment: .top, spacing: 12) {
                    // Bull points
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundColor(AppTheme.positive)
                            Text(L("Bullish Factors"))
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundColor(AppTheme.positive)
                        }
                        ForEach(d.bullPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(.caption2))
                                    .foregroundColor(AppTheme.positive)
                                Text(point)
                                    .font(.system(.caption2))
                                    .foregroundColor(AppTheme.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Divider
                    Rectangle()
                        .fill(AppTheme.border)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    // Bear points
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundColor(AppTheme.negative)
                            Text(L("Bearish Factors"))
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundColor(AppTheme.negative)
                        }
                        ForEach(d.bearPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(.caption2))
                                    .foregroundColor(AppTheme.negative)
                                Text(point)
                                    .font(.system(.caption2))
                                    .foregroundColor(AppTheme.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // ── Action Guide for Beginners ──
                if !d.actionGuide.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundColor(AppTheme.accentText)
                            Text(L("What to Watch"))
                                .font(.system(.caption, weight: .semibold))
                                .foregroundColor(AppTheme.accentText)
                        }
                        Text(d.actionGuide)
                            .font(.system(.footnote))
                            .foregroundColor(AppTheme.primaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.accent.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(AppTheme.accent.opacity(0.15), lineWidth: 1)
                            )
                    )
                }

                Text(L("AI-generated research summary for education. Not a recommendation to buy or sell."))
                    .font(AppTheme.caption(10))
                    .foregroundColor(AppTheme.secondaryText)

                // ── Deep Dive Link ──
                NavigationLink(destination: AIAnalysisView(symbol: symbol, name: name)) {
                    HStack {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(.caption))
                        Text(L("Ask Orion for deeper analysis"))
                            .font(.system(.footnote))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(.caption2, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.accentText)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.accent.opacity(0.08))
                    )
                }
            } else if !aiConsent.granted && !isLoadingDashboard {
                aiOptInPrompt
            } else if aiDashboardFailed && !isLoadingDashboard {
                HStack(spacing: 12) {
                    Text(L("Couldn't generate the snapshot right now."))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Button(L("Retry")) { Task { await loadAIDashboard() } }
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
            } else if isLoadingDashboard {
                // Loading state
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(L("Generating AI analysis..."))
                            .font(.system(.footnote))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    // Skeleton preview
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10).fill(AppTheme.subtleFill).frame(width: 80, height: 32)
                        Circle().fill(AppTheme.subtleFill).frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(height: 10)
                            RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(width: 120, height: 10)
                        }
                    }
                    .shimmer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }

    /// Shown instead of the snapshot until the user opts in to AI. Tapping is the only thing that
    /// can bring up the consent sheet on this page.
    private var aiOptInPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: L("A short, AI-written research summary of %@: what's driving the stock, key risks and what to watch. Not a recommendation."), symbol))
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task {
                    if await aiConsent.request() { await loadAIDashboard() }
                }
            } label: {
                Label(L("Generate snapshot"), systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.accentText)
        }
    }

    private func ratingColor(_ rating: String) -> Color {
        let r = rating.lowercased()
        if r.contains("positive") || r.contains("buy") || r.contains("买") { return AppTheme.positive }
        if r.contains("negative") || r.contains("sell") || r.contains("卖") { return AppTheme.negative }
        return AppTheme.accent
    }

    private func sentimentColor(_ value: Double) -> Color {
        if value > 0.2 { return AppTheme.positive }
        if value < -0.2 { return AppTheme.negative }
        return AppTheme.accent
    }

    private func priceTargetItem(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(.caption2))
                .foregroundColor(AppTheme.secondaryText)
            Text(String(format: "$%.2f", value))
                .font(AppTheme.number(15, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // ===================================
    // MARK: - Fundamentals Module
    // ===================================
    private func hasAnyFundamental(_ f: FundamentalMetrics) -> Bool {
        f.peRatio != nil || f.pbRatio != nil || f.epsGrowth != nil || f.revenueGrowth != nil ||
        f.dividendYield != nil || f.beta != nil || f.roe != nil
    }

    private func fundamentalRow(_ key: String, value: String, color: Color? = nil) -> some View {
        let label = L(key)
        return Button {
            metricKey = key
            metricValue = value
            metricAIText = ""
            metricAIFailed = false
            isLoadingMetricAI = false
            showMetricExplanation = true
            // Only reach the AI if the user already opted in; otherwise the sheet offers it.
            if aiConsent.granted { Task { await loadMetricAI() } }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.footnote)
                    .foregroundColor(AppTheme.secondaryText)
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(AppTheme.tertiaryText)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundColor(color ?? AppTheme.primaryText)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(L("Shows what this metric means"))
    }

    // ===================================
    // MARK: - Earnings Module
    // ===================================
    // MARK: - Holdings Module
    @ViewBuilder
    private var holdingsModule: some View {
        VStack(spacing: 0) {
            // Manual trade entry was removed: positions come from linked accounts only.
            // Show holdings info if user has a position
            if let agg = holdingAgg, agg.totalShares > 0.0001 {
                VStack(alignment: .leading, spacing: 12) {
                    AccentSectionTitle(L("Your Position"), icon: "briefcase.fill")

                    // Summary row
                    HStack(spacing: 0) {
                        // Shares & Avg Cost
                        VStack(spacing: 4) {
                            Text(String(format: "%.4g", agg.totalShares))
                                .font(AppTheme.number(18, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)
                            Text(L("Shares"))
                                .font(.system(.caption2))
                                .foregroundColor(AppTheme.secondaryText)
                            Text(HoldingsManager.shared.snapshot.format(agg.averageCost))
                                .font(AppTheme.number(12, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                            Text(L("Avg Cost"))
                                .font(.system(.caption2))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 60)

                        // Market Value
                        VStack(spacing: 4) {
                            Text(HoldingsManager.shared.snapshot.format(agg.marketValue))
                                .font(AppTheme.number(18, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)
                            Text(L("Market Value"))
                                .font(.system(.caption2))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 60)

                        // Total P&L
                        VStack(spacing: 4) {
                            Text((agg.totalPnL >= 0 ? "+" : "-") + HoldingsManager.shared.snapshot.format(abs(agg.totalPnL)))
                                .font(AppTheme.number(16, weight: .bold))
                                .foregroundColor(agg.totalPnL >= 0 ? AppTheme.positive : AppTheme.negative)
                            Text(String(format: "%@%.2f%%", agg.totalPnLPercent >= 0 ? "+" : "", agg.totalPnLPercent))
                                .font(AppTheme.number(12, weight: .semibold))
                                .foregroundColor(agg.totalPnLPercent >= 0 ? AppTheme.positive : AppTheme.negative)
                            Text(L("Total P&L"))
                                .font(.system(.caption2))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Day P&L
                    HStack {
                        Text(L("Today"))
                            .font(.system(.caption))
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                        Text(String(format: "%@%@ (%@%.2f%%)",
                                    agg.dayPnL >= 0 ? "+" : "-", HoldingsManager.shared.snapshot.format(abs(agg.dayPnL)),
                                    agg.dayPnLPercent >= 0 ? "+" : "", agg.dayPnLPercent))
                            .font(AppTheme.number(13, weight: .semibold))
                            .foregroundColor(agg.dayPnL >= 0 ? AppTheme.positive : AppTheme.negative)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill((agg.dayPnL >= 0 ? AppTheme.positive : AppTheme.negative).opacity(0.06))
                    )

                    // Transaction History
                    if !holdingTransactions.isEmpty {
                        Divider().overlay(AppTheme.border.opacity(0.4))

                        VStack(alignment: .leading, spacing: 8) {
                            Text(L("Transaction History"))
                                .font(.system(.caption, weight: .semibold))
                                .foregroundColor(AppTheme.secondaryText)

                            ForEach(holdingTransactions.suffix(5).reversed()) { tx in
                                HStack(spacing: 8) {
                                    Image(systemName: tx.action == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                        .font(.system(.subheadline))
                                        .foregroundColor(tx.action == .buy ? AppTheme.positive : AppTheme.negative)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(tx.action == .buy ? L("Buy") : L("Sell"))
                                            .font(.system(.caption, weight: .semibold))
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(txDateString(tx.date))
                                            .font(.system(.caption2))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(String(format: "%.4g × $%.2f", tx.shares, tx.pricePerShare))
                                            .font(AppTheme.number(12, weight: .medium))
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(String(format: "$%.2f", tx.totalValue))
                                            .font(AppTheme.number(11))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(AppTheme.cardPadding)
                .themeCardSurface()
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
    }

    private func txDateString(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.abbreviated).day().locale(AppLocale.current))
    }

    @ViewBuilder
    private var earningsModule: some View {
        if !upcomingEarnings.isEmpty {
            moduleCard("Upcoming Earnings", icon: "calendar.badge.clock") {
                ForEach(upcomingEarnings.prefix(3)) { event in
                    HStack(spacing: 12) {
                        // Date badge
                        VStack(spacing: 0) {
                            Text(earningsMonth(event.date))
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundColor(AppTheme.onAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent)
                            Text(earningsDay(event.date))
                                .font(AppTheme.number(18, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .frame(width: 44)
                        .background(AppTheme.subtleFill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(L("Earnings Report"))
                                    .font(.system(.footnote, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                if !event.hour.isEmpty {
                                    Text(event.hour == "bmo" ? L("Before Open") : L("After Close"))
                                        .font(.system(.caption2))
                                        .foregroundColor(AppTheme.accentText)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(AppTheme.accent.opacity(0.1)))
                                }
                            }
                            if let est = event.epsEstimate {
                                Text(String(format: "EPS %@: $%.2f", L("Estimate"), est))
                                    .font(.system(.caption2))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                // Beginner tip
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(.caption2))
                        .foregroundColor(AppTheme.accentText)
                        .padding(.top, 1)
                    Text(L("Prices often move more than usual around an earnings report."))
                        .font(.system(.caption2))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(2)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.accent.opacity(0.05))
                )
            }
        }
    }

    private func earningsMonth(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count >= 2, let month = Int(parts[1]) else { return "" }
        let months = ["", "JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
        return month < months.count ? months[month] : ""
    }

    private func earningsDay(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count >= 3 else { return "" }
        return String(parts[2])
    }

    // =============================
    // MARK: - Existing sections
    // =============================
    @ViewBuilder
    private var intervalSelector: some View {
        RangePicker(options: intervals, selection: $selectedInterval) { _ in
            selectedEntry = nil
            showMarker = false
            Task { await loadChart() }
        }
        .padding(.horizontal, 12)
    }

    /// Splits a price string into (currency symbol, number) for typographic contrast
    private func splitPrice(_ value: Double, format: String = "%.2f") -> (symbol: String, number: String) {
        ("$", String(format: format, value))
    }

    @ViewBuilder
    private var headerSection: some View {
        // One layout for both resting and scrubbing states, so nothing jumps under the finger.
        let scrubbing = showMarker && selectedEntry != nil
        let shownPrice: String = {
            if scrubbing, let e = selectedEntry { return String(format: "%.2f", e.close) }
            return priceString
        }()
        let shownChange: PriceChange? = {
            guard scrubbing, let e = selectedEntry else { return intervalChange }
            return PriceChange(price: Double(e.close), reference: changeReference ?? Double(e.close))
        }()

        VStack(alignment: .leading, spacing: 4) {
            Text(MyHoldingView.displaySymbol(symbol))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.secondaryText)
            Text(name)
                .font(AppTheme.serifTitle(24))
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(2)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("$")
                        .font(AppTheme.heroCurrency(.title3))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(shownPrice)
                        .font(AppTheme.heroNumber(.largeTitle))
                        .foregroundColor(AppTheme.primaryText)
                        .redacted(reason: priceLoaded || scrubbing ? [] : .placeholder)
                        .contentTransition(.numericText())
                        .animation(scrubbing ? .easeInOut(duration: 0.05) : Motion.number, value: shownPrice)
                }
                if let ch = shownChange {
                    ChangeBadge(value: ch.percent, amount: ch.amount, size: .large)
                        .animation(scrubbing ? .easeInOut(duration: 0.05) : Motion.number, value: ch.percent)
                }
            }
            .padding(.top, 4)

            // The resting status stays laid out (hidden) while scrubbing, so the row keeps its
            // height — a two-line status collapsing to a one-line time would jerk the chart upward.
            ZStack(alignment: .topLeading) {
                HStack(spacing: 8) {
                    Text(marketStatusText)
                    if let ext = extendedHoursChange {
                        Text("·")
                        Text(String(format: "$%.2f", ext.price)).foregroundColor(AppTheme.primaryText)
                        ChangeBadge(value: ext.percent, size: .compact)
                    }
                }
                .opacity(scrubbing ? 0 : 1)
                .accessibilityHidden(scrubbing)

                if scrubbing, let e = selectedEntry {
                    Text(scrubTimeText(e.datetime))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.05), value: e.datetime)
                }
            }
            .font(.footnote)
            .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.horizontal, 16)
        .background(
            GeometryReader { geo in
                Color.clear.onChange(of: geo.frame(in: .named("scroll")).maxY) { _, newVal in
                    // Compact layout pins the header; its visibility comes from the parallax offset.
                    guard isWide else { return }
                    let isNowVisible = newVal > 0
                    if isNowVisible != headerVisible {
                        withAnimation(Motion.tap) { headerVisible = isNowVisible }
                    }
                }
            }
        )
    }

    @ViewBuilder
    private var toolbarHeader: some View {
        HStack(spacing: 8) {
            Text(symbol).font(.headline).foregroundColor(AppTheme.primaryText)
            Text("$\(priceString)").font(AppTheme.number()).foregroundColor(AppTheme.secondaryText)
                .redacted(reason: priceLoaded ? [] : .placeholder)
            if let ch = intervalChange {
                ChangeBadge(value: ch.percent, size: .compact)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(AppTheme.barBackground))
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private var chartSection: some View {
        if isLoadingChart {
            SkeletonChart()
                .frame(height: chartHeight)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
        } else if let error = chartError {
            ErrorStateView(
                message: error,
                retryAction: { Task { await loadChart() } }
            )
            .frame(height: chartHeight)
            .padding(.horizontal, 16)
        } else if !chartEntries.isEmpty {
            let closes = chartEntries.map { Double($0.close) }
            let baseline: Double? = selectedInterval == "1D" ? quote?.previousClose : nil
            let lo = min(closes.min() ?? 0, baseline ?? .infinity)
            let hi = max(closes.max() ?? 0, baseline ?? -.infinity)
            let pad = max((hi - lo) * 0.05, 0.01)
            let isUp = (intervalChange?.amount ?? 0) >= 0
            let lineColor = isUp ? AppTheme.positive : AppTheme.negative

            let lastIndex = max(chartEntries.last?.index ?? 1, 1)
            let hasVolume = chartEntries.contains { $0.volume > 0 }

            VStack(spacing: 6) {
            Chart {
                ForEach(chartEntries) { entry in
                    AreaMark(
                        x: .value("Time", entry.index),
                        yStart: .value("Min", lo - pad),
                        yEnd: .value("Price", Double(entry.close))
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [lineColor.opacity(0.08), lineColor.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.monotone)
                }

                ForEach(chartEntries) { entry in
                    LineMark(x: .value("Time", entry.index), y: .value("Price", Double(entry.close)))
                        .foregroundStyle(lineColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                }

                // Previous close: the line the day is measured against
                if let baseline {
                    RuleMark(y: .value("Previous close", baseline))
                        .foregroundStyle(AppTheme.tertiaryText)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
                }

                // Latest point while the market is open (static dot, no pulse)
                if selectedInterval == "1D" && marketSession == .open && !showMarker, let last = chartEntries.last {
                    PointMark(x: .value("Time", last.index), y: .value("Price", Double(last.close)))
                        .symbol { LivePulseDot(color: lineColor) }
                }

                if let entry = selectedEntry, showMarker {
                    RuleMark(x: .value("Time", entry.index))
                        .foregroundStyle(AppTheme.tertiaryText)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    PointMark(x: .value("Time", entry.index), y: .value("Price", Double(entry.close)))
                        .foregroundStyle(AppTheme.primaryText)
                        .symbolSize(40)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: (lo - pad)...(hi + pad))
            .chartXScale(domain: 0...lastIndex, range: .plotDimension)
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !showMarker { ChartScrubTip().invalidate(reason: .actionPerformed) }
                                guard let index: Int = proxy.value(atX: value.location.x),
                                      let nearest = chartEntries.min(by: { abs($0.index - index) < abs($1.index - index) })
                                else { return }
                                if nearest.index != selectedEntry?.index { selectedEntry = nearest }
                                showMarker = true
                            }
                            .onEnded { _ in
                                showMarker = false
                                selectedEntry = nil
                            }
                    )
            }
            // One tick when scrubbing starts — not one per data point.
            .sensoryFeedback(.selection, trigger: showMarker) { _, new in new && Haptic.isEnabled }
            .popoverTip(ChartScrubTip(), arrowEdge: .top)
            .frame(height: hasVolume ? chartHeight - VolumeStrip.height - 6 : chartHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(chartAccessibilitySummary)

                if hasVolume {
                    VolumeStrip(entries: chartEntries, lastIndex: lastIndex,
                                highlighted: showMarker ? selectedEntry?.index : nil)
                }
            }
        }
    }

    private var chartAccessibilitySummary: String {
        guard let first = chartEntries.first, let last = latestPrice else { return L("Price chart") }
        let change = intervalChange.map { ChangeBadge.spoken($0.percent) } ?? ""
        return String(format: L("%@ price chart, %@: from %@ to %@, %@"),
                      symbol, RangePicker.spoken(selectedInterval),
                      String(format: "$%.2f", changeReference ?? Double(first.close)), String(format: "$%.2f", last), change)
    }

    // MARK: - Data Loading
    private func loadChart() async {
        isLoadingChart = true; chartError = nil
        // Yahoo Finance uses range + interval (not outputSize)
        let (range, interval): (String, String) = {
            switch selectedInterval {
            case "1D":  return ("1d",  "5m")
            case "5D":  return ("5d",  "30m")
            case "1M":  return ("1mo", "1d")
            case "6M":  return ("6mo", "1d")
            case "YTD": return ("ytd", "1d")
            case "1Y":  return ("1y",  "1wk")
            case "ALL": return ("max", "1mo")
            default:    return ("1mo", "1d")
            }
        }()
        do {
            let entries = try await APIService.shared.fetchChartData(symbol: symbol, range: range, interval: interval)
            await MainActor.run { chartEntries = entries; isLoadingChart = false }
        } catch {
            await MainActor.run { chartError = "\(L("Chart load failed")): \(error.localizedDescription)"; isLoadingChart = false }
        }
    }

    private func loadQuote() async {
        do {
            let q = try await APIService.shared.fetchFullQuote(symbol: symbol)
            await MainActor.run { quote = q; currentPrice = q.price; priceLoaded = true }
        } catch {
            await MainActor.run { priceLoaded = false }
        }
    }

    /// Whether this asset is a stock (vs crypto/metal/commodity)
    private var isStock: Bool {
        AssetMeta.assetType(for: symbol) == .stock
    }

    private func loadHoldings() async {
        let txs = HoldingsManager.shared.transactions(for: symbol)
        holdingTransactions = txs
        holdingAgg = HoldingsManager.shared.aggregatedHolding(for: symbol)
        // If manager hasn't loaded yet, do a full load
        if !HoldingsManager.shared.hasLoaded {
            await HoldingsManager.shared.loadAll()
            let txs2 = HoldingsManager.shared.transactions(for: symbol)
            holdingTransactions = txs2
            holdingAgg = HoldingsManager.shared.aggregatedHolding(for: symbol)
        }
    }

    private func loadAllModules() async {
        // Only load stock-specific modules for actual stocks
        // Crypto/metals don't have analyst ratings, peers, or company profiles
        async let commentsTask: () = loadComments()
        async let newsTask: () = loadCompanyNews()
        async let holdingsTask: () = loadHoldings()

        if isStock {
            async let recTask: () = loadRecommendation()
            async let peersTask: () = loadPeers()
            async let profileTask: () = loadCompanyProfile()
            async let week52Task: () = loadWeek52Range()
            async let fundamentalsTask: () = loadFundamentals()
            async let earningsTask: () = loadEarnings()
            _ = await (recTask, newsTask, peersTask, profileTask, commentsTask, week52Task, fundamentalsTask, earningsTask, holdingsTask)
        } else {
            _ = await (newsTask, commentsTask, holdingsTask)
        }
    }

    private func loadRecommendation() async {
        do { recommendation = try await APIService.shared.fetchRecommendation(symbol: symbol) } catch {}
    }
    private func loadCompanyNews() async {
        do { companyNews = try await APIService.shared.fetchCompanyNews(symbol: symbol) } catch {}
    }
    private func loadPeers() async {
        do { peers = try await APIService.shared.fetchPeers(symbol: symbol) } catch {}
    }
    private func loadWeek52Range() async {
        do {
            let range = try await APIService.shared.fetchWeek52Range(symbol: symbol)
            await MainActor.run { week52High = range.high; week52Low = range.low }
        } catch {}
    }
    private func loadCompanyProfile() async {
        do { companyProfile = try await APIService.shared.fetchFullCompanyProfile(symbol: symbol) } catch {}
    }
    private func loadComments() async {
        comments = await FirebaseController.shared.fetchComments(symbol: symbol)
    }
    private func loadFundamentals() async {
        do { fundamentals = try await APIService.shared.fetchFundamentalMetrics(symbol: symbol) } catch {}
    }
    private func loadEarnings() async {
        do { upcomingEarnings = try await APIService.shared.fetchEarningsCalendar(symbol: symbol) } catch {}
    }
    private func loadAIDashboard() async {
        await MainActor.run { isLoadingDashboard = true; aiDashboardFailed = false }
        do {
            _ = try await APIService.shared.streamAIDecisionDashboard(
                symbol: symbol,
                name: name,
                price: currentPrice,
                quote: quote,
                metrics: fundamentals,
                news: companyNews
            ) { partial in
                self.aiDashboard = partial
                self.isLoadingDashboard = false
            }
        } catch {
            await MainActor.run {
                isLoadingDashboard = false
                aiDashboardFailed = aiDashboard == nil && !(error is AIConsent.ConsentError)
            }
        }
    }
}

// MARK: - All Comments View
struct AllCommentsView: View {
    let symbol: String
    @State private var comments: [StockComment] = []
    @State private var commentText = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 8) {
                    TextField(L("Leave a comment..."), text: $commentText)
                        .textFieldStyle(.roundedBorder)
                    Button(action: post) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(commentText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.secondaryText : AppTheme.primaryText)
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            ForEach(comments) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "person.circle.fill").foregroundColor(AppTheme.secondaryText)
                        Text(comment.userName).font(.subheadline).fontWeight(.semibold).foregroundColor(AppTheme.primaryText)
                        Spacer()
                        Text(timeAgo(comment.timestamp)).font(.caption).foregroundColor(AppTheme.secondaryText)
                    }
                    Text(comment.text).font(.body).foregroundColor(AppTheme.primaryText)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle("\(symbol) · \(L("Comments"))")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            comments = await FirebaseController.shared.fetchComments(symbol: symbol, limitCount: 50)
        }
    }

    private func post() {
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        FirebaseController.shared.postComment(symbol: symbol, text: text)
        commentText = ""
        Task { comments = await FirebaseController.shared.fetchComments(symbol: symbol, limitCount: 50) }
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return L("just now") }
        if s < 3600 { return "\(s/60)m" }
        if s < 86400 { return "\(s/3600)h" }
        return "\(s/86400)d"
    }
}

// MARK: - AI Analysis View (separate page with chat)
struct AIAnalysisView: View {
    let symbol: String
    let name: String

    @State private var aiHeadlines = ""
    @State private var aiAnalysis = ""
    @State private var currentTone = "moderate"
    @State private var isLoadingAnalysis = false
    @State private var hasLoaded = false

    @State private var chatMessages: [ChatMessage] = []
    @State private var userInput = ""
    @State private var isSending = false

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var attachedImageData: Data?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        toneSelector
                        analysisContent

                        if hasLoaded && !chatMessages.isEmpty {
                            HStack {
                                Rectangle().fill(AppTheme.border).frame(height: 0.5)
                                Text(L("Conversation")).font(AppTheme.caption()).foregroundColor(AppTheme.secondaryText).layoutPriority(1)
                                Rectangle().fill(AppTheme.border).frame(height: 0.5)
                            }
                            .padding(.horizontal, 16).padding(.top, 8)
                        }

                        ForEach(chatMessages) { msg in
                            AnalysisChatBubble(message: msg).id(msg.id).padding(.horizontal, 16)
                        }

                        if isSending {
                            HStack {
                                ProgressView().padding(.horizontal, 16)
                                Text(L("Thinking...")).foregroundColor(AppTheme.secondaryText)
                                Spacer()
                            }.padding(.horizontal, 24).id("loading")
                        }

                        Spacer(minLength: 16)
                    }
                }
                .onChange(of: chatMessages.count) { _, _ in
                    withAnimation(Motion.standard) { if let last = chatMessages.last { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }

            if attachedImageData != nil { imagePreview }
            inputBar
        }
        .navigationTitle("\(symbol) · \(L("AI Analysis"))")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data), let jpeg = ui.jpegData(compressionQuality: 0.7) {
                    await MainActor.run { attachedImageData = jpeg }
                }
            }
        }
        .task { if !hasLoaded { await loadAnalysis() } }
    }

    @ViewBuilder private var toneSelector: some View {
        HStack(spacing: 8) {
            ForEach(["conservative", "moderate", "aggressive"], id: \.self) { tone in
                Button(L(tone.capitalized)) {
                    withAnimation(Motion.tap) { currentTone = tone }
                    Task { await loadAnalysis() }
                }
                .font(.system(.footnote, weight: currentTone == tone ? .semibold : .regular))
                .foregroundColor(currentTone == tone ? AppTheme.onAccent : AppTheme.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(currentTone == tone ? AppTheme.accent : AppTheme.subtleFill))
                .overlay(Capsule().stroke(currentTone == tone ? Color.clear : AppTheme.border, lineWidth: 0.5))
            }
            Spacer()
            Button(action: { Task { await loadAnalysis() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(.subheadline))
                    .foregroundColor(AppTheme.accentText)
                    .padding(8)
                    .background(Circle().fill(AppTheme.accent.opacity(0.1)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var analysisContent: some View {
        if isLoadingAnalysis {
            VStack(spacing: 12) { ProgressView(); Text(L("Generating...")).font(.subheadline).foregroundColor(AppTheme.secondaryText) }
                .frame(maxWidth: .infinity).padding(.top, 48)
        } else if hasLoaded {
            if !aiHeadlines.isEmpty { Text(aiHeadlines).font(AppTheme.caption()).foregroundColor(AppTheme.secondaryText).padding(.horizontal, 16) }
            MarkdownText(text: aiAnalysis).font(.body).foregroundColor(AppTheme.primaryText).padding(.horizontal, 16)
        }
    }

    @ViewBuilder private var imagePreview: some View {
        HStack(spacing: 8) {
            if let d = attachedImageData, let ui = UIImage(data: d) {
                Image(uiImage: ui).resizable().scaledToFill().frame(width: 48, height: 48).cornerRadius(10).clipped()
                Text(L("Photo attached")).font(AppTheme.caption()).foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            Button(action: { attachedImageData = nil; selectedPhoto = nil }) {
                Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.secondaryText)
            }
        }.padding(.horizontal, 16).padding(.vertical, 8).background(AppTheme.subtleFill)
    }

    @ViewBuilder private var inputBar: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo").font(.system(.title3)).foregroundColor(AppTheme.secondaryText)
            }
            TextField(L("Ask about") + " \(symbol)...", text: $userInput).textFieldStyle(.roundedBorder)
            Button(action: sendChat) {
                Image(systemName: "paperplane.fill").foregroundColor(canSend ? AppTheme.primaryText : AppTheme.secondaryText)
            }.disabled(!canSend || isSending)
        }.padding(.horizontal, 12).padding(.vertical, 8).background(AppTheme.barBackground).padding(.bottom, 64)
    }

    private var canSend: Bool { !userInput.trimmingCharacters(in: .whitespaces).isEmpty || attachedImageData != nil }

    private func sendChat() {
        let text = userInput.trimmingCharacters(in: .whitespaces)
        guard canSend else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let imgData = attachedImageData
        chatMessages.append(ChatMessage(role: "user", content: text.isEmpty ? L("Photo attached") : text, imageData: imgData))
        userInput = ""; attachedImageData = nil; selectedPhoto = nil; isSending = true
        let ctx = "You are analyzing \(name) (\(symbol)). Current analysis:\n\(aiAnalysis)\n\nUser asks: "
        Task {
            do {
                let reply: String
                if let imgData { reply = try await APIService.shared.sendGeminiMultimodal(text: ctx + (text.isEmpty ? "What do you see?" : text), imageData: imgData, fileText: nil) }
                else { reply = try await APIService.shared.sendGeminiMessage(text: ctx + text) }
                await MainActor.run { chatMessages.append(ChatMessage(role: "ai", content: reply)); isSending = false }
            } catch {
                await MainActor.run { chatMessages.append(ChatMessage(role: "ai", content: "Error: \(error.localizedDescription)")); isSending = false }
            }
        }
    }

    private func loadAnalysis() async {
        isLoadingAnalysis = true
        do {
            let r = try await APIService.shared.fetchAIAnalysis(symbol: symbol, name: name, tone: currentTone)
            await MainActor.run { aiHeadlines = r.headlines; aiAnalysis = r.analysis; isLoadingAnalysis = false; hasLoaded = true }
        } catch {
            await MainActor.run { aiAnalysis = "Error: \(error.localizedDescription)"; isLoadingAnalysis = false; hasLoaded = true }
        }
    }
}

private struct AnalysisChatBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == "user" }
    var body: some View {
        HStack {
            if isUser { Spacer() }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if let d = message.imageData, let ui = UIImage(data: d) {
                    Image(uiImage: ui).resizable().scaledToFit().frame(maxWidth: 220, maxHeight: 200).cornerRadius(10)
                }
                if !message.content.isEmpty {
                    Group { if isUser { Text(message.content) } else { MarkdownText(text: message.content) } }
                        .padding(12).background(isUser ? AppTheme.accent.opacity(0.15) : AppTheme.subtleFill)
                        .foregroundColor(AppTheme.primaryText).cornerRadius(18)
                }
            }
            .frame(maxWidth: isUser ? 280 : .infinity, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer() }
        }
    }
}

// MARK: - Transaction Entry Sheet
struct TransactionEntrySheet: View {
    let symbol: String
    let name: String
    let currentPrice: Double
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var action: HoldingTransaction.HoldingAction = .buy
    @State private var sharesText = ""
    @State private var priceText = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Symbol header
                    VStack(spacing: 4) {
                        Text(symbol)
                            .font(.system(.title2, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Text(name)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(String(format: "$%.2f", currentPrice))
                            .font(AppTheme.number(16, weight: .semibold))
                            .foregroundColor(AppTheme.accentText)
                    }
                    .padding(.top, 8)

                    // Buy / Sell picker
                    Picker("", selection: $action) {
                        Text(L("Buy")).tag(HoldingTransaction.HoldingAction.buy)
                        Text(L("Sell")).tag(HoldingTransaction.HoldingAction.sell)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    // Input fields
                    VStack(spacing: 16) {
                        // Shares
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L("Number of Shares"))
                                .font(.system(.footnote))
                                .foregroundColor(AppTheme.secondaryText)
                            TextField("0", text: $sharesText)
                                .keyboardType(.decimalPad)
                                .font(AppTheme.number(18, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                                .padding(12)
                                .background(AppTheme.subtleFill)
                                .cornerRadius(10)
                        }

                        // Price per share
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(L("Price per Share"))
                                    .font(.system(.footnote))
                                    .foregroundColor(AppTheme.secondaryText)
                                Spacer()
                                Button(L("Use Current")) {
                                    priceText = String(format: "%.2f", currentPrice)
                                }
                                .font(.system(.caption))
                                .foregroundColor(AppTheme.accentText)
                            }
                            HStack {
                                Text("$")
                                    .font(AppTheme.number(18, weight: .medium))
                                    .foregroundColor(AppTheme.secondaryText)
                                TextField("0.00", text: $priceText)
                                    .keyboardType(.decimalPad)
                                    .font(AppTheme.number(18, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                            }
                            .padding(12)
                            .background(AppTheme.subtleFill)
                            .cornerRadius(10)
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L("Transaction Date"))
                                .font(.system(.footnote))
                                .foregroundColor(AppTheme.secondaryText)
                            DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    .padding(.horizontal, 16)

                    // Total
                    if let shares = Double(sharesText), let price = Double(priceText), shares > 0, price > 0 {
                        HStack {
                            Text(L("Total"))
                                .font(.system(.subheadline))
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                            Text(String(format: "$%.2f", shares * price))
                                .font(AppTheme.number(20, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(AppTheme.subtleFill)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                    }

                    // Save button
                    Button {
                        save()
                    } label: {
                        Text(action == .buy ? L("Record Purchase") : L("Record Sale"))
                            .font(.system(.callout, weight: .semibold))
                            .foregroundColor(AppTheme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isValid ? AppTheme.accent : AppTheme.accent.opacity(0.3))
                            )
                    }
                    .disabled(!isValid)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            }
            .background(AppTheme.background)
            .navigationTitle(action == .buy ? L("Buy") + " \(symbol)" : L("Sell") + " \(symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .onAppear {
                priceText = String(format: "%.2f", currentPrice)
            }
        }
    }

    private var isValid: Bool {
        guard let shares = Double(sharesText), let price = Double(priceText) else { return false }
        return shares > 0 && price > 0
    }

    private func save() {
        guard let shares = Double(sharesText), let price = Double(priceText) else { return }
        let tx = HoldingTransaction(
            symbol: symbol.uppercased(),
            action: action,
            shares: shares,
            pricePerShare: price,
            date: date,
            createdAt: Date()
        )
        HoldingsManager.shared.addTransaction(tx)
        Haptic.success()
        onComplete()
        dismiss()
    }
}

// MARK: - Placeholder that holds a module's space while data loads
struct ModulePlaceholder: View {
    var height: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(width: 120, height: 14)
            RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(height: 10)
            RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(width: 200, height: 10)
            Spacer(minLength: 0)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
        .themeCardSurface()
        .padding(.horizontal, 16)
        .accessibilityHidden(true)
    }
}

// MARK: - All related news for a symbol
struct CompanyNewsListView: View {
    let title: String
    let items: [NewsItem]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    NavigationLink(destination: NewsDetailView(url: item.url)) {
                        NewsCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppTheme.background)
        .navigationTitle(String(format: L("%@ news"), title))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tip: scrub the chart

/// Shown once, the first time someone opens a chart, until they scrub it.
struct ChartScrubTip: Tip {
    var title: Text { Text(L("Touch and hold to explore")) }
    var message: Text? { Text(L("Slide across the chart to see the price at any point.")) }
    var image: Image? { Image(systemName: "hand.point.up.left") }
}


// MARK: - Bottom action bar
/// The page's actions in one floating glass bar at the thumb's reach — watchlist, paper trade,
/// compare, ask Orion. Liquid Glass on iOS 26; a frosted material capsule before that.
/// Read-only app: "Paper trade" is the only order-shaped action, and it's clearly labelled as such.
struct StockActionBar: View {
    let symbol: String
    let name: String
    let isStock: Bool
    @Binding var inWatchlist: Bool
    let onPaperTrade: () -> Void
    let onCompare: () -> Void

    @State private var busy = false

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) { items(glass: true) }
                }
            } else {
                HStack(spacing: 10) { items(glass: false) }
            }
        }
        .padding(.horizontal, AppTheme.Space.screenMargin)
        .padding(.top, AppTheme.Space.s)
        .padding(.bottom, AppTheme.Space.xs)
        .sensoryFeedback(.selection, trigger: inWatchlist) { _, _ in Haptic.isEnabled }
    }

    @ViewBuilder
    private func items(glass: Bool) -> some View {
        Button(action: toggleWatchlist) {
            Image(systemName: inWatchlist ? "star.fill" : "star")
                .font(.body.weight(.medium))
                .foregroundColor(inWatchlist ? AppTheme.accentText : AppTheme.primaryText)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .modifier(GlassPill(glass: glass, circle: true))
        .accessibilityLabel(inWatchlist ? String(format: L("Remove %@ from watchlist"), symbol)
                                        : String(format: L("Add %@ to watchlist"), symbol))

        if isStock {
            Button(action: onPaperTrade) {
                pillLabel(L("Paper trade"), systemImage: "chart.line.uptrend.xyaxis")
            }
            .buttonStyle(.plain)
            .modifier(GlassPill(glass: glass, circle: false))

            Button(action: onCompare) {
                pillLabel(L("Compare"), systemImage: "arrow.left.arrow.right")
            }
            .buttonStyle(.plain)
            .modifier(GlassPill(glass: glass, circle: false))

            NavigationLink(destination: AIAnalysisView(symbol: symbol, name: name)) {
                Image(systemName: "sparkles")
                    .font(.body.weight(.medium))
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .modifier(GlassPill(glass: glass, circle: true))
            .accessibilityLabel(L("Ask Orion"))
        } else {
            Spacer(minLength: 0)
        }
    }

    private func pillLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.subheadline.weight(.medium))
            .foregroundColor(AppTheme.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, AppTheme.Space.s)
    }

    private func toggleWatchlist() {
        let adding = !inWatchlist
        withAnimation(Motion.tap) { inWatchlist = adding }
        if adding {
            busy = true
            Task {
                do { try await FirebaseController.shared.addToWatchlist(symbol: symbol) }
                catch { withAnimation(Motion.tap) { inWatchlist = false } }
                busy = false
            }
        } else {
            FirebaseController.shared.removeStockFromWatchlist(symbol: symbol)
        }
    }
}

/// One capsule (or circle) of the action bar.
private struct GlassPill: ViewModifier {
    let glass: Bool
    let circle: Bool
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if glass, #available(iOS 26.0, *) {
            if circle {
                content.contentShape(Circle()).glassEffect(.regular.interactive(), in: Circle())
            } else {
                content.contentShape(Capsule()).glassEffect(.regular.interactive(), in: Capsule())
            }
        } else if circle {
            content
                .contentShape(Circle())
                .background(AdaptiveMaterialBackground(shape: Circle()))
                .overlay(Circle().strokeBorder(GlassEdge.gradient(colorScheme), lineWidth: 0.75))
        } else {
            content
                .contentShape(Capsule())
                .background(AdaptiveMaterialBackground(shape: Capsule()))
                .overlay(Capsule().strokeBorder(GlassEdge.gradient(colorScheme), lineWidth: 0.75))
        }
    }
}

extension View {
    /// Pins a floating bar to the bottom edge. iOS 26: `safeAreaBar`, so content scrolling beneath
    /// gets the system's soft edge fade. Earlier: a safe-area inset over a short fade to the page color.
    @ViewBuilder
    func bottomActionBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom, spacing: 0, content: bar)
        } else {
            safeAreaInset(edge: .bottom, spacing: 0) {
                bar().background(
                    LinearGradient(colors: [AppTheme.background.opacity(0), AppTheme.background],
                                   startPoint: .top, endPoint: .center)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }
}

// MARK: - Volume strip
/// Trading volume as a fine "barcode" under the price line: hairline bars on the same x-scale,
/// quiet gray so it never competes with the price. The scrubbed bar darkens with the marker.
/// Decorative — the chart's spoken summary carries the information.
private struct VolumeStrip: View {
    static let height: CGFloat = 28
    let entries: [ChartEntry]
    let lastIndex: Int
    let highlighted: Int?

    var body: some View {
        // Scale to the 90th percentile, clipping the rest: opening/closing auctions are often 10×
        // a normal bar and would otherwise flatten the whole strip into dots.
        let sorted = entries.map(\.volume).filter { $0 > 0 }.sorted()
        let cap = max(sorted.isEmpty ? 1 : sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.9))], 1)
        Chart(entries) { entry in
            BarMark(
                x: .value("Time", entry.index),
                yStart: .value("Zero", 0),
                yEnd: .value("Volume", min(entry.volume, cap)),
                width: .fixed(1.5)
            )
            .foregroundStyle(entry.index == highlighted ? AppTheme.primaryText : AppTheme.secondaryText.opacity(0.4))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXScale(domain: 0...lastIndex, range: .plotDimension)
        .chartYScale(domain: 0...cap)
        .frame(height: Self.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
