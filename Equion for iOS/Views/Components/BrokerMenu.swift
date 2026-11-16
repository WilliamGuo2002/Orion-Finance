import SwiftUI
import UIKit

// MARK: - Open in your broker
/// Orion explains; it never places trades (no dealer registration, and App Store 3.2.1(viii)
/// requires trading apps to come from licensed firms). When someone wants to act, this hands them
/// to their own broker. The user's linked brokers come first. Each opens its website, which
/// opens the broker's app instead when it's installed (universal link).
enum BrokerLinks {
    struct Broker: Identifiable {
        var id: String { name }
        let name: String
        /// Lowercased fragments matched against linked institution names.
        let matches: [String]
        let url: (String) -> URL?
    }

    static let all: [Broker] = [
        Broker(name: "Wealthsimple", matches: ["wealthsimple"]) { _ in URL(string: "https://my.wealthsimple.com") },
        Broker(name: "Questrade", matches: ["questrade"]) { _ in URL(string: "https://my.questrade.com") },
        Broker(name: "Interactive Brokers", matches: ["interactive brokers", "ibkr"]) { _ in URL(string: "https://www.interactivebrokers.ca") },
        Broker(name: "TD Direct Investing", matches: ["td direct", "td webbroker", "td bank", "td waterhouse"]) { _ in URL(string: "https://webbroker.td.com") },
        Broker(name: "RBC Direct Investing", matches: ["rbc"]) { _ in URL(string: "https://www.rbcdirectinvesting.com") },
        Broker(name: "BMO InvestorLine", matches: ["bmo"]) { _ in URL(string: "https://www.bmoinvestorline.com") },
        Broker(name: "CIBC Investor's Edge", matches: ["cibc"]) { _ in URL(string: "https://www.investorsedge.cibc.com") },
        Broker(name: "Scotia iTRADE", matches: ["scotia"]) { _ in URL(string: "https://www.scotiaitrade.com") },
        Broker(name: "National Bank Direct Brokerage", matches: ["national bank", "nbdb"]) { _ in URL(string: "https://nbdb.ca") },
        Broker(name: "Robinhood", matches: ["robinhood"]) { symbol in URL(string: "https://robinhood.com/stocks/\(symbol)") },
    ]

    /// Brokers the user has linked, in the order they appear in Linked Accounts.
    @MainActor
    static var linked: [Broker] {
        let names = BrokerageManager.shared.currentAccounts.map { $0.institution.lowercased() }
        var seen = Set<String>()
        return names.compactMap { inst in all.first { b in b.matches.contains { inst.contains($0) } } }
            .filter { seen.insert($0.name).inserted }
    }
}

struct BrokerMenu: View {
    let symbol: String
    @Environment(\.openURL) private var openURL

    var body: some View {
        let linked = BrokerLinks.linked
        let linkedNames = Set(linked.map(\.name))
        let others = BrokerLinks.all.filter { !linkedNames.contains($0.name) }
        Menu {
            Section(L("Orion doesn't place trades. To buy or sell, use your broker.")) {
                ForEach(linked) { broker in item(broker) }
                if linked.isEmpty {
                    ForEach(others.prefix(2)) { broker in item(broker) }
                }
            }
            Menu(L("Other brokers")) {
                ForEach(linked.isEmpty ? Array(others.dropFirst(2)) : others) { broker in item(broker) }
            }
            Button {
                UIPasteboard.general.string = symbol
            } label: {
                Label(String(format: L("Copy %@"), symbol), systemImage: "doc.on.doc")
            }
        } label: {
            Image(systemName: "arrow.up.forward.app")
                .font(.body.weight(.medium))
                .foregroundColor(AppTheme.primaryText)
        }
        .accessibilityLabel(L("Open in your broker"))
    }

    private func item(_ broker: BrokerLinks.Broker) -> some View {
        Button {
            if let url = broker.url(symbol) { openURL(url) }
        } label: {
            Label(String(format: L("Open in %@"), broker.name), systemImage: "arrow.up.forward.app")
        }
    }
}
