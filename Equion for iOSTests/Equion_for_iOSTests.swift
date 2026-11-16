//
//  Equion_for_iOSTests.swift
//  Equion for iOSTests
//
//  Created by William Kuo on 2025-08-03.
//

import Testing
@testable import Equion_for_iOS

struct PriceChangeTests {

    /// NVDA on Nov 13 2026: last 162.85, previous close 166.19. Every screen must show −3.34 / −2.01%.
    @Test func dailyChangeUsesPreviousClose() throws {
        let ch = try #require(PriceChange(price: 162.85, reference: 166.19))
        #expect(abs(ch.amount - (-3.34)) < 0.005)
        #expect(abs(ch.percent - (-2.0098)) < 0.001)
        #expect(String(format: "%.2f", ch.percent) == "-2.01")
        #expect(!ch.isUp)
    }

    @Test func dailyPercentHelperMatches() {
        #expect(String(format: "%.2f", PriceChange.dailyPercent(price: 162.85, previousClose: 166.19)) == "-2.01")
    }

    @Test func missingReferenceIsNotAZeroDivide() {
        #expect(PriceChange(price: 100, reference: 0) == nil)
        #expect(PriceChange(price: 0, reference: 100) == nil)
        #expect(PriceChange(price: .nan, reference: 100) == nil)
        #expect(PriceChange.dailyPercent(price: 100, previousClose: 0) == 0)
    }

    @Test func flatIsUp() throws {
        let ch = try #require(PriceChange(price: 50, reference: 50))
        #expect(ch.amount == 0)
        #expect(ch.isUp)
    }
}

// MARK: - ACB / capital gains (numbers worked by hand)

struct ACBEngineTests {
    private func act(_ id: String, _ type: String, _ date: String, _ symbol: String, units: Double, price: Double? = nil,
                     fee: Double? = nil, account: String = "tax", currency: String = "CAD") -> BrokerActivity {
        BrokerActivity(id: id, accountId: account, type: type, date: date, symbol: symbol, units: units,
                       price: price, amount: nil, currency: currency, fee: fee)
    }

    private func input(_ acts: [BrokerActivity], held: [String: Double] = [:], heldTaxable: [String: Double]? = nil,
                       transferCosts: [String: Double] = [:], usdcad: Double = 1.35) -> ACBInput {
        ACBInput(activities: acts,
                 accountTypes: ["tax": .taxable, "tax2": .taxable, "tfsa": .tfsa],
                 accountNames: ["tax": "Personal", "tax2": "Margin", "tfsa": "TFSA"],
                 heldNowAnywhere: held, heldNowTaxable: heldTaxable ?? held, transferCosts: transferCosts,
                 today: "2026-11-16",
                 rate: { cur, _ in cur == "USD" ? FXQuote(cadPerUnit: usdcad, exact: true) : FXQuote(cadPerUnit: 1, exact: true) })
    }

    /// Two brokers, one pool: 100 @ $10 (fee $5) + 100 @ $20 (fee $5) → ACB $3,010 / 200 = $15.05.
    /// Sell 50 @ $30, fee $5: proceeds 1,500, ACB 752.50, outlays 5 → gain 742.50.
    @Test func poolsAcrossTaxableAccounts() throws {
        let r = ACBEngine.compute(input([
            act("b1", "BUY", "2025-01-10", "XYZ", units: 100, price: 10, fee: 5, account: "tax"),
            act("b2", "BUY", "2025-03-10", "XYZ", units: 100, price: 20, fee: 5, account: "tax2"),
            act("s1", "SELL", "2025-06-10", "XYZ", units: 50, price: 30, fee: 5, account: "tax"),
        ], held: ["XYZ": 150]))
        let d = try #require(r.dispositions.first)
        #expect(abs(d.acbCAD - 752.50) < 0.01)
        #expect(abs(d.gainCAD - 742.50) < 0.01)
        let p = try #require(r.positions.first)
        #expect(abs(p.acbCAD - 2257.50) < 0.01)
        #expect(abs(p.acbPerUnit - 15.05) < 0.0001)
        #expect(p.issues.isEmpty)
    }

    /// Registered accounts never enter the pool or produce gains.
    @Test func ignoresRegisteredAccounts() {
        let r = ACBEngine.compute(input([
            act("b1", "BUY", "2025-01-10", "XYZ", units: 10, price: 10, account: "tfsa"),
            act("s1", "SELL", "2025-02-10", "XYZ", units: 10, price: 50, account: "tfsa"),
        ]))
        #expect(r.dispositions.isEmpty)
        #expect(r.positions.isEmpty)
    }

    /// USD trades convert at the rate of each trade date: 10 @ US$100 at 1.30 = 1,300; sell 10 @ US$120 at 1.40 = 1,680.
    @Test func convertsEachTradeAtItsOwnRate() throws {
        let acts = [
            act("b1", "BUY", "2024-01-10", "AAPL", units: 10, price: 100, currency: "USD"),
            act("s1", "SELL", "2025-01-10", "AAPL", units: 10, price: 120, currency: "USD"),
        ]
        let inp = ACBInput(activities: acts, accountTypes: ["tax": .taxable], accountNames: [:],
                           heldNowAnywhere: [:], heldNowTaxable: [:], transferCosts: [:], today: "2026-11-16",
                           rate: { _, day in FXQuote(cadPerUnit: day < "2025-01-01" ? 1.30 : 1.40, exact: true) })
        let d = try #require(ACBEngine.compute(inp).dispositions.first)
        #expect(abs(d.acbCAD - 1300) < 0.01)
        #expect(abs(d.proceedsCAD - 1680) < 0.01)
        #expect(abs(d.gainCAD - 380) < 0.01)
    }

    /// Sell 100 at a $500 loss, buy 100 back 10 days later in a TFSA and still hold → loss fully denied,
    /// and (registered account) not added to any pool.
    @Test func superficialLossAcrossAccounts() throws {
        let r = ACBEngine.compute(input([
            act("b1", "BUY", "2026-01-05", "XYZ", units: 100, price: 20),
            act("s1", "SELL", "2026-03-02", "XYZ", units: 100, price: 15),
            act("b2", "BUY", "2026-03-12", "XYZ", units: 100, price: 15, account: "tfsa"),
        ], held: ["XYZ": 100], heldTaxable: [:]))
        let d = try #require(r.dispositions.first)
        #expect(abs(d.gainCAD - (-500)) < 0.01)
        #expect(abs(d.deniedLossCAD - 500) < 0.01)
        #expect(abs(d.reportableGainCAD) < 0.01)
        #expect(r.summary(2026).net == 0)
    }

    /// Partial: sold 100 at a $1,000 loss, bought back 40 in the same taxable account → 40% denied ($400),
    /// added to the cost of the 40 new shares (40 × $10 + 400 = $800).
    @Test func partialSuperficialLossRaisesNewCost() throws {
        let r = ACBEngine.compute(input([
            act("b1", "BUY", "2026-01-05", "XYZ", units: 100, price: 20),
            act("s1", "SELL", "2026-03-02", "XYZ", units: 100, price: 10),
            act("b2", "BUY", "2026-03-20", "XYZ", units: 40, price: 10),
        ], held: ["XYZ": 40]))
        let d = try #require(r.dispositions.first)
        #expect(abs(d.deniedLossCAD - 400) < 0.01)
        #expect(abs(d.reportableGainCAD - (-600)) < 0.01)
        let p = try #require(r.positions.first)
        #expect(abs(p.acbCAD - 800) < 0.01)
    }

    /// Sold 30 days after buying more, but held nothing afterwards → not superficial.
    @Test func noDenialWhenNothingHeldAfter() throws {
        let r = ACBEngine.compute(input([
            act("b1", "BUY", "2026-01-05", "XYZ", units: 100, price: 20),
            act("b2", "BUY", "2026-02-20", "XYZ", units: 100, price: 12),
            act("s1", "SELL", "2026-03-02", "XYZ", units: 200, price: 10),
        ], held: [:]))
        #expect(try #require(r.dispositions.first).deniedLossCAD == 0)
    }

    /// A 2-for-1 split doubles units and keeps cost.
    @Test func splitKeepsCost() throws {
        let r = ACBEngine.compute(input([
            act("b1", "BUY", "2025-01-05", "XYZ", units: 10, price: 100),
            act("sp", "SPLIT", "2025-06-01", "XYZ", units: 10),
        ], held: ["XYZ": 20]))
        let p = try #require(r.positions.first)
        #expect(abs(p.acbCAD - 1000) < 0.01)
        #expect(abs(p.acbPerUnit - 50) < 0.0001)
    }

    /// Transfer-in with no cost is flagged until the user enters it.
    @Test func transferInNeedsCost() throws {
        let acts = [act("t1", "EXTERNAL_ASSET_TRANSFER_IN", "2025-01-05", "XYZ", units: 50)]
        let flagged = try #require(ACBEngine.compute(input(acts, held: ["XYZ": 50])).positions.first)
        #expect(flagged.issues.contains { $0.kind == .transferInWithoutCost && $0.activityIds == ["t1"] })
        let fixed = try #require(ACBEngine.compute(input(acts, held: ["XYZ": 50], transferCosts: ["t1": 1234])).positions.first)
        #expect(fixed.issues.isEmpty)
        #expect(abs(fixed.acbCAD - 1234) < 0.01)
    }

    /// Selling more than the history shows marks the gain as incomplete.
    @Test func sellBeyondHistoryIsIncomplete() throws {
        let r = ACBEngine.compute(input([act("s1", "SELL", "2025-01-05", "XYZ", units: 10, price: 10)]))
        #expect(try #require(r.dispositions.first).incomplete)
    }

    @Test func summaryNetsGainsAndLosses() {
        let r = ACBEngine.compute(input([
            act("b1", "BUY", "2026-01-05", "AAA", units: 10, price: 10),
            act("s1", "SELL", "2026-02-05", "AAA", units: 10, price: 30),   // +200
            act("b2", "BUY", "2026-01-05", "BBB", units: 10, price: 10),
            act("s2", "SELL", "2026-02-05", "BBB", units: 10, price: 5),    // −50
        ]))
        let s = r.summary(2026)
        #expect(abs(s.net - 150) < 0.01)
        #expect(abs(s.taxablePortion - 75) < 0.01)
    }
}
