import SwiftUI
import Charts

// MARK: - Chart display settings
/// How the stock chart is drawn. One app-wide choice (remembered), set from the button beside the
/// range picker.
enum ChartDisplay {
    static let styleKey = "chartStyle"
    static let volumeKey = "chartVolumeStyle"

    enum Style: String, CaseIterable, Identifiable {
        case line, candles
        var id: String { rawValue }
        var title: String { self == .line ? L("Line") : L("Candles") }
    }

    enum Volume: String, CaseIterable, Identifiable {
        case off, mono, upDown
        var id: String { rawValue }
        var title: String {
            switch self {
            case .off: return L("Hidden")
            case .mono: return L("Single color")
            case .upDown: return L("Up / down colors")
            }
        }
    }
}

// MARK: - Orion candles
/// Our candlestick style, drawn on the chart's own scales:
/// - up candles are hollow (an outline in the gain color), down candles are solid — the eye reads
///   direction from shape, not only from red/green;
/// - hairline wicks that stop at the body instead of running through it;
/// - softly rounded bodies; a doji (open ≈ close) is a neutral tick, not a colored sliver;
/// - while scrubbing, every candle but the focused one steps back.
/// Narrow candles (long ranges) are filled either way, since a 2pt outline reads as noise.
struct OrionCandles: View {
    /// Horizontal inset so edge candles are whole (half the widest body plus a hair).
    static func edgeInset(count: Int) -> CGFloat {
        count > 40 ? 3 : 6
    }

    let entries: [ChartEntry]
    let proxy: ChartProxy
    var focused: Int?

    var body: some View {
        GeometryReader { geo in
            let plot = geo[proxy.plotFrame!]
            Canvas { ctx, _ in
                guard entries.count > 0 else { return }
                let step = plot.width / CGFloat(max(entries.count - 1, 1))
                let bodyW = min(max(step * 0.62, 1.5), 9)
                let hollowOK = bodyW >= 3
                let radius = min(bodyW / 2, 1.5)

                for e in entries {
                    guard let x0 = proxy.position(forX: e.index),
                          let yO = proxy.position(forY: Double(e.o)),
                          let yC = proxy.position(forY: Double(e.close)),
                          let yH = proxy.position(forY: Double(e.h)),
                          let yL = proxy.position(forY: Double(e.l)) else { continue }
                    let x = x0 + plot.minX
                    let top = min(yO, yC) + plot.minY, bottom = max(yO, yC) + plot.minY
                    let high = yH + plot.minY, low = yL + plot.minY
                    let dimmed = focused != nil && focused != e.index
                    let isDoji = bottom - top < 0.75   // body thinner than a hairline
                    let base: Color = isDoji ? AppTheme.secondaryText : (e.isUp ? AppTheme.positive : AppTheme.negative)
                    let color = base.opacity(dimmed ? 0.3 : 1)

                    // Wicks: above and below the body only.
                    var wick = Path()
                    wick.move(to: CGPoint(x: x, y: high)); wick.addLine(to: CGPoint(x: x, y: top))
                    wick.move(to: CGPoint(x: x, y: bottom)); wick.addLine(to: CGPoint(x: x, y: low))
                    ctx.stroke(wick, with: .color(color.opacity(0.8)), style: StrokeStyle(lineWidth: 1, lineCap: .round))

                    if isDoji {
                        var tick = Path()
                        tick.move(to: CGPoint(x: x - bodyW / 2, y: top))
                        tick.addLine(to: CGPoint(x: x + bodyW / 2, y: top))
                        ctx.stroke(tick, with: .color(color), style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
                        continue
                    }

                    let rect = CGRect(x: x - bodyW / 2, y: top, width: bodyW, height: max(bottom - top, 1))
                    let shape = Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
                    if e.isUp && hollowOK {
                        let inset = rect.insetBy(dx: 0.6, dy: 0.6)
                        ctx.stroke(Path(roundedRect: inset, cornerRadius: max(radius - 0.6, 0), style: .continuous),
                                   with: .color(color), lineWidth: 1.2)
                    } else {
                        ctx.fill(shape, with: .color(color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Settings sheet
/// Chart type and volume style, each as a row of small live previews. Changes apply immediately —
/// the chart stays visible above the half-height sheet.
struct ChartDisplaySheet: View {
    @Binding var style: ChartDisplay.Style
    @Binding var volume: ChartDisplay.Volume
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                section(L("Chart")) {
                    ForEach(ChartDisplay.Style.allCases) { option in
                        tile(option.title, selected: style == option) {
                            withAnimation(Motion.tap) { style = option }
                        } preview: {
                            StylePreview(style: option)
                        }
                    }
                }
                section(L("Volume")) {
                    ForEach(ChartDisplay.Volume.allCases) { option in
                        tile(option.title, selected: volume == option) {
                            withAnimation(Motion.tap) { volume = option }
                        } preview: {
                            VolumePreview(volume: option)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.Space.screenMargin)
            .padding(.top, AppTheme.Space.s)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L("Chart display"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        // No dimming: the chart above stays fully visible, so each choice previews live.
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .sensoryFeedback(.selection, trigger: style) { _, _ in Haptic.isEnabled }
        .sensoryFeedback(.selection, trigger: volume) { _, _ in Haptic.isEnabled }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.s) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(AppTheme.secondaryText)
            HStack(spacing: AppTheme.Space.m) { content() }
        }
    }

    private func tile<Preview: View>(_ title: String, selected: Bool, action: @escaping () -> Void,
                                     @ViewBuilder preview: () -> Preview) -> some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Space.s) {
                preview()
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppTheme.Space.m)
                    .padding(.top, AppTheme.Space.m)
                Text(title)
                    .font(.footnote.weight(selected ? .semibold : .regular))
                    .foregroundColor(selected ? AppTheme.primaryText : AppTheme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, AppTheme.Space.xs)
                    .padding(.bottom, AppTheme.Space.m)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? AppTheme.accent : AppTheme.border, lineWidth: selected ? 1.5 : 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: Previews (tiny hand-drawn samples, not live data)
private let sample: [(o: CGFloat, c: CGFloat, h: CGFloat, l: CGFloat)] = [
    (0.18, 0.44, 0.52, 0.08), (0.44, 0.28, 0.50, 0.20), (0.28, 0.62, 0.70, 0.24),
    (0.62, 0.48, 0.72, 0.40), (0.48, 0.80, 0.88, 0.44), (0.80, 0.64, 0.86, 0.56), (0.64, 0.92, 0.99, 0.58)
]

private struct StylePreview: View {
    let style: ChartDisplay.Style

    var body: some View {
        Canvas { ctx, size in
            let n = sample.count
            let step = size.width / CGFloat(n)
            func y(_ v: CGFloat) -> CGFloat { size.height * (1 - v) }
            if style == .line {
                var path = Path()
                for (i, s) in sample.enumerated() {
                    let p = CGPoint(x: step * (CGFloat(i) + 0.5), y: y(s.c))
                    i == 0 ? path.move(to: p) : path.addLine(to: p)
                }
                ctx.stroke(path, with: .color(AppTheme.positive),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            } else {
                for (i, s) in sample.enumerated() {
                    let x = step * (CGFloat(i) + 0.5)
                    let up = s.c >= s.o
                    let color = up ? AppTheme.positive : AppTheme.negative
                    let top = y(max(s.o, s.c)), bottom = y(min(s.o, s.c))
                    var wick = Path()
                    wick.move(to: CGPoint(x: x, y: y(s.h))); wick.addLine(to: CGPoint(x: x, y: top))
                    wick.move(to: CGPoint(x: x, y: bottom)); wick.addLine(to: CGPoint(x: x, y: y(s.l)))
                    ctx.stroke(wick, with: .color(color.opacity(0.8)), lineWidth: 1)
                    let rect = CGRect(x: x - 3, y: top, width: 6, height: bottom - top)
                    let body = Path(roundedRect: rect, cornerRadius: 1.5, style: .continuous)
                    if up { ctx.stroke(Path(roundedRect: rect.insetBy(dx: 0.6, dy: 0.6), cornerRadius: 1, style: .continuous),
                                       with: .color(color), lineWidth: 1.2) }
                    else { ctx.fill(body, with: .color(color)) }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct VolumePreview: View {
    let volume: ChartDisplay.Volume
    private let bars: [(h: CGFloat, up: Bool)] = [
        (0.9, true), (0.6, false), (0.45, true), (0.3, true), (0.35, false), (0.25, false),
        (0.3, true), (0.4, false), (0.5, true), (0.7, true), (0.95, false)
    ]

    var body: some View {
        Canvas { ctx, size in
            let step = size.width / CGFloat(bars.count)
            if volume == .off {
                var dash = Path()
                dash.move(to: CGPoint(x: 0, y: size.height - 1)); dash.addLine(to: CGPoint(x: size.width, y: size.height - 1))
                ctx.stroke(dash, with: .color(AppTheme.tertiaryText), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                return
            }
            for (i, b) in bars.enumerated() {
                let x = step * (CGFloat(i) + 0.5)
                var bar = Path()
                bar.move(to: CGPoint(x: x, y: size.height)); bar.addLine(to: CGPoint(x: x, y: size.height * (1 - b.h)))
                let color: Color = volume == .mono
                    ? AppTheme.secondaryText.opacity(0.5)
                    : (b.up ? AppTheme.positive : AppTheme.negative).opacity(0.7)
                ctx.stroke(bar, with: .color(color), lineWidth: 2)
            }
        }
        .accessibilityHidden(true)
    }
}
