import SwiftUI

// MARK: - Risk Profile Question
struct RiskQuestion: Identifiable {
    let id: Int
    let question: String       // English key for L()
    let icon: String           // SF Symbol
    let options: [RiskOption]
}

struct RiskOption: Identifiable {
    let id: String
    let label: String          // English key for L()
    let emoji: String
    let score: Int             // 1 = conservative, 2 = moderate, 3 = aggressive
}

// MARK: - Risk Profile View
// Used for: (1) new user onboarding (after interests), (2) editing from More menu
struct RiskProfileView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    /// If true, this is the onboarding flow
    let isOnboarding: Bool
    /// Called when onboarding finishes
    var onComplete: (() -> Void)? = nil

    @State private var currentPage = 0
    @State private var answers: [Int: String] = [:]  // questionId -> optionId

    private var isWide: Bool { hSize == .regular || vSize == .compact }

    // MARK: - Questions

    private let questions: [RiskQuestion] = [
        RiskQuestion(
            id: 0,
            question: "How long do you plan to invest?",
            icon: "calendar.badge.clock",
            options: [
                RiskOption(id: "short",  label: "Less than 1 year",  emoji: "⏱️", score: 1),
                RiskOption(id: "mid",    label: "1 to 3 years",      emoji: "📅", score: 2),
                RiskOption(id: "long",   label: "3+ years",          emoji: "🏔️", score: 3),
            ]
        ),
        RiskQuestion(
            id: 1,
            question: "How much loss can you tolerate?",
            icon: "chart.line.downtrend.xyaxis",
            options: [
                RiskOption(id: "low",    label: "Up to 10% — I prefer safety",     emoji: "🛡️", score: 1),
                RiskOption(id: "mid",    label: "Up to 20% — I can handle dips",   emoji: "⚖️", score: 2),
                RiskOption(id: "high",   label: "30%+ — High risk, high reward",   emoji: "🎢", score: 3),
            ]
        ),
        RiskQuestion(
            id: 2,
            question: "If your stock drops 15% in a week, you would:",
            icon: "exclamationmark.triangle",
            options: [
                RiskOption(id: "sell",   label: "Sell immediately to stop losses",  emoji: "🏃", score: 1),
                RiskOption(id: "hold",   label: "Hold and wait for recovery",       emoji: "🧘", score: 2),
                RiskOption(id: "buy",    label: "Buy more at the lower price",      emoji: "🛒", score: 3),
            ]
        ),
        RiskQuestion(
            id: 3,
            question: "What's your primary investment goal?",
            icon: "target",
            options: [
                RiskOption(id: "preserve", label: "Preserve my money, beat inflation",  emoji: "🏦", score: 1),
                RiskOption(id: "grow",     label: "Steady growth over time",            emoji: "🌱", score: 2),
                RiskOption(id: "maximize", label: "Maximize returns aggressively",      emoji: "🚀", score: 3),
            ]
        ),
        RiskQuestion(
            id: 4,
            question: "How would you describe your investing experience?",
            icon: "graduationcap",
            options: [
                RiskOption(id: "none",     label: "Complete beginner",                  emoji: "🐣", score: 1),
                RiskOption(id: "some",     label: "I know the basics",                  emoji: "📚", score: 2),
                RiskOption(id: "exp",      label: "Experienced investor",               emoji: "🎯", score: 3),
            ]
        ),
    ]

    // MARK: - Computed

    private var totalScore: Int {
        answers.values.compactMap { optionId in
            questions.flatMap(\.options).first(where: { $0.id == optionId })?.score
        }.reduce(0, +)
    }

    private var profileResult: (key: String, label: String, icon: String, color: Color, description: String) {
        let score = totalScore
        if score <= 7 {
            return ("conservative", "Conservative", "shield.checkered", .blue,
                    "You prefer stability and capital preservation. We'll focus on blue-chip stocks, bonds, and dividend-paying investments.")
        } else if score <= 11 {
            return ("moderate", "Moderate", "scale.3d", .orange,
                    "You balance growth with safety. We'll suggest a mix of growth stocks and stable investments.")
        } else {
            return ("aggressive", "Aggressive", "flame", .red,
                    "You chase high returns and can handle volatility. We'll highlight high-growth opportunities and emerging trends.")
        }
    }

    private var allAnswered: Bool { answers.count == questions.count }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if currentPage < questions.count {
                questionView(questions[currentPage])
            } else {
                resultView
            }
        }
        .background(AppTheme.background)
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

    // MARK: - Question View

    private func questionView(_ q: RiskQuestion) -> some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                if isOnboarding && currentPage == 0 {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(.top, 20)

                    Text(L("Investment Style"))
                        .font(AppTheme.serifTitle(28))
                        .foregroundColor(AppTheme.primaryText)

                    Text(L("Help us understand your preferences for better recommendations"))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Progress
                HStack(spacing: 4) {
                    ForEach(0..<questions.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentPage ? AppTheme.accent : AppTheme.subtleFill)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, isOnboarding && currentPage == 0 ? 8 : 20)

                // Question
                HStack(spacing: 10) {
                    Image(systemName: q.icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.accent)
                    Text(L(q.question))
                        .font(AppTheme.serifHeadline(20))
                        .foregroundColor(AppTheme.primaryText)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                Text("\(currentPage + 1) / \(questions.count)")
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.bottom, 24)

            // Options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(q.options) { option in
                        optionCard(option, questionId: q.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }

            // Navigation
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button {
                        Haptic.light()
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage -= 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text(L("Back"))
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(Capsule().fill(AppTheme.subtleFill))
                    }
                }

                Spacer()

                if answers[q.id] != nil {
                    Button {
                        Haptic.light()
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage += 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentPage < questions.count - 1 ? L("Next") : L("See Result"))
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(Capsule().fill(AppTheme.accent))
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, y: 4)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                AppTheme.background
                    .shadow(color: AppTheme.primaryText.opacity(0.05), radius: 10, y: -4)
            )
        }
    }

    private func optionCard(_ option: RiskOption, questionId: Int) -> some View {
        let isSelected = answers[questionId] == option.id
        return Button {
            Haptic.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                answers[questionId] = option.id
            }
        } label: {
            HStack(spacing: 14) {
                Text(option.emoji)
                    .font(.system(size: 28))

                Text(L(option.label))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.accent)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 2 : 0.5)
            )
            .shadow(color: isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.primaryText.opacity(0.04), radius: 8, y: 4)
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Result View

    private var resultView: some View {
        let result = profileResult
        return VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(result.color.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: result.icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(result.color)
            }

            // Title
            Text(L("Your Investment Style"))
                .font(AppTheme.serifHeadline(16))
                .foregroundColor(AppTheme.secondaryText)

            Text(L(result.label))
                .font(AppTheme.serifTitle(32))
                .foregroundColor(result.color)

            // Description
            Text(L(result.description))
                .font(.body)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Score breakdown
            HStack(spacing: 0) {
                scoreSegment(label: L("Conservative"), color: .blue, range: 5...7, score: totalScore)
                scoreSegment(label: L("Moderate"), color: .orange, range: 8...11, score: totalScore)
                scoreSegment(label: L("Aggressive"), color: .red, range: 12...15, score: totalScore)
            }
            .frame(height: 8)
            .clipShape(Capsule())
            .padding(.horizontal, 40)

            Spacer()

            // Save button
            Button(action: saveProfile) {
                HStack(spacing: 8) {
                    Text(isOnboarding ? L("Get Started") : L("Save"))
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(AppTheme.accent))
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 24)

            // Retake
            Button {
                Haptic.light()
                withAnimation {
                    currentPage = 0
                    answers.removeAll()
                }
            } label: {
                Text(L("Retake Quiz"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.bottom, 24)
        }
        .background(AppTheme.background)
    }

    private func scoreSegment(label: String, color: Color, range: ClosedRange<Int>, score: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(color.opacity(0.2))
                if range.contains(score) {
                    let fraction = CGFloat(score - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound + 1)
                    Circle()
                        .fill(color)
                        .frame(width: 14, height: 14)
                        .offset(x: geo.size.width * fraction)
                }
            }
        }
    }

    // MARK: - Actions

    private func saveProfile() {
        Haptic.success()
        settings.riskProfile = profileResult.key
        FirebaseController.shared.saveUserRiskProfile(profileResult.key)

        if isOnboarding {
            onComplete?()
        } else {
            dismiss()
        }
    }
}
