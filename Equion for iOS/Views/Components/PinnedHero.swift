import SwiftUI

// MARK: - Pinned hero (chart pages)
/// The home chart behaviour, reusable inside an ordinary ScrollView: the hero (header + chart)
/// stays put while the content below slides up over it, and as it's covered it sinks a little,
/// blurs softly and dims. Same numbers as the home chart, so every chart page feels the same.
///
/// How it pins: the hero stays in the scroll content (so its own buttons and scrub gestures keep
/// working) and is counter-offset by the scroll distance. Siblings after it need a higher
/// `zIndex` to draw on top. Only this thin wrapper reads `parallax.scrollOffset`, so scrolling
/// doesn't re-render the page body.
struct PinnedHero<Content: View>: View {
    var parallax: ChartParallax
    /// Height the cover progress is measured against (the hero's own height).
    var height: CGFloat
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let raw = ChartParallax.progress(offset: parallax.scrollOffset, chartHeight: height)
        let progress = reduceMotion ? 0 : raw
        content
            .offset(y: parallax.scrollOffset + progress * 20)   // pin, then a gentle sink
            .blur(radius: progress * 6)                          // soft — stays readable
            .opacity(1.0 - progress * 0.3)                       // dims only to 0.7
            .scaleEffect(1.0 - progress * 0.03, anchor: .top)
            // Once mostly covered, touches in the gaps between cards scroll the page instead
            // of scrubbing a chart the user can barely see.
            .allowsHitTesting(raw < 0.5)
    }
}

extension View {
    /// Feeds a ScrollView's offset into a `ChartParallax` (0 at rest, positive scrolling up).
    /// Rounded to whole points to cut update churn; clamped so pull-to-refresh doesn't pin.
    func trackingParallax(_ parallax: ChartParallax, onChange: ((CGFloat) -> Void)? = nil) -> some View {
        onScrollGeometryChange(for: CGFloat.self) { geo in
            (geo.contentOffset.y + geo.contentInsets.top).rounded()
        } action: { _, newValue in
            let clamped = max(0, newValue)
            parallax.scrollOffset = clamped
            onChange?(clamped)
        }
    }
}
