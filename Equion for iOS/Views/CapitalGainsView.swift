import SwiftUI

// MARK: - Tax Assistant entry rows

/// Two rows in the Tax Assistant: cost basis (ACB) and this year's capital gains.
struct CostBasisSection: View {
    @ObservedObject private var tax = TaxCenter.shared
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false

    var body: some View {
        Section {
            if let report = tax.acb {
                let issues = report.positions.filter { !$0.issues.isEmpty }.count
                NavigationLink { CostBasisListView() } label: {
                    row(icon: "scalemass", title: L("Cost basis (ACB)"),
                        detail: String(format: L("%d securities"), report.positions.count),
                        warning: issues > 0 ? String(format: L("%d need a look"), issues) : nil)
                }
                let year = TaxCenter.year
                let s = report.summary(year)
                NavigationLink { CapitalGainsView(initialYear: year) } label: {
                    row(icon: "doc.plaintext", title: String(format: L("%d capital gains"), year),
                        detail: s.dispositions.isEmpty ? L("No sales yet this year")
                            : (hideValues ? PortfolioPrivacy.shortMask : Money.format(s.net, currency: "CAD")),
                        warning: s.hasIncomplete ? L("Incomplete") : nil)
                }
            } else if tax.isLoading || tax.isBuildingACB {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else {
                Text(L("No trades found in your non-registered accounts yet."))
                    .font(AppTheme.caption(12))
                    .foregroundColor(AppTheme.secondaryText)
            }
        } header: {
            Text(L("Cost basis and capital gains"))
        } footer: {
            Text(L("Non-registered accounts only. Identical securities are pooled across all of them, in Canadian dollars at Bank of Canada daily rates — the way CRA expects, which a single broker can't do."))
                .font(AppTheme.caption(11))
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    private func row(icon: String, title: String, detail: String, warning: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundColor(AppTheme.accentText)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundColor(AppTheme.primaryText)
                Text(detail).font(.footnote).foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            if let warning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(AppTheme.warning)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Cost basis list

struct CostBasisListView: View {
    @ObservedObject private var tax = TaxCenter.shared
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false
    @State private var editing: TransferEdit?

    struct TransferEdit: Identifiable {
        let symbol: String
        let issue: ACBIssue
        var id: String { symbol }
    }

    var body: some View {
        List {
            if let report = tax.acb {
                let values = tax.taxableMarketValueCAD
                Section {
                    ForEach(report.positions) { p in
                        positionRow(p, marketValue: values[p.symbol])
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        if !tax.taxableAccountNames.isEmpty {
                            Text(String(format: L("Accounts included: %@"), tax.taxableAccountNames.joined(separator: ", ")))
                        }
                        if report.usedEstimatedFX {
                            Text(L("Some exchange rates are estimated (trades before 2017, or a rate that couldn't be loaded)."))
                        }
                        Text(L("Your broker's book cost can differ: it only sees its own account, and may not convert to CAD at each trade date."))
                    }
                    .font(AppTheme.caption(11))
                }
                .listRowBackground(AppTheme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle(L("Cost basis (ACB)"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { edit in
            TransferCostEditor(symbol: edit.symbol, units: edit.issue.units) { total in
                Task { await tax.setTransferCost(totalCAD: total, for: edit.issue) }
            }
            .presentationDetents([.medium])
        }
    }

    private func money(_ v: Double) -> String {
        hideValues ? PortfolioPrivacy.shortMask : Money.format(v, currency: "CAD")
    }

    private func positionRow(_ p: ACBPosition, marketValue: Double?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(p.symbol).font(.subheadline.weight(.semibold)).foregroundColor(AppTheme.primaryText)
                Text(String(format: "%g", (p.units * 10_000).rounded() / 10_000) + " " + L("shares"))
                    .font(.caption).foregroundColor(AppTheme.secondaryText)
                Spacer()
                Text(money(p.acbCAD)).font(AppTheme.number(15, weight: .semibold)).foregroundColor(AppTheme.primaryText)
            }
            HStack {
                Text(String(format: L("%@ per share"), money(p.acbPerUnit)))
                Spacer()
                if let mv = marketValue, p.issues.isEmpty {
                    let gain = mv - p.acbCAD
                    Text(String(format: L("Unrealized %@"), (gain >= 0 ? "+" : "−") + money(abs(gain))))
                        .foregroundColor(gain >= 0 ? AppTheme.positive : AppTheme.negative)
                }
            }
            .font(.caption)
            .foregroundColor(AppTheme.secondaryText)

            ForEach(p.issues, id: \.self) { issue in
                issueRow(issue, symbol: p.symbol)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func issueRow(_ issue: ACBIssue, symbol: String) -> some View {
        switch issue.kind {
        case .transferInWithoutCost:
            VStack(alignment: .leading, spacing: 4) {
                Label(String(format: L("%@ shares moved in from another institution — Orion doesn't know what you paid."),
                             String(format: "%g", issue.units)),
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.warning)
                    .fixedSize(horizontal: false, vertical: true)
                Button(L("Enter their cost")) { editing = TransferEdit(symbol: symbol, issue: issue) }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.accentText)
                    .buttonStyle(.borderless)
            }
            .font(.caption)
        case .soldMoreThanHistory:
            Label(L("Sold more than the trade history shows — older trades are missing, so this cost is incomplete."),
                  systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundColor(AppTheme.warning)
        case .unitsMismatch:
            Label(L("Your trade history doesn't add up to what you hold now. Some trades may be missing."),
                  systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundColor(AppTheme.warning)
        case .estimatedFX:
            EmptyView()
        }
    }
}

private struct TransferCostEditor: View {
    let symbol: String
    let units: Double
    let onSave: (Double?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var value: Double? {
        Double(text.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("Total cost in CAD"), text: $text).keyboardType(.decimalPad)
                } header: {
                    Text(String(format: L("What you paid for the %@ %@ shares you moved in"), String(format: "%g", units), symbol))
                } footer: {
                    Text(L("Use the book cost (in CAD) from your previous broker's last statement, including commissions. It stays on this device."))
                }
            }
            .navigationTitle(symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) { onSave(value); dismiss() }.disabled(value == nil)
                }
            }
        }
    }
}

// MARK: - Capital gains for a year

struct CapitalGainsView: View {
    @ObservedObject private var tax = TaxCenter.shared
    @AppStorage(PortfolioPrivacy.storageKey) private var hideValues = false
    @State private var year: Int

    init(initialYear: Int) { _year = State(initialValue: initialYear) }

    private var years: [Int] {
        Array(Set((tax.acb?.years ?? []) + [TaxCenter.year])).sorted(by: >)
    }

    var body: some View {
        let s = tax.acb?.summary(year)
        List {
            Section {
                Picker(L("Tax year"), selection: $year) {
                    ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.accentText)
            }
            .listRowBackground(AppTheme.cardBackground)

            if let s {
                Section { totals(s) }
                    .listRowBackground(AppTheme.cardBackground)

                if s.hasIncomplete {
                    Section {
                        Label(L("Some sales have incomplete cost history, so these totals may be off. See Cost basis for what's missing."),
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundColor(AppTheme.warning)
                    }
                    .listRowBackground(AppTheme.cardBackground)
                }

                Section {
                    if s.dispositions.isEmpty {
                        Text(L("No sales in non-registered accounts this year."))
                            .font(.footnote).foregroundColor(AppTheme.secondaryText)
                    }
                    ForEach(s.dispositions) { d in dispositionRow(d) }
                } header: {
                    Text(L("Sales"))
                } footer: {
                    Text(L("Information only, not tax advice. On your return, capital gains go on Schedule 3. Compare with the T5008 slips from your brokers — they often leave out the cost, which is what this fills in."))
                        .font(AppTheme.caption(11))
                }
                .listRowBackground(AppTheme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle(String(format: L("%d capital gains"), year))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let s, !s.dispositions.isEmpty, let url = exportFile(s) {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel(L("Export for your tax return"))
                }
            }
        }
    }

    private func money(_ v: Double) -> String {
        hideValues ? PortfolioPrivacy.shortMask : Money.format(v, currency: "CAD")
    }

    private func signed(_ v: Double) -> String {
        hideValues ? PortfolioPrivacy.shortMask : (v < 0 ? "−" : "") + Money.format(abs(v), currency: "CAD")
    }

    private func totals(_ s: CapitalGainsSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Net capital gain"))
                .font(.footnote).foregroundColor(AppTheme.secondaryText)
            Text(signed(s.net))
                .font(AppTheme.heroNumber(.title))
                .foregroundColor(AppTheme.primaryText)
                .leftToRightNumber()
            Divider()
            line(L("Proceeds"), money(s.proceeds))
            line(L("Adjusted cost base"), money(s.acb))
            line(L("Commissions and fees"), money(s.outlays))
            if s.denied > 0.005 {
                line(L("Losses denied (superficial)"), money(s.denied))
            }
            Divider()
            line(L("Taxable portion (50% inclusion)"), money(s.taxablePortion), bold: true)
            if s.net < 0 {
                Text(L("A net capital loss isn't taxable. It can be applied to gains in the past 3 years or carried forward."))
                    .font(.caption).foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, AppTheme.Space.s)
    }

    private func line(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).font(AppTheme.number(14, weight: bold ? .semibold : .regular)).leftToRightNumber()
        }
        .font(.footnote)
        .foregroundColor(bold ? AppTheme.primaryText : AppTheme.secondaryText)
    }

    private func dispositionRow(_ d: Disposition) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(d.symbol).font(.subheadline.weight(.semibold)).foregroundColor(AppTheme.primaryText)
                Text(TaxCenter.date(d.day)?.formatted(date: .abbreviated, time: .omitted) ?? d.day)
                    .font(.caption).foregroundColor(AppTheme.secondaryText)
                Spacer()
                Text(signed(d.reportableGainCAD))
                    .font(AppTheme.number(14, weight: .semibold))
                    .foregroundColor(d.reportableGainCAD >= 0 ? AppTheme.positive : AppTheme.negative)
                    .leftToRightNumber()
            }
            Text(String(format: L("%@ shares · proceeds %@ · cost %@ · %@"),
                        String(format: "%g", d.units), money(d.proceedsCAD), money(d.acbCAD + d.outlaysCAD), d.accountName))
                .font(.caption).foregroundColor(AppTheme.secondaryText)
            if d.currency.uppercased() != "CAD" {
                Text(String(format: L("%@ at %@ CAD (Bank of Canada%@)"), d.currency, String(format: "%.4f", d.fx.cadPerUnit),
                            d.fx.exact ? "" : L(", estimated")))
                    .font(.caption2).foregroundColor(AppTheme.tertiaryText)
            }
            if d.deniedLossCAD > 0.005 {
                Text(String(format: L("Superficial loss: %@ denied"), money(d.deniedLossCAD)))
                    .font(.caption).foregroundColor(AppTheme.warning)
            }
            if d.incomplete {
                Text(L("Cost history incomplete")).font(.caption).foregroundColor(AppTheme.warning)
            }
        }
        .padding(.vertical, 2)
    }

    private func exportFile(_ s: CapitalGainsSummary) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Orion capital gains \(s.year).csv")
        do { try ACBEngine.csv(s).write(to: url, atomically: true, encoding: .utf8); return url } catch { return nil }
    }
}
