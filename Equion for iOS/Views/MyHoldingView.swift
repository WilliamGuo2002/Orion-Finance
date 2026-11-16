import SwiftUI
import Charts
import Observation
import Combine

/// Fine-grained scroll state for the parallax chart.
/// Living in an @Observable (not @State on the view) means writing it during scroll
/// only re-renders the small chart layer that reads it — NOT the whole heavy body
/// (watchlist grid, cards, etc.), which is what caused the scroll jank.
@Observable
final class ChartParallax {
    var scrollOffset: CGFloat = 0

    /// 0 → 1 as the cards cover the chart (holds off until ~1/3 is covered). Quantized to 1/40
    /// steps so identical values let SwiftUI skip redundant updates while scrolling.
    static func progress(offset: CGFloat, chartHeight: CGFloat) -> CGFloat {
        let threshold = chartHeight / 3
        let ramp = max(chartHeight * 0.45, 1)
        let raw = min(max((offset - threshold) / ramp, 0), 1)
        return (raw * 40).rounded() / 40
    }
}

struct MyHoldingView: View {
    @State private var stockList: [StockInfo] = []
    @State private var marketIndices: [MarketIndex] = []
    @State private var showAddDialog = false
    @State private var showPortfolioWizard = false
    @State private var isLoading = false
    @State private var recommendedStocks: [RecommendedStock] = []
    @State private var isLoadingRecommendations = false
    // Holdings — use @State snapshots instead of @ObservedObject to avoid cascade redraws
    @State private var holdingsSnapshot = HoldingsSnapshot()
    @State private var portfolioChartData: [PortfolioValueEntry] = []
    /// Defaults to a year — looking at returns less often (and over longer windows) is calmer and
    /// leads to less loss-averse decisions. The user's own choice is remembered.
    @AppStorage("homeChartRange") private var portfolioInterval = "1Y"
    @State private var selectedPortfolioEntry: PortfolioValueEntry?
    @State private var showPortfolioMarker = false
    // Privacy: mask portfolio amounts and swap the chart for a gray placeholder
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false
    @State private var holdingsLoaded = false
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
    @State private var todayTab: TodayTab = .active  // neutral default: most active, not a gainers list
    @State private var isLoadingToday = false
    @ObservedObject private var interests = InterestsManager.shared
    // Watchlist add feedback
    @State private var pendingAdds: [String] = []
    @State private var watchlistNotice: WatchlistNotice?

    struct WatchlistNotice: Equatable {
        enum Kind { case info, error }
        let id = UUID()
        let kind: Kind
        let text: String
        var retrySymbol: String? = nil
    }

    enum TodayTab: String, CaseIterable {
        case active, gainers, losers
        var label: String {
            switch self {
            case .active:  return L("Most active")
            case .gainers: return L("Up")
            case .losers:  return L("Down")
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


    /// Adaptive grid: 2 columns on iPad/wide, single column on phone
    private var gridColumns: [GridItem] {
        if isWide {
            return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        }
        return [GridItem(.flexible())]
    }

    /// Height reserved for the portfolio chart background area (header + chart; the range picker
    /// sits in the scroll layer just below it)
    private var portfolioChartHeight: CGFloat {
        holdingsSnapshot.hasHoldings ? 184 : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Market ticker bar
            MarketTickerView(indices: marketIndices)

            // Greeting header
            VStack(alignment: .leading, spacing: 8) {
                Text(AppTheme.greeting())
                    .font(AppTheme.serifTitle(26))
                    .foregroundColor(AppTheme.primaryText)

                // One status line from the trading calendar — it can't contradict itself.
                // Side by side when it fits; stacked at large text sizes instead of truncating.
                let status = Text(MarketClock.statusLine())
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                let date = Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(AppLocale.current)))
                    .font(.footnote)
                    .foregroundColor(AppTheme.secondaryText)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        status.lineLimit(1)
                        Spacer(minLength: 8)
                        date.lineLimit(1)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        status
                        date
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

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

                // Foreground layer: scrollable cards — frosted glass while there's a chart behind them,
                // so the chart blurs through as they slide over it instead of being cut off.
                scrollContent
                    .environment(\.glassCards, holdingsSnapshot.hasHoldings)
                    .zIndex(1)
            }
        }
        .background(AppTheme.background)
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
        // Holdings can change from other screens (linking a brokerage, adding a trade).
        // These only fire on real data updates, never per scroll frame.
        .onReceive(HoldingsManager.shared.$snapshot.dropFirst()) { holdingsSnapshot = $0 }
        .onReceive(HoldingsManager.shared.$portfolioChart.dropFirst()) { portfolioChartData = $0 }
        .onReceive(NotificationCenter.default.publisher(for: .watchlistRemoved)) { note in
            guard let symbol = note.object as? String else { return }
            stockList.removeAll { $0.symbol.uppercased() == symbol.uppercased() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchlistAdded)) { note in
            guard let symbol = note.object as? String,
                  !stockList.contains(where: { $0.symbol.uppercased() == symbol.uppercased() }) else { return }
            Task { await fetchAndAddStock(symbol: symbol, persist: false) }
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

                // Range picker lives in the scrolling layer (the pinned chart behind it doesn't take
                // taps), directly under the chart.
                if holdingsSnapshot.hasHoldings && !portfolioChartData.isEmpty && !hideValues {
                    RangePicker(options: ["1D", "5D", "1M", "6M", "1Y"], selection: $portfolioInterval) { interval in
                        Task {
                            await HoldingsManager.shared.loadPortfolioChart(range: interval)
                            portfolioChartData = HoldingsManager.shared.portfolioChart
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, -12)
                }

                // Nothing linked yet → invite to link accounts (net worth needs them)
                if holdingsLoaded && !holdingsSnapshot.hasHoldings {
                    linkAccountsPrompt
                }
                // A connection broke or went stale → say so before the user trusts old numbers
                SyncHealthBanner()

                content()
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        // iOS 18 first-class scroll observation — fires reliably on every scroll.
        // contentOffset.y + contentInsets.top == 0 at rest, grows positive scrolling up.
        // Rounded to whole points to cut sub-pixel update churn. Writes the @Observable
        // (not view @State), so only the chart layer re-renders — the body stays put.
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            (geo.contentOffset.y + geo.contentInsets.top).rounded()
        } action: { _, newValue in
            let clamped = max(0, newValue)
            parallax.scrollOffset = clamped
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
                            guard !hideValues else { return }
                            let entries = portfolioChartData
                            let width = geo.size.width
                            guard !entries.isEmpty, width > 0 else { return }
                            let ratio = max(0, min(1, val.location.x / width))
                            let idx = Int(round(ratio * Double(entries.count - 1)))
                            let clamped = max(0, min(entries.count - 1, idx))
                            if !showPortfolioMarker { Haptic.selection() }   // one tick when scrubbing starts
                            withAnimation(.easeInOut(duration: 0.05)) {
                                selectedPortfolioEntry = entries[clamped]
                                showPortfolioMarker = true
                            }
                        }
                        .onEnded { _ in
                            guard showPortfolioMarker else { return }
                            withAnimation(Motion.tap) {
                                showPortfolioMarker = false
                                selectedPortfolioEntry = nil
                            }
                        }
                )
        }
        .frame(height: portfolioChartHeight)
        // Invisible, tappable copy of the header controls (Holdings / USD-CAD / hide),
        // laid exactly over the visible ones in the pinned chart header. Pinned via offset
        // (in its own view) so it tracks the chart without re-rendering this body on scroll.
        // Top padding: header sits 6pt into the chart layer; this spacer starts 4pt down.
        .overlay(alignment: .topTrailing) {
            if holdingsSnapshot.hasHoldings {
                PinnedHeaderTapLayer(parallax: parallax, chartHeight: portfolioChartHeight) {
                    headerControls(ghost: true)
                }
                .padding(.top, 2)
                .padding(.trailing, 20)
            }
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        if isLoading && stockList.isEmpty {
            trackedScrollView {
                watchlistHeader
                SkeletonWatchlist()
                todayMarketCard
                    .padding(.top, 12)
            }
        } else if stockList.isEmpty {
            trackedScrollView {
                watchlistHeader
                watchlistStatus

                // Never an empty page: well-known names to start from, one tap to add.
                // Falls back to the plain empty state if quotes can't load.
                StarterPicksSection(
                    title: L("You might be interested in"),
                    watchlist: watchlistSymbols,
                    pending: pendingAdds,
                    onAdd: { symbol in Task { await fetchAndAddStock(symbol: symbol) } },
                    onSearch: { showAddDialog = true }
                ) {
                    emptyStateView
                        .padding(.vertical, 12)
                }

                if !StarterPicksModel.shared.failed {   // the fallback carries its own link
                    Button { showPortfolioWizard = true } label: {
                        Text(L("Explore example portfolios"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.accentText)
                            .frame(minHeight: 44)
                    }
                    .frame(maxWidth: .infinity)
                }

                todayMarketCard
                    .padding(.top, 12)

                if !interests.selectedInterests.isEmpty {
                    recommendationsSection
                        .padding(.top, 12)
                }
            }
            .refreshable { await loadAll() }
        } else {
            trackedScrollView {
                watchlistHeader
                watchlistStatus

                // Watchlist
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(Array(stockList.enumerated()), id: \.element.id) { index, stock in
                        NavigationLink(destination: StockDetailView(symbol: stock.symbol, name: stock.name)) {
                            StockRowView(stock: stock)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if index > 0 {
                                Button {
                                    withAnimation(Motion.standard) {
                                        let item = stockList.remove(at: index)
                                        stockList.insert(item, at: 0)
                                    }
                                } label: {
                                    Label(L("Move to Top"), systemImage: "arrow.up.to.line")
                                }
                            }

                            ShareLink(item: "\(stock.symbol) - \(stock.name)\n$\(String(format: "%.2f", stock.price)) (\(AppTheme.formattedChange(stock.changePercent)))") {
                                Label(L("Share"), systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
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

                // Still a short list: keep the starter picks under it (added ones show a check).
                if stockList.count < 3 {
                    StarterPicksSection(
                        title: L("You might also like"),
                        watchlist: watchlistSymbols,
                        pending: pendingAdds,
                        maxRows: 5,
                        onAdd: { symbol in Task { await fetchAndAddStock(symbol: symbol) } }
                    ) { EmptyView() }
                    .padding(.top, 12)
                }

                myMoversCard
                    .padding(.top, 12)

                todayMarketCard
                    .padding(.top, 12)

                if !interests.selectedInterests.isEmpty {
                    recommendationsSection
                        .padding(.top, 12)
                }
            }
            .refreshable { await loadAll() }
        }
    }

    /// "Watchlist  3" with the add button where it belongs — next to the list it adds to.
    private var watchlistHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(L("Watchlist"))
                .font(AppTheme.serifHeadline(17))
                .foregroundColor(AppTheme.primaryText)
                .accessibilityAddTraits(.isHeader)
            if !stockList.isEmpty {
                Text("\(stockList.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            Button { showAddDialog = true } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L("Add to watchlist"))
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.top, 4)
    }

    // MARK: - Empty State
    /// One sentence and one button. The example-portfolio wizard stays available as a quiet link.
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                ConstellationView()
                    .frame(width: 64, height: 64)
                Image(systemName: "sparkle")
                    .font(.title3.weight(.light))
                    .foregroundColor(AppTheme.accentText)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(L("Your watchlist is empty"))
                    .font(AppTheme.serifHeadline(20))
                    .foregroundColor(AppTheme.primaryText)
                Text(L("Add the stocks and funds you want to follow."))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button { showAddDialog = true } label: {
                Label(L("Add Stock"), systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppTheme.onAccent)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 48)
                    .background(Capsule().fill(AppTheme.accent))
            }

            Button { showPortfolioWizard = true } label: {
                Text(L("Explore example portfolios"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.accentText)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
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
        holdingsLoaded = true
    }

    /// Shown on home until at least one account is linked.
    private var linkAccountsPrompt: some View {
        NavigationLink {
            LinkedAccountsView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(.title3))
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppTheme.accent.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("See your net worth"))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(L("Link your brokerage and bank accounts · read-only"))
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(16)
            .themeCardSurface()
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions
    private func loadMarketData() async {
        // ETF proxies — labelled as what they are (SPY, not "S&P 500 754.37").
        let symbols = [("SPY", "S&P 500 ETF"), ("QQQ", "Nasdaq-100 ETF"), ("DIA", "Dow Jones ETF")]
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
                results.first { $0.symbol == pair.0 }
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
                            async let profile = try? APIService.shared.fetchCompanyProfile(symbol: symbol)
                            // A missing company name/logo must not drop the whole row.
                            let (cq, prof) = (try await chartQuote, await profile)
                            let changePercent = PriceChange.dailyPercent(price: cq.price, previousClose: cq.previousClose)
                            return StockInfo(
                                symbol: symbol,
                                name: prof?.name ?? symbol,
                                price: cq.price,
                                changePercent: changePercent,
                                chartData: cq.chartData,
                                logoURL: prof?.logoURL
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

    /// Adds a symbol to the watchlist with visible feedback for every outcome: a pending row while
    /// it loads, a quiet inline note if it was already there, couldn't load (with Retry), or could
    /// only be kept for this session (guest).
    /// - Parameter persist: false when the symbol was already saved elsewhere (e.g. a peer's "Add").
    private func fetchAndAddStock(symbol: String, persist: Bool = true) async {
        let key = symbol.uppercased()
        if stockList.contains(where: { $0.symbol.uppercased() == key }) {
            if persist {
                watchlistNotice = WatchlistNotice(kind: .info, text: String(format: L("%@ is already in your watchlist."), Self.displaySymbol(symbol)))
            }
            return
        }
        guard !pendingAdds.contains(key) else { return }
        watchlistNotice = nil
        withAnimation(Motion.standard) { pendingAdds.append(key) }
        defer { withAnimation(Motion.standard) { pendingAdds.removeAll { $0 == key } } }

        do {
            async let chartQuote = APIService.shared.fetchChartAndQuote(symbol: symbol)
            async let profile = try? APIService.shared.fetchCompanyProfile(symbol: symbol)
            let (cq, prof) = (try await chartQuote, await profile)
            let stock = StockInfo(symbol: symbol, name: prof?.name ?? symbol, price: cq.price,
                                  changePercent: PriceChange.dailyPercent(price: cq.price, previousClose: cq.previousClose),
                                  chartData: cq.chartData, logoURL: prof?.logoURL)
            withAnimation(Motion.standard) { stockList.append(stock) }
            updateCachedMovers()
        } catch {
            print("[Add] Failed to add \(symbol): \(error.localizedDescription)")
            watchlistNotice = WatchlistNotice(
                kind: .error,
                text: String(format: L("Couldn't add %@. Check your connection and try again."), Self.displaySymbol(symbol)),
                retrySymbol: symbol
            )
            Haptic.error()
            return
        }

        guard persist else { return }
        do {
            if try await FirebaseController.shared.addToWatchlist(symbol: symbol) {
                Haptic.success()
            } else {
                watchlistNotice = WatchlistNotice(kind: .info, text: L("Added for this session. Sign in to keep your watchlist."))
            }
        } catch {
            watchlistNotice = WatchlistNotice(kind: .error, text: String(format: L("%@ was added here but couldn't be saved to your account."), Self.displaySymbol(symbol)), retrySymbol: nil)
        }
    }

    static func displaySymbol(_ s: String) -> String {
        if s.hasSuffix("-USD") { return String(s.dropLast(4)) }
        if s.hasSuffix("=F") || s.hasSuffix("=X") { return String(s.dropLast(2)) }
        return s
    }

    /// Inline status for watchlist adds — sits with the watchlist, never a banner or alert.
    @ViewBuilder
    private var watchlistStatus: some View {
        VStack(spacing: 8) {
            if let notice = watchlistNotice {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: notice.kind == .error ? "exclamationmark.circle" : "info.circle")
                        .foregroundColor(AppTheme.secondaryText)
                    Text(notice.text)
                        .font(.footnote)
                        .foregroundColor(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    if let retry = notice.retrySymbol {
                        Button(L("Retry")) { Task { await fetchAndAddStock(symbol: retry) } }
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.accentText)
                    }
                    Button {
                        withAnimation(Motion.tap) { watchlistNotice = nil }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(L("Dismiss"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.subtleFill))
                .transition(.opacity)
                .task(id: notice.id) {
                    // Informational notes fade on their own; errors stay until dismissed or retried.
                    guard notice.kind == .info else { return }
                    try? await Task.sleep(for: .seconds(6))
                    if watchlistNotice?.id == notice.id {
                        withAnimation(Motion.standard) { watchlistNotice = nil }
                    }
                }
            }
            ForEach(pendingAdds, id: \.self) { sym in
                HStack(spacing: 12) {
                    ProgressView()
                    Text(String(format: L("Adding %@…"), Self.displaySymbol(sym)))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .themeCardSurface()
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
    }

    private var watchlistSymbols: Set<String> {
        Set(stockList.map { $0.symbol.uppercased() })
    }

    private func deleteStock(at offsets: IndexSet) {
        // Remove locally first: removeStockFromWatchlist posts .watchlistRemoved, which this view
        // also handles — removing by symbol afterwards is a no-op instead of shifting offsets.
        let symbols = offsets.map { stockList[$0].symbol }
        stockList.remove(atOffsets: offsets)
        symbols.forEach { FirebaseController.shared.removeStockFromWatchlist(symbol: $0) }
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
        // A rising stock is never a "loser": each column only holds moves in its direction.
        let sorted = stockList.sorted { $0.changePercent > $1.changePercent }
        cachedGainers = Array(sorted.filter { $0.changePercent > 0 }.prefix(3))
        cachedLosers = Array(sorted.reversed().filter { $0.changePercent < 0 }.prefix(3))
    }

    // MARK: - Portfolio Chart Background (pinned behind scroll)
    private var portfolioChartBackground: some View {
        VStack(spacing: 0) {
            // Value & P&L header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("My Net Worth"))
                        .font(.system(.caption2))
                        .foregroundColor(AppTheme.secondaryText)

                    // Hidden → asterisks; else touched value; else current total
                    if hideValues {
                        Text(PortfolioPrivacy.mask)
                            .font(AppTheme.heroNumber(.title))
                            .foregroundColor(AppTheme.primaryText)
                            .padding(.top, 2)
                        Text("\(PortfolioPrivacy.shortMask) (\(PortfolioPrivacy.shortMask))  ·  \(L("Today")) \(PortfolioPrivacy.shortMask)")
                            .font(AppTheme.number(12, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText)
                    } else if let sel = selectedPortfolioEntry, showPortfolioMarker {
                        // During touch: show market value at that point
                        // Amounts are stored in USD; holdingsSnapshot converts to the display currency.
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text(holdingsSnapshot.currencySymbol)
                                .font(AppTheme.heroCurrency(.callout))
                                .foregroundColor(AppTheme.secondaryText)
                            Text(String(format: "%.2f", holdingsSnapshot.display(sel.value)))
                                .font(AppTheme.heroNumber(.title))
                                .foregroundColor(AppTheme.primaryText)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.05), value: sel.value)
                        }

                        // Date + cost basis + change (cash is in both value and cost, so it cancels;
                        // the % is on invested cost only)
                        let selPnL = sel.value - sel.costBasis
                        let investedCost = sel.costBasis - sel.cash
                        let selPnLPct = investedCost > 0 ? (selPnL / investedCost) * 100 : 0

                        Text(sel.datetime)
                            .font(AppTheme.caption(11))
                            .foregroundColor(AppTheme.secondaryText)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.05), value: sel.datetime)

                        HStack(spacing: 8) {
                            Text("\(L("Cost")) \(holdingsSnapshot.format(investedCost))")
                                .font(AppTheme.number(11, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.05), value: investedCost)

                            Text(String(format: "%@%@ (%@%.2f%%)",
                                        selPnL >= 0 ? "+" : "-", holdingsSnapshot.format(abs(selPnL)),
                                        selPnLPct >= 0 ? "+" : "", selPnLPct))
                                .font(AppTheme.number(11, weight: .semibold))
                                .foregroundColor(selPnL >= 0 ? AppTheme.positive : AppTheme.negative)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.05), value: selPnL)
                        }
                    } else {
                        // Default: show current total
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text(holdingsSnapshot.currencySymbol)
                                .font(AppTheme.heroCurrency(.callout))
                                .foregroundColor(AppTheme.secondaryText)
                            Text((holdingsSnapshot.totalValue < 0 ? "−" : "") + String(format: "%.2f", abs(holdingsSnapshot.display(holdingsSnapshot.totalValue))))
                                .font(AppTheme.heroNumber(.title))
                                .foregroundColor(AppTheme.primaryText)
                                .contentTransition(.numericText())
                        }

                        HStack(spacing: 8) {
                            Text(String(format: "%@%@ (%@%.2f%%)",
                                        holdingsSnapshot.totalPnL >= 0 ? "+" : "-", holdingsSnapshot.format(abs(holdingsSnapshot.totalPnL)),
                                        holdingsSnapshot.totalPnLPercent >= 0 ? "+" : "", holdingsSnapshot.totalPnLPercent))
                                .font(AppTheme.number(12, weight: .semibold))
                                .foregroundColor(holdingsSnapshot.totalPnL >= 0 ? AppTheme.positive : AppTheme.negative)

                            Text("·")
                                .foregroundColor(AppTheme.tertiaryText)

                            // Today's move is context, not the headline: secondary ink, no red/green.
                            Text(String(format: "%@ %@%@",
                                        L("Today"),
                                        holdingsSnapshot.totalDayPnL >= 0 ? "+" : "−",
                                        holdingsSnapshot.format(abs(holdingsSnapshot.totalDayPnL))))
                                .font(.footnote.monospacedDigit())
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                Spacer()

                // Visible header controls (Holdings, USD/CAD, hide). They live in the pinned
                // chart background so they sink + blur with the chart; taps are handled by an
                // identical invisible copy in the foreground (the scroll layer captures touches here).
                headerControls(ghost: false)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Edge-to-edge chart — isolated view, won't re-render on scroll
            if !portfolioChartData.isEmpty {
                Group {
                    if hideValues {
                        PortfolioChartPlaceholder()
                    } else {
                        PortfolioChartView(
                            entries: portfolioChartData,
                            selectedEntry: $selectedPortfolioEntry,
                            showMarker: $showPortfolioMarker
                        )
                    }
                }
                .frame(height: 110)

            }
        }
    }

    // MARK: - Portfolio header controls
    /// The same view is drawn twice: visibly in the pinned chart header (`ghost: false`,
    /// not hit-testable) and invisibly in the foreground scroll layer (`ghost: true`),
    /// which is what actually receives the taps. Identical layout keeps them aligned.
    private func headerControls(ghost: Bool) -> some View {
        PortfolioHeaderControls(
            displayCurrency: holdingsSnapshot.displayCurrency,
            showCurrencyToggle: holdingsSnapshot.hasCADExposure || holdingsSnapshot.displayCurrency != "USD"
        )
        .opacity(ghost ? 0.001 : 1)   // not 0: fully transparent views don't receive touches
    }

    // MARK: - Today's Market Card
    @ViewBuilder
    private var todayMarketCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 0) {
                AccentSectionTitle(L("Market Overview"))
                Spacer()
                if isLoadingToday {
                    ProgressView().controlSize(.small)
                }
            }

            // Neutral views of the market — no flame, no "hot" list, selection isn't a call to action
            HStack(spacing: 4) {
                ForEach([TodayTab.active, .gainers, .losers], id: \.self) { tab in
                    let selected = todayTab == tab
                    Button {
                        withAnimation(Motion.tap) { todayTab = tab }
                    } label: {
                        Text(tab.label)
                            .font(.subheadline.weight(selected ? .semibold : .regular))
                            .foregroundColor(selected ? AppTheme.primaryText : AppTheme.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background { if selected { LitPill() } }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                Spacer()
            }
            .padding(.vertical, -8)

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
                    .padding(.vertical, 8)
            } else {
                // Horizontal scroll; the right edge fades the content itself (a mask), so there's no
                // coloured overlay to mismatch the card surface.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(movers) { mover in
                            NavigationLink(destination: StockDetailView(symbol: mover.symbol, name: mover.name)) {
                                MoverChip(symbol: mover.symbol, name: mover.name, price: mover.price, changePercent: mover.changePercent)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer().frame(width: 20)
                    }
                    .padding(.vertical, 8)   // room for the chips' outline
                }
                .padding(.vertical, -8)
                .mask(
                    LinearGradient(stops: [.init(color: .black, location: 0.88), .init(color: .clear, location: 1)],
                                   startPoint: .leading, endPoint: .trailing)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .themeCardSurface()
        .padding(.horizontal, 16)
    }

    // MARK: - My Movers Card (separate module)
    @ViewBuilder
    private var myMoversCard: some View {
        if stockList.count >= 2 && (!cachedGainers.isEmpty || !cachedLosers.isEmpty) {
            VStack(alignment: .leading, spacing: 12) {
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
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(.caption2, weight: .semibold))
                                    .foregroundColor(AppTheme.positive)
                                Text(L("Gainers"))
                                    .font(.system(.caption2, weight: .semibold))
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
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(.caption2, weight: .semibold))
                                    .foregroundColor(AppTheme.negative)
                                Text(L("Losers"))
                                    .font(.system(.caption2, weight: .semibold))
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .themeCardSurface()
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func myMoverRow(symbol: String, name: String, changePercent: Double) -> some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.system(.caption, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(1)
            Spacer()
            ChangeBadge(value: changePercent, showBackground: false, size: .compact)
                .animation(Motion.standard, value: changePercent)
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
                        let changePercent = PriceChange.dailyPercent(price: cq.price, previousClose: cq.previousClose)
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
                    AccentSectionTitle(L("Ideas to Explore"), icon: "sparkles")
                    Text(L("Popular names in your interests · not a recommendation"))
                        .font(AppTheme.caption(12))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.leading, 12) // align with title text after accent bar
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // As cards cover the chart it sinks a little, blurs softly and dims (never fully hidden).
        // With Reduce Motion on, the chart simply stays put.
        let progress = reduceMotion ? 0 : ChartParallax.progress(offset: parallax.scrollOffset, chartHeight: chartHeight)
        content
            .offset(y: progress * 20)              // gentle sink
            .blur(radius: progress * 6)            // soft blur — stays readable
            .opacity(1.0 - progress * 0.3)         // fades only to 0.7
            .scaleEffect(1.0 - progress * 0.03, anchor: .top)
            .allowsHitTesting(false)               // gestures go to the scroll spacer
    }
}

// MARK: - Pinned Header Tap Layer
/// Hosts tappable controls that sit over the pinned chart header. It lives in the foreground
/// scroll layer (so it actually receives touches) but counter-offsets the scroll so it stays
/// glued to the pinned header. Reads `parallax.scrollOffset` itself, keeping the parent body
/// off the per-frame scroll path.
struct PinnedHeaderTapLayer<Content: View>: View {
    var parallax: ChartParallax
    var chartHeight: CGFloat
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let progress = ChartParallax.progress(offset: parallax.scrollOffset, chartHeight: chartHeight)
        let sink = reduceMotion ? 0 : progress * 20   // same sink as the visible header
        content
            // Cancel the scroll translation (pin), then follow the chart's sink.
            .offset(y: parallax.scrollOffset + sink)
            // Stop catching taps once the header is mostly covered by cards.
            .allowsHitTesting(progress < 0.85)
    }
}

// MARK: - Portfolio privacy (hide amounts)
enum PortfolioPrivacy {
    static let storageKey = "hidePortfolioValues"
    static let mask = "******"
    static let shortMask = "****"
}

/// Eye / eye-slash button that toggles hiding portfolio amounts app-wide.
struct HideValuesButton: View {
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false

    var body: some View {
        Button {
            withAnimation(Motion.tap) { hideValues.toggle() }
        } label: {
            Image(systemName: hideValues ? "eye.slash" : "eye")
                .font(.system(.caption, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 34, height: 27)
                .background(LitPill())
                .expandedHitArea()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hideValues ? L("Show amounts") : L("Hide amounts"))
    }
}

/// Compact USD | CAD pill. Same setting as More → Display Currency.
struct CurrencyToggle: View {
    let selected: String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(SettingsManager.supportedCurrencies, id: \.self) { currency in
                Button {
                    guard currency != selected else { return }
                    Task { await HoldingsManager.shared.setDisplayCurrency(currency) }
                } label: {
                    Text(currency)
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundColor(currency == selected ? AppTheme.onAccent : AppTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Group { if currency == selected { LitPill(fill: AnyShapeStyle(AppTheme.accent)) } }
                        )
                        .expandedHitArea(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(LitPill())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L("Display Currency"))
    }
}

/// Right-hand controls of the home portfolio header:
/// row 1 = Holdings portal, row 2 = [USD|CAD] (Canadian accounts only) + hide button.
struct PortfolioHeaderControls: View {
    let displayCurrency: String
    let showCurrencyToggle: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            NavigationLink(destination: HoldingsListPage()) {
                HStack(spacing: 4) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(.caption2, weight: .semibold))
                    Text(L("Accounts"))
                        .font(.system(.caption, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(.caption2, weight: .semibold))
                        .opacity(0.6)
                }
                .foregroundColor(AppTheme.accentText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppTheme.accent.opacity(0.12)))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                if showCurrencyToggle {
                    CurrencyToggle(selected: displayCurrency)
                }
                HideValuesButton()
            }
        }
    }
}

/// Gray stand-in for the portfolio chart while amounts are hidden — same footprint,
/// fixed shape, no real data.
struct PortfolioChartPlaceholder: View {
    private static let points: [Double] = [0.42, 0.48, 0.45, 0.55, 0.52, 0.6, 0.57, 0.66,
                                           0.62, 0.7, 0.68, 0.74, 0.71, 0.78, 0.82]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let pts = Self.points.enumerated().map { i, v in
                CGPoint(x: w * CGFloat(i) / CGFloat(Self.points.count - 1),
                        y: h * (1 - CGFloat(v)))
            }
            ZStack {
                // Soft area
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    pts.forEach { p.addLine(to: $0) }
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color.gray.opacity(0.12), Color.gray.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
                // Line
                Path { p in
                    p.move(to: pts[0])
                    pts.dropFirst().forEach { p.addLine(to: $0) }
                }
                .stroke(Color.gray.opacity(0.45),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Holdings List Page (pushed from the chart's Holdings button)
/// Full-screen holdings list, opened from the compact Holdings pill on the home chart.
struct HoldingsListPage: View {
    @ObservedObject private var manager = HoldingsManager.shared
    @ObservedObject private var brokerage = BrokerageManager.shared
    @ObservedObject private var bank = BankManager.shared
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false
    /// Scroll offset for the pinned net-worth chart.
    @State private var parallax = ChartParallax()

    /// Banks that have at least one account counted in net worth (or need attention).
    private var bankItems: [BankItem] {
        bank.currentItems.filter { item in
            item.error != nil || bankAccounts(in: item).contains { manager.snapshot.accountValues[HoldingsSnapshot.bankKey($0.id)] != nil }
        }
    }

    private func bankAccounts(in item: BankItem) -> [BankAccount] {
        bank.currentAccounts.filter { $0.itemId == item.id }
            .filter { manager.snapshot.accountValues[HoldingsSnapshot.bankKey($0.id)] != nil }
            .sorted { ($0.isDebt ? 1 : 0, $0.name) < ($1.isDebt ? 1 : 0, $1.name) }
    }

    /// Investments first, then bank accounts, then debts; largest first within each.
    private var accounts: [LinkedAccount] {
        let values = manager.snapshot.accountValues
        func rank(_ a: LinkedAccount) -> Int {
            switch a.accountKind { case .investment: 0; case .cash: 1; case .other: 2; case .debt: 3 }
        }
        return brokerage.currentAccounts.sorted { a, b in
            rank(a) != rank(b) ? rank(a) < rank(b) : abs(values[a.id] ?? 0) > abs(values[b.id] ?? 0)
        }
    }

    private func holdings(in account: LinkedAccount) -> [AggregatedHolding] {
        manager.snapshot.aggregated
            .filter { if case .linked(let id, _, _) = $0.source { return id == account.id } else { return false } }
            .sorted { $0.marketValue > $1.marketValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NetWorthChartModule(parallax: parallax)
                    .zIndex(0)

                // Everything below slides up over the pinned chart.
                VStack(spacing: 16) {
                SyncHealthBanner()

                TaxAssistantCard()

                if accounts.isEmpty && bankItems.isEmpty {
                    Text(L("No accounts linked yet"))
                        .font(AppTheme.caption(13))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.top, 64)
                } else {
                    ForEach(accounts) { account in
                        VStack(alignment: .leading, spacing: 8) {
                            accountHeader(account)
                            ForEach(holdings(in: account)) { holding in
                                NavigationLink(destination: StockDetailView(symbol: holding.symbol, name: holding.name)) {
                                    holdingRow(holding)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .themeCardSurface()
                        .padding(.horizontal, 16)
                    }
                }

                // Banks (Plaid): one card per bank login, one row per account
                ForEach(bankItems) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(item.institution, systemImage: "building.columns.fill")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundColor(AppTheme.accentText)
                        if let error = item.error {
                            Text(L(error))
                                .font(AppTheme.caption(10))
                                .foregroundColor(AppTheme.warning)
                        }
                        ForEach(bankAccounts(in: item)) { account in
                            bankRow(account)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .themeCardSurface()
                    .padding(.horizontal, 16)
                }

                linkBrokerageCard
                }
                .environment(\.glassCards, true)
                .zIndex(1)
            }
            .padding(.top, 12)
            .padding(.bottom, 48)
        }
        .trackingParallax(parallax)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(L("Accounts"))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            async let b: Void = brokerage.sync()
            async let p: Void = bank.sync()
            _ = await (b, p)
            await manager.reloadAfterBrokerageChange()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    LinkedAccountsView()
                } label: {
                    Image(systemName: "building.columns")
                }
                .accessibilityLabel(L("Linked Accounts"))
            }
        }
    }

    private func bankRow(_ account: BankAccount) -> some View {
        let value = manager.snapshot.accountValues[HoldingsSnapshot.bankKey(account.id)] ?? 0
        return HStack(spacing: 12) {
            Image(systemName: account.icon)
                .font(.system(.caption))
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                if let masked = account.maskedNumber {
                    Text(masked)
                        .font(.system(.caption2))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            Spacer()
            Text(hideValues ? PortfolioPrivacy.shortMask
                 : (value < 0 ? "-" : "") + manager.snapshot.format(abs(value)))
                .font(AppTheme.number(14, weight: .semibold))
                .foregroundColor(value < 0 && !hideValues ? AppTheme.negative : AppTheme.primaryText)
        }
        .padding(.vertical, 8)
    }

    private func accountIcon(_ account: LinkedAccount) -> String {
        switch account.accountKind {
        case .investment: return "chart.line.uptrend.xyaxis"
        case .cash: return "banknote.fill"
        case .debt: return "creditcard.fill"
        case .other: return "building.columns.fill"
        }
    }

    private func accountHeader(_ account: LinkedAccount) -> some View {
        let value = manager.snapshot.accountValues[account.id]
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Label("\(account.institution) · \(account.name)", systemImage: accountIcon(account))
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(AppTheme.accentText)
                    .lineLimit(1)
                Spacer()
                if let value {
                    Text(hideValues ? PortfolioPrivacy.shortMask
                         : (value < 0 ? "-" : "") + manager.snapshot.format(abs(value)))
                        .font(AppTheme.number(12, weight: .semibold))
                        .foregroundColor(value < 0 && !hideValues ? AppTheme.negative : AppTheme.primaryText)
                }
            }
            if account.accountKind == .investment, !account.cash.isEmpty {
                // Multi-currency cash summed into the display currency
                let cashUSD = account.cash.reduce(0) { $0 + manager.usd($1.amount, from: $1.currency) }
                Text(L("Cash") + " " + (hideValues ? PortfolioPrivacy.shortMask : manager.snapshot.format(cashUSD)))
                    .font(AppTheme.caption(10))
                    .foregroundColor(AppTheme.secondaryText)
            }
            if let error = account.error {
                Text(L(error))
                    .font(AppTheme.caption(10))
                    .foregroundColor(AppTheme.warning)
            }
        }
        .padding(.bottom, 2)
    }

    private var linkBrokerageCard: some View {
        NavigationLink {
            LinkedAccountsView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "building.columns")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.accentText)
                VStack(alignment: .leading, spacing: 2) {
                    Text(brokerage.connections.isEmpty && bank.currentItems.isEmpty ? L("Link your accounts") : L("Manage linked accounts"))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(L("Wealthsimple, banks and more · read-only"))
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(16)
            .themeCardSurface()
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private func holdingRow(_ holding: AggregatedHolding) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(hideValues ? "\(PortfolioPrivacy.shortMask) \(L("shares"))" : String(format: "%.4g %@", holding.totalShares, L("shares")))
                    .font(.system(.caption2))
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                // Display currency, so the rows add up to the total above.
                Text(hideValues ? PortfolioPrivacy.shortMask : manager.snapshot.format(holding.marketValue))
                    .font(AppTheme.number(14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(hideValues ? PortfolioPrivacy.shortMask : String(format: "%@%.2f%%", holding.totalPnLPercent >= 0 ? "+" : "", holding.totalPnLPercent))
                    .font(AppTheme.number(11, weight: .medium))
                    .foregroundColor(hideValues ? AppTheme.secondaryText : (holding.totalPnLPercent >= 0 ? AppTheme.positive : AppTheme.negative))
            }
        }
        .padding(.vertical, 8)
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
/// A still row of market gauges. Nothing moves on its own — peripheral motion at the top of the
/// home screen is the most attention-grabbing thing an app can do, and auto-updating prices must be
/// pausable (WCAG 2.2.2). If it doesn't fit, the user scrolls it.
struct MarketTickerView: View {
    let indices: [MarketIndex]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(indices) { index in
                    tickerLabel(index)
                }
                if let asOf = indices.compactMap(\.asOf).max() {
                    Text(Self.asOfText(asOf))
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .frame(minHeight: 36)
        .background(AppTheme.background)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.border.opacity(0.6)).frame(height: 0.5)
        }
        .opacity(indices.isEmpty ? 0 : 1)
    }

    @ViewBuilder
    private func tickerLabel(_ index: MarketIndex) -> some View {
        HStack(spacing: 8) {
            Text(index.symbol)
                .foregroundColor(AppTheme.secondaryText)
                .font(.system(.caption))
            Text(String(format: "%.2f", index.price))
                .foregroundColor(AppTheme.primaryText)
                .font(AppTheme.number(12))
            ChangeBadge(value: index.changePercent, showBackground: false, size: .compact)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(index.name), \(String(format: "%.2f", index.price)), \(AppTheme.formattedChange(index.changePercent))")
    }

    /// "As of 4:00 PM ET", with the weekday when it isn't today.
    static func asOfText(_ date: Date) -> String {
        var et = Calendar(identifier: .gregorian)
        et.timeZone = AppLocale.easternTime
        let sameDay = et.isDate(date, inSameDayAs: Date())
        let style: Date.FormatStyle = sameDay
            ? Date.FormatStyle(date: .omitted, time: .shortened, locale: AppLocale.current, timeZone: AppLocale.easternTime)
            : Date.FormatStyle(locale: AppLocale.current, timeZone: AppLocale.easternTime).weekday(.abbreviated).hour().minute()
        return String(format: L("As of %@ ET"), date.formatted(style))
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
                RemoteImage(url: URL(string: logoURL), fit: true) { assetIcon }
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            } else {
                assetIcon
            }

            // Symbol & Name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(displaySymbol)
                        .font(.system(.callout, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    if assetType != .stock {
                        Text(assetType.label)
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundColor(assetTypeColor)
                            .padding(.horizontal, 4)
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
                Sparkline(stock.chartData,
                          color: stock.changePercent >= 0 ? AppTheme.positive : AppTheme.negative)
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
                        .animation(Motion.standard, value: priceNumber)
                }
                ChangeBadge(value: stock.changePercent, size: .compact)
                    .animation(Motion.number, value: stock.changePercent)
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
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
                    .font(.system(.body, weight: .semibold))
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
        case .stock:     return AppTheme.accentText
        case .crypto, .forex, .metal, .commodity: return AppTheme.accentText
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
                    .padding(.vertical, 12)
                }

                // Search field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.secondaryText)
                    TextField(searchPlaceholder, text: $searchText)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.tertiaryText)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.subtleFill)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Custom manual entry button (when search has text)
                if !searchText.isEmpty {
                    let sym = searchText.trimmingCharacters(in: .whitespaces).uppercased()
                    if !sym.isEmpty && !existingSymbols.contains(sym) {
                        Button(action: { addSymbol(sym) }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.accentText)
                                Text(L("Add") + " \"\(sym)\"")
                                    .font(.system(.subheadline))
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(.caption))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
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
                    LazyVStack(spacing: 8) {
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
                                            .font(.system(.callout, weight: .semibold))
                                            .foregroundColor(iconColor(for: asset.type))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(asset.name)
                                            .font(.system(.subheadline))
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
                                            .foregroundColor(AppTheme.accentText)
                                            .font(.system(.title3))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            .disabled(alreadyAdded)
                            .opacity(alreadyAdded ? 0.5 : 1)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(AppTheme.background)
            .navigationTitle(L("Add Asset"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                        .foregroundColor(AppTheme.accentText)
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
        Button(action: { withAnimation(Motion.standard) { selectedTab = type } }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(.footnote))
                Text(type.label)
                    .font(.system(.footnote))
            }
            .foregroundColor(selectedTab == type ? AppTheme.onAccent : AppTheme.primaryText)
            .padding(.horizontal, 16)
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
        AppTheme.accentText   // one accent family for all asset types
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
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                Text(name)
                    .font(.system(.caption2))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            .frame(minWidth: 50, alignment: .leading)

            // Change badge
            ChangeBadge(value: changePercent, size: .compact)
                .animation(Motion.number, value: changePercent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
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
        VStack(alignment: .leading, spacing: 12) {
            // Top: category badge
            HStack {
                Text(L(stock.categoryName))
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundColor(AppTheme.accentText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.accent.opacity(0.1)))
                Spacer()
                // Add button
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.title3))
                        .foregroundColor(AppTheme.accentText)
                }
            }

            // Symbol & Name
            VStack(alignment: .leading, spacing: 2) {
                Text(displaySymbol)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(stock.name)
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            // Mini chart
            if !stock.chartData.isEmpty {
                Sparkline(stock.chartData,
                          color: stock.changePercent >= 0 ? AppTheme.positive : AppTheme.negative,
                          fillOpacity: 0.25)
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
        .padding(16)
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

    /// A still illustration — no breathing loop, no glow.
    var body: some View {
        Canvas { context, size in
            var path = Path()
            for line in lines {
                let a = stars[line.0], b = stars[line.1]
                path.move(to: CGPoint(x: a.x * size.width, y: a.y * size.height))
                path.addLine(to: CGPoint(x: b.x * size.width, y: b.y * size.height))
            }
            context.stroke(path, with: .color(AppTheme.accent.opacity(0.25)), lineWidth: 0.8)
            for star in stars {
                let rect = CGRect(x: star.x * size.width - star.size / 2, y: star.y * size.height - star.size / 2,
                                  width: star.size, height: star.size)
                context.fill(Path(ellipseIn: rect), with: .color(AppTheme.accent.opacity(0.6)))
            }
        }
        .accessibilityHidden(true)
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
            HStack(spacing: 12) {
                if let logoURL = stock.logoURL, !logoURL.isEmpty {
                    AsyncImage(url: URL(string: logoURL)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFit()
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.subtleFill)
                                .frame(width: 36, height: 36)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol)
                        .font(.system(.title3, weight: .semibold))
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
