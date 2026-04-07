import SwiftUI
import Charts
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

    // Chart hint
    @AppStorage("hasUsedChartTouch") private var hasUsedChartTouch = false
    @State private var showChartHint = false
    @State private var hintPulse = false

    // Scroll tracking
    @State private var headerVisible = true

    // New module data
    @State private var recommendation: RecommendationTrend?
    @State private var companyNews: [NewsItem] = []
    @State private var peers: [PeerStock] = []
    @State private var companyProfile: CompanyProfile?
    @State private var comments: [StockComment] = []
    @State private var commentText = ""
    @State private var week52High: Double?
    @State private var week52Low: Double?
    @State private var fundamentals: FundamentalMetrics?
    @State private var aiDashboard: AIDecisionDashboard?
    @State private var isLoadingDashboard = false

    private let intervals = ["1D", "5D", "1M", "6M", "YTD", "1Y", "ALL"]
    private let etZone = TimeZone(identifier: "America/New_York")!

    // MARK: - Computed properties
    private var intervalChange: (amount: Double, percent: Double)? {
        guard let first = chartEntries.first, let last = chartEntries.last,
              first.close != 0 else { return nil }
        let change = Double(last.close - first.close)
        let pct = change / Double(first.close) * 100
        return (change, pct)
    }

    private var marketSession: MarketSession {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = etZone
        let now = Date()
        let weekday = cal.component(.weekday, from: now)

        // Weekend or holiday → closed
        if weekday == 1 || weekday == 7 { return .closed }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = etZone
        if AppTheme.marketHolidays.contains(fmt.string(from: now)) { return .holiday }

        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let timeVal = hour * 60 + minute
        if timeVal >= 570 && timeVal < 960 { return .open }
        if timeVal >= 240 && timeVal < 570 { return .preMarket }
        if timeVal >= 960 && timeVal < 1200 { return .afterHours }
        return .closed
    }

    private enum MarketSession { case open, preMarket, afterHours, closed, holiday }

    private var marketStatusText: String {
        let fmt = DateFormatter()
        fmt.timeZone = etZone
        fmt.dateFormat = "M/d h:mm a"
        let timeStr = fmt.string(from: Date()) + " ET"
        switch marketSession {
        case .open:        return "\(L("Open")) · \(timeStr)"
        case .preMarket:   return "\(L("Pre-Market")) · \(timeStr)"
        case .afterHours:  return "\(L("After-Hours")) · \(timeStr)"
        case .closed:      return "\(L("Closed")) · \(timeStr)"
        case .holiday:     return "\(L("Holiday")) · \(L("Closed")) · \(timeStr)"
        }
    }

    private var extendedHoursChange: (price: Double, change: Double, percent: Double)? {
        guard let q = quote else { return nil }
        switch marketSession {
        case .preMarket, .afterHours:
            let change = q.price - q.previousClose
            let pct = q.previousClose != 0 ? (change / q.previousClose) * 100 : 0
            return (q.price, change, pct)
        default: return nil
        }
    }

    private var priceString: String {
        priceLoaded ? String(format: "%.2f", currentPrice) : L("Loading...")
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                toolbarHeader.opacity(headerVisible ? 0 : 1)
            }
        }
        .task {
            await loadChart()
            await loadQuote()
            await loadAllModules()
        }
    }

    // MARK: - Compact (iPhone portrait)
    /// Accent-tinted divider between module groups
    private var moduleDivider: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [AppTheme.accent.opacity(0), AppTheme.accent.opacity(0.4), AppTheme.accent.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .padding(.horizontal, 32)
    }

    private var compactBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ── Chart group (tight) ──
                headerSection
                    .padding(.bottom, 8)
                chartSection
                intervalSelector
                    .padding(.bottom, 6)

                moduleDivider
                    .padding(.vertical, 14)

                // ── AI & Data group ──
                VStack(spacing: 16) {
                    aiDashboardModule
                    fundamentalsModule
                    keyDataModule
                    predictionsModule
                }

                BannerAdView().padding(.horizontal, 16).padding(.top, 20)

                moduleDivider
                    .padding(.vertical, 14)

                // ── News & Activity group ──
                VStack(spacing: 16) {
                    newsModule
                    optionsModule
                }

                BannerAdView().padding(.horizontal, 16).padding(.top, 20)

                moduleDivider
                    .padding(.vertical, 14)

                // ── Social group (wider breathing room) ──
                VStack(spacing: 20) {
                    peersModule
                    commentsModule
                }

                BannerAdView().padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 8)

                companyInfoModule
                    .padding(.top, 8)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Wide (iPad / landscape)
    private var wideBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.moduleSpacing) {
                // Top: header + chart full width
                headerSection
                chartSection
                intervalSelector

                // Two-column layout for modules
                HStack(alignment: .top, spacing: 16) {
                    // Left column
                    VStack(spacing: AppTheme.moduleSpacing) {
                        aiDashboardModule
                        fundamentalsModule
                        keyDataModule
                        predictionsModule
                        newsModule
                        BannerAdView().padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity)

                    // Right column
                    VStack(spacing: AppTheme.moduleSpacing) {
                        peersModule
                        optionsModule
                        commentsModule
                        companyInfoModule
                        BannerAdView().padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 80)
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
    // MARK: - Module 1: Key Data
    // ============================
    @ViewBuilder
    private var keyDataModule: some View {
        if let q = quote {
            moduleCard("Key Data", icon: "chart.bar.doc.horizontal") {
                let items: [(String, String)] = [
                    (L("Open Price"), String(format: "$%.2f", q.open)),
                    (L("Previous Close"), String(format: "$%.2f", q.previousClose)),
                    (L("Day High"), String(format: "$%.2f", q.high)),
                    (L("Day Low"), String(format: "$%.2f", q.low)),
                    (L("Volume"), formatVolume(q.timestamp))
                ]
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(items, id: \.0) { label, value in
                        HStack(spacing: 4) {
                            Text(label)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                            Text(value)
                                .font(AppTheme.number(14, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Day range bar
                if q.high > q.low {
                    VStack(spacing: 4) {
                        HStack {
                            Text(String(format: "$%.2f", q.low))
                                .font(.caption2)
                                .foregroundColor(AppTheme.negative)
                            Spacer()
                            Text(L("Day Range"))
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                            Text(String(format: "$%.2f", q.high))
                                .font(.caption2)
                                .foregroundColor(AppTheme.positive)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.negative.opacity(0.2), AppTheme.positive.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 5)
                                let pct = (q.price - q.low) / (q.high - q.low)
                                let clampedPct = max(0, min(1, pct))
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 3, y: 1)
                                    .offset(x: geo.size.width * clampedPct - 6)
                            }
                        }
                        .frame(height: 12)
                    }
                }

                // 52-Week range bar
                if let w52H = week52High, let w52L = week52Low, w52H > w52L {
                    VStack(spacing: 4) {
                        HStack {
                            Text(String(format: "$%.2f", w52L))
                                .font(.caption2)
                                .foregroundColor(AppTheme.negative)
                            Spacer()
                            Text(L("52W Range"))
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                            Text(String(format: "$%.2f", w52H))
                                .font(.caption2)
                                .foregroundColor(AppTheme.positive)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.negative.opacity(0.2), AppTheme.positive.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 5)
                                let pct = (q.price - w52L) / (w52H - w52L)
                                let clampedPct = max(0, min(1, pct))
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 3, y: 1)
                                    .offset(x: geo.size.width * clampedPct - 6)
                            }
                        }
                        .frame(height: 12)
                    }
                }
            }
        }
    }

    // Helper: format volume from timestamp (we'll use quote change as proxy or fetch separately)
    private func formatVolume(_ ts: Int) -> String {
        // Finnhub free tier doesn't return volume in quote endpoint
        // Show "N/A" or use change as proxy indicator
        return "—"
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
                ForEach(companyNews.prefix(5)) { item in
                    NavigationLink(destination: NewsDetailView(url: item.url)) {
                        HStack(spacing: 10) {
                            AsyncImage(url: URL(string: item.image ?? "")) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 42).clipped().cornerRadius(6)
                                } else {
                                    RoundedRectangle(cornerRadius: 6).fill(AppTheme.subtleFill)
                                        .frame(width: 56, height: 42)
                                        .overlay(Image(systemName: "newspaper").font(.caption).foregroundColor(AppTheme.secondaryText))
                                }
                            }
                            Text(item.headline)
                                .font(.caption)
                                .foregroundColor(AppTheme.primaryText)
                                .lineLimit(2)
                            Spacer()
                        }
                    }
                    if item.id != companyNews.prefix(5).last?.id {
                        Divider()
                            .overlay(AppTheme.border.opacity(0.3))
                            .padding(.leading, 28)
                    }
                }
            }
        }
    }

    // ===========================
    // MARK: - Module 4: Options
    // ===========================
    @ViewBuilder
    private var optionsModule: some View {
        moduleCard("Options Activity", icon: "arrow.left.arrow.right") {
            Text(L("Options data requires a premium data subscription."))
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            // Placeholder layout showing concept
            HStack(spacing: 0) {
                // Calls side
                VStack(spacing: 6) {
                    Text(L("Calls"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.positive)
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.positive.opacity(0.08))
                            .frame(height: 28)
                            .overlay(
                                Text("—").font(.caption).foregroundColor(AppTheme.secondaryText)
                            )
                    }
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 100).padding(.horizontal, 8)

                // Puts side
                VStack(spacing: 6) {
                    Text(L("Puts"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.negative)
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.negative.opacity(0.08))
                            .frame(height: 28)
                            .overlay(
                                Text("—").font(.caption).foregroundColor(AppTheme.secondaryText)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
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
        VStack(alignment: .leading, spacing: 6) {
            Text(peer.symbol)
                .font(.system(size: 15, weight: .bold))
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

            Button(action: {
                Task {
                    FirebaseController.shared.addStockToWatchlist(symbol: peer.symbol)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text(L("Add"))
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppTheme.accent))
            }
        }
        .frame(width: 128)
        .padding(12)
        .themeCardSurface()
    }

    // ============================
    // MARK: - Module 6: Comments
    // ============================
    @ViewBuilder
    private var commentsModule: some View {
        moduleCard("Comments", icon: "bubble.left.and.bubble.right") {
            // Post comment
            HStack(spacing: 8) {
                TextField(L("Leave a comment..."), text: $commentText)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
                Button(action: postComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(commentText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.secondaryText : AppTheme.primaryText)
                }
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if comments.isEmpty {
                Text(L("No comments yet. Be the first!"))
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(AppTheme.secondaryText)
                                .font(.subheadline)
                            Text(comment.userName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            Text(commentTimeAgo(comment.timestamp))
                                .font(.caption2)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        Text(comment.text)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primaryText)
                    }
                    .padding(.vertical, 4)
                    if comment.id != comments.last?.id {
                        Divider()
                            .overlay(AppTheme.border.opacity(0.3))
                            .padding(.leading, 28)
                    }
                }

                NavigationLink(destination: AllCommentsView(symbol: symbol)) {
                    Text(L("View more comments"))
                        .font(.caption)
                        .foregroundColor(AppTheme.accent)
                }
                .padding(.top, 4)
            }
        }
    }

    private func postComment() {
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        FirebaseController.shared.postComment(symbol: symbol, text: text)
        commentText = ""
        // Reload comments
        Task {
            comments = await FirebaseController.shared.fetchComments(symbol: symbol)
        }
    }

    private func commentTimeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return L("just now") }
        if seconds < 3600 { return "\(seconds / 60)m" }
        if seconds < 86400 { return "\(seconds / 3600)h" }
        return "\(seconds / 86400)d"
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
        moduleCard("AI Decision Dashboard", icon: "sparkles") {
            if let d = aiDashboard {
                // ── Rating + Score Row ──
                HStack(spacing: 12) {
                    // Rating badge
                    Text(L(d.rating))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
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
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // ── Price Targets ──
                if d.entryPrice != nil || d.stopLoss != nil || d.targetPrice != nil {
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
                VStack(spacing: 6) {
                    HStack {
                        Text(L("Market Sentiment"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                        Text(L(d.sentimentLabel))
                            .font(.system(size: 12, weight: .semibold))
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
                                .shadow(color: sentimentColor(d.sentiment).opacity(0.4), radius: 3, y: 1)
                                .overlay(Circle().fill(sentimentColor(d.sentiment)).frame(width: 8, height: 8))
                                .offset(x: geo.size.width * CGFloat(max(0, min(1, pct))) - 7)
                        }
                    }
                    .frame(height: 14)
                }

                // ── Bull / Bear Points ──
                HStack(alignment: .top, spacing: 12) {
                    // Bull points
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(AppTheme.positive)
                            Text(L("Bullish Factors"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.positive)
                        }
                        ForEach(d.bullPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.positive)
                                Text(point)
                                    .font(.system(size: 11))
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
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(AppTheme.negative)
                            Text(L("Bearish Factors"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.negative)
                        }
                        ForEach(d.bearPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.negative)
                                Text(point)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // ── Deep Dive Link ──
                NavigationLink(destination: AIAnalysisView(symbol: symbol, name: name)) {
                    HStack {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 12))
                        Text(L("Ask Orion for deeper analysis"))
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.accent)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.accent.opacity(0.08))
                    )
                }
            } else if isLoadingDashboard {
                // Loading state
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(L("Generating AI analysis..."))
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    // Skeleton preview
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10).fill(AppTheme.subtleFill).frame(width: 80, height: 32)
                        Circle().fill(AppTheme.subtleFill).frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 6) {
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

    private func ratingColor(_ rating: String) -> Color {
        let r = rating.lowercased()
        if r.contains("buy") || r.contains("买") { return AppTheme.positive }
        if r.contains("sell") || r.contains("卖") { return AppTheme.negative }
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
                .font(.system(size: 10, weight: .medium))
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
    @ViewBuilder
    private var fundamentalsModule: some View {
        if let f = fundamentals, hasAnyFundamental(f) {
            moduleCard("Fundamentals", icon: "chart.bar.xaxis") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if let pe = f.peRatio { fundamentalRow("P/E", value: String(format: "%.1f", pe)) }
                    if let pb = f.pbRatio { fundamentalRow("P/B", value: String(format: "%.1f", pb)) }
                    if let eps = f.epsGrowth { fundamentalRow(L("EPS Growth"), value: String(format: "%.1f%%", eps), color: eps >= 0 ? AppTheme.positive : AppTheme.negative) }
                    if let rev = f.revenueGrowth { fundamentalRow(L("Revenue Growth"), value: String(format: "%.1f%%", rev), color: rev >= 0 ? AppTheme.positive : AppTheme.negative) }
                    if let dy = f.dividendYield { fundamentalRow(L("Div Yield"), value: String(format: "%.2f%%", dy)) }
                    if let beta = f.beta { fundamentalRow("Beta", value: String(format: "%.2f", beta)) }
                    if let roe = f.roe { fundamentalRow("ROE", value: String(format: "%.1f%%", roe), color: roe >= 0 ? AppTheme.positive : AppTheme.negative) }
                    if let de = f.debtToEquity { fundamentalRow("D/E", value: String(format: "%.1f", de)) }
                    if let gm = f.grossMargin { fundamentalRow(L("Gross Margin"), value: String(format: "%.1f%%", gm)) }
                    if let om = f.operatingMargin { fundamentalRow(L("Op Margin"), value: String(format: "%.1f%%", om)) }
                }
            }
        }
    }

    private func hasAnyFundamental(_ f: FundamentalMetrics) -> Bool {
        f.peRatio != nil || f.pbRatio != nil || f.epsGrowth != nil || f.revenueGrowth != nil ||
        f.dividendYield != nil || f.beta != nil || f.roe != nil
    }

    private func fundamentalRow(_ label: String, value: String, color: Color? = nil) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(AppTheme.number(14, weight: .semibold))
                .foregroundColor(color ?? AppTheme.primaryText)
        }
        .padding(.vertical, 2)
    }

    // =============================
    // MARK: - Existing sections
    // =============================
    @ViewBuilder
    private var intervalSelector: some View {
        HStack(spacing: 6) {
            ForEach(intervals, id: \.self) { interval in
                Button(interval) {
                    Haptic.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedInterval = interval
                    }
                    selectedEntry = nil
                    showMarker = false
                    Task { await loadChart() }
                }
                .font(.system(size: 13, weight: selectedInterval == interval ? .bold : .medium))
                .foregroundColor(selectedInterval == interval ? .white : AppTheme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    ZStack {
                        if selectedInterval == interval {
                            Capsule()
                                .fill(AppTheme.accent)
                                .matchedGeometryEffect(id: "intervalCapsule", in: intervalAnimation)
                        }
                    }
                )
                .contentShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    /// Splits a price string into (currency symbol, number) for typographic contrast
    private func splitPrice(_ value: Double, format: String = "%.2f") -> (symbol: String, number: String) {
        ("$", String(format: format, value))
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(AppTheme.serifTitle(24)).foregroundColor(AppTheme.primaryText)
            if let entry = selectedEntry, showMarker {
                // Chart drag: split $ sign
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("$")
                        .font(AppTheme.number(20, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(String(format: "%.2f", entry.close))
                        .font(AppTheme.number(32, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.05), value: entry.close)
                }
                Text(entry.datetime)
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.secondaryText)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.05), value: entry.datetime)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    // Split currency symbol from number
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("$")
                            .font(AppTheme.number(20, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText)
                        Text(priceString)
                            .font(AppTheme.number(32, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: currentPrice)
                    }
                    if let ch = intervalChange {
                        Text("\(AppTheme.changeArrow(ch.amount)) \(ch.amount >= 0 ? "+" : "")\(String(format: "%.2f", ch.amount)) (\(ch.percent >= 0 ? "+" : "")\(String(format: "%.2f%%", ch.percent)))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: ch.amount >= 0
                                            ? [AppTheme.positive, AppTheme.positive.opacity(0.85)]
                                            : [AppTheme.negative, AppTheme.negative.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                            .shadow(color: (ch.amount >= 0 ? AppTheme.positive : AppTheme.negative).opacity(0.3), radius: 4, y: 2)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: ch.percent)
                    }
                }
                HStack(spacing: 6) {
                    if marketSession == .closed || marketSession == .holiday {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.accent)
                    }
                    Text(marketStatusText).font(AppTheme.caption()).foregroundColor(AppTheme.secondaryText)
                    if let ext = extendedHoursChange {
                        Text("·").font(AppTheme.caption()).foregroundColor(AppTheme.secondaryText)
                        Text(String(format: "$%.2f", ext.price)).font(AppTheme.caption()).fontWeight(.medium).foregroundColor(AppTheme.primaryText)
                        Text(AppTheme.formattedChange(ext.percent))
                            .font(AppTheme.caption()).foregroundColor(ext.change >= 0 ? AppTheme.positive : AppTheme.negative)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(
            GeometryReader { geo in
                Color.clear.onChange(of: geo.frame(in: .named("scroll")).maxY) { _, newVal in
                    let isNowVisible = newVal > 0
                    if isNowVisible != headerVisible {
                        withAnimation(.easeInOut(duration: 0.2)) { headerVisible = isNowVisible }
                    }
                }
            }
        )
    }

    @ViewBuilder
    private var toolbarHeader: some View {
        HStack(spacing: 6) {
            Text(symbol).font(.headline).foregroundColor(AppTheme.primaryText)
            Text("$\(priceString)").font(AppTheme.number()).foregroundColor(AppTheme.secondaryText)
            if let ch = intervalChange {
                Text("\(ch.percent >= 0 ? "+" : "")\(String(format: "%.2f%%", ch.percent))")
                    .font(AppTheme.caption()).foregroundColor(ch.amount >= 0 ? AppTheme.positive : AppTheme.negative)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(AppTheme.barBackground).shadow(color: AppTheme.primaryText.opacity(0.08), radius: 2, y: 1))
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
            let minPrice = Double(chartEntries.map(\.close).min() ?? 0)
            let maxPrice = Double(chartEntries.map(\.close).max() ?? 0)
            let padding = (maxPrice - minPrice) * 0.1
            let isUp = (intervalChange?.amount ?? 0) >= 0
            let lineColor = isUp ? AppTheme.positive : AppTheme.negative

            ZStack {
                // The chart
                Chart {
                    ForEach(chartEntries) { entry in
                        AreaMark(
                            x: .value("Time", entry.index),
                            yStart: .value("Min", minPrice - padding),
                            yEnd: .value("Price", Double(entry.close))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [lineColor.opacity(0.2), lineColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    ForEach(chartEntries) { entry in
                        LineMark(x: .value("Time", entry.index), y: .value("Price", Double(entry.close)))
                            .foregroundStyle(lineColor)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                            .interpolationMethod(.catmullRom)
                    }

                    if let entry = selectedEntry, showMarker {
                        PointMark(x: .value("Time", entry.index), y: .value("Price", Double(entry.close)))
                            .foregroundStyle(AppTheme.primaryText).symbolSize(50)
                        RuleMark(x: .value("Time", entry.index))
                            .foregroundStyle(AppTheme.secondaryText.opacity(0.3)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: (minPrice - padding)...(maxPrice + padding))
                .chartLegend(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { _ in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // Dismiss hint on first touch
                                        if !hasUsedChartTouch {
                                            hasUsedChartTouch = true
                                            withAnimation(.easeOut(duration: 0.3)) { showChartHint = false }
                                        }
                                        if let index: Int = proxy.value(atX: value.location.x) {
                                            let previousEntry = selectedEntry
                                            if let entry = chartEntries.first(where: { $0.index == index }) {
                                                selectedEntry = entry; showMarker = true
                                            } else if let closest = chartEntries.min(by: { abs($0.index - index) < abs($1.index - index) }) {
                                                selectedEntry = closest; showMarker = true
                                            }
                                            // Haptic when moving to a different data point
                                            if selectedEntry?.index != previousEntry?.index {
                                                Haptic.selection()
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        showMarker = false; selectedEntry = nil
                                        Haptic.soft()
                                    }
                            )
                    }
                }

                // Live pulse dot at the last data point
                if selectedInterval == "1D" && marketSession == .open && !showMarker {
                    GeometryReader { geo in
                        let totalEntries = max(chartEntries.count - 1, 1)
                        if let lastEntry = chartEntries.last {
                            let xFrac = CGFloat(lastEntry.index - (chartEntries.first?.index ?? 0)) / CGFloat(totalEntries)
                            let yFrac = 1.0 - (Double(lastEntry.close) - (minPrice - padding)) / ((maxPrice + padding) - (minPrice - padding))
                            LivePulseDot(color: lineColor)
                                .position(x: xFrac * geo.size.width, y: yFrac * geo.size.height)
                        }
                    }
                    .allowsHitTesting(false)
                }

                // Touch hint overlay — only shown if user has never interacted
                if showChartHint && !showMarker {
                    chartHintOverlay(lineColor: lineColor)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

            }
            .frame(height: chartHeight)
            .padding(.horizontal, -16) // bleed to screen edges for immersive feel
            .clipped()
            .onAppear {
                if !hasUsedChartTouch {
                    // Delay slightly so chart renders first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeIn(duration: 0.6)) { showChartHint = true }
                        // Start pulse
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            hintPulse = true
                        }
                    }
                    // Auto-dismiss after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        withAnimation(.easeOut(duration: 0.8)) { showChartHint = false }
                    }
                }
            }
        }
    }

    // MARK: - Chart Touch Hint
    @ViewBuilder
    private func chartHintOverlay(lineColor: Color) -> some View {
        GeometryReader { geo in
            // Position the hint at roughly 60% along the x-axis on the chart line
            let targetIndex = Int(Double(chartEntries.count) * 0.6)
            let entry = chartEntries.indices.contains(targetIndex) ? chartEntries[targetIndex] : chartEntries.last

            if let entry = entry {
                let minP = Double(chartEntries.map(\.close).min() ?? 0)
                let maxP = Double(chartEntries.map(\.close).max() ?? 0)
                let pad = (maxP - minP) * 0.1
                let totalEntries = max(chartEntries.count - 1, 1)

                let xFraction = CGFloat(entry.index - (chartEntries.first?.index ?? 0)) / CGFloat(totalEntries)
                let yFraction = 1.0 - (Double(entry.close) - (minP - pad)) / ((maxP + pad) - (minP - pad))

                let dotX = xFraction * geo.size.width
                let dotY = yFraction * geo.size.height

                // Pulsing dot on the line
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .fill(lineColor.opacity(0.15))
                        .frame(width: hintPulse ? 36 : 20, height: hintPulse ? 36 : 20)
                    Circle()
                        .fill(lineColor.opacity(0.3))
                        .frame(width: hintPulse ? 22 : 14, height: hintPulse ? 22 : 14)
                    // Inner dot
                    Circle()
                        .fill(lineColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: lineColor.opacity(0.6), radius: 4)
                }
                .position(x: dotX, y: dotY)

                // Floating label below the dot
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 10))
                    Text(L("Touch to explore"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: AppTheme.primaryText.opacity(0.08), radius: 6, y: 2)
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                .position(
                    x: min(max(dotX, 70), geo.size.width - 70),
                    y: min(dotY + 32, geo.size.height - 16)
                )
            }
        }
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

    private func loadAllModules() async {
        // Only load stock-specific modules for actual stocks
        // Crypto/metals don't have analyst ratings, peers, or company profiles
        async let commentsTask: () = loadComments()
        async let newsTask: () = loadCompanyNews()

        if isStock {
            async let recTask: () = loadRecommendation()
            async let peersTask: () = loadPeers()
            async let profileTask: () = loadCompanyProfile()
            async let week52Task: () = loadWeek52Range()
            async let fundamentalsTask: () = loadFundamentals()
            _ = await (recTask, newsTask, peersTask, profileTask, commentsTask, week52Task, fundamentalsTask)
            // Load AI dashboard after news & fundamentals are ready (needs them as input)
            await loadAIDashboard()
        } else {
            _ = await (newsTask, commentsTask)
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
    private func loadAIDashboard() async {
        await MainActor.run { isLoadingDashboard = true }
        do {
            let dashboard = try await APIService.shared.fetchAIDecisionDashboard(
                symbol: symbol,
                name: name,
                price: currentPrice,
                quote: quote,
                metrics: fundamentals,
                news: companyNews
            )
            await MainActor.run {
                aiDashboard = dashboard
                isLoadingDashboard = false
            }
        } catch {
            await MainActor.run { isLoadingDashboard = false }
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
                    withAnimation { if let last = chatMessages.last { proxy.scrollTo(last.id, anchor: .bottom) } }
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
                    withAnimation(.easeInOut(duration: 0.2)) { currentTone = tone }
                    Task { await loadAnalysis() }
                }
                .font(.system(size: 13, weight: currentTone == tone ? .bold : .medium))
                .foregroundColor(currentTone == tone ? .white : AppTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(currentTone == tone ? AppTheme.accent : AppTheme.subtleFill))
                .overlay(Capsule().stroke(currentTone == tone ? Color.clear : AppTheme.border, lineWidth: 0.5))
            }
            Spacer()
            Button(action: { Task { await loadAnalysis() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accent)
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
                .frame(maxWidth: .infinity).padding(.top, 40)
        } else if hasLoaded {
            if !aiHeadlines.isEmpty { Text(aiHeadlines).font(AppTheme.caption()).foregroundColor(AppTheme.secondaryText).padding(.horizontal, 16) }
            MarkdownText(text: aiAnalysis).font(.body).foregroundColor(AppTheme.primaryText).padding(.horizontal, 16)
        }
    }

    @ViewBuilder private var imagePreview: some View {
        HStack(spacing: 8) {
            if let d = attachedImageData, let ui = UIImage(data: d) {
                Image(uiImage: ui).resizable().scaledToFill().frame(width: 48, height: 48).cornerRadius(8).clipped()
                Text(L("Photo attached")).font(AppTheme.caption()).foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            Button(action: { attachedImageData = nil; selectedPhoto = nil }) {
                Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.secondaryText)
            }
        }.padding(.horizontal, 16).padding(.vertical, 6).background(AppTheme.subtleFill)
    }

    @ViewBuilder private var inputBar: some View {
        HStack(spacing: 6) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo").font(.system(size: 20)).foregroundColor(AppTheme.secondaryText)
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
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                if let d = message.imageData, let ui = UIImage(data: d) {
                    Image(uiImage: ui).resizable().scaledToFit().frame(maxWidth: 220, maxHeight: 200).cornerRadius(12)
                }
                if !message.content.isEmpty {
                    Group { if isUser { Text(message.content) } else { MarkdownText(text: message.content) } }
                        .padding(12).background(isUser ? AppTheme.accent.opacity(0.15) : AppTheme.subtleFill)
                        .foregroundColor(AppTheme.primaryText).cornerRadius(16)
                }
            }
            .frame(maxWidth: isUser ? 280 : .infinity, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer() }
        }
    }
}
