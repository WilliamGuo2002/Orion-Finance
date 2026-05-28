import SwiftUI

struct MenuView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @ObservedObject private var settings = SettingsManager.shared

    @State private var showAppearance = false
    @State private var showLanguage = false
    @State private var showInterests = false
    @State private var showRiskProfile = false
    @State private var showPortfolioWizard = false
    @State private var showStockCompare = false

    var body: some View {
        List {
            // Profile section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(AppTheme.accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(firebaseController.currentUser?.email?.components(separatedBy: "@").first ?? "User")
                            .font(AppTheme.serifHeadline(18))
                            .foregroundColor(AppTheme.primaryText)
                        Text(firebaseController.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(AppTheme.cardBackground)
            }

            // Settings section
            Section(L("Settings")) {
                // Appearance
                Button(action: { showAppearance = true }) {
                    menuRow(icon: "paintbrush", title: L("Appearance"), detail: appearanceLabel)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Notifications
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    menuRow(icon: "bell.badge", title: L("Notifications"),
                            detail: settings.notificationsEnabled ? L("On") : L("Off"))
                }
                .listRowBackground(AppTheme.cardBackground)

                // Language
                Button(action: { showLanguage = true }) {
                    menuRow(icon: "globe", title: L("Language"), detail: settings.appLanguage)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Interests
                Button(action: { showInterests = true }) {
                    menuRow(icon: "star.circle", title: L("My Interests"), detail: interestsDetail)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Risk Profile
                Button(action: { showRiskProfile = true }) {
                    menuRow(icon: "shield.checkered", title: L("Investment Style"), detail: riskProfileDetail)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Portfolio Builder
                Button(action: { showPortfolioWizard = true }) {
                    menuRow(icon: "sparkles", title: L("Portfolio Builder"), detail: nil)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Stock Compare
                Button(action: { showStockCompare = true }) {
                    menuRow(icon: "arrow.left.arrow.right", title: L("Compare Stocks"), detail: nil)
                }
                .listRowBackground(AppTheme.cardBackground)

                // Paper Trading
                NavigationLink {
                    PaperTradingView()
                } label: {
                    menuRow(icon: "chart.line.uptrend.xyaxis", title: L("Paper Trading"), detail: String(format: "$%.0f", PaperPortfolioManager.shared.cash + PaperPortfolioManager.shared.holdings.reduce(0) { $0 + $1.cost }))
                }
                .listRowBackground(AppTheme.cardBackground)

                menuRow(icon: "square.and.arrow.up", title: L("Share"))
                    .listRowBackground(AppTheme.cardBackground)
                menuRow(icon: "questionmark.circle", title: L("Support"))
                    .listRowBackground(AppTheme.cardBackground)
                menuRow(icon: "envelope", title: L("Contact"))
                    .listRowBackground(AppTheme.cardBackground)
                menuRow(icon: "doc.text", title: L("Copyright Info"))
                    .listRowBackground(AppTheme.cardBackground)
            }

            // Logout
            Section {
                Button(action: logout) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text(L("Log Out"))
                    }
                    .foregroundColor(AppTheme.warning)
                }
                .listRowBackground(AppTheme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .sheet(isPresented: $showAppearance) {
            AppearanceSheet(selected: $settings.appearanceMode)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showLanguage) {
            LanguageSheet(selected: $settings.appLanguage)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showInterests) {
            NavigationStack {
                InterestsSelectionView(isOnboarding: false)
            }
        }
        .sheet(isPresented: $showRiskProfile) {
            NavigationStack {
                RiskProfileView(isOnboarding: false)
            }
        }
        .sheet(isPresented: $showPortfolioWizard) {
            PortfolioWizardView()
        }
        .sheet(isPresented: $showStockCompare) {
            StockCompareView()
        }
    }

    private var interestsDetail: String {
        let count = InterestsManager.shared.selectedInterests.count
        return count > 0 ? "\(count) \(L("selected"))" : L("Not set")
    }

    private var riskProfileDetail: String {
        switch settings.riskProfile {
        case "conservative": return L("Conservative")
        case "moderate":     return L("Moderate")
        case "aggressive":   return L("Aggressive")
        default:             return L("Not set")
        }
    }

    private var appearanceLabel: String {
        switch settings.appearanceMode {
        case "light": return L("Light")
        case "dark": return L("Dark")
        default: return L("System")
        }
    }

    @ViewBuilder
    private func menuRow(icon: String, title: String, detail: String? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundColor(AppTheme.secondaryText)
                    .font(.subheadline)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
    }

    private func logout() {
        try? firebaseController.signOut()
    }
}

// MARK: - Appearance Sheet
struct AppearanceSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let options = [
        ("system", "System", "iphone"),
        ("light", "Light", "sun.max"),
        ("dark", "Dark", "moon")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.0) { key, label, icon in
                    Button(action: { selected = key; dismiss() }) {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 24)
                            Text(L(label))
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            if selected == key {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(L("Appearance"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Done")) { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Language Sheet
struct LanguageSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(SettingsManager.supportedLanguages, id: \.self) { lang in
                    Button(action: { selected = lang; dismiss() }) {
                        HStack {
                            Text(lang)
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            if selected == lang {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(L("Language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("Done")) { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}
