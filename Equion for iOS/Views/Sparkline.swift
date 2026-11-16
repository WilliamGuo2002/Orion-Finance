import SwiftUI

/// Lightweight mini chart for list rows and cards: two Paths instead of Swift Charts.
/// A `Chart` builds its own scene graph (scales, marks, layout) per instance, which made
/// the watchlist stutter as rows scrolled into view. Same look: 10% vertical padding,
/// gradient area under a thin line.
struct Sparkline: View {
    let values: [Double]
    let color: Color
    var lineWidth: CGFloat = 1.5
    var fillOpacity: Double = 0.2

    init(_ entries: [ChartEntry], color: Color, lineWidth: CGFloat = 1.5, fillOpacity: Double = 0.2) {
        self.values = entries.map { Double($0.close) }
        self.color = color
        self.lineWidth = lineWidth
        self.fillOpacity = fillOpacity
    }

    var body: some View {
        ZStack {
            SparklineShape(values: values, closed: true)
                .fill(LinearGradient(colors: [color.opacity(fillOpacity), color.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
            SparklineShape(values: values, closed: false)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .environment(\.layoutDirection, .leftToRight)   // time runs left to right in every language
        .accessibilityHidden(true)
    }
}

private struct SparklineShape: Shape {
    let values: [Double]
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1, let lo = values.min(), let hi = values.max() else { return path }
        let pad = (hi - lo) * 0.1
        let low = lo - pad
        let span = (hi + pad) - low
        let step = rect.width / CGFloat(values.count - 1)

        func point(_ i: Int) -> CGPoint {
            let t = span > 0 ? (values[i] - low) / span : 0.5
            return CGPoint(x: rect.minX + CGFloat(i) * step, y: rect.maxY - CGFloat(t) * rect.height)
        }

        path.move(to: point(0))
        for i in 1..<values.count { path.addLine(to: point(i)) }
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}
