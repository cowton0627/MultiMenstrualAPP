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

    func testAppearComputesRangesFromExistingRecords() {
        let person = TestCoreDataFactory.makePerson(in: context, colorHex: "#AABBCC")
        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-01-01"),
                                       end: day("2026-01-05"))
        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-02-01"),
                                       end: day("2026-02-04"))
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))
        vm.send(.appear)

        XCTAssertEqual(vm.state.ranges.count, 2)
        XCTAssertEqual(vm.state.ranges.map(\.start), [day("2026-01-01"), day("2026-02-01")])
        XCTAssertEqual(vm.state.predicted.count, 1,
                       "Two start dates is enough for the predictor to project a window")
    }

    // MARK: - tap day

    func testTapDayOnEmptyDayEmitsOpenEditorWithNoRecord() {
        let person = TestCoreDataFactory.makePerson(in: context)
        try! context.save()

        let vm = CalendarViewModel(ctx: context, person: PersonProfile(person: person))
        vm.send(.appear)

        var captured: CalendarViewModel.Action?
        vm.onAction = { captured = $0 }

        vm.send(.tapDay(day("2026-03-10")))

        guard case .openEditor(let context) = captured else {
            return XCTFail("expected .openEditor, got \(String(describing: captured))")
        }
        XCTAssertNil(context.recordObjectID)
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
        vm.send(.appear)

        var captured: CalendarViewModel.Action?
        vm.onAction = { captured = $0 }

        vm.send(.tapDay(day("2026-03-04")))

        guard case .openEditor(let editorCtx) = captured else {
            return XCTFail("expected .openEditor, got \(String(describing: captured))")
        }
        XCTAssertEqual(editorCtx.recordObjectID, record.objectID)
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
        vm.send(.appear)

        var captured: CalendarViewModel.Action?
        vm.onAction = { captured = $0 }

        vm.send(.tapDay(day("2026-04-10")))

        guard case .presentRecordPicker(let pickerDay, let records) = captured else {
            return XCTFail("expected .presentRecordPicker, got \(String(describing: captured))")
        }
        XCTAssertEqual(pickerDay, day("2026-04-10"))
        XCTAssertEqual(Set(records.map(\.objectID)), Set([r1.objectID, r2.objectID]))
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
