import SwiftUI

/// "How familiar are you with investing?" — first onboarding step, also reachable from More.
/// It only picks sensible defaults; the copy says so, so nobody feels tested or boxed in.
struct ExperienceSelectionView: View {
    let isOnboarding: Bool
    var onComplete: (() -> Void)? = nil

    @State private var selection: ExperienceLevel? = Experience.current
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppTheme.Space.xl) {
                    VStack(spacing: AppTheme.Space.m) {
                        if isOnboarding {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "sparkle")
                                    .font(.system(.largeTitle, weight: .light))
                                    .foregroundColor(AppTheme.accentText)
                            }
                            .padding(.top, AppTheme.Space.xl)
                            .accessibilityHidden(true)
                        }
                        Text(L("How familiar are you with investing?"))
                            .font(AppTheme.serifTitle(isOnboarding ? 28 : 24))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                        Text(L("This only sets a few defaults. You can see everything either way, and change it anytime."))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, AppTheme.Space.xxl)

                    VStack(spacing: AppTheme.Space.m) {
                        ForEach(ExperienceLevel.allCases) { level in
                            option(level)
                        }
                    }
                    .padding(.horizontal, AppTheme.Space.screenMargin)
                }
                .padding(.bottom, AppTheme.Space.xl)
            }

            Button(action: save) {
                Text(isOnboarding ? (selection == nil ? L("Skip for now") : L("Continue")) : L("Save"))
                    .font(.system(.callout, weight: .semibold))
                    .foregroundColor(AppTheme.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(selection == nil && !isOnboarding
                                               ? AppTheme.secondaryText.opacity(0.4) : AppTheme.accent))
            }
            .disabled(selection == nil && !isOnboarding)
            .padding(.horizontal, AppTheme.Space.xl)
            .padding(.vertical, AppTheme.Space.m)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection) { _, _ in Haptic.isEnabled }
    }

    private func option(_ level: ExperienceLevel) -> some View {
        let selected = selection == level
        return Button {
            withAnimation(Motion.tap) { selection = level }
        } label: {
            HStack(spacing: AppTheme.Space.m) {
                Image(systemName: level.icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.accent.opacity(0.1)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(level.subtitle)
                        .font(.footnote)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selected ? AppTheme.accentText : AppTheme.tertiaryText)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(AppTheme.Space.l)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .strokeBorder(selected ? AppTheme.accent : AppTheme.border, lineWidth: selected ? 1.5 : 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func save() {
        if let selection { Experience.set(selection) }
        if isOnboarding { onComplete?() } else { dismiss() }
    }
}
