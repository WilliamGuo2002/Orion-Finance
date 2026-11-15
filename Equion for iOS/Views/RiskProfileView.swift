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
    let symbol: String         // SF Symbol
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
    /// Direction of the last page change, so Back slides the other way.
    @State private var movingForward = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isWide: Bool { hSize == .regular || vSize == .compact }

    // MARK: - Questions

    private let questions: [RiskQuestion] = [
        RiskQuestion(
            id: 0,
            question: "How long do you plan to invest?",
            icon: "calendar.badge.clock",
            options: [
                RiskOption(id: "short",  label: "Less than 1 year",  symbol: "hourglass", score: 1),
                RiskOption(id: "mid",    label: "1 to 3 years",      symbol: "calendar", score: 2),
                RiskOption(id: "long",   label: "3+ years",          symbol: "tree", score: 3),
            ]
        ),
        RiskQuestion(
            id: 1,
            question: "How much loss can you tolerate?",
            icon: "chart.line.downtrend.xyaxis",
            options: [
                RiskOption(id: "low",    label: "Up to 10% — I prefer safety",     symbol: "shield", score: 1),
                RiskOption(id: "mid",    label: "Up to 20% — I can handle dips",   symbol: "scalemass", score: 2),
                RiskOption(id: "high",   label: "30%+ — High risk, high reward",   symbol: "chart.line.uptrend.xyaxis", score: 3),
            ]
        ),
        RiskQuestion(
            id: 2,
            question: "If your stock drops 15% in a week, you would:",
            icon: "exclamationmark.triangle",
            options: [
                RiskOption(id: "sell",   label: "Sell immediately to stop losses",  symbol: "arrow.uturn.backward", score: 1),
                RiskOption(id: "hold",   label: "Hold and wait for recovery",       symbol: "pause.circle", score: 2),
                RiskOption(id: "buy",    label: "Buy more at the lower price",      symbol: "plus.circle", score: 3),
            ]
        ),
        RiskQuestion(
            id: 3,
            question: "What's your primary investment goal?",
            icon: "target",
            options: [
                RiskOption(id: "preserve", label: "Preserve my money, beat inflation",  symbol: "building.columns", score: 1),
                RiskOption(id: "grow",     label: "Steady growth over time",            symbol: "leaf", score: 2),
                RiskOption(id: "maximize", label: "Maximize returns aggressively",      symbol: "bolt", score: 3),
            ]
        ),
        RiskQuestion(
            id: 4,
            question: "How would you describe your investing experience?",
            icon: "graduationcap",
            options: [
                RiskOption(id: "none",     label: "Complete beginner",                  symbol: "lightbulb", score: 1),
                RiskOption(id: "some",     label: "I know the basics",                  symbol: "book", score: 2),
                RiskOption(id: "exp",      label: "Experienced investor",               symbol: "chart.bar.xaxis", score: 3),
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
            return ("conservative", "Conservative", "shield", AppTheme.accent,
                    "You put stability first. When Orion explains things, it will spend more time on diversification, income investments and protecting what you have.")
        } else if score <= 11 {
            return ("moderate", "Moderate", "scalemass", AppTheme.accent,
                    "You balance growth with stability. Orion will explain both growth companies and steadier investments, and how they fit together.")
        } else {
            return ("aggressive", "Aggressive", "chart.line.uptrend.xyaxis", AppTheme.accent,
                    "You're comfortable with bigger swings in pursuit of growth. Orion will explain growth companies and newer trends — including their risks.")
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
                        .foregroundColor(AppTheme.accentText)
                }
            }
        }
    }

    // MARK: - Question View

    /// The page body slides in from the side it came from; with Reduce Motion it only cross-fades.
    private var pageTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: movingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: movingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func goTo(_ page: Int) {
        movingForward = page > currentPage
        withAnimation(Motion.standard) { currentPage = page }
    }

    private func questionView(_ q: RiskQuestion) -> some View {
        VStack(spacing: 0) {
            // Fixed header: identical on every question, so nothing above the options jumps.
            VStack(spacing: 16) {
                HStack(spacing: 4) {
                    ForEach(0..<questions.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentPage ? AppTheme.accent : AppTheme.subtleFill)
                            .frame(height: 4)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(format: L("Question %d of %d"), currentPage + 1, questions.count))

                if isOnboarding {
                    VStack(spacing: 8) {
                        Text(L("Investment Style"))
                            .font(AppTheme.serifTitle(28))
                            .foregroundColor(AppTheme.primaryText)
                        Text(L("Help Orion tailor what it explains and shows you"))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)

            // Page content — a new identity per question; the two pages slide apart in a ZStack
            // (in a VStack they'd briefly stack on top of each other and push things around).
            ZStack(alignment: .top) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(currentPage + 1) / \(questions.count)")
                        .font(.footnote.weight(.medium).monospacedDigit())
                        .foregroundColor(AppTheme.secondaryText)
                    Text(L(q.question))
                        .font(AppTheme.serifHeadline(22))
                        .foregroundColor(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(q.options) { option in
                            optionCard(option, questionId: q.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .id(currentPage)
            .transition(pageTransition)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()

            // Navigation
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button {
                        goTo(currentPage - 1)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(.footnote, weight: .semibold))
                            Text(L("Back"))
                                .font(.system(.subheadline))
                        }
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(Capsule().fill(AppTheme.subtleFill))
                    }
                }

                Spacer()

                Button {
                    goTo(currentPage + 1)
                } label: {
                    HStack(spacing: 4) {
                        Text(currentPage < questions.count - 1 ? L("Next") : L("See Result"))
                            .font(.system(.subheadline, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(.footnote, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.onAccent)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Capsule().fill(AppTheme.accent))
                }
                // Always in place (no pop-in); disabled until the question is answered.
                .disabled(answers[q.id] == nil)
                .opacity(answers[q.id] == nil ? 0.4 : 1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppTheme.background)
            .overlay(alignment: .top) {
                Rectangle().fill(AppTheme.border.opacity(0.6)).frame(height: 0.5)
            }
        }
    }

    private func optionCard(_ option: RiskOption, questionId: Int) -> some View {
        let isSelected = answers[questionId] == option.id
        return Button {
            withAnimation(Motion.tap) {
                answers[questionId] = option.id
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: option.symbol)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 28)

                Text(L(option.label))
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.border)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.08) : AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Result View

    private var resultView: some View {
        let result = profileResult
        return VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: result.icon)
                .font(.system(.largeTitle, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(AppTheme.accentText)
                .frame(width: 88, height: 88)
                .background(Circle().fill(AppTheme.accent.opacity(0.1)))
                .accessibilityHidden(true)

            // Title
            Text(L("Your Investment Style"))
                .font(AppTheme.serifHeadline(16))
                .foregroundColor(AppTheme.secondaryText)

            Text(L(result.label))
                .font(AppTheme.serifTitle(32))
                .foregroundColor(AppTheme.primaryText)

            // Description
            Text(L(result.description))
                .font(.body)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Where the score sits — one accent family, labelled, never colour alone
            VStack(spacing: 8) {
                HStack(spacing: 2) {
                    scoreSegment(shade: 0.25, range: 5...7, score: totalScore)
                    scoreSegment(shade: 0.45, range: 8...11, score: totalScore)
                    scoreSegment(shade: 0.7, range: 12...15, score: totalScore)
                }
                .frame(height: 14)
                HStack {
                    Text(L("Conservative")).frame(maxWidth: .infinity, alignment: .leading)
                    Text(L("Moderate")).frame(maxWidth: .infinity)
                    Text(L("Aggressive")).frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal, 48)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(format: L("Investment style: %@"), L(result.label)))

            Spacer()

            // Save button
            Button(action: saveProfile) {
                HStack(spacing: 8) {
                    Text(isOnboarding ? L("Get Started") : L("Save"))
                        .font(.system(.callout, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(.subheadline, weight: .semibold))
                }
                .foregroundColor(AppTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(AppTheme.accent))
            }
            .padding(.horizontal, 24)

            // Retake
            Button {
                movingForward = false
                withAnimation(Motion.standard) {
                    currentPage = 0
                    answers.removeAll()
                }
            } label: {
                Text(L("Retake Quiz"))
                    .font(.system(.subheadline))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.bottom, 24)
        }
        .background(AppTheme.background)
    }

    private func scoreSegment(shade: Double, range: ClosedRange<Int>, score: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.accent.opacity(shade)).frame(height: 6)
                if range.contains(score) {
                    let fraction = (CGFloat(score - range.lowerBound) + 0.5) / CGFloat(range.count)
                    Circle()
                        .fill(AppTheme.primaryText)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))
                        // Centre the marker on its point (offset is from the leading edge).
                        .offset(x: geo.size.width * fraction - 7)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Actions

    private func saveProfile() {
        settings.riskProfile = profileResult.key
        FirebaseController.shared.saveUserRiskProfile(profileResult.key)

        if isOnboarding {
            onComplete?()
        } else {
            dismiss()
        }
    }
}
