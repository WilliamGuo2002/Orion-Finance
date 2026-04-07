import SwiftUI

// MARK: - Shimmer Modifier
// Adds a shimmering gradient animation to any view, used for skeleton loading states.

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.5

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            AppTheme.primaryText.opacity(0.06),
                            AppTheme.primaryText.opacity(0.10),
                            AppTheme.primaryText.opacity(0.06),
                            .clear
                        ],
                        startPoint: .init(x: phase, y: 0.5),
                        endPoint: .init(x: phase + 1, y: 0.5)
                    )
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Shapes
// Pre-built skeleton placeholders that match the actual UI layout.

/// Skeleton for a single stock card row
struct SkeletonStockCard: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.subtleFill)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.subtleFill)
                    .frame(width: 70, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.subtleFill)
                    .frame(width: 100, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 6)
                .fill(AppTheme.subtleFill)
                .frame(width: 60, height: 36)

            VStack(alignment: .trailing, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.subtleFill)
                    .frame(width: 55, height: 12)
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.subtleFill)
                    .frame(width: 60, height: 18)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
        .shimmer()
    }
}

/// Skeleton for the chart area in detail view
struct SkeletonChart: View {
    var body: some View {
        ZStack {
            // Fake wave line
            WavePath()
                .stroke(AppTheme.subtleFill, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(height: 120)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .shimmer()
    }
}

private struct WavePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 60
        let midY = rect.midY
        let amp = rect.height * 0.3
        path.move(to: CGPoint(x: 0, y: midY))
        for i in 0...steps {
            let x = rect.width * CGFloat(i) / CGFloat(steps)
            let y = midY + sin(CGFloat(i) * 0.15) * amp * sin(CGFloat(i) * 0.05)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

/// Skeleton for a news card
struct SkeletonNewsCard: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.subtleFill)
                .frame(width: 80, height: 64)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.subtleFill)
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.subtleFill)
                    .frame(width: 140, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.subtleFill)
                    .frame(width: 60, height: 10)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
        .shimmer()
    }
}

/// Full skeleton loading view for the watchlist (shows 4 placeholder cards)
struct SkeletonWatchlist: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonStockCard()
            }
        }
        .padding(.horizontal, 16)
    }
}
