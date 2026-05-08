//
//  CyclePredictorTests.swift
//  MultiMenstrualAPPTests
//
//  Created by Codex on 2026/4/7.
//

import XCTest
@testable import MultiMenstrualAPP

final class CyclePredictorTests: XCTestCase {
    func testPredictedNextStartIsNilWhenNoRecordsExist() {
        let predictor = CyclePredictor(records: [])

        XCTAssertNil(predictor.predictedNextStart)
    }

    func testPredictedNextStartUsesDefault28DaysWhenOnlyOneRecordExists() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)
        let start = makeDate(year: 2026, month: 4, day: 1)
        let record = TestCoreDataFactory.makeRecord(in: context,
                                                    person: person,
                                                    start: start)

        let predictor = CyclePredictor(records: [record])

        XCTAssertSameDay(predictor.predictedNextStart, start.addDays(28))
    }

    func testPredictedNextStartSortsRecordsBeforeCalculating() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)

        let records = [
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 3, day: 1)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 1, day: 1)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 1, day: 29)),
        ]

        let predictor = CyclePredictor(records: records)

        XCTAssertSameDay(predictor.predictedNextStart,
                         makeDate(year: 2026, month: 3, day: 31))
    }

    func testPredictedNextStartUsesAverageOfRecentThreeCycles() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)

        let records = [
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 1, day: 1)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 1, day: 30)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 2, day: 28)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 3, day: 30)),
        ]

        let predictor = CyclePredictor(records: records)

        XCTAssertSameDay(predictor.predictedNextStart,
                         makeDate(year: 2026, month: 4, day: 28))
    }

    func testPredictedNextStartUsesOnlyRecentThreeCyclesWhenMoreHistoryExists() {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext
        let person = TestCoreDataFactory.makePerson(in: context)

        let records = [
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2025, month: 11, day: 1)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2025, month: 12, day: 31)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 1, day: 28)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 2, day: 25)),
            TestCoreDataFactory.makeRecord(in: context, person: person, start: makeDate(year: 2026, month: 3, day: 25)),
        ]

        let predictor = CyclePredictor(records: records)

        XCTAssertSameDay(predictor.predictedNextStart,
                         makeDate(year: 2026, month: 4, day: 22))
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

    private func XCTAssertSameDay(_ lhs: Date?,
                                  _ rhs: Date,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) {
        guard let lhs else {
            XCTFail("Expected date but got nil", file: file, line: line)
            return
        }

        XCTAssertEqual(Calendar.current.startOfDay(for: lhs),
                       Calendar.current.startOfDay(for: rhs),
                       file: file,
                       line: line)
    }
}
