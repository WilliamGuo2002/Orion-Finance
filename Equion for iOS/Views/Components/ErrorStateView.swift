import SwiftUI

// MARK: - Friendly Error State
// Replaces raw error strings with an inviting, actionable error view.

struct ErrorStateView: View {
    let message: String
    var icon: String = "wifi.slash"
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.08))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(AppTheme.warning.opacity(0.7))
            }

            VStack(spacing: 6) {
                Text(L("Something went wrong"))
                    .font(AppTheme.serifHeadline(16))
                    .foregroundColor(AppTheme.primaryText)
                Text(message)
                    .font(AppTheme.caption(13))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            if let retry = retryAction {
                Button(action: {
                    Haptic.tap()
                    retry()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text(L("Try Again"))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AppTheme.accent))
                }
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}
