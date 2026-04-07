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
            VStack(spacing: 10) {
                if isOnboarding {
                    // Big welcome icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(.top, 20)
                }

                Text(isOnboarding ? L("What interests you?") : L("My Interests"))
                    .font(AppTheme.serifTitle(isOnboarding ? 28 : 24))
                    .foregroundColor(AppTheme.primaryText)

                Text(isOnboarding ? L("Pick your favorite categories to get personalized recommendations") : L("Update your interests for better recommendations"))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Selection count
                if !localSelection.isEmpty {
                    Text("\(localSelection.count) \(L("selected"))")
                        .font(AppTheme.caption(12))
                        .foregroundColor(AppTheme.accent)
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
                                .font(.system(size: 16, weight: .semibold))
                        } else {
                            Text(L("Save"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        if !localSelection.isEmpty {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            localSelection.isEmpty
                                ? AppTheme.secondaryText.opacity(0.4)
                                : AppTheme.accent
                        )
                    )
                    .shadow(color: localSelection.isEmpty ? .clear : AppTheme.accent.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 12)
            .background(
                AppTheme.background
                    .shadow(color: AppTheme.primaryText.opacity(0.05), radius: 10, y: -4)
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
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }

    private func toggleCategory(_ id: String) {
        Haptic.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if localSelection.contains(id) {
                localSelection.remove(id)
            } else {
                localSelection.insert(id)
            }
        }
    }

    private func saveAndContinue() {
        Haptic.success()
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

    private var accentColor: Color {
        switch category.color {
        case "blue":   return .blue
        case "green":  return Color(red: 0.2, green: 0.7, blue: 0.4)
        case "red":    return .red
        case "orange": return .orange
        case "purple": return .purple
        case "brown":  return Color(red: 0.6, green: 0.4, blue: 0.2)
        case "gray":   return .gray
        case "teal":   return .teal
        case "yellow": return Color(red: 0.85, green: 0.75, blue: 0.3)
        case "indigo": return .indigo
        default:       return AppTheme.accent
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor : accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : accentColor)
                }

                Text(L(category.name))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(category.description)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(isSelected ? accentColor : AppTheme.border, lineWidth: isSelected ? 2 : 0.5)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.15) : AppTheme.primaryText.opacity(0.04), radius: 8, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
