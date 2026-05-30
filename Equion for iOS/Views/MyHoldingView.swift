import SwiftUI
import Charts
import Observation

/// Fine-grained scroll state for the parallax chart.
/// Living in an @Observable (not @State on the view) means writing it during scroll
/// only re-renders the small chart layer that reads it — NOT the whole heavy body
/// (watchlist grid, cards, etc.), which is what caused the scroll jank.
@Observable
final class ChartParallax {
    var scrollOffset: CGFloat = 0
}

struct MyHoldingView: View {
    @State private var stockList: [StockInfo] = []
    @State private var marketIndices: [MarketIndex] = []
    @State private var showAddDialog = false
    @State private var showPortfolioWizard = false
    @State private var isLoading = false
    @State private var greetingSub = AppTheme.greetingSubtitle()
    @State private var recommendedStocks: [RecommendedStock] = []
    @State private var isLoadingRecommendations = false
    // Holdings — use @State snapshots instead of @ObservedObject to avoid cascade redraws
    @State private var holdingsSnapshot = HoldingsSnapshot()
    @State private var portfolioChartData: [PortfolioValueEntry] = []
    @State private var portfolioInterval = "1M"
    @State private var selectedPortfolioEntry: PortfolioValueEntry?
    @State private var showPortfolioMarker = false
    // Scroll-driven parallax state, isolated so scrolling doesn't re-render the whole body
    @State private var parallax = ChartParallax()
    // Width of chart area (for gesture → entry index calculation)
    @State private var chartAreaWidth: CGFloat = 0
    // Cached movers — only recomputed when stockList changes
    @State private var cachedGainers: [StockInfo] = []
    @State private var cachedLosers: [StockInfo] = []
    // Today's Market
    @State private var todayGainers: [MarketMover] = []
    @State private var todayLosers: [MarketMover] = []
    @State private var todayActive: [MarketMover] = []
    @State private var todayTab: TodayTab = .active
    @State private var isLoadingToday = false
    @ObservedObject private var interests = InterestsManager.shared

    enum TodayTab: String, CaseIterable {
        case active, gainers, losers
        var label: String {
            switch self {
            case .active:  return L("Hot")
            case .gainers: return L("Gainers")
            case .losers:  return L("Losers")
            }
        }
        var icon: String {
            switch self {
            case .active:  return "flame.fill"
            case .gainers: return "arrow.up.right"
            case .losers:  return "arrow.down.right"
            }
        }
    }
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    /// Wide layout: iPad OR iPhone landscape
    private var isWide: Bool { hSize == .regular || vSize == .compact }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    /// Adaptive grid: 2 columns on iPad/wide, single column on phone
    private var gridColumns: [GridItem] {
        if isWide {
            return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        }
        return [GridItem(.flexible())]
    }

    /// Height reserved for the portfolio chart background area
    private var portfolioChartHeight: CGFloat {
        holdingsSnapshot.hasHoldings ? 220 : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Market ticker bar
            MarketTickerView(indices: marketIndices)

            // Greeting header
            VStack(alignment: .leading, spacing: 6) {
                Text(AppTheme.greeting())
                    .font(AppTheme.serifTitle(26))
                    .foregroundColor(AppTheme.primaryText)

                HStack(spacing: 0) {
                    Text(greetingSub)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Text(dateFormatter.string(from: Date()))
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                }

                // Market closed reminder
                if let reason = AppTheme.marketClosedReason() {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.accent)
                        Text(reason)
                            .font(AppTheme.caption(12))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(AppTheme.accent.opacity(0.08))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Main content area — chart pinned behind, cards scroll over it
            ZStack(alignment: .top) {
                // Background layer: portfolio chart (stays in place, sinks & blurs on scroll).
                // The parallax math lives inside ParallaxChartLayer (which reads parallax.scrollOffset),
                // so this body doesn't depend on scroll position and won't re-render while scrolling.
                if holdingsSnapshot.hasHoldings {
                    ParallaxChartLayer(parallax: parallax, chartHeight: portfolioChartHeight) {
                        portfolioChartBackground
                    }
                    .zIndex(0)
                }

                // Foreground layer: scrollable cards
                scrollContent
                    .zIndex(1)
            }
        }
        .background(AppTheme.background)
        .overlay(alignment: .bottomTrailing) {
            // Floating add button
            Button(action: { Haptic.tap(); showAddDialog = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(AppTheme.accent)
                            .shadow(color: AppTheme.accent.opacity(0.35), radius: 12, y: 6)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showPortfolioWizard) {
            PortfolioWizardView()
        }
        .sheet(isPresented: $showAddDialog) {
            AddAssetSheet(
                existingSymbols: Set(stockList.map { $0.symbol.uppercased() }),
                onAdd: { symbol in
                    showAddDialog = false
                    Task { await fetchAndAddStock(symbol: symbol) }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await loadAll()
        }
    }

    // MARK: - Scroll Content (foreground layer)
    @ViewBuilder
    /// Wraps content in a ScrollView with scroll-offset tracking for parallax
    private func trackedScrollView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Chart area spacer — transparent gap so chart shows through; handles chart touch
                chartTouchSpacer

                content()
            }
            .padding(.top, 4)
            .padding(.bottom, 80)
        }
        // iOS 18 first-class scroll observation — fires reliably on every scroll.
        // contentOffset.y + contentInsets.top == 0 at rest, grows positive scrolling up.
        // Rounded to whole points to cut sub-pixel update churn. Writes the @Observable
        // (not view @State), so only the chart layer re-renders — the body stays put.
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            (geo.contentOffset.y + geo.contentInsets.top).rounded()
        } action: { _, newValue in
            parallax.scrollOffset = max(0, newValue)
        }
    }

    /// Transparent spacer occupying the chart area; captures horizontal drag for chart scrubbing.
    private var chartTouchSpacer: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .onAppear { chartAreaWidth = geo.size.width }
                .onChange(of: geo.size.width) { _, newVal in chartAreaWidth = newVal }
                // Simultaneous + horizontal-dominance gate: lets vertical drags scroll
                // the list (so the parallax blur still works) while horizontal drags scrub.
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { val in
                            guard abs(val.translation.width) > abs(val.translation.height) else { return }
                            let entries = portfolioChartData
                            let width = geo.size.width
                            guard !entries.isEmpty, width > 0 else { return }
                            let ratio = max(0, min(1, val.location.x / width))
                            let idx = Int(round(ratio * Double(entries.count - 1)))
                            let clamped = max(0, min(entries.count - 1, idx))
                            let previous = selectedPortfolioEntry
                            withAnimation(.easeInOut(duration: 0.05)) {
                                selectedPortfolioEntry = entries[clamped]
                                showPortfolioMarker = true
                            }
                            if selectedPortfolioEntry?.index != previous?.index {
                                Haptic.selection()
                            }
                        }
                        .onEnded { _ in
                            guard showPortfolioMarker else { return }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showPortfolioMarker = false
                                selectedPortfolioEntry = nil
                            }
                            Haptic.soft()
                        }
                )
        }
        .frame(height: portfolioChartHeight)
    }

    @ViewBuilder
    private var scrollContent: some View {
        if isLoading && stockList.isEmpty {
            trackedScrollView {
                todayMarketCard
                SkeletonWatchlist()
                    .padding(.top, 4)
            }
        } else if stockList.isEmpty {
            trackedScrollView {
                portfolioHoldingsListCard
                todayMarketCard
                myMoversCard

                emptyStateView
                    .padding(.top, 12)

                if !interests.selectedInterests.isEmpty {
                    recommendationsSection
                }
            }
            .refreshable { await loadAll() }
        } else {
            trackedScrollView {
                portfolioHoldingsListCard
                todayMarketCard
                myMoversCard

                // Section label
                SectionLabel(title: L("Watchlist"), count: stockList.count)
                    .padding(.top, 4)

                // Watchlist
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(Array(stockList.enumerated()), id: \.element.id) { index, stock in
                        NavigationLink(destination: StockDetailView(symbol: stock.symbol, name: stock.name)) {
                            StockRowView(stock: stock)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                            } label: {
                                Label(L("View Details"), systemImage: "chart.xyaxis.line")
                            }

                            if index > 0 {
                                Button {
                                    Haptic.light()
                                    withAnimation {
                                        let item = stockList.remove(at: index)
                                        stockList.insert(item, at: 0)
                                    }
                                } label: {
                                    Label(L("Move to Top"), systemImage: "arrow.up.to.line")
                                }
                            }

                            Button {
                                let text = "\(stock.symbol) - \(stock.name): $\(String(format: "%.2f", stock.price)) (\(AppTheme.formattedChange(stock.changePercent)))"
                                UIPasteboard.general.string = text
                                Haptic.tap()
                            } label: {
                                Label(L("Copy Info"), systemImage: "doc.on.doc")
                            }

                            ShareLink(item: "\(stock.symbol) - \(stock.name)\n$\(String(format: "%.2f", stock.price)) (\(AppTheme.formattedChange(stock.changePercent)))") {
                                Label(L("Share"), systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                Haptic.warning()
                                deleteStock(at: IndexSet(integer: index))
                            } label: {
                                Label(L("Remove from Watchlist"), systemImage: "trash")
                            }
                        } preview: {
                            StockContextPreview(stock: stock)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if !interests.selectedInterests.isEmpty {
                    recommendationsSection
                        .padding(.top, 8)
                }
            }
            .refreshable { await loadAll() }
        }
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Orion constellation illustration
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.accent.opacity(0.08), AppTheme.accent.opacity(0.0)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Constellation dots
                ConstellationView()
                    .frame(width: 120, height: 120)

                // Center star
                Image(systemName: "sparkle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(AppTheme.accent)
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 8)
            }

            VStack(spacing: 8) {
                Text(L("Your watchlist is empty"))
                    .font(AppTheme.serifHeadline(20))
                    .foregroundColor(AppTheme.primaryText)
                Text(L("Start building your constellation of investments"))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: { Haptic.tap(); showAddDialog = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L("Add Stock"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Capsule().fill(AppTheme.accent))
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, y: 4)
            }

            Button(action: { Haptic.tap(); showPortfolioWizard = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L("Help Me Pick Stocks"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(AppTheme.accent)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(AppTheme.accent, lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Load All
    private func loadAll() async {
        async let m: () = loadMarketData()
        async let w: () = loadWatchlist()
        async let r: () = loadRecommendations()
        async let t: () = loadTodayMarket()
        async let h: () = loadHoldings()
        _ = await (m, w, r, t, h)
    }

    private func loadHoldings() async {
        let mgr = HoldingsManager.shared
        await mgr.loadAll()
        await mgr.loadPortfolioChart(range: portfolioInterval)
        // Copy to @State — single update, no @ObservedObject cascade
        holdingsSnapshot = mgr.snapshot
        portfolioChartData = mgr.portfolioChart
    }

    // MARK: - Actions
    private func loadMarketData() async {
        let symbols = [("SPY", "S&P 500"), ("QQQ", "NASDAQ"), ("DIA", "Dow Jones")]
        // Load all 3 indices concurrently — don't let one slow request block the others
        let indices: [MarketIndex] = await withTaskGroup(of: MarketIndex?.self, returning: [MarketIndex].self) { group in
            for (sym, name) in symbols {
                group.addTask {
                    try? await APIService.shared.fetchMarketIndex(symbol: sym, name: name)
                }
            }
            var results: [MarketIndex] = []
            for await index in group {
                if let index { results.append(index) }
            }
            // Preserve original order: SPY, QQQ, DIA
            return symbols.compactMap { pair in
                results.first { $0.name == pair.1 }
            }
        }
        await MainActor.run { marketIndices = indices }
    }

    private func loadWatchlist() async {
        isLoading = true
        let symbols = await FirebaseController.shared.getWatchlistSymbols()

        // Deduplicate
        var seen = Set<String>()
        let uniqueSymbols = symbols.filter { seen.insert($0.uppercased()).inserted }

        // Load all stocks concurrently with TaskGroup
        // Optimization: fetchChartAndQuote = 1 Yahoo call (chart + price)
        //               fetchCompanyProfile = cached 24h (usually 0 calls after first load)
        // Total: ~1 API call per stock instead of 3
        let loaded: [StockInfo] = await withTaskGroup(of: StockInfo?.self, returning: [StockInfo].self) { group in
            for symbol in uniqueSymbols {
                group.addTask {
                    for attempt in 0..<2 {
                        do {
                            if attempt > 0 {
                                try await Task.sleep(nanoseconds: 500_000_000)
                            }
                            // One Yahoo call: chart data + price + previousClose
                            async let chartQuote = APIService.shared.fetchChartAndQuote(symbol: symbol)
                            // Finnhub profile (24h cache — usually instant after first load)
                            async let profile = APIService.shared.fetchCompanyProfile(symbol: symbol)

                            let (cq, prof) = try await (chartQuote, profile)
                            let changePercent = cq.previousClose != 0
                                ? ((cq.price - cq.previousClose) / cq.previousClose) * 100.0
                                : 0
                            return StockInfo(
                                symbol: symbol,
                                name: prof.name,
                                price: cq.price,
                                changePercent: changePercent,
                                chartData: cq.chartData,
                                logoURL: prof.logoURL
                            )
                        } catch {
                            print("[Watchlist] Failed to load \(symbol) (attempt \(attempt + 1)): \(error.localizedDescription)")
                            continue
                        }
                    }
                    return nil
                }
            }

            var results: [StockInfo] = []
            for await stock in group {
                if let stock = stock {
                    results.append(stock)
                }
            }
            return uniqueSymbols.compactMap { sym in
                results.first { $0.symbol.uppercased() == sym.uppercased() }
            }
        }

        await MainActor.run {
            stockList = loaded
            isLoading = false
            updateCachedMovers()
        }
    }

    private func fetchAndAddStock(symbol: String) async {
        guard !stockList.contains(where: { $0.symbol.uppercased() == symbol.uppercased() }) else { return }
        do {
            async let chartQuote = APIService.shared.fetchChartAndQuote(symbol: symbol)
            async let profile = APIService.shared.fetchCompanyProfile(symbol: symbol)
            let (cq, prof) = try await (chartQuote, profile)
            let changePercent = cq.previousClose != 0
                ? ((cq.price - cq.previousClose) / cq.previousClose) * 100.0
                : 0
            let stock = StockInfo(symbol: symbol, name: prof.name, price: cq.price, changePercent: changePercent, chartData: cq.chartData, logoURL: prof.logoURL)
            await MainActor.run {
                stockList.append(stock)
                Haptic.success()
            }
            FirebaseController.shared.addStockToWatchlist(symbol: symbol)
        } catch {
            await MainActor.run { Haptic.error() }
            print("[Add] Failed to add \(symbol): \(error.localizedDescription)")
        }
    }

    private func deleteStock(at offsets: IndexSet) {
        for index in offsets {
            let symbol = stockList[index].symbol
            FirebaseController.shared.removeStockFromWatchlist(symbol: symbol)
        }
        stockList.remove(atOffsets: offsets)
        Haptic.tap()
    }

    private func moveStock(from source: IndexSet, to destination: Int) {
        stockList.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Today's Market Data
    private func loadTodayMarket() async {
        await MainActor.run { isLoadingToday = true }

        // Load all 3 in parallel via TaskGroup
        let results = await withTaskGroup(of: (String, [MarketMover]).self, returning: [String: [MarketMover]].self) { group in
            for scrId in ["day_gainers", "day_losers", "most_actives"] {
                group.addTask {
                    let movers = (try? await APIService.shared.fetchMarketMovers(scrId: scrId, count: 6)) ?? []
                    return (scrId, movers)
                }
            }
            var dict: [String: [MarketMover]] = [:]
            for await (key, movers) in group {
                dict[key] = movers
            }
            return dict
        }

        await MainActor.run {
            todayGainers = results["day_gainers"] ?? []
            todayLosers = results["day_losers"] ?? []
            todayActive = results["most_actives"] ?? []
            isLoadingToday = false
        }
    }

    /// Cache watchlist movers (called only when stockList changes)
    private func updateCachedMovers() {
        guard stockList.count >= 2 else {
            cachedGainers = []
            cachedLosers = []
            return
        }
        let sorted = stockList.sorted { $0.changePercent > $1.changePercent }
        cachedGainers = Array(sorted.prefix(3))
        cachedLosers = Array(sorted.suffix(3).reversed())
    }

    // MARK: - Portfolio Chart Background (pinned behind scroll)
    private var portfolioChartBackground: some View {
        VStack(spacing: 0) {
            // Value & P&L header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("My Portfolio"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)

                    // Show touched value or total value
                    if let sel = selectedPortfolioEntry, showPortfolioMarker {
                        // During touch: show market value at that point
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("$")
                                .font(AppTheme.number(16, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                            Text(String(format: "%.2f", sel.value))
                                .font(AppTheme.number(24, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.05), value: sel.value)
                        }

                        // Date + cost basis + change
                        let selPnL = sel.value - sel.costBasis
                        let selPnLPct = sel.costBasis > 0 ? (selPnL / sel.costBasis) * 100 : 0

                        Text(sel.datetime)
                            .font(AppTheme.caption(11))
                            .foregroundColor(AppTheme.secondaryText)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.05), value: sel.datetime)

                        HStack(spacing: 8) {
                            Text(String(format: "%@ $%.2f",
                                        L("Cost"),
                                        sel.costBasis))
                                .font(AppTheme.number(11, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)

                            Text(String(format: "%@$%.2f (%@%.2f%%)",
                                        selPnL >= 0 ? "+" : "-", abs(selPnL),
                                        selPnLPct >= 0 ? "+" : "", selPnLPct))
                                .font(AppTheme.number(11, weight: .semibold))
                                .foregroundColor(selPnL >= 0 ? AppTheme.positive : AppTheme.negative)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.05), value: selPnL)
                        }
                    } else {
                        // Default: show current total
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("$")
                                .font(AppTheme.number(16, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                            Text(String(format: "%.2f", holdingsSnapshot.totalValue))
                                .font(AppTheme.number(24, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)
                                .contentTransition(.numericText())
                        }

                        HStack(spacing: 8) {
                            Text(String(format: "%@$%.2f (%@%.2f%%)",
                                        holdingsSnapshot.totalPnL >= 0 ? "+" : "-", abs(holdingsSnapshot.totalPnL),
                                        holdingsSnapshot.totalPnLPercent >= 0 ? "+" : "", holdingsSnapshot.totalPnLPercent))
                                .font(AppTheme.number(12, weight: .semibold))
                                .foregroundColor(holdingsSnapshot.totalPnL >= 0 ? AppTheme.positive : AppTheme.negative)

                            Text("·")
                                .foregroundColor(AppTheme.secondaryText.opacity(0.5))

                            Text(String(format: "%@ %@$%.2f",
                                        L("Today"),
                                        holdingsSnapshot.totalDayPnL >= 0 ? "+" : "-",
                                        abs(holdingsSnapshot.totalDayPnL)))
                                .font(AppTheme.number(11, weight: .medium))
                                .foregroundColor(holdingsSnapshot.totalDayPnL >= 0 ? AppTheme.positive : AppTheme.negative)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            // Edge-to-edge chart — isolated view, won't re-render on scroll
            if !portfolioChartData.isEmpty {
                PortfolioChartView(
                    entries: portfolioChartData,
                    selectedEntry: $selectedPortfolioEntry,
                    showMarker: $showPortfolioMarker
                )
                .frame(height: 110)

                // Interval selector
                HStack(spacing: 4) {
                    ForEach(["1D", "5D", "1M", "6M", "1Y"], id: \.self) { interval in
                        Button {
                            portfolioInterval = interval
                            Task {
                                await HoldingsManager.shared.loadPortfolioChart(range: interval)
                                portfolioChartData = HoldingsManager.shared.portfolioChart
                            }
                        } label: {
                            Text(interval)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(portfolioInterval == interval ? .white : AppTheme.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    portfolioInterval == interval
                                        ? AnyShapeStyle(AppTheme.accent)
                                        : AnyShapeStyle(AppTheme.subtleFill)
                                )
                                .cornerRadius(6)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Portfolio Holdings List Card (scrollable)
    @ViewBuilder
    private var portfolioHoldingsListCard: some View {
        if holdingsSnapshot.hasHoldings {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    AccentSectionTitle(L("Holdings"), icon: "briefcase.fill")
                    Spacer()
                    Text(String(format: "%d %@", holdingsSnapshot.aggregated.count, L("positions")))
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText)
                }

                ForEach(holdingsSnapshot.aggregated, id: \.symbol) { holding in
                    NavigationLink(destination: StockDetailView(symbol: holding.symbol, name: holding.name)) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(holding.symbol)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(String(format: "%.4g %@", holding.totalShares, L("shares")))
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.secondaryText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "$%.2f", holding.marketValue))
                                    .font(AppTheme.number(13, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(String(format: "%@%.2f%%", holding.totalPnLPercent >= 0 ? "+" : "", holding.totalPnLPercent))
                                    .font(AppTheme.number(11, weight: .medium))
                                    .foregroundColor(holding.totalPnLPercent >= 0 ? AppTheme.positive : AppTheme.negative)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .themeCardSurface()
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Today's Market Card
    @ViewBuilder
    private var todayMarketCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 0) {
                AccentSectionTitle(L("Today's Market"), icon: "chart.bar.xaxis")
                Spacer()
                if isLoadingToday {
                    ProgressView().scaleEffect(0.6)
                }
            }

            // Tab pills
            HStack(spacing: 6) {
                ForEach([TodayTab.active, .gainers, .losers], id: \.self) { tab in
                    Button {
                        Haptic.light()
                        withAnimation(.easeInOut(duration: 0.2)) { todayTab = tab }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 9))
                            Text(tab.label)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(todayTab == tab ? .white : AppTheme.secondaryText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(todayTab == tab ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(.ultraThinMaterial))
                        )
                    }
                }
                Spacer()
            }

            // Scrollable movers with fade edge
            let movers: [MarketMover] = {
                switch todayTab {
                case .active:  return todayActive
                case .gainers: return todayGainers
                case .losers:  return todayLosers
                }
            }()

            if movers.isEmpty && !isLoadingToday {
                Text(L("No data available"))
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            } else {
                // Horizontal scroll with right-edge fade hint
                ZStack(alignment: .trailing) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(movers) { mover in
                                NavigationLink(destination: StockDetailView(symbol: mover.symbol, name: mover.name)) {
                                    MoverChip(symbol: mover.symbol, name: mover.name, price: mover.price, changePercent: mover.changePercent)
                                }
                                .buttonStyle(.plain)
                            }
                            // Trailing spacer so last chip isn't under fade
                            Spacer().frame(width: 28)
                        }
                    }
                    // Fade gradient on right edge — visual hint for "swipe for more"
                    LinearGradient(
                        colors: [AppTheme.cardBackground.opacity(0), AppTheme.cardBackground],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 36)
                    .allowsHitTesting(false)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .themeCardSurface()
        .padding(.horizontal, 16)
    }

    // MARK: - My Movers Card (separate module)
    @ViewBuilder
    private var myMoversCard: some View {
        if stockList.count >= 2 && (!cachedGainers.isEmpty || !cachedLosers.isEmpty) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 0) {
                    AccentSectionTitle(L("My Movers"), icon: "star.fill")
                    Spacer()
                    Text(L("Today"))
                        .font(AppTheme.caption(10))
                        .foregroundColor(AppTheme.secondaryText)
                }

                // Two rows: top gainers / top losers
                HStack(spacing: 0) {
                    // Gainers column
                    if !cachedGainers.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.positive)
                                Text(L("Gainers"))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.positive)
                            }
                            ForEach(cachedGainers) { stock in
                                NavigationLink(destination: StockDetailView(symbol: stock.symbol, name: stock.name)) {
                                    myMoverRow(symbol: stock.symbol, name: stock.name, changePercent: stock.changePercent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Vertical divider
                    if !cachedGainers.isEmpty && !cachedLosers.isEmpty {
                        Rectangle()
                            .fill(AppTheme.border)
                            .frame(width: 0.5)
                            .padding(.vertical, 2)
                    }

                    // Losers column
                    if !cachedLosers.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.negative)
                                Text(L("Losers"))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.negative)
                            }
                            ForEach(cachedLosers) { stock in
                                NavigationLink(destination: StockDetailView(symbol: stock.symbol, name: stock.name)) {
                                    myMoverRow(symbol: stock.symbol, name: stock.name, changePercent: stock.changePercent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .themeCardSurface()
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func myMoverRow(symbol: String, name: String, changePercent: Double) -> some View {
        HStack(spacing: 6) {
            Text(symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(1)
            Spacer()
            ChangeBadge(value: changePercent, showBackground: false, size: .compact)
                .animation(.easeInOut(duration: 0.3), value: changePercent)
        }
        .padding(.vertical, 1)
    }

    // MARK: - Recommendations
    private func loadRecommendations() async {
        guard !interests.selectedInterests.isEmpty else { return }
        isLoadingRecommendations = true

        let existingSymbols = Set(stockList.map { $0.symbol.uppercased() })
        let candidates = interests.recommendedSymbols(excluding: existingSymbols)
        // Load top 8 recommendations with live prices
        let top = Array(candidates.prefix(8))

        let loaded: [RecommendedStock] = await withTaskGroup(of: RecommendedStock?.self, returning: [RecommendedStock].self) { group in
            for item in top {
                group.addTask {
                    do {
                        let cq = try await APIService.shared.fetchChartAndQuote(symbol: item.symbol)
                        let changePercent = cq.previousClose != 0
                            ? ((cq.price - cq.previousClose) / cq.previousClose) * 100.0
                            : 0
                        let catName = InterestCategory.all.first { $0.id == item.categoryId }?.name ?? ""
                        return RecommendedStock(
                            symbol: item.symbol,
                            name: item.name,
                            price: cq.price,
                            changePercent: changePercent,
                            chartData: cq.chartData,
                            categoryId: item.categoryId,
                            categoryName: catName
                        )
                    } catch {
                        return nil
                    }
                }
            }
            var results: [RecommendedStock] = []
            for await stock in group {
                if let stock { results.append(stock) }
            }
            // Preserve order
            return top.compactMap { item in
                results.first { $0.symbol.uppercased() == item.symbol.uppercased() }
            }
        }

        await MainActor.run {
            recommendedStocks = loaded
            isLoadingRecommendations = false
        }
    }

    // MARK: - Recommendations Section
    @ViewBuilder
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    AccentSectionTitle(L("Recommended for You"), icon: "sparkles")
                    Text(L("Based on your interests"))
                        .font(AppTheme.caption(12))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.leading, 11) // align with title text after accent bar
                }
                Spacer()
                if isLoadingRecommendations {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 20)

            // Horizontal scroll of recommendation cards
            if recommendedStocks.isEmpty && !isLoadingRecommendations {
                // Empty — no recommendations loaded
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recommendedStocks) { stock in
                            NavigationLink(destination: StockDetailView(symbol: stock.symbol, name: stock.name)) {
                                RecommendationCard(stock: stock, onAdd: {
                                    Task { await fetchAndAddStock(symbol: stock.symbol) }
                                })
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Parallax Chart Layer
/// Applies the scroll-driven sink + blur to the pinned chart. This is the ONLY view that
/// reads `parallax.scrollOffset`, so scrolling re-renders just this thin wrapper (cheap
/// modifier updates on an already-built chart) instead of the whole holdings screen.
struct ParallaxChartLayer<Content: View>: View {
    var parallax: ChartParallax
    var chartHeight: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        // Blur holds off until cards have covered ~1/3 of the chart, then ramps in gently.
        let threshold = chartHeight / 3
        let ramp = max(chartHeight * 0.45, 1)
        let progress = min(max((parallax.scrollOffset - threshold) / ramp, 0), 1)

        content
            .offset(y: progress * 20)              // gentle sink
            .blur(radius: progress * 6)            // soft blur — stays readable, never opaque
            .opacity(1.0 - progress * 0.3)         // fades only to 0.7
            .scaleEffect(1.0 - progress * 0.03, anchor: .top)
            .allowsHitTesting(false)               // gestures go to the scroll spacer
    }
}

// MARK: - Portfolio Chart View (isolated to prevent scroll-triggered re-renders)
struct PortfolioChartView: View {
    let entries: [PortfolioValueEntry]
    @Binding var selectedEntry: PortfolioValueEntry?
    @Binding var showMarker: Bool

    var body: some View {
        let allValues = entries.map(\.value) + entries.map(\.costBasis)
        let minY = allValues.min() ?? 0
        let maxY = allValues.max() ?? 0
        let pad = max((maxY - minY) * 0.1, 1)
        let chartChange = (entries.last?.value ?? 0) - (entries.first?.value ?? 0)
        let chartColor = chartChange >= 0 ? AppTheme.positive : AppTheme.negative

        Chart {
            // Portfolio value area + line
            ForEach(entries) { entry in
                AreaMark(
                    x: .value("X", entry.index),
                    yStart: .value("Min", minY - pad),
                    yEnd: .value("Value", entry.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [chartColor.opacity(0.15), chartColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("X", entry.index),
                    y: .value("Value", entry.value),
                    series: .value("Series", "value")
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }

            // Cost basis — light gray dashed line (own series so it doesn't connect to value line)
            ForEach(entries) { entry in
                LineMark(
                    x: .value("X", entry.index),
                    y: .value("Cost", entry.costBasis),
                    series: .value("Series", "cost")
                )
                .foregroundStyle(Color.gray.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }

            // Touch indicator: vertical rule + points
            if let entry = selectedEntry, showMarker {
                RuleMark(x: .value("X", entry.index))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))

                PointMark(x: .value("X", entry.index), y: .value("Value", entry.value))
                    .foregroundStyle(chartColor)
                    .symbolSize(50)

                PointMark(x: .value("X", entry.index), y: .value("Cost", entry.costBasis))
                    .foregroundStyle(Color.gray.opacity(0.4))
                    .symbolSize(30)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (minY - pad)...(maxY + pad))
        .chartLegend(.hidden)
        .chartXScale(range: .plotDimension)
        // No gesture here — gesture lives on the scroll spacer overlay
    }
}

// MARK: - Market Ticker View
struct MarketTickerView: View {
    let indices: [MarketIndex]

    @State private var offset: CGFloat = 0
    @State private var itemsWidth: CGFloat = 0

    private let speed: CGFloat = 40

    var body: some View {
        GeometryReader { geo in
            let repeats = max(3, Int(ceil(geo.size.width * 3 / max(itemsWidth, 1))) + 1)

            ZStack(alignment: .leading) {
                HStack(spacing: 32) {
                    ForEach(0..<repeats, id: \.self) { _ in
                        ForEach(indices) { index in
                            tickerLabel(index)
                        }
                    }
                }
                .fixedSize()
                .background(
                    GeometryReader { inner in
                        Color.clear.onAppear {
                            itemsWidth = inner.size.width / CGFloat(repeats)
                        }
                    }
                )
                .offset(x: -offset)
            }
            .frame(width: geo.size.width, alignment: .leading)
            .clipped()
        }
        .frame(height: 36)
        .background(.ultraThinMaterial)
        .onChange(of: indices.count) { _, newCount in
            if newCount > 0 {
                // Wait for layout to compute itemsWidth
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startScrolling()
                }
            }
        }
        .onAppear {
            if !indices.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startScrolling()
                }
            }
        }
    }

    @ViewBuilder
    private func tickerLabel(_ index: MarketIndex) -> some View {
        HStack(spacing: 6) {
            Text(index.name)
                .foregroundColor(AppTheme.secondaryText)
                .font(.system(size: 12, weight: .medium))
            Text(String(format: "%.2f", index.price))
                .foregroundColor(AppTheme.primaryText)
                .font(AppTheme.number(12))
            ChangeBadge(value: index.changePercent, showBackground: false, size: .compact)
        }
    }

    private func startScrolling() {
        guard itemsWidth > 0, !indices.isEmpty else { return }
        offset = 0
        let duration = Double(itemsWidth) / Double(speed)
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = itemsWidth
        }
    }
}

// MARK: - Stock Row View (Card Style)
struct StockRowView: View {
    let stock: StockInfo
    private var assetType: AssetType { AssetMeta.assetType(for: stock.symbol) }

    var body: some View {
        HStack(spacing: 12) {
            // Asset icon with ring border
            if let logoURL = stock.logoURL, !logoURL.isEmpty, assetType == .stock {
                AsyncImage(url: URL(string: logoURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    default:
                        assetIcon
                    }
                }
            } else {
                assetIcon
            }

            // Symbol & Name
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(displaySymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    if assetType != .stock {
                        Text(assetType.label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(assetTypeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(assetTypeColor.opacity(0.12)))
                    }
                }
                Text(stock.name)
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Mini chart
            if !stock.chartData.isEmpty {
                let minY = stock.chartData.map(\.close).min() ?? 0
                let maxY = stock.chartData.map(\.close).max() ?? 0
                let pad = (maxY - minY) * 0.1
                let chartColor = stock.changePercent >= 0 ? AppTheme.positive : AppTheme.negative

                Chart(stock.chartData) { entry in
                    AreaMark(
                        x: .value("X", entry.index),
                        yStart: .value("Min", Double(minY - pad)),
                        yEnd: .value("Price", Double(entry.close))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.2), chartColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("X", entry.index),
                        y: .value("Price", Double(entry.close))
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: Double(minY - pad)...Double(maxY + pad))
                .chartLegend(.hidden)
                .frame(width: 64, height: 36)
            }

            // Price & Change
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(priceCurrencySymbol)
                        .font(AppTheme.number(11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(priceNumber)
                        .font(AppTheme.number(15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: priceNumber)
                }
                ChangeBadge(value: stock.changePercent, size: .compact)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: stock.changePercent)
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .themeCardSurface()
    }

    // MARK: - Helpers

    private var assetIcon: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(assetTypeColor.opacity(0.1))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: assetType.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(assetTypeColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(assetTypeColor.opacity(0.3), lineWidth: 1)
            )
    }

    /// Display-friendly symbol
    /// Crypto: BTC-USD → BTC, Futures: GC=F → GC, Forex: CADCNY=X → CAD/CNY
    private var displaySymbol: String {
        let s = stock.symbol
        if assetType == .forex, let pair = AssetMeta.forexPair(from: s) {
            return "\(pair.from)/\(pair.to)"
        }
        if s.hasSuffix("-USD") { return String(s.dropLast(4)) }
        if s.hasSuffix("=F") { return String(s.dropLast(2)) }
        if s.hasSuffix("=X") { return String(s.dropLast(2)) }
        return s
    }

    /// Currency symbol part for split display
    private var priceCurrencySymbol: String {
        if assetType == .forex {
            if let pair = AssetMeta.forexPair(from: stock.symbol) {
                return AssetMeta.currencySymbols[pair.to] ?? ""
            }
            return ""
        }
        return "$"
    }

    /// Number part for split display
    private var priceNumber: String {
        if assetType == .forex {
            return stock.price >= 100
                ? String(format: "%.2f", stock.price)
                : String(format: "%.4f", stock.price)
        }
        return String(format: "%.2f", stock.price)
    }

    /// Full price text (for contexts that need it)
    private var priceText: String {
        "\(priceCurrencySymbol)\(priceNumber)"
    }

    private var assetTypeColor: Color {
        switch assetType {
        case .stock:     return AppTheme.accent
        case .crypto:    return Color.orange
        case .forex:     return Color.blue
        case .metal:     return Color(red: 0.85, green: 0.75, blue: 0.40)
        case .commodity: return Color(red: 0.55, green: 0.75, blue: 0.55)
        }
    }
}

// MARK: - Add Asset Sheet
struct AddAssetSheet: View {
    let existingSymbols: Set<String>
    let onAdd: (String) -> Void

    @State private var searchText = ""
    @State private var selectedTab: AssetType = .stock
    @State private var isAdding = false
    @Environment(\.dismiss) private var dismiss
    @Namespace private var tabAnimation

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryTab(.stock, icon: "building.2")
                        categoryTab(.crypto, icon: "bitcoinsign.circle")
                        categoryTab(.forex, icon: "arrow.left.arrow.right")
                        categoryTab(.metal, icon: "diamond")
                        categoryTab(.commodity, icon: "drop.halffull")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.secondaryText)
                    TextField(searchPlaceholder, text: $searchText)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.subtleFill)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Custom manual entry button (when search has text)
                if !searchText.isEmpty {
                    let sym = searchText.trimmingCharacters(in: .whitespaces).uppercased()
                    if !sym.isEmpty && !existingSymbols.contains(sym) {
                        Button(action: { addSymbol(sym) }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.accent)
                                Text(L("Add") + " \"\(sym)\"")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Popular assets list
                ScrollView {
                    LazyVStack(spacing: 6) {
                        Text(L("Popular"))
                            .font(AppTheme.caption(12))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        ForEach(filteredAssets, id: \.symbol) { asset in
                            let alreadyAdded = existingSymbols.contains(asset.symbol.uppercased())
                            Button(action: {
                                if !alreadyAdded { addSymbol(asset.symbol) }
                            }) {
                                HStack(spacing: 12) {
                                    // Icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(iconColor(for: asset.type).opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: asset.type.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(iconColor(for: asset.type))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(asset.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(asset.symbol)
                                            .font(AppTheme.caption(12))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }

                                    Spacer()

                                    if alreadyAdded {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.positive)
                                    } else {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(AppTheme.accent)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            .disabled(alreadyAdded)
                            .opacity(alreadyAdded ? 0.5 : 1)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .background(AppTheme.background)
            .navigationTitle(L("Add Asset"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }

    // MARK: - Helpers

    private var searchPlaceholder: String {
        switch selectedTab {
        case .stock:     return L("Search stocks") + "  (AAPL, MSFT...)"
        case .crypto:    return L("Search crypto") + "  (BTC, ETH...)"
        case .forex:     return L("Search forex") + "  (CADCNY=X...)"
        case .metal:     return L("Search metals") + "  (GC=F, SI=F...)"
        case .commodity: return L("Search commodities")
        }
    }

    private var filteredAssets: [AssetMeta] {
        let assets: [AssetMeta]
        switch selectedTab {
        case .stock:     assets = AssetMeta.popularStocks
        case .crypto:    assets = AssetMeta.popularCrypto
        case .forex:     assets = AssetMeta.popularForex
        case .metal:     assets = AssetMeta.popularMetals
        case .commodity: assets = AssetMeta.popularCommodities
        }

        if searchText.isEmpty { return assets }
        let q = searchText.lowercased()
        return assets.filter {
            $0.symbol.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    private func addSymbol(_ symbol: String) {
        guard !isAdding else { return }
        isAdding = true
        onAdd(symbol)
    }

    private func categoryTab(_ type: AssetType, icon: String) -> some View {
        Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selectedTab = type } }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(type.label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(selectedTab == type ? .white : AppTheme.primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if selectedTab == type {
                        Capsule()
                            .fill(AppTheme.accent)
                            .matchedGeometryEffect(id: "categoryTab", in: tabAnimation)
                    } else {
                        Capsule().fill(AppTheme.subtleFill)
                    }
                }
            )
        }
    }

    private func iconColor(for type: AssetType) -> Color {
        switch type {
        case .stock:     return AppTheme.accent
        case .crypto:    return .orange
        case .forex:     return .blue
        case .metal:     return Color(red: 0.85, green: 0.75, blue: 0.40)
        case .commodity: return Color(red: 0.55, green: 0.75, blue: 0.55)
        }
    }
}

// MARK: - Mover Chip (compact card for today's movers)
struct MoverChip: View {
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double

    private var isPositive: Bool { changePercent >= 0 }
    private var changeColor: Color { isPositive ? AppTheme.positive : AppTheme.negative }

    var body: some View {
        HStack(spacing: 8) {
            // Symbol & name
            VStack(alignment: .leading, spacing: 1) {
                Text(symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                Text(name)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            .frame(minWidth: 50, alignment: .leading)

            // Change badge
            ChangeBadge(value: changePercent, size: .compact)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: changePercent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
        .shadow(color: AppTheme.primaryText.opacity(0.03), radius: 4, y: 2)
    }
}

// MARK: - Recommended Stock Model
struct RecommendedStock: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double
    let chartData: [ChartEntry]
    let categoryId: String
    let categoryName: String
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let stock: RecommendedStock
    let onAdd: () -> Void
    private var assetType: AssetType { AssetMeta.assetType(for: stock.symbol) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top: category badge
            HStack {
                Text(L(stock.categoryName))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppTheme.accent.opacity(0.1)))
                Spacer()
                // Add button
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.accent)
                }
            }

            // Symbol & Name
            VStack(alignment: .leading, spacing: 2) {
                Text(displaySymbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                Text(stock.name)
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            // Mini chart
            if !stock.chartData.isEmpty {
                let minY = stock.chartData.map(\.close).min() ?? 0
                let maxY = stock.chartData.map(\.close).max() ?? 0
                let pad = (maxY - minY) * 0.1
                let chartColor = stock.changePercent >= 0 ? AppTheme.positive : AppTheme.negative

                Chart(stock.chartData) { entry in
                    AreaMark(
                        x: .value("X", entry.index),
                        yStart: .value("Min", Double(minY - pad)),
                        yEnd: .value("Price", Double(entry.close))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.25), chartColor.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("X", entry.index),
                        y: .value("Price", Double(entry.close))
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: Double(minY - pad)...Double(maxY + pad))
                .chartLegend(.hidden)
                .frame(height: 40)
            }

            // Price & Change
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(priceCurrencySymbol)
                        .font(AppTheme.number(10, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(priceNumber)
                        .font(AppTheme.number(14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
                Spacer()
                ChangeBadge(value: stock.changePercent, size: .compact)
            }
        }
        .padding(14)
        .frame(width: 170)
        .themeCardSurface()
    }

    private var displaySymbol: String {
        let s = stock.symbol
        if assetType == .forex, let pair = AssetMeta.forexPair(from: s) {
            return "\(pair.from)/\(pair.to)"
        }
        if s.hasSuffix("-USD") { return String(s.dropLast(4)) }
        if s.hasSuffix("=F") { return String(s.dropLast(2)) }
        if s.hasSuffix("=X") { return String(s.dropLast(2)) }
        return s
    }

    private var priceCurrencySymbol: String {
        if assetType == .forex {
            if let pair = AssetMeta.forexPair(from: stock.symbol) {
                return AssetMeta.currencySymbols[pair.to] ?? ""
            }
            return ""
        }
        return "$"
    }

    private var priceNumber: String {
        if assetType == .forex {
            return stock.price >= 100
                ? String(format: "%.2f", stock.price)
                : String(format: "%.4f", stock.price)
        }
        return String(format: "%.2f", stock.price)
    }

    private var priceText: String {
        "\(priceCurrencySymbol)\(priceNumber)"
    }
}

// MARK: - Orion Constellation View
struct ConstellationView: View {
    @State private var glow = false

    // Star positions (normalized 0-1) to form a simple constellation shape
    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.2, 0.15, 3), (0.45, 0.1, 4), (0.7, 0.18, 3),
        (0.3, 0.4, 5), (0.6, 0.35, 4),
        (0.25, 0.65, 3), (0.5, 0.55, 5), (0.75, 0.6, 3),
        (0.35, 0.85, 4), (0.65, 0.82, 3),
    ]

    // Lines connecting stars (index pairs)
    private let lines: [(Int, Int)] = [
        (0, 1), (1, 2), (0, 3), (2, 4), (3, 6), (4, 6),
        (5, 6), (6, 7), (5, 8), (7, 9), (8, 9)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Connecting lines
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    let s1 = stars[line.0]
                    let s2 = stars[line.1]
                    Path { path in
                        path.move(to: CGPoint(x: s1.x * geo.size.width, y: s1.y * geo.size.height))
                        path.addLine(to: CGPoint(x: s2.x * geo.size.width, y: s2.y * geo.size.height))
                    }
                    .stroke(AppTheme.accent.opacity(glow ? 0.25 : 0.12), lineWidth: 0.8)
                }

                // Stars
                ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                    Circle()
                        .fill(AppTheme.accent.opacity(glow ? 0.8 : 0.4))
                        .frame(width: star.size, height: star.size)
                        .shadow(color: AppTheme.accent.opacity(0.5), radius: star.size)
                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Stock Context Menu Preview
struct StockContextPreview: View {
    let stock: StockInfo

    private var changeColor: Color {
        stock.changePercent >= 0 ? AppTheme.positive : AppTheme.negative
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: symbol + name
            HStack(spacing: 10) {
                if let logoURL = stock.logoURL, !logoURL.isEmpty {
                    AsyncImage(url: URL(string: logoURL)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFit()
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.subtleFill)
                                .frame(width: 36, height: 36)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(stock.name)
                        .font(AppTheme.caption(12))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
            }

            // Price + change
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("$")
                        .font(AppTheme.number(16, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(String(format: "%.2f", stock.price))
                        .font(AppTheme.number(26, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                }
                ChangeBadge(value: stock.changePercent, size: .large)
            }

            // Mini chart
            if !stock.chartData.isEmpty {
                let minY = stock.chartData.map(\.close).min() ?? 0
                let maxY = stock.chartData.map(\.close).max() ?? 0
                let pad = (maxY - minY) * 0.1

                Chart(stock.chartData) { entry in
                    AreaMark(
                        x: .value("X", entry.index),
                        yStart: .value("Min", Double(minY - pad)),
                        yEnd: .value("Price", Double(entry.close))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [changeColor.opacity(0.25), changeColor.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("X", entry.index),
                        y: .value("Price", Double(entry.close))
                    )
                    .foregroundStyle(changeColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: Double(minY - pad)...Double(maxY + pad))
                .chartLegend(.hidden)
                .frame(height: 80)
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(AppTheme.cardBackground)
    }
}
