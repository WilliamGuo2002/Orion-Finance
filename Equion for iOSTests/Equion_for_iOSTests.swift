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
