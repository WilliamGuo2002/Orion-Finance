import SwiftUI
import Observation

// MARK: - Starter picks ("You might be interested in")
/// What a new user sees instead of an empty watchlist: a short, live list of well-known names
/// with one-tap add. From the user's interests when they picked some; otherwise a broad default
/// (US large caps, the two index ETFs, two large Canadian names). Facts only — price, today's
/// move, a sparkline — and labelled "not a recommendation".
///
/// Loaded once per launch into a shared model, so the list doesn't reload when home switches
/// from its empty layout to the watchlist layout after the first add.
@MainActor
@Observable
final class StarterPicksModel {
    static let shared = StarterPicksModel()

    struct Pick: Identifiable {
        var id: String { symbol }
        let symbol: String
        let name: String
        let price: Double
        let changePercent: Double
        let chart: [ChartEntry]
    }

    private(set) var picks: [Pick] = []
    private(set) var isLoading = false
    private(set) var failed = false
    private(set) var fromInterests = false
    private var loaded = false

    private static let defaults: [(String, String)] = [
        ("AAPL", "Apple"), ("NVDA", "NVIDIA"), ("MSFT", "Microsoft"), ("SPY", "SPDR S&P 500 ETF"),
        ("SHOP", "Shopify"), ("RY", "Royal Bank of Canada"), ("AMZN", "Amazon"), ("QQQ", "Invesco QQQ"),
    ]

    /// Starts the load in its own task. Not tied to a view's `.task`: home swaps layouts (skeleton →
    /// empty → list) while this runs, and a view-scoped task would be cancelled mid-flight — every
    /// request failing with "cancelled" and the section wrongly showing its error fallback.
    func loadIfNeeded() {
        guard !loaded, !isLoading else { return }
        isLoading = true
        failed = false
        Task { await load() }
    }

    private func load() async {
        defer { isLoading = false }

        let interests = InterestsManager.shared
        let candidates: [(String, String)]
        if !interests.selectedInterests.isEmpty {
            candidates = interests.recommendedSymbols(excluding: []).prefix(8).map { ($0.symbol, $0.name) }
            fromInterests = !candidates.isEmpty
        } else {
            candidates = []
        }
        let list = candidates.isEmpty ? Self.defaults : candidates

        let results: [Int: Pick] = await withTaskGroup(of: (Int, Pick?).self) { group in
            for (i, item) in list.enumerated() {
                group.addTask {
                    guard let cq = try? await APIService.shared.fetchChartAndQuote(symbol: item.0) else { return (i, nil) }
                    return (i, Pick(symbol: item.0, name: item.1, price: cq.price,
                                    changePercent: PriceChange.dailyPercent(price: cq.price, previousClose: cq.previousClose),
                                    chart: cq.chartData))
                }
            }
            var out: [Int: Pick] = [:]
            for await (i, pick) in group { if let pick { out[i] = pick } }
            return out
        }
        picks = results.keys.sorted().compactMap { results[$0] }   // keep the list's own order
        failed = picks.isEmpty
        loaded = !picks.isEmpty
    }
}

struct StarterPicksSection<Fallback: View>: View {
    let title: String
    /// Symbols already in the watchlist (shown with a check, not hidden, so an add is visibly acknowledged).
    let watchlist: Set<String>
    let pending: [String]
    var maxRows: Int = 8
    let onAdd: (String) -> Void
    var onSearch: (() -> Void)? = nil
    @ViewBuilder var fallback: () -> Fallback

    private var model: StarterPicksModel { .shared }

    var body: some View {
        if model.failed {
            fallback()
        } else {
            VStack(alignment: .leading, spacing: AppTheme.Space.m) {
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(title)
                        .font(AppTheme.serifHeadline(20))
                        .foregroundColor(AppTheme.primaryText)
                    Text(model.fromInterests
                         ? L("From your interests · not a recommendation")
                         : L("Well-known names to start a watchlist · not a recommendation"))
                        .font(.footnote)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal, AppTheme.Space.xs)

                VStack(spacing: 0) {
                    if model.picks.isEmpty {
                        ForEach(0..<4, id: \.self) { i in
                            placeholderRow
                            if i < 3 { divider }
                        }
                    } else {
                        let rows = Array(model.picks.prefix(maxRows))
                        ForEach(Array(rows.enumerated()), id: \.element.id) { i, pick in
                            NavigationLink(destination: StockDetailView(symbol: pick.symbol, name: pick.name)) {
                                row(pick)
                            }
                            .buttonStyle(.plain)
                            if i < rows.count - 1 { divider }
                        }
                    }

                    if let onSearch {
                        divider
                        Button(action: onSearch) {
                            HStack(spacing: AppTheme.Space.s) {
                                Image(systemName: "magnifyingglass")
                                Text(L("Search for any stock or fund"))
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.accentText)
                            .padding(.horizontal, AppTheme.Space.l)
                            .frame(minHeight: 48)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .themeCardSurface()
            }
            .padding(.horizontal, AppTheme.Space.l)
            .onAppear { model.loadIfNeeded() }
        }
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.border).frame(height: 0.5).padding(.leading, AppTheme.Space.l)
    }

    private func row(_ pick: StarterPicksModel.Pick) -> some View {
        let key = pick.symbol.uppercased()
        let added = watchlist.contains(key)
        let adding = pending.contains(key)
        let up = pick.changePercent >= 0
        return HStack(spacing: AppTheme.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(MyHoldingView.displaySymbol(pick.symbol))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(pick.name)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Sparkline(pick.chart, color: up ? AppTheme.positive : AppTheme.negative, lineWidth: 1.25, fillOpacity: 0.12)
                .frame(width: 52, height: 24)

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", pick.price))
                    .font(AppTheme.number(15))
                    .foregroundColor(AppTheme.primaryText)
                ChangeBadge(value: pick.changePercent, size: .compact)
            }
            .frame(minWidth: 72, alignment: .trailing)

            Button {
                guard !added, !adding else { return }
                onAdd(pick.symbol)
            } label: {
                ZStack {
                    Circle().fill(added ? AppTheme.subtleFill : AppTheme.accent.opacity(0.14))
                    if adding {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: added ? "checkmark" : "plus")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(added ? AppTheme.secondaryText : AppTheme.accentText)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .frame(width: 32, height: 32)
                .expandedHitArea(6)
            }
            .buttonStyle(.plain)
            .disabled(added)
            .accessibilityLabel(added ? String(format: L("%@ added to watchlist"), pick.symbol)
                                      : String(format: L("Add %@ to watchlist"), pick.symbol))
        }
        .padding(.horizontal, AppTheme.Space.l)
        .padding(.vertical, AppTheme.Space.m)
        .contentShape(Rectangle())
        .animation(Motion.tap, value: added)
        .animation(Motion.tap, value: adding)
    }

    private var placeholderRow: some View {
        HStack(spacing: AppTheme.Space.m) {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(width: 52, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(width: 110, height: 10)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 4).fill(AppTheme.subtleFill).frame(width: 64, height: 24)
            Circle().fill(AppTheme.subtleFill).frame(width: 32, height: 32)
        }
        .padding(.horizontal, AppTheme.Space.l)
        .padding(.vertical, AppTheme.Space.m)
        .shimmer()
        .accessibilityHidden(true)
    }
}
