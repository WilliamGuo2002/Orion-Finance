import SwiftUI
import Charts

struct MyHoldingView: View {
    @State private var stockList: [StockInfo] = []
    @State private var marketIndices: [MarketIndex] = []
    @State private var showAddDialog = false
    @State private var showPortfolioWizard = false
    @State private var isLoading = false
    @State private var greetingSub = AppTheme.greetingSubtitle()
    @State private var recommendedStocks: [RecommendedStock] = []
    @State private var isLoadingRecommendations = false
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

            // Stock list — adaptive grid
            if isLoading && stockList.isEmpty {
                // Skeleton loading state
                ScrollView {
                    VStack(spacing: 12) {
                        todayMarketCard
                        SkeletonWatchlist()
                            .padding(.top, 4)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 80)
                }
            } else if stockList.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        todayMarketCard
                        myMoversCard

                        emptyStateView
                            .padding(.top, 12)

                        if !interests.selectedInterests.isEmpty {
                            recommendationsSection
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 80)
                }
                .refreshable { await loadAll() }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
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
                                        // NavigationLink handles this, but provide explicit option
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
                                    // Rich preview card
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
                    .padding(.top, 4)
                    .padding(.bottom, 80)
                }
                .refreshable { await loadAll() }
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
        _ = await (m, w, r, t)
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

    /// Top 3 gainers and top 3 losers from user's watchlist
    private var watchlistMovers: (gainers: [StockInfo], losers: [StockInfo]) {
        guard stockList.count >= 2 else { return ([], []) }
        let sorted = stockList.sorted { $0.changePercent > $1.changePercent }
        let top = Array(sorted.prefix(3))
        let bottom = Array(sorted.suffix(3).reversed())
        return (top, bottom)
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
        let movers = watchlistMovers
        if stockList.count >= 2 && (!movers.gainers.isEmpty || !movers.losers.isEmpty) {
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
                    if !movers.gainers.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.positive)
                                Text(L("Gainers"))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.positive)
                            }
                            ForEach(movers.gainers) { stock in
                                NavigationLink(destination: StockDetailView(symbol: stock.symbol, name: stock.name)) {
                                    myMoverRow(symbol: stock.symbol, name: stock.name, changePercent: stock.changePercent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Vertical divider
                    if !movers.gainers.isEmpty && !movers.losers.isEmpty {
                        Rectangle()
                            .fill(AppTheme.border)
                            .frame(width: 0.5)
                            .padding(.vertical, 2)
                    }

                    // Losers column
                    if !movers.losers.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.negative)
                                Text(L("Losers"))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.negative)
                            }
                            ForEach(movers.losers) { stock in
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
