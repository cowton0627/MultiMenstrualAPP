//
//  PeriodRecordRepositoryTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
@testable import MultiMenstrualAPP

final class PeriodRecordRepositoryTests: XCTestCase {
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

    // MARK: - save (create)

    func testSaveCreatesRecordWhenEditingIDIsNil() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        try context.save()

        try repository.save(
            input: PeriodRecordInput(startDate: day("2026-04-01"),
                                     endDate: day("2026-04-05"),
                                     notes: "  spotting  "),
            personID: PersonID(person.objectID),
            editingID: nil
        )

        let stored = try context.fetch(PeriodRecord.fetchRequest()) as! [PeriodRecord]
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored[0].startDate?.stripTime(), day("2026-04-01"))
        XCTAssertEqual(stored[0].endDate?.stripTime(), day("2026-04-05"))
        XCTAssertEqual(stored[0].notes, "spotting",
                       "save should trim whitespace before persisting")
    }

    func testSaveCreatesOngoingRecordWhenEndIsNil() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        try context.save()

        try repository.save(
            input: PeriodRecordInput(startDate: day("2026-04-01"),
                                     endDate: nil,
                                     notes: ""),
            personID: PersonID(person.objectID),
            editingID: nil
        )

        let stored = try context.fetch(PeriodRecord.fetchRequest()) as! [PeriodRecord]
        XCTAssertEqual(stored.count, 1)
        XCTAssertNil(stored[0].endDate)
    }

    // MARK: - save (update)

    func testSaveUpdatesExistingRecordWhenEditingIDProvided() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-04-01"),
                                                    end: day("2026-04-05"))
        try context.save()

        try repository.save(
            input: PeriodRecordInput(startDate: day("2026-04-01"),
                                     endDate: day("2026-04-08"),
                                     notes: ""),
            personID: PersonID(person.objectID),
            editingID: PeriodRecordID(record.objectID)
        )

        let stored = try context.fetch(PeriodRecord.fetchRequest()) as! [PeriodRecord]
        XCTAssertEqual(stored.count, 1, "editing must not create a duplicate")
        XCTAssertEqual(stored[0].endDate?.stripTime(), day("2026-04-08"))
    }

    // MARK: - error paths

    func testSaveThrowsNotFoundWhenPersonIDDoesNotResolve() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        try context.save()
        let personID = PersonID(person.objectID)
        context.delete(person)
        try context.save()

        XCTAssertThrowsError(
            try repository.save(
                input: PeriodRecordInput(startDate: day("2026-04-01"),
                                         endDate: day("2026-04-05"),
                                         notes: ""),
                personID: personID,
                editingID: nil
            )
        ) { error in
            guard case RepositoryError.notFound = error else {
                XCTFail("expected RepositoryError.notFound, got \(error)")
                return
            }
        }
    }

    func testSaveThrowsNotFoundWhenEditingIDDoesNotResolve() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-04-01"),
                                                    end: day("2026-04-05"))
        try context.save()
        let editingID = PeriodRecordID(record.objectID)
        context.delete(record)
        try context.save()

        XCTAssertThrowsError(
            try repository.save(
                input: PeriodRecordInput(startDate: day("2026-04-10"),
                                         endDate: day("2026-04-15"),
                                         notes: ""),
                personID: PersonID(person.objectID),
                editingID: editingID
            )
        ) { error in
            guard case RepositoryError.notFound = error else {
                XCTFail("expected RepositoryError.notFound, got \(error)")
                return
            }
        }

        let stored = try context.fetch(PeriodRecord.fetchRequest()) as! [PeriodRecord]
        XCTAssertEqual(stored.count, 0,
                       "Stale editingID must not silently create a new record")
    }

    // MARK: - fetchSnapshot

    func testFetchSnapshotReturnsSnapshotForExistingRecord() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-04-01"),
                                                    end: day("2026-04-05"),
                                                    notes: "ok")
        try context.save()

        let snapshot = repository.fetchSnapshot(id: PeriodRecordID(record.objectID))

        XCTAssertEqual(snapshot?.startDate, day("2026-04-01"))
        XCTAssertEqual(snapshot?.endDate, day("2026-04-05"))
        XCTAssertEqual(snapshot?.notes, "ok")
    }

    func testFetchSnapshotReturnsNilForMissingID() throws {
        let person = TestCoreDataFactory.makePerson(in: context)
        let record = TestCoreDataFactory.makeRecord(in: context, person: person,
                                                    start: day("2026-04-01"))
        try context.save()
        let id = PeriodRecordID(record.objectID)
        context.delete(record)
        try context.save()

        XCTAssertNil(repository.fetchSnapshot(id: id))
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
