//
//  PeriodRangeMapperTests.swift
//  MultiMenstrualAPPTests
//
//  Created by Codex on 2026/4/7.
//

import XCTest
@testable import MultiMenstrualAPP

final class PeriodRangeMapperTests: XCTestCase {
    func testMakeRangesReturnsEmptyArrayWhenNoRecordsExist() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)

        let mapper = PeriodRangeMapper()
        let ranges = mapper.makeRanges(from: [], person: person)

        XCTAssertTrue(ranges.isEmpty)
    }

    func testMakeRangesUsesFallbackDaysForOngoingRecords() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context,
                                                    colorHex: "#007AFF")
        let start = makeDate(year: 2026, month: 4, day: 10)
        let ongoing = TestCoreDataFactory.makeRecord(in: context,
                                                     person: person,
                                                     start: start,
                                                     end: nil)

        let mapper = PeriodRangeMapper(ongoingFallbackDays: 5)
        let ranges = mapper.makeRanges(from: [ongoing], person: person)

        XCTAssertEqual(ranges.count, 1)
        XCTAssertSameDay(ranges[0].start, start)
        XCTAssertSameDay(ranges[0].end, start.addDays(5))
    }

    func testMakeRangesSkipsRecordsWhoseEndDateIsBeforeStartDate() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let invalid = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 10),
            end: makeDate(year: 2026, month: 4, day: 8)
        )

        let mapper = PeriodRangeMapper()
        let ranges = mapper.makeRanges(from: [invalid], person: person)

        XCTAssertTrue(ranges.isEmpty)
    }

    func testMakeRangesMapsClosedRecordStartEndAndPersonMetadata() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context,
                                                    name: "Alice",
                                                    colorHex: "#34C759")
        let record = TestCoreDataFactory.makeRecord(
            in: context,
            person: person,
            start: makeDate(year: 2026, month: 4, day: 1),
            end: makeDate(year: 2026, month: 4, day: 4)
        )

        let mapper = PeriodRangeMapper()
        let ranges = mapper.makeRanges(from: [record], person: person)

        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges[0].personId, person.id)
        XCTAssertEqual(ranges[0].personName, "Alice")
        XCTAssertSameDay(ranges[0].start, makeDate(year: 2026, month: 4, day: 1))
        XCTAssertSameDay(ranges[0].end, makeDate(year: 2026, month: 4, day: 4))
    }

    func testMakePredictedWindowsReturnsEmptyArrayWhenNoRecordsExist() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)

        let mapper = PeriodRangeMapper()
        let windows = mapper.makePredictedWindows(from: [], person: person)

        XCTAssertTrue(windows.isEmpty)
    }

    func testMakePredictedWindowsCreatesPlusMinusTwoDayWindow() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let records = [
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 1, day: 1)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 1, day: 29)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 2, day: 26)),
        ]

        let mapper = PeriodRangeMapper()
        let windows = mapper.makePredictedWindows(from: records, person: person)

        XCTAssertEqual(windows.count, 1)
        XCTAssertSameDay(windows[0].range.lowerBound,
                         makeDate(year: 2026, month: 3, day: 24))
        XCTAssertSameDay(windows[0].range.upperBound,
                         makeDate(year: 2026, month: 3, day: 28))
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

    private func XCTAssertSameDay(_ lhs: Date,
                                  _ rhs: Date,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) {
        XCTAssertEqual(Calendar.current.startOfDay(for: lhs),
                       Calendar.current.startOfDay(for: rhs),
                       file: file,
                       line: line)
    }
}
