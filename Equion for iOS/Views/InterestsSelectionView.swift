import SwiftUI

// MARK: - Interests Selection View
// Used for: (1) new user onboarding, (2) re-selecting from More menu
struct InterestsSelectionView: View {
    @ObservedObject private var manager = InterestsManager.shared
    @State private var localSelection: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    /// If true, this is the onboarding flow (full screen, different CTA)
    let isOnboarding: Bool
    /// Called when onboarding finishes
    var onComplete: (() -> Void)? = nil

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    private var isWide: Bool { hSize == .regular || vSize == .compact }

    private var gridColumns: [GridItem] {
        if isWide {
            return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        }
        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                if isOnboarding {
                    // Big welcome icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "sparkles")
                            .font(.system(.largeTitle, weight: .light))
                            .foregroundColor(AppTheme.accentText)
                    }
                    .padding(.top, 20)
                }

                Text(isOnboarding ? L("What interests you?") : L("My Interests"))
                    .font(AppTheme.serifTitle(isOnboarding ? 28 : 24))
                    .foregroundColor(AppTheme.primaryText)

                Text(isOnboarding ? L("Pick the categories you want to follow and learn about") : L("Update the categories you follow"))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Selection count
                if !localSelection.isEmpty {
                    Text("\(localSelection.count) \(L("selected"))")
                        .font(AppTheme.caption(12))
                        .foregroundColor(AppTheme.accentText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.accent.opacity(0.1)))
                }
            }
            .padding(.bottom, 16)

            // Interest grid
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(InterestCategory.all) { category in
                        InterestCard(
                            category: category,
                            isSelected: localSelection.contains(category.id),
                            onTap: { toggleCategory(category.id) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }

            // Bottom button
            VStack(spacing: 8) {
                Button(action: saveAndContinue) {
                    HStack(spacing: 8) {
                        if isOnboarding {
                            Text(localSelection.isEmpty ? L("Skip for now") : L("Continue"))
                                .font(.system(.callout, weight: .semibold))
                        } else {
                            Text(L("Save"))
                                .font(.system(.callout, weight: .semibold))
                        }
                        if !localSelection.isEmpty {
                            Image(systemName: "arrow.right")
                                .font(.system(.subheadline, weight: .semibold))
                        }
                    }
                    .foregroundColor(AppTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            localSelection.isEmpty
                                ? AppTheme.secondaryText.opacity(0.4)
                                : AppTheme.accent
                        )
                    )
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 12)
            .background(
                AppTheme.background
            )
        }
        .background(AppTheme.background)
        .onAppear {
            localSelection = manager.selectedInterests
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Done")) { dismiss() }
                        .foregroundColor(AppTheme.accentText)
                }
            }
        }
    }

    private func toggleCategory(_ id: String) {
        withAnimation(Motion.tap) {
            if localSelection.contains(id) {
                localSelection.remove(id)
            } else {
                localSelection.insert(id)
            }
        }
    }

    private func saveAndContinue() {
        manager.selectedInterests = localSelection
        manager.hasCompletedOnboarding = true
        manager.syncToFirestore()

        if isOnboarding {
            onComplete?()
        } else {
            dismiss()
        }
    }
}

// MARK: - Interest Card
struct InterestCard: View {
    let category: InterestCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // One accent family for every category — ten hues made the grid read as a toy box.
                Image(systemName: category.icon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? AppTheme.onAccent : AppTheme.accentText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.12)))

                Text(L(category.name))
                    .font(.system(.footnote))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(category.description)
                    .font(.system(.caption2))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }
}
