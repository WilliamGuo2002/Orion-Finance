import SwiftUI

struct ContentView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var interests = InterestsManager.shared
    @State private var showOnboarding = false
    @State private var showRiskProfile = false
    @State private var checkingNewUser = true

    var body: some View {
        Group {
            if firebaseController.isLoggedIn {
                if showRiskProfile {
                    NavigationStack {
                        RiskProfileView(isOnboarding: true, onComplete: {
                            withAnimation(Motion.standard) {
                                showRiskProfile = false
                            }
                        })
                    }
                    .transition(.move(edge: .trailing))
                } else if showOnboarding {
                    NavigationStack {
                        InterestsSelectionView(isOnboarding: true, onComplete: {
                            withAnimation(Motion.standard) {
                                showOnboarding = false
                                showRiskProfile = true
                            }
                        })
                    }
                    .transition(.move(edge: .trailing))
                } else if checkingNewUser {
                    // Brief loading while we check onboarding status
                    ZStack {
                        AppTheme.background.ignoresSafeArea()
                        ProgressView()
                    }
                } else {
                    MainTabView()
                        .environmentObject(firebaseController)
                }
            } else {
                LoginView()
                    .environmentObject(firebaseController)
            }
        }
        .preferredColorScheme(settings.colorScheme)
        // In-app language drives layout direction and formatting, not the device language:
        // Hebrew and Arabic mirror the whole UI.
        .environment(\.layoutDirection, AppLocale.isRightToLeft ? .rightToLeft : .leftToRight)
        .environment(\.locale, AppLocale.current)
        .onChange(of: firebaseController.isLoggedIn) { _, loggedIn in
            if loggedIn {
                checkOnboardingStatus()
            } else {
                showOnboarding = false
                checkingNewUser = true
            }
        }
        .onAppear {
            if firebaseController.isLoggedIn {
                checkOnboardingStatus()
            } else {
                checkingNewUser = false
            }
        }
    }

    private func checkOnboardingStatus() {
        // Already completed locally — skip
        if interests.hasCompletedOnboarding {
            checkingNewUser = false
            showOnboarding = false
            return
        }
        // Check Firestore
        Task {
            await interests.loadFromFirestore()
            await MainActor.run {
                if interests.hasCompletedOnboarding {
                    checkingNewUser = false
                    showOnboarding = false
                } else {
                    checkingNewUser = false
                    showOnboarding = true
                }
            }
        }
    }
}

// MARK: - Main tabs
/// The system tab bar: on iOS 26 it's the floating Liquid Glass bar that minimizes on scroll and
/// adapts to Reduce Transparency / Increase Contrast by itself; on iPad it becomes a sidebar.
/// Each tab keeps its own navigation stack and state.
struct MainTabView: View {
    @EnvironmentObject var firebaseController: FirebaseController
    @ObservedObject private var settings = SettingsManager.shared
    @State private var selectedTab: AppTab = .holdings

    enum AppTab: String, CaseIterable, Hashable {
        case holdings, news, gurus, more, orion

        var icon: String {
            switch self {
            case .holdings: return "house"
            case .news:     return "newspaper"
            case .gurus:    return "person.2"
            case .more:     return "line.3.horizontal"
            case .orion:    return "sparkles"
            }
        }

        func label() -> String {
            switch self {
            case .holdings: return L("Home")
            case .news:     return L("News")
            case .gurus:    return L("Gurus")
            case .more:     return L("More")
            case .orion:    return "Orion"
            }
        }
    }

    var body: some View {
        tabs
            .tint(AppTheme.accentText)
            .id(settings.appLanguage)
    }

    @ViewBuilder
    private var tabs: some View {
        let view = TabView(selection: $selectedTab) {
            Tab(AppTab.holdings.label(), systemImage: AppTab.holdings.icon, value: AppTab.holdings) {
                NavigationStack { MyHoldingView() }
            }
            Tab(AppTab.news.label(), systemImage: AppTab.news.icon, value: AppTab.news) {
                NavigationStack { NewsView() }
            }
            Tab(AppTab.gurus.label(), systemImage: AppTab.gurus.icon, value: AppTab.gurus) {
                NavigationStack { InvestorsView() }
            }
            Tab(AppTab.orion.label(), systemImage: AppTab.orion.icon, value: AppTab.orion) {
                NavigationStack { ChatView() }
            }
            Tab(AppTab.more.label(), systemImage: AppTab.more.icon, value: AppTab.more) {
                NavigationStack { MenuView().environmentObject(firebaseController) }
            }
        }
        .tabViewStyle(.sidebarAdaptable)

        if #available(iOS 26.0, *) {
            view.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            view
        }
    }
}
