//
//  PersonRepositoryTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
@testable import MultiMenstrualAPP

final class PersonRepositoryTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext { container.viewContext }
    private var repository: PersonRepository!

    override func setUp() {
        super.setUp()
        container = TestCoreDataFactory.makeContainer()
        repository = PersonRepository(context: context)
    }

    override func tearDown() {
        repository = nil
        container = nil
        super.tearDown()
    }

    // MARK: - add

    func testAddPersistsTrimmedNameAndColor() throws {
        try repository.add(PersonAttributes(name: "  Aiko  ", colorHex: "#34C759"))

        let stored = repository.fetchAllSummaries()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.displayName, "Aiko")
        XCTAssertEqual(stored.first?.colorHex, "#34C759")
    }

    // MARK: - update

    func testUpdateAppliesNewAttributes() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try context.save()
        let id = PersonID(person.objectID)

        try repository.update(id: id,
                              attributes: PersonAttributes(name: "Mei", colorHex: "#5AC8FA"))

        let profile = repository.fetchProfile(id: id)
        XCTAssertEqual(profile?.displayName, "Mei")
        XCTAssertEqual(profile?.colorHex, "#5AC8FA")
    }

    func testUpdateThrowsNotFoundWhenIDNoLongerResolves() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try context.save()
        let id = PersonID(person.objectID)

        context.delete(person)
        try context.save()

        XCTAssertThrowsError(
            try repository.update(id: id,
                                  attributes: PersonAttributes(name: "Mei",
                                                               colorHex: "#5AC8FA"))
        ) { error in
            guard case RepositoryError.notFound = error else {
                XCTFail("expected RepositoryError.notFound, got \(error)")
                return
            }
        }
    }

    // MARK: - delete

    func testDeleteRemovesPersonAndCascadesRecords() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-01-01"),
                                       end: day("2026-01-05"))
        try context.save()

        try repository.delete(id: PersonID(person.objectID))

        XCTAssertEqual(repository.fetchAllSummaries().count, 0)
        let leftoverRecords = try context.fetch(PeriodRecord.fetchRequest()) as! [PeriodRecord]
        XCTAssertEqual(leftoverRecords.count, 0,
                       "Person delete should cascade to associated records")
    }

    func testDeleteThrowsNotFoundWhenIDNoLongerResolves() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try context.save()
        let id = PersonID(person.objectID)

        context.delete(person)
        try context.save()

        XCTAssertThrowsError(try repository.delete(id: id)) { error in
            guard case RepositoryError.notFound = error else {
                XCTFail("expected RepositoryError.notFound, got \(error)")
                return
            }
        }
    }

    // MARK: - fetch

    func testFetchAllSummariesSortsByCreatedAtAscending() throws {
        let aiko = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        aiko.createdAt = day("2026-01-01")
        let mei = TestCoreDataFactory.makePerson(in: context, name: "Mei")
        mei.createdAt = day("2025-12-01")
        try context.save()

        let summaries = repository.fetchAllSummaries()

        XCTAssertEqual(summaries.map(\.displayName), ["Mei", "Aiko"])
    }

    func testFetchProfileReturnsNilForMissingID() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try context.save()
        let id = PersonID(person.objectID)
        context.delete(person)
        try context.save()

        XCTAssertNil(repository.fetchProfile(id: id))
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
