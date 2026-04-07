import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var notifService = NotificationService.shared
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    // Local state for threshold sliders
    @State private var stockThreshold: Double
    @State private var indexThreshold: Double

    init() {
        let s = NotificationService.shared
        _stockThreshold = State(initialValue: s.bigMoveThreshold)
        _indexThreshold = State(initialValue: s.indexMoveThreshold)
    }

    var body: some View {
        List {
            // Master toggle
            Section {
                Toggle(isOn: $settings.notificationsEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("Enable Notifications"))
                                .foregroundColor(AppTheme.primaryText)
                            Text(L("Monitor stocks in background"))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    } icon: {
                        Image(systemName: "bell.badge")
                            .foregroundColor(AppTheme.accent)
                    }
                }
                .tint(AppTheme.accent)
                .onChange(of: settings.notificationsEnabled) { _, newValue in
                    if newValue {
                        Task {
                            let granted = await notifService.requestPermission()
                            if granted {
                                notifService.scheduleBackgroundTask()
                            }
                        }
                    }
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            if settings.notificationsEnabled {
                // Market Indices Alerts
                Section {
                    Toggle(isOn: $notifService.marketAlertEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Market Index Alerts"))
                                    .foregroundColor(AppTheme.primaryText)
                                Text("S&P 500, NASDAQ, Dow Jones")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.orange)
                        }
                    }
                    .tint(AppTheme.accent)
                    .listRowBackground(AppTheme.cardBackground)

                    if notifService.marketAlertEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(L("Alert Threshold"))
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                Text(String(format: "%.1f%%", indexThreshold))
                                    .font(AppTheme.number(15, weight: .bold))
                                    .foregroundColor(AppTheme.accent)
                            }
                            Slider(value: $indexThreshold, in: 0.5...5.0, step: 0.5)
                                .tint(AppTheme.accent)
                                .onChange(of: indexThreshold) { _, val in
                                    notifService.indexMoveThreshold = val
                                }
                            Text(L("Notify when any major index moves more than this percentage"))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppTheme.cardBackground)
                    }
                } header: {
                    Text(L("Market Alerts"))
                }

                // Watchlist Price Alerts
                Section {
                    Toggle(isOn: $notifService.priceAlertEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Watchlist Price Alerts"))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(L("Alert on big moves in your watchlist"))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(AppTheme.negative)
                        }
                    }
                    .tint(AppTheme.accent)
                    .listRowBackground(AppTheme.cardBackground)

                    if notifService.priceAlertEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(L("Alert Threshold"))
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                Text(String(format: "%.1f%%", stockThreshold))
                                    .font(AppTheme.number(15, weight: .bold))
                                    .foregroundColor(AppTheme.accent)
                            }
                            Slider(value: $stockThreshold, in: 1.0...15.0, step: 0.5)
                                .tint(AppTheme.accent)
                                .onChange(of: stockThreshold) { _, val in
                                    notifService.bigMoveThreshold = val
                                }
                            Text(L("Notify when a watchlist stock moves more than this percentage"))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppTheme.cardBackground)
                    }
                } header: {
                    Text(L("Price Alerts"))
                }

                // Daily Summary
                Section {
                    Toggle(isOn: $notifService.dailySummaryEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Daily Market Summary"))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(L("Receive a summary after market close (4:05 PM ET)"))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(AppTheme.positive)
                        }
                    }
                    .tint(AppTheme.accent)
                    .onChange(of: notifService.dailySummaryEnabled) { _, enabled in
                        if enabled {
                            notifService.scheduleDailySummary()
                        } else {
                            notifService.cancelDailySummary()
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground)
                } header: {
                    Text(L("Daily Summary"))
                }

                // Info section
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppTheme.accent)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("How it works"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.primaryText)
                            Text(L("Orion monitors stock prices in the background using iOS Background App Refresh. Checks happen approximately every 15-30 minutes when the market is open. For real-time alerts, keep the app open."))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.cardBackground)
                } header: {
                    Text(L("About"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle(L("Notifications"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
