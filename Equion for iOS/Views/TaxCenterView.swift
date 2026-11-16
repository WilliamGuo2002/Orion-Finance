import SwiftUI

/// Registered-account room and superficial-loss watch, from linked brokerage data.
struct TaxCenterView: View {
    @ObservedObject private var tax = TaxCenter.shared
    @ObservedObject private var brokerage = BrokerageManager.shared
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false

    @State private var editingType: TaxAccountType?

    var body: some View {
        List {
            Section {
                Label(L("Information only, not tax advice. Check your figures in CRA My Account or with a tax professional."),
                      systemImage: "info.circle")
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
                    .listRowBackground(AppTheme.cardBackground)
            }

            if let error = tax.lastError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(AppTheme.caption(12))
                        .foregroundColor(AppTheme.warning)
                        .listRowBackground(AppTheme.cardBackground)
                }
            }

            contributionSection
            CostBasisSection()
            superficialLossSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle(L("Tax Assistant"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await tax.load() }
        .refreshable { await tax.load(force: true) }
        .sheet(item: $editingType) { type in
            RoomEditor(type: type, initial: tax.room(for: type)) { tax.setRoom($0, for: type) }
                .presentationDetents([.medium])
        }
    }

    private func money(_ cad: Double) -> String {
        hideValues ? PortfolioPrivacy.shortMask : Money.format(cad, currency: "CAD")
    }

    // MARK: Contribution room

    @ViewBuilder
    private var contributionSection: some View {
        Section {
            if tax.heldTypes.isEmpty {
                Text(brokerage.connections.isEmpty
                     ? L("Link a brokerage to track TFSA, RRSP and FHSA contributions.")
                     : L("No TFSA, RRSP or FHSA accounts found among your linked accounts."))
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
                    .listRowBackground(AppTheme.cardBackground)
            }
            ForEach(tax.contributions) { summary in
                contributionRow(summary)
                    .listRowBackground(AppTheme.cardBackground)
            }
        } header: {
            Text(String(format: L("%d contribution room"), TaxCenter.year))
        } footer: {
            Text(L("Contributions are counted from your linked accounts this calendar year. Transfers between institutions aren't counted. RRSP contributions in the first 60 days of the year can apply to the previous tax year."))
                .font(AppTheme.caption(11))
        }
    }

    private func contributionRow(_ s: ContributionSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(s.type.title)
                    .font(.system(.callout, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Button {
                    editingType = s.type
                } label: {
                    Text(s.roomCAD == nil ? L("Set room") : L("Edit room"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(AppTheme.accentText)
                }
                .buttonStyle(.borderless)
            }

            HStack {
                Text(L("Contributed this year"))
                Spacer()
                Text(money(s.contributedCAD)).font(AppTheme.number(13, weight: .semibold))
            }
            .font(.system(.footnote))
            .foregroundColor(AppTheme.secondaryText)

            if let room = s.roomCAD, let remaining = s.remainingCAD {
                ProgressView(value: min(max(s.contributedCAD, 0), max(room, 1)), total: max(room, 1))
                    .tint(remaining < 0 ? AppTheme.warning : AppTheme.accent)
                HStack {
                    Text(remaining >= 0 ? L("Room left") : L("Over your room by"))
                    Spacer()
                    Text(money(abs(remaining)))
                        .font(AppTheme.number(15, weight: .bold))
                        .foregroundColor(remaining < 0 ? AppTheme.warning : AppTheme.primaryText)
                }
                .font(.system(.footnote))
                .foregroundColor(AppTheme.primaryText)

                if s.overContributedCAD > 0 {
                    Label(String(format: L("CRA charges 1%% per month on over-contributions (%@ here). Withdraw the excess to stop the penalty."),
                                 money(s.overContributedCAD)),
                          systemImage: "exclamationmark.triangle.fill")
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.warning)
                } else if remaining < 0 && s.type == .rrsp {
                    Label(L("Within the $2,000 RRSP over-contribution allowance."), systemImage: "info.circle")
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText)
                }
            } else {
                Text(L("Enter your room from CRA My Account to see what's left."))
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
            }

            if s.type == .tfsa && s.withdrawnCAD > 0 {
                Text(String(format: L("Withdrawn this year: %@ — this room comes back on January 1."), money(s.withdrawnCAD)))
                    .font(AppTheme.caption(11))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: Superficial loss

    @ViewBuilder
    private var superficialLossSection: some View {
        Section {
            let alerts = tax.superficialLossAlerts
            if tax.isLoading && tax.activities.isEmpty {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowBackground(AppTheme.cardBackground)
            } else if alerts.isEmpty {
                Label(L("No recent losses to watch."), systemImage: "checkmark.circle")
                    .font(.system(.footnote))
                    .foregroundColor(AppTheme.secondaryText)
                    .listRowBackground(AppTheme.cardBackground)
            }
            ForEach(alerts) { alert in
                lossRow(alert)
                    .listRowBackground(AppTheme.cardBackground)
            }
        } header: {
            Text(L("Superficial loss watch"))
        } footer: {
            Text(L("If you sell at a loss in a non-registered account and you (or your spouse) buy the same security within 30 days before or after — in any account, including a TFSA or RRSP — and still hold it, CRA denies the loss. Orion checks all your linked accounts. Spouses' accounts aren't included unless linked."))
                .font(AppTheme.caption(11))
        }
    }

    private func lossRow(_ a: SuperficialLossAlert) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(a.symbol)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text(hideValues ? PortfolioPrivacy.shortMask : "-" + Money.format(a.loss, currency: a.currency))
                    .font(AppTheme.number(13, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
            }
            Text(String(format: L("Sold at a loss on %@ in %@"),
                        a.saleDate.formatted(date: .abbreviated, time: .omitted), a.accountName))
                .font(AppTheme.caption(11))
                .foregroundColor(AppTheme.secondaryText)

            switch a.status {
            case .watching:
                Label(String(format: L("Don't buy %@ in any account until %@ to keep this loss."),
                             a.symbol, a.windowEnds.formatted(date: .abbreviated, time: .omitted)),
                      systemImage: "clock.badge.exclamationmark")
                    .font(.system(.caption))
                    .foregroundColor(AppTheme.accentText)
            case .likelyDenied:
                Label(L("Likely a superficial loss — you bought it again within 30 days and still hold it."),
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.caption))
                    .foregroundColor(AppTheme.warning)
                ForEach(Array(a.repurchases.enumerated()), id: \.offset) { _, r in
                    Text("· " + String(format: L("Bought on %@ in %@"),
                                       r.date.formatted(date: .abbreviated, time: .omitted), r.account))
                        .font(AppTheme.caption(11))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Room editor

private struct RoomEditor: View {
    let type: TaxAccountType
    let initial: Double?
    let onSave: (Double?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("Amount in CAD"), text: $text)
                        .keyboardType(.decimalPad)
                } header: {
                    Text(String(format: L("%@ room available on January 1, %d"), type.title, TaxCenter.year))
                } footer: {
                    Text(hint)
                }
                if initial != nil {
                    Section {
                        Button(L("Clear"), role: .destructive) { onSave(nil); dismiss() }
                    }
                }
            }
            .navigationTitle(type.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        let cleaned = text.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: "")
                        onSave(Double(cleaned))
                        dismiss()
                    }
                    .disabled(Double(text.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: "")) == nil)
                }
            }
            .onAppear { if let initial { text = String(format: "%.0f", initial) } }
        }
    }

    private var hint: String {
        switch type {
        case .tfsa: return L("Find it in CRA My Account → RRSP, TFSA and FHSA → TFSA contribution room.")
        case .rrsp: return L("Use the RRSP deduction limit on your latest Notice of Assessment or in CRA My Account.")
        case .fhsa: return L("Find it in CRA My Account. The annual FHSA limit is $8,000 plus any carry-forward.")
        default: return ""
        }
    }
}
