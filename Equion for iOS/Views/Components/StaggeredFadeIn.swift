import SwiftUI

// MARK: - Staggered Fade-In Animation
// Wraps child content so it fades in from below with a stagger delay.
// Usage:
//   StaggeredItem(index: 0) { MyCardView() }
//   StaggeredItem(index: 1) { AnotherView() }

struct StaggeredItem<Content: View>: View {
    let index: Int
    let content: () -> Content

    @State private var appeared = false

    private var delay: Double { Double(index) * 0.06 }

    var body: some View {
        content()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Fade-Slide Transition
// A reusable asymmetric transition: slide up + fade in, fade out on removal.

extension AnyTransition {
    static var fadeSlideUp: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom).animation(.easeOut(duration: 0.35))),
            removal: .opacity.animation(.easeIn(duration: 0.2))
        )
    }
}
