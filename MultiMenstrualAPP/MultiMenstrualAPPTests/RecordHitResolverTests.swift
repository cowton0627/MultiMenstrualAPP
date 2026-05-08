//
//  RecordHitResolverTests.swift
//  MultiMenstrualAPPTests
//
//  Created by Codex on 2026/4/7.
//

import XCTest
@testable import MultiMenstrualAPP

final class RecordHitResolverTests: XCTestCase {
    func testReturnsEmptyArrayWhenNoRecordsExist() {
        let resolver = RecordHitResolver()

        let hits = resolver.records(on: makeDate(year: 2026, month: 4, day: 3),
                                    in: [])

        XCTAssertTrue(hits.isEmpty)
    }

    func testReturnsClosedRangeRecordsContainingTappedDay() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let matching = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 1),
            end: makeDate(year: 2026, month: 4, day: 5)
        )
        let nonMatching = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 10),
            end: makeDate(year: 2026, month: 4, day: 12)
        )

        let resolver = RecordHitResolver()
        let hits = resolver.records(on: makeDate(year: 2026, month: 4, day: 3),
                                    in: [matching, nonMatching])

        XCTAssertEqual(hits, [matching])
    }

    func testClosedRangeIncludesStartAndEndDates() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 1),
            end: makeDate(year: 2026, month: 4, day: 5)
        )

        let resolver = RecordHitResolver()
        let startHits = resolver.records(on: makeDate(year: 2026, month: 4, day: 1),
                                         in: [record])
        let endHits = resolver.records(on: makeDate(year: 2026, month: 4, day: 5),
                                       in: [record])

        XCTAssertEqual(startHits, [record])
        XCTAssertEqual(endHits, [record])
    }

    func testTreatsOngoingRecordAsMatchingAnyDateAfterStart() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let ongoing = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 2),
            end: nil
        )

        let resolver = RecordHitResolver()
        let hits = resolver.records(on: makeDate(year: 2026, month: 4, day: 8),
                                    in: [ongoing])

        XCTAssertEqual(hits, [ongoing])
    }

    func testOngoingRecordDoesNotMatchDatesBeforeStart() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let ongoing = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 2),
            end: nil
        )

        let resolver = RecordHitResolver()
        let hits = resolver.records(on: makeDate(year: 2026, month: 4, day: 1),
                                    in: [ongoing])

        XCTAssertTrue(hits.isEmpty)
    }

    func testReturnsMultipleRecordsWhenRangesOverlapTappedDay() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let first = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 1),
            end: makeDate(year: 2026, month: 4, day: 5)
        )
        let second = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 3),
            end: makeDate(year: 2026, month: 4, day: 8)
        )

        let resolver = RecordHitResolver()
        let hits = resolver.records(on: makeDate(year: 2026, month: 4, day: 4),
                                    in: [first, second])

        XCTAssertEqual(hits, [first, second])
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date!
    }
}
