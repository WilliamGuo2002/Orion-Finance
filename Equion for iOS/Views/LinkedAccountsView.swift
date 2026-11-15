import SwiftUI
import AuthenticationServices

/// Connect / manage read-only accounts: brokerages (Wealthsimple, etc.) via SnapTrade,
/// banks (chequing, savings, credit cards, loans) via Plaid.
struct LinkedAccountsView: View {
    @ObservedObject private var brokerage = BrokerageManager.shared
    @ObservedObject private var bank = BankManager.shared
    @Environment(\.webAuthenticationSession) private var webAuthSession

    @State private var isConnecting = false
    @State private var actionError: String?
    @State private var pendingDisconnect: BrokerageConnection?
    @State private var isConnectingBank = false
    @State private var pendingBankRemoval: BankItem?

    /// Must match APP_CALLBACK_URL in firebase/functions/src/index.ts
    private let callbackScheme = "orionfinance"

    var body: some View {
        List {
            introSection

            if let error = brokerage.lastError ?? bank.lastError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(AppTheme.caption(12))
                        .foregroundColor(AppTheme.warning)
                        .listRowBackground(AppTheme.cardBackground)
                }
            }

            ForEach(brokerage.connections) { connection in
                Section {
                    let accounts = accounts(for: connection)
                    if accounts.isEmpty {
                        Text(brokerage.isSyncing ? L("Loading accounts…") : L("No accounts found yet. Pull to refresh in a moment."))
                            .font(AppTheme.caption(12))
                            .foregroundColor(AppTheme.secondaryText)
                            .listRowBackground(AppTheme.cardBackground)
                    }
                    ForEach(accounts) { account in
                        accountRow(account)
                            .listRowBackground(AppTheme.cardBackground)
                    }
                    if connection.disabled {
                        Button {
                            Task { await connect(reconnect: connection.id) }
                        } label: {
                            Label(L("Reconnect"), systemImage: "arrow.triangle.2.circlepath")
                                .foregroundColor(AppTheme.accentText)
                        }
                        .disabled(isConnecting)
                        .listRowBackground(AppTheme.cardBackground)
                    }
                } header: {
                    connectionHeader(connection)
                } footer: {
                    if let text = SyncHealth.freshnessText(SyncHealth.lastUpdated(connection: connection)) {
                        freshnessFooter(text, stale: isStale(SyncHealth.lastUpdated(connection: connection)))
                    }
                }
            }

            // Accounts whose connection isn't listed (shouldn't happen, but never hide data)
            let orphans = brokerage.accounts.filter { acct in
                !brokerage.connections.contains { $0.id == acct.connectionId }
            }
            if !orphans.isEmpty {
                Section(L("Accounts")) {
                    ForEach(orphans) { account in
                        accountRow(account).listRowBackground(AppTheme.cardBackground)
                    }
                }
            }

            // Banks (Plaid)
            ForEach(bank.currentItems) { item in
                Section {
                    let accounts = bank.currentAccounts.filter { $0.itemId == item.id }
                    if let error = item.error {
                        Text(L(error))
                            .font(AppTheme.caption(12))
                            .foregroundColor(AppTheme.warning)
                            .listRowBackground(AppTheme.cardBackground)
                    }
                    ForEach(accounts) { account in
                        bankAccountRow(account)
                            .listRowBackground(AppTheme.cardBackground)
                    }
                    if item.needsReconnect {
                        Button {
                            Task { await connectBank(reconnect: item.id) }
                        } label: {
                            Label(L("Reconnect"), systemImage: "arrow.triangle.2.circlepath")
                                .foregroundColor(AppTheme.accentText)
                        }
                        .disabled(isConnectingBank)
                        .listRowBackground(AppTheme.cardBackground)
                    }
                } header: {
                    HStack {
                        Text(item.institution)
                        Spacer()
                        Menu {
                            Button(role: .destructive) {
                                pendingBankRemoval = item
                            } label: {
                                Label(L("Disconnect"), systemImage: "link.badge.plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(.subheadline))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                } footer: {
                    if let text = SyncHealth.freshnessText(SyncHealth.lastUpdated(item: item)) {
                        freshnessFooter(text, stale: isStale(SyncHealth.lastUpdated(item: item)))
                    }
                }
            }

            connectSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle(L("Linked Accounts"))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await refresh() }
        .task { await refresh() }
        .alert(L("Something went wrong"), isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button(L("OK"), role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
        .confirmationDialog(
            L("Disconnect this brokerage?"),
            isPresented: Binding(
                get: { pendingDisconnect != nil },
                set: { if !$0 { pendingDisconnect = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDisconnect
        ) { connection in
            Button(L("Disconnect"), role: .destructive) {
                Task { await disconnect(connection) }
            }
            Button(L("Cancel"), role: .cancel) { pendingDisconnect = nil }
        } message: { connection in
            Text(String(format: L("%@ holdings will be removed from Orion. Your brokerage account itself is not affected."), connection.brokerageName))
        }
        .confirmationDialog(
            L("Disconnect this bank?"),
            isPresented: Binding(
                get: { pendingBankRemoval != nil },
                set: { if !$0 { pendingBankRemoval = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingBankRemoval
        ) { item in
            Button(L("Disconnect"), role: .destructive) {
                Task { await removeBank(item) }
            }
            Button(L("Cancel"), role: .cancel) { pendingBankRemoval = nil }
        } message: { item in
            Text(String(format: L("%@ accounts will be removed from Orion. Your bank account itself is not affected."), item.institution))
        }
    }

    // MARK: - Sections

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(.title2))
                        .foregroundColor(AppTheme.accentText)
                    Text(L("See your real holdings"))
                        .font(AppTheme.serifHeadline(18))
                        .foregroundColor(AppTheme.primaryText)
                }
                Text(L("Link Wealthsimple, other brokerages or your bank to see your net worth in Orion. Read-only: Orion can never trade or move money, and never sees your passwords."))
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
            .listRowBackground(AppTheme.cardBackground)
        }
    }

    private var connectSection: some View {
        Section {
            Button {
                Task { await connect() }
            } label: {
                HStack(spacing: 12) {
                    if isConnecting {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(brokerage.connections.isEmpty ? L("Connect a Brokerage") : L("Connect Another Brokerage"))
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppTheme.accentText)
            }
            .disabled(isConnecting)
            .listRowBackground(AppTheme.cardBackground)

            Button {
                Task { await connectBank() }
            } label: {
                HStack(spacing: 12) {
                    if isConnectingBank {
                        ProgressView()
                    } else {
                        Image(systemName: "building.columns.circle.fill")
                    }
                    Text(bank.currentItems.isEmpty ? L("Connect a Bank") : L("Connect Another Bank"))
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppTheme.accentText)
            }
            .disabled(isConnectingBank)
            .listRowBackground(AppTheme.cardBackground)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Brokerages connect securely through SnapTrade, banks through Plaid. You sign in on your institution's own page."))
                if let synced = brokerage.lastSynced ?? bank.lastSynced {
                    Text(String(format: L("Updated %@"), synced.formatted(.relative(presentation: .named))))
                }
            }
            .font(AppTheme.caption(11))
        }
    }

    private func connectionHeader(_ connection: BrokerageConnection) -> some View {
        HStack {
            Text(connection.brokerageName)
            if connection.disabled {
                Text(L("Needs reconnect"))
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundColor(AppTheme.warning)
            }
            Spacer()
            Menu {
                Button(role: .destructive) {
                    pendingDisconnect = connection
                } label: {
                    Label(L("Disconnect"), systemImage: "link.badge.plus")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(.subheadline))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
    }

    private func accountRow(_ account: LinkedAccount) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    Text([account.institution, account.maskedNumber].compactMap { $0 }.joined(separator: " · "))
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
                if let total = account.totalValue {
                    Text(Money.format(total, currency: account.currency))
                        .font(AppTheme.number(15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
            }
            HStack {
                Text(String(format: "%d %@", account.positions.count, L("positions")))
                Spacer()
                if !account.cash.isEmpty {
                    Text(L("Cash") + " " + account.cash.map { Money.format($0.amount, currency: $0.currency) }.joined(separator: " · "))
                }
            }
            .font(AppTheme.caption(11))
            .foregroundColor(AppTheme.secondaryText)

            if let error = account.error {
                Text(L(error))
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.warning)
            }
        }
        .padding(.vertical, 4)
    }

    private func isStale(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Date().timeIntervalSince(date) > SyncHealth.staleAfter
    }

    private func freshnessFooter(_ text: String, stale: Bool) -> some View {
        HStack(spacing: 4) {
            if stale {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.warning)
            }
            Text(text)
        }
        .font(AppTheme.caption(11))
    }

    private func bankAccountRow(_ account: BankAccount) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text([account.subtype?.capitalized, account.maskedNumber].compactMap { $0 }.joined(separator: " · "))
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            if let value = account.netValue {
                Text((value < 0 ? "-" : "") + Money.format(abs(value), currency: account.currency))
                    .font(AppTheme.number(15, weight: .semibold))
                    .foregroundColor(value < 0 ? AppTheme.negative : AppTheme.primaryText)
            }
        }
        .padding(.vertical, 4)
    }

    private func accounts(for connection: BrokerageConnection) -> [LinkedAccount] {
        brokerage.accounts.filter { $0.connectionId == connection.id }
    }

    // MARK: - Actions

    private func refresh() async {
        async let b: Void = brokerage.sync()
        async let p: Void = bank.sync()
        _ = await (b, p)
        await HoldingsManager.shared.reloadAfterBrokerageChange()
    }

    private func connectBank(reconnect itemId: String? = nil) async {
        isConnectingBank = true
        defer { isConnectingBank = false }
        do {
            let session = try await bank.startLink(reconnect: itemId)
            do {
                _ = try await webAuthSession.authenticate(
                    using: session.url,
                    callbackURLScheme: callbackScheme,
                    preferredBrowserSession: .ephemeral
                )
            } catch {
                // Closing the sheet is normal; a bank may still have been linked, so check below.
            }
            try await bank.completeLink(linkToken: session.linkToken)
            await refresh()
            if !bank.currentItems.isEmpty { Haptic.success() }
        } catch {
            actionError = error.localizedDescription
            Haptic.error()
        }
    }

    private func removeBank(_ item: BankItem) async {
        pendingBankRemoval = nil
        do {
            try await bank.remove(itemId: item.id)
            await HoldingsManager.shared.reloadAfterBrokerageChange()
        } catch {
            actionError = error.localizedDescription
            Haptic.error()
        }
    }

    private func connect(reconnect connectionId: String? = nil) async {
        isConnecting = true
        defer { isConnecting = false }
        do {
            let url = try await brokerage.connectionPortalURL(reconnect: connectionId)
            do {
                // Ephemeral: brokerage sign-in cookies are not shared with Safari.
                _ = try await webAuthSession.authenticate(
                    using: url,
                    callbackURLScheme: callbackScheme,
                    preferredBrowserSession: .ephemeral
                )
            } catch {
                // Closing the sheet is normal; the connection may still have
                // completed on SnapTrade's side, so we always re-sync below.
            }
            await refresh()
            if !brokerage.connections.isEmpty { Haptic.success() }
        } catch {
            actionError = error.localizedDescription
            Haptic.error()
        }
    }

    private func disconnect(_ connection: BrokerageConnection) async {
        pendingDisconnect = nil
        do {
            try await brokerage.disconnect(connectionId: connection.id)
            await HoldingsManager.shared.reloadAfterBrokerageChange()
        } catch {
            actionError = error.localizedDescription
            Haptic.error()
        }
    }
}
