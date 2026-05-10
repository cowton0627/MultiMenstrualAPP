//
//  RecordPeriodViewModelTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
@testable import MultiMenstrualAPP

final class RecordPeriodViewModelTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext { container.viewContext }
    private var repository: PeriodRecordRepository!

    override func setUp() {
        super.setUp()
        container = TestCoreDataFactory.makeContainer()
        repository = PeriodRecordRepository(context: context)
    }

    override func tearDown() {
        repository = nil
        container = nil
        super.tearDown()
    }

    // MARK: - init seeding

    func testInitWithoutEditingUsesProvidedDefaults() {
        let person = TestCoreDataFactory.makePerson(in: context)
        try! context.save()
        let profile = PersonProfile(person: person)

        let vm = RecordPeriodViewModel(person: profile,
                                       defaultStart: day("2026-04-10"),
                                       defaultEnd: day("2026-04-15"),
                                       repository: repository)

        XCTAssertEqual(vm.startDate, day("2026-04-10"))
        XCTAssertEqual(vm.endDate, day("2026-04-15"))
        XCTAssertFalse(vm.inProgress)
        XCTAssertEqual(vm.notes, "")
    }

    func testInitWithSnapshotPopulatesFromSnapshot() {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-05-01"),
                                                    end: day("2026-05-06"),
                                                    notes: "headache")
        try! context.save()

        let vm = RecordPeriodViewModel(person: PersonProfile(person: person),
                                       defaultStart: day("2026-05-20"),
                                       defaultEnd: day("2026-05-25"),
                                       editing: PeriodRecordSnapshot(record: record),
                                       repository: repository)

        XCTAssertEqual(vm.startDate, day("2026-05-01"))
        XCTAssertEqual(vm.endDate, day("2026-05-06"))
        XCTAssertEqual(vm.notes, "headache")
        XCTAssertFalse(vm.inProgress)
    }

    func testInitWithOngoingSnapshotMarksInProgress() {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-06-01"),
                                                    end: nil)
        try! context.save()

        let vm = RecordPeriodViewModel(person: PersonProfile(person: person),
                                       defaultStart: day("2026-06-01"),
                                       defaultEnd: day("2026-06-06"),
                                       editing: PeriodRecordSnapshot(record: record),
                                       repository: repository)

        XCTAssertTrue(vm.inProgress)
        XCTAssertEqual(vm.startDate, day("2026-06-01"))
        XCTAssertEqual(vm.endDate, day("2026-06-06"),
                       "endDate falls back to default when snapshot has no end")
    }

    // MARK: - canSave

    func testCanSaveRejectsEndBeforeStartUnlessOngoing() {
        let vm = makeFreshVM()
        vm.startDate = day("2026-04-10")
        vm.endDate = day("2026-04-05")
        vm.inProgress = false

        XCTAssertFalse(vm.canSave)
    }

    func testCanSaveAllowsAnyDateOrderWhenOngoing() {
        let vm = makeFreshVM()
        vm.startDate = day("2026-04-10")
        vm.endDate = day("2026-04-05")  // ignored when ongoing
        vm.inProgress = true

        XCTAssertTrue(vm.canSave)
    }

    // MARK: - save

    func testSaveCreatesNewRecordWhenNotEditing() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        try! context.save()

        let vm = RecordPeriodViewModel(person: PersonProfile(person: person),
                                       defaultStart: day("2026-07-01"),
                                       defaultEnd: day("2026-07-06"),
                                       repository: repository)
        vm.notes = "  spotting  "
        try vm.save()

        let stored = (try context.fetch(PeriodRecord.fetchRequest())) as! [PeriodRecord]
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored[0].startDate?.stripTime(), day("2026-07-01"))
        XCTAssertEqual(stored[0].endDate?.stripTime(), day("2026-07-06"))
        XCTAssertEqual(stored[0].notes, "spotting", "save should trim whitespace via repository")
    }

    func testSaveUpdatesExistingRecordWhenEditingSnapshot() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-08-01"),
                                                    end: day("2026-08-05"))
        try! context.save()

        let vm = RecordPeriodViewModel(person: PersonProfile(person: person),
                                       defaultStart: day("2026-08-01"),
                                       defaultEnd: day("2026-08-05"),
                                       editing: PeriodRecordSnapshot(record: record),
                                       repository: repository)
        vm.endDate = day("2026-08-08")
        try vm.save()

        // Still only one record, with the new end
        let all = (try context.fetch(PeriodRecord.fetchRequest())) as! [PeriodRecord]
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].endDate?.stripTime(), day("2026-08-08"))
    }

    func testSaveWithInProgressClearsEndDate() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        try! context.save()

        let vm = RecordPeriodViewModel(person: PersonProfile(person: person),
                                       defaultStart: day("2026-09-01"),
                                       defaultEnd: day("2026-09-06"),
                                       repository: repository)
        vm.inProgress = true
        try vm.save()

        let stored = (try context.fetch(PeriodRecord.fetchRequest())) as! [PeriodRecord]
        XCTAssertEqual(stored.count, 1)
        XCTAssertNil(stored[0].endDate)
    }

    // MARK: - helpers

    private func makeFreshVM() -> RecordPeriodViewModel {
        let person = TestCoreDataFactory.makePerson(in: context)
        try! context.save()
        return RecordPeriodViewModel(person: PersonProfile(person: person),
                                     defaultStart: day("2026-01-01"),
                                     defaultEnd: day("2026-01-06"),
                                     repository: repository)
    }

    private func day(_ ymd: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: ymd)!.stripTime()
    }
}
