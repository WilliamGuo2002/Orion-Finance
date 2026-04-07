import SwiftUI

// MARK: - Ad Placeholder (replace with real AdMob later)

/// Banner-style ad placeholder
struct BannerAdView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.adBackground)
            HStack(spacing: 6) {
                Image(systemName: "megaphone.fill")
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    .font(.system(size: 14))
                Text("Ad")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
    }
}

/// Inline ad row for use inside Lists
struct InlineAdBannerView: View {
    var body: some View {
        BannerAdView()
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
