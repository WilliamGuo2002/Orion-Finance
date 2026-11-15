import SwiftUI

struct NewsView: View {
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
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(Array(newsList.enumerated()), id: \.element.id) { index, item in
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
                                        Haptic.tap()
                                    } label: {
                                        Label(L("Copy Link"), systemImage: "link")
                                    }
                                }

                                Divider()

                                Button {
                                    Haptic.light()
                                    orionSummaryItem = item
                                } label: {
                                    Label(L("Summarize with Orion"), systemImage: "sparkles")
                                }
                            }

                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 80)
                }
                .refreshable { await loadNews() }
                .tracksTabBarCollapse()
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
            let items = try await APIService.shared.fetchNews()
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

                HStack(spacing: 8) {
                    if let ts = item.datetime {
                        Text(timeString(from: ts))
                            .font(AppTheme.caption(11))
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
                Haptic.soft()
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
                Haptic.error()
            }
        }
    }
}
