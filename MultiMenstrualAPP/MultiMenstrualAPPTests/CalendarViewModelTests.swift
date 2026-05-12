//
//  CalendarViewModelTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
@testable import MultiMenstrualAPP

final class CalendarViewModelTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext { container.viewContext }

    override func setUp() {
        super.setUp()
        container = TestCoreDataFactory.makeContainer()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    // MARK: - state seeding

    func testInitTakesTitleFromPersonProfileDisplayName() {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))

        XCTAssertEqual(vm.state.title, "Aiko")
    }

    func testInitImmediatelyComputesRangesWithoutNeedingAppear() {
        let person = TestCoreDataFactory.makePerson(in: context, colorHex: "#AABBCC")
        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-01-01"),
                                       end: day("2026-01-05"))
        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-02-01"),
                                       end: day("2026-02-04"))
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))

        XCTAssertEqual(vm.state.ranges.count, 2)
        XCTAssertEqual(vm.state.ranges.map(\.start), [day("2026-01-01"), day("2026-02-01")])
        XCTAssertEqual(vm.state.predicted.count, 1,
                       "Two start dates is enough for the predictor to project a window")
    }

    func testFRCPropagatesNewRecordsWithoutManualRefresh() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        try context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))
        XCTAssertTrue(vm.state.ranges.isEmpty)

        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-05-01"),
                                       end: day("2026-05-05"))
        try context.save()

        XCTAssertEqual(vm.state.ranges.count, 1,
                       "FRC delegate should push the new record into state.ranges")
        XCTAssertEqual(vm.state.ranges[0].start, day("2026-05-01"))
    }

    func testInitWithMissingPersonDoesNotLeakOtherPeoplesRecords() throws {
        // Seed another person with records, then build a profile whose objectID
        // points at a now-deleted person to simulate the race window.
        let other = TestCoreDataFactory.makePerson(in: context, name: "Other")
        TestCoreDataFactory.makeRecord(in: context, person: other,
                                       start: day("2026-06-01"),
                                       end: day("2026-06-05"))
        let ghost = TestCoreDataFactory.makePerson(in: context, name: "Ghost")
        try context.save()
        let ghostProfile = PersonProfile(person: ghost)
        context.delete(ghost)
        try context.save()

        let vm = CalendarViewModel(ctx: context, person: ghostProfile)

        XCTAssertTrue(vm.state.ranges.isEmpty,
                      "missing person must not fall back to fetching everyone's records")
        XCTAssertEqual(vm.state.title, "Ghost",
                       "title still reflects the profile passed in")
    }

    // MARK: - tap day

    func testTapDayOnEmptyDayEmitsOpenEditorWithNoRecord() {
        let person = TestCoreDataFactory.makePerson(in: context)
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))

        var captured: CalendarViewModel.Action?
        vm.onAction = { captured = $0 }

        vm.send(.tapDay(day("2026-03-10")))

        guard case .openEditor(let context) = captured else {
            return XCTFail("expected .openEditor, got \(String(describing: captured))")
        }
        XCTAssertNil(context.recordID)
        XCTAssertEqual(context.defaultStart, day("2026-03-10"))
        XCTAssertEqual(context.defaultEnd, day("2026-03-15"))
    }

    func testTapDayWithASingleHitEmitsOpenEditorForThatRecord() {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-03-01"),
                                                    end: day("2026-03-06"))
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))

        var captured: CalendarViewModel.Action?
        vm.onAction = { captured = $0 }

        vm.send(.tapDay(day("2026-03-04")))

        guard case .openEditor(let editorCtx) = captured else {
            return XCTFail("expected .openEditor, got \(String(describing: captured))")
        }
        XCTAssertEqual(editorCtx.recordID, PeriodRecordID(record.objectID))
        XCTAssertEqual(editorCtx.defaultStart, day("2026-03-01"))
        XCTAssertEqual(editorCtx.defaultEnd, day("2026-03-06"))
    }

    func testTapDayWithMultipleHitsPresentsPickerOfSnapshots() {
        let person = TestCoreDataFactory.makePerson(in: context)
        // Two records both covering 2026-04-10
        let r1 = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                start: day("2026-04-08"),
                                                end: day("2026-04-12"))
        let r2 = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                start: day("2026-04-09"),
                                                end: day("2026-04-11"))
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))

        var captured: CalendarViewModel.Action?
        vm.onAction = { captured = $0 }

        vm.send(.tapDay(day("2026-04-10")))

        guard case .presentRecordPicker(let pickerDay, let records) = captured else {
            return XCTFail("expected .presentRecordPicker, got \(String(describing: captured))")
        }
        XCTAssertEqual(pickerDay, day("2026-04-10"))
        XCTAssertEqual(Set(records.map(\.id)),
                       Set([PeriodRecordID(r1.objectID), PeriodRecordID(r2.objectID)]))
    }

    // MARK: - misc

    func testSetVisibleMonthSnapsToTheStartOfTheMonth() {
        let person = TestCoreDataFactory.makePerson(in: context)
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))
        vm.send(.setVisibleMonth(day("2026-06-17")))

        XCTAssertEqual(vm.state.visibleMonth, day("2026-06-01"))
    }

    // MARK: - helpers

    private func day(_ ymd: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: ymd)!.stripTime()
    }
}
