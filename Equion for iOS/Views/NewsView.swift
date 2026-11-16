import SwiftUI

struct NewsView: View {
    /// What the feed shows. "Your watchlist" pulls company news for the symbols you follow.
    enum Feed: String, CaseIterable, Identifiable {
        case top, watchlist, deals, crypto
        var id: String { rawValue }
        var label: String {
            switch self {
            case .top: return L("Top stories")
            case .watchlist: return L("Your watchlist")
            case .deals: return L("Deals")
            case .crypto: return L("Crypto")
            }
        }
    }

    @State private var feed: Feed = .top
    @State private var newsList: [NewsItem] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var orionSummaryItem: NewsItem?
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    private var isWide: Bool { hSize == .regular || vSize == .compact }

    private var gridColumns: [GridItem] {
        if isWide {
            return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        }
        return [GridItem(.flexible())]
    }


    var body: some View {
        VStack(spacing: 0) {
            // Header — pull to refresh does the same as the button; the button stays for discoverability.
            PageHeader(title: L("News"),
                       subtitle: Date.now.formatted(.dateTime.month(.wide).day().locale(AppLocale.current))) {
                HeaderIconButton(systemImage: "arrow.clockwise", label: L("Refresh")) {
                    Task { await loadNews() }
                }
            }
            feedPicker
                .padding(.bottom, 4)

            // News list — card style matching watchlist
            if isLoading && newsList.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonNewsCard()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            } else if let error = loadError, newsList.isEmpty {
                Spacer()
                ErrorStateView(
                    message: error,
                    retryAction: { Task { await loadNews() } }
                )
                .padding(.horizontal, 32)
                Spacer()
            } else if newsList.isEmpty && !isLoading {
                Spacer()
                VStack(spacing: 8) {
                    Text(feed == .watchlist ? L("No recent stories for your watchlist") : L("No stories right now"))
                        .font(AppTheme.serifHeadline(17))
                        .foregroundColor(AppTheme.primaryText)
                    if feed == .watchlist {
                        Text(L("Add stocks to your watchlist to see news about them here."))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(newsList) { item in
                            NavigationLink(destination: NewsDetailView(url: item.url)) {
                                NewsCardView(item: item)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if let url = URL(string: item.url) {
                                    ShareLink(item: url) {
                                        Label(L("Share"), systemImage: "square.and.arrow.up")
                                    }

                                    Button {
                                        UIPasteboard.general.string = item.url
                                    } label: {
                                        Label(L("Copy Link"), systemImage: "link")
                                    }
                                }

                                Divider()

                                Button {
                                    orionSummaryItem = item
                                } label: {
                                    Label(L("Summarize with Orion"), systemImage: "sparkles")
                                }
                            }

                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .refreshable { await loadNews() }
            }
        }
        .background(AppTheme.background)
        .task {
            await loadNews()
        }
        .sheet(item: $orionSummaryItem) { item in
            OrionSummarySheet(newsItem: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func loadNews() async {
        isLoading = true
        loadError = nil
        do {
            let items: [NewsItem]
            switch feed {
            case .top: items = try await APIService.shared.fetchNews(category: "general")
            case .deals: items = try await APIService.shared.fetchNews(category: "merger")
            case .crypto: items = try await APIService.shared.fetchNews(category: "crypto")
            case .watchlist: items = await watchlistNews()
            }
            await MainActor.run {
                newsList = items
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }
}

extension NewsView {
    /// Company news for up to 8 followed symbols, newest first, de-duplicated by headline.
    func watchlistNews() async -> [NewsItem] {
        let symbols = Array(await FirebaseController.shared.getWatchlistSymbols().prefix(8))
        guard !symbols.isEmpty else { return [] }
        let batches = await withTaskGroup(of: [NewsItem].self, returning: [[NewsItem]].self) { group in
            for sym in symbols {
                group.addTask { (try? await APIService.shared.fetchCompanyNews(symbol: sym))?.prefix(6).map { $0 } ?? [] }
            }
            var all: [[NewsItem]] = []
            for await b in group { all.append(b) }
            return all
        }
        var seen = Set<String>()
        return batches.flatMap { $0 }
            .sorted { ($0.datetime ?? 0) > ($1.datetime ?? 0) }
            .filter { seen.insert($0.headline).inserted }
    }

    /// Feed chooser — neutral selection, same style as Market Overview.
    var feedPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Feed.allCases) { f in
                    let selected = feed == f
                    Button {
                        guard !selected else { return }
                        withAnimation(Motion.tap) { feed = f }
                        newsList = []
                        Task { await loadNews() }
                    } label: {
                        Text(f.label)
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
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - News Card View (matches watchlist card style)
struct NewsCardView: View {
    let item: NewsItem


    var body: some View {
        HStack(spacing: 12) {
            // News image
            RemoteImage(url: item.image.flatMap(URL.init(string:))) {
                placeholderImage
            }
            .frame(width: 80, height: 64)

            // Title & source
            VStack(alignment: .leading, spacing: 8) {
                Text(item.headline)
                    .font(.system(.subheadline))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 4) {
                    if let source = item.source, !source.isEmpty {
                        Text(source)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(1)
                        Text("·")
                            .font(.footnote)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    if let ts = item.datetime {
                        Text(timeString(from: ts))
                            .font(.footnote)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }

            Spacer(minLength: 0)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(.caption))
                .foregroundColor(AppTheme.tertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .themeCardSurface()
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(AppTheme.subtleFill)
            .frame(width: 80, height: 64)
            .overlay {
                Image(systemName: "newspaper")
                    .font(.system(.title3))
                    .foregroundColor(AppTheme.tertiaryText)
            }
    }

    /// "2 hr ago" / "Nov 13" in the app's language.
    private func timeString(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        if Date().timeIntervalSince(date) < 86_400 {
            let f = RelativeDateTimeFormatter()
            f.unitsStyle = .short
            f.locale = AppLocale.current
            return f.localizedString(for: date, relativeTo: Date())
        }
        return date.formatted(.dateTime.month(.abbreviated).day().locale(AppLocale.current))
    }
}

// MARK: - Orion AI Summary Sheet
struct OrionSummarySheet: View {
    let newsItem: NewsItem
    @State private var summary = ""
    @State private var isLoading = true
    @State private var loadError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Original headline
                    Text(newsItem.headline)
                        .font(AppTheme.serifHeadline(17))
                        .foregroundColor(AppTheme.primaryText)

                    Divider()

                    if isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(L("Orion is reading the article..."))
                                .font(AppTheme.caption(14))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 20)
                    } else if let error = loadError {
                        ErrorStateView(
                            message: error,
                            retryAction: { Task { await loadSummary() } }
                        )
                    } else {
                        // AI icon + summary
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(.subheadline))
                                .foregroundColor(AppTheme.accentText)
                                .padding(.top, 2)
                            Text(summary)
                                .font(AppTheme.body(15))
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle(L("Orion Summary"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
        }
        .task {
            await loadSummary()
        }
    }

    private func loadSummary() async {
        isLoading = true
        loadError = nil
        do {
            let prompt = "Please summarize this news article in 3-4 concise bullet points. Article title: \"\(newsItem.headline)\". Article URL: \(newsItem.url). Respond in the same language as the title."
            let result = try await APIService.shared.sendGeminiMessage(text: prompt)
            await MainActor.run {
                summary = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }
}
