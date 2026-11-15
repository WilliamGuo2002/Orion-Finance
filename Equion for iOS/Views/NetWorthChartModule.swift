import SwiftUI
import Charts

// MARK: - Institution colors
/// Categorical palette for per-institution lines. Validated (dataviz validate_palette.js) against
/// the app surfaces: light #f4f1ed and dark #1c1815 — lightness, chroma, CVD separation and
/// normal-vision floor all pass. Light-mode contrast is below 3:1 for some slots, so every line
/// is also named with its value in the legend (never color alone).
/// Green and red are left out on purpose: the app uses them for gains and losses.
enum InstitutionPalette {
    private static let light: [UInt32] = [0x2a78d6, 0xeb6834, 0x1baf7a, 0xeda100, 0xe87ba4, 0x6250d6]
    private static let dark: [UInt32]  = [0x3987e5, 0xd95926, 0x199e70, 0xc98500, 0xd55181, 0x9085e9]
    static let slots = light.count
    /// Folded series beyond the palette ("Other").
    static let other = Color(uiColor: .systemGray)

    static func color(_ slot: Int) -> Color {
        let l = light[slot % slots], d = dark[slot % slots]
        return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? uiColor(d) : uiColor(l) })
    }

    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255, alpha: 1)
    }
}

// MARK: - Net Worth chart module (Accounts page)
/// Value + chart + range picker for the Accounts page. Tapping the split button turns the single
/// net-worth line into one line per institution (brokerage / bank) with a legend; scrubbing the
/// chart shows every institution's value at that moment.
struct NetWorthChartModule: View {
    @ObservedObject private var manager = HoldingsManager.shared
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false
    @AppStorage("netWorthSplitByInstitution") private var split = false

    @State private var range = "1M"
    @State private var entries: [PortfolioValueEntry] = []
    @State private var isLoading = false
    @State private var selectedIndex: Int?

    private static let ranges = ["1D", "5D", "1M", "6M", "1Y"]

    /// One line per institution. Colors are assigned by name (alphabetical), so an institution
    /// keeps its color when values change; beyond the palette, the rest fold into "Other".
    private struct Series: Identifiable {
        let id: String          // institution name, or "__other"
        let name: String
        let color: Color
        let members: [String]   // institutions summed into this line
        func value(_ e: PortfolioValueEntry) -> Double { members.reduce(0) { $0 + (e.breakdown[$1] ?? 0) } }
    }

    private var series: [Series] {
        let names = Set(entries.flatMap { $0.breakdown.keys }).sorted()
        guard names.count > InstitutionPalette.slots else {
            return names.enumerated().map { Series(id: $1, name: $1, color: InstitutionPalette.color($0), members: [$1]) }
        }
        let keep = Array(names.prefix(InstitutionPalette.slots - 1))
        let rest = Array(names.dropFirst(InstitutionPalette.slots - 1))
        return keep.enumerated().map { Series(id: $1, name: $1, color: InstitutionPalette.color($0), members: [$1]) }
            + [Series(id: "__other", name: L("Other"), color: InstitutionPalette.other, members: rest)]
    }

    private var selected: PortfolioValueEntry? { selectedIndex.flatMap { entries[safe: $0] } }

    var body: some View {
        let snap = manager.snapshot
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L("Net Worth"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
                Spacer()
                CurrencyToggle(selected: snap.displayCurrency)
                HideValuesButton()
            }

            valueHeader(snap)
            }
            .padding(.horizontal, 20)

            // Edge to edge: no side padding, the plot spans the full screen width.
            chartArea
                .frame(height: 180)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
            controls

            if split && !entries.isEmpty {
                legend(snap)
            }

            if snap.aggregated.contains(where: { $0.currency != snap.displayCurrency })
                || BankManager.shared.currentAccounts.contains(where: { $0.currency != snap.displayCurrency }) {
                Text(L("Converted at live exchange rates"))
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
            }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 6)
        .task(id: range) { await reload() }
        // New balances (sync / link / unlink) → redraw. Currency changes don't need new data:
        // entries are USD and converted at display time.
        .onChange(of: manager.snapshot.accountValues) { _, _ in Task { await reload() } }
    }

    private func reload() async {
        isLoading = entries.isEmpty
        let fresh = await manager.computeChart(range: range)
        entries = fresh
        selectedIndex = nil
        isLoading = false
    }

    // MARK: Header

    private func signed(_ usd: Double, _ snap: HoldingsSnapshot) -> String {
        (usd < 0 ? "-" : "") + snap.format(abs(usd))
    }

    @ViewBuilder
    private func valueHeader(_ snap: HoldingsSnapshot) -> some View {
        if hideValues {
            Text(PortfolioPrivacy.mask)
                .font(AppTheme.number(28, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
            Text("\(PortfolioPrivacy.shortMask) (\(PortfolioPrivacy.shortMask))")
                .font(AppTheme.number(13, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText)
        } else {
            let value = selected?.value ?? snap.totalValue
            Text(signed(value, snap))
                .font(AppTheme.number(28, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
                .contentTransition(.numericText())

            // Change over the visible range (to the scrubbed point, or to now)
            if let first = entries.first {
                let change = value - first.value
                let pct = abs(first.value) > 0.005 ? change / abs(first.value) * 100 : 0
                HStack(spacing: 6) {
                    Text(String(format: "%@%@ (%@%.2f%%)", change >= 0 ? "+" : "-", snap.format(abs(change)),
                                pct >= 0 ? "+" : "", pct))
                        .font(AppTheme.number(13, weight: .semibold))
                        .foregroundColor(change >= 0 ? AppTheme.positive : AppTheme.negative)
                        .contentTransition(.numericText())
                    Text(selected?.datetime ?? rangeLabel)
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    private var rangeLabel: String {
        switch range {
        case "1D": return L("Today")
        case "5D": return L("Past 5 days")
        case "1M": return L("Past month")
        case "6M": return L("Past 6 months")
        default:   return L("Past year")
        }
    }

    // MARK: Chart

    @ViewBuilder
    private var chartArea: some View {
        if hideValues {
            PortfolioChartPlaceholder()
        } else if entries.isEmpty {
            ZStack {
                if isLoading { ProgressView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            chart
                .chartOverlay { _ in
                    GeometryReader { geo in
                        Color.clear
                            .contentShape(Rectangle())
                            // Horizontal drags scrub; vertical drags still scroll the page.
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 8)
                                    .onChanged { g in
                                        guard abs(g.translation.width) > abs(g.translation.height) || selectedIndex != nil,
                                              entries.count > 1, geo.size.width > 0 else { return }
                                        let ratio = max(0, min(1, g.location.x / geo.size.width))
                                        let idx = Int((ratio * Double(entries.count - 1)).rounded())
                                        if idx != selectedIndex {
                                            // Same quick transaction as home, so numericText rolls the digits
                                            withAnimation(.easeInOut(duration: 0.05)) { selectedIndex = idx }
                                            Haptic.selection()
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeOut(duration: 0.15)) { selectedIndex = nil }
                                    }
                            )
                    }
                }
        }
    }

    private var chart: some View {
        let lines = series
        let values: [Double] = split
            ? entries.flatMap { e in lines.map { $0.value(e) } }
            : entries.map(\.value)
        let minY = values.min() ?? 0, maxY = values.max() ?? 0
        let pad = max((maxY - minY) * 0.1, 1)
        let change = (entries.last?.value ?? 0) - (entries.first?.value ?? 0)
        let totalColor = change >= 0 ? AppTheme.positive : AppTheme.negative

        return Chart {
            if split {
                ForEach(lines) { line in
                    ForEach(entries) { e in
                        // Fading fill under each line (unstacked: each from the chart floor)
                        AreaMark(
                            x: .value("Time", e.index),
                            yStart: .value("Min", minY - pad),
                            yEnd: .value("Value", line.value(e)),
                            series: .value("Institution", line.id)
                        )
                        .foregroundStyle(LinearGradient(colors: [line.color.opacity(0.12), line.color.opacity(0)],
                                                        startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", e.index),
                            y: .value("Value", line.value(e)),
                            series: .value("Institution", line.id)
                        )
                        .foregroundStyle(line.color)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
            } else {
                ForEach(entries) { e in
                    AreaMark(
                        x: .value("Time", e.index),
                        yStart: .value("Min", minY - pad),
                        yEnd: .value("Value", e.value)
                    )
                    .foregroundStyle(LinearGradient(colors: [totalColor.opacity(0.15), totalColor.opacity(0)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)

                    LineMark(x: .value("Time", e.index), y: .value("Value", e.value), series: .value("Series", "total"))
                        .foregroundStyle(totalColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                }
            }

            // Scrub: vertical rule + a ringed dot on every line
            if let e = selected {
                RuleMark(x: .value("Time", e.index))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                if split {
                    ForEach(lines) { line in
                        PointMark(x: .value("Time", e.index), y: .value("Value", line.value(e)))
                            .symbol { ringedDot(line.color) }
                    }
                } else {
                    PointMark(x: .value("Time", e.index), y: .value("Value", e.value))
                        .symbol { ringedDot(totalColor) }
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: (minY - pad)...(maxY + pad))
        .chartXScale(range: .plotDimension)
        .animation(.easeInOut(duration: 0.25), value: split)
    }

    private func ringedDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 4) {
            ForEach(Self.ranges, id: \.self) { r in
                Button {
                    guard r != range else { return }
                    Haptic.selection()
                    range = r
                } label: {
                    Text(r)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(range == r ? AppTheme.onAccent : AppTheme.secondaryText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(range == r ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.subtleFill))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button {
                Haptic.selection()
                withAnimation(.easeInOut(duration: 0.25)) { split.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: split ? "chart.line.uptrend.xyaxis" : "square.stack.3d.up")
                        .font(.system(size: 11, weight: .semibold))
                    Text(split ? L("Total") : L("By institution"))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(split ? AppTheme.onAccent : AppTheme.accentText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(split ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.accent.opacity(0.12))))
            }
            .buttonStyle(.plain)
            .disabled(series.count < 2 && !split)
            .opacity(series.count < 2 && !split ? 0.4 : 1)
            .accessibilityLabel(split ? L("Show total") : L("Split by institution"))
        }
    }

    // MARK: Legend

    /// Always shown in split mode: name + value per line, so identity never relies on color alone.
    private func legend(_ snap: HoldingsSnapshot) -> some View {
        let point = selected ?? entries.last
        let rows = series.map { ($0, point.map($0.value) ?? 0) }.sorted { $0.1 > $1.1 }
        return VStack(spacing: 8) {
            ForEach(rows, id: \.0.id) { line, value in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(line.color)
                        .frame(width: 14, height: 3)
                    Text(line.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(1)
                    Spacer()
                    Text(hideValues ? PortfolioPrivacy.shortMask : signed(value, snap))
                        .font(AppTheme.number(13, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .contentTransition(.numericText())
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(12)
        .themeCardSurface()
        .padding(.top, 4)
    }
}
