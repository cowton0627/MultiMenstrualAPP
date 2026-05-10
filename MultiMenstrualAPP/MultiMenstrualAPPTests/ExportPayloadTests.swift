//
//  ExportPayloadTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
@testable import MultiMenstrualAPP

final class ExportPayloadTests: XCTestCase {

    // MARK: - round trip

    func testRoundTripPreservesProfilesAndRecords() throws {
        let source = TestCoreDataFactory.makeContainer()
        seedSource(source.viewContext)
        try source.viewContext.save()

        let payload = try ExportPayload.make(context: source.viewContext)
        let json = try JSONEncoder().encode(payload)

        let dest = TestCoreDataFactory.makeContainer()
        let decoded = try JSONDecoder().decode(ExportPayload.self, from: json)
        let summary = try decoded.importInto(context: dest.viewContext)
        try dest.viewContext.save()

        XCTAssertEqual(summary.profileCount, 2)
        XCTAssertEqual(summary.recordCount, 3)

        let importedPeople = try dest.viewContext.fetch(Person.fetchRequest()) as! [Person]
        XCTAssertEqual(importedPeople.count, 2)
        XCTAssertEqual(Set(importedPeople.compactMap(\.name)),
                       Set(["Aiko", "Mei"]))

        let importedRecords = try dest.viewContext.fetch(PeriodRecord.fetchRequest()) as! [PeriodRecord]
        XCTAssertEqual(importedRecords.count, 3)
    }

    // MARK: - merge by id

    func testImportMergesIntoExistingPersonByID() throws {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext

        let person = TestCoreDataFactory.makePerson(in: context, name: "Old name")
        let originalID = person.id!
        try context.save()

        // Build a payload that points at the same UUID with a different name
        let payload = ExportPayload(
            schemaVersion: 1,
            exportedAt: "2026-05-10T00:00:00.000Z",
            app: ExportAppMetadata(name: "MultiMenstrualAPP", platform: "ios", version: "1"),
            profiles: [
                ExportProfile(
                    id: originalID.uuidString,
                    name: "New name",
                    colorHex: "#34C759",
                    createdAt: nil,
                    periodRecords: []
                )
            ]
        )

        _ = try payload.importInto(context: context)
        try context.save()

        let people = try context.fetch(Person.fetchRequest()) as! [Person]
        XCTAssertEqual(people.count, 1, "import should update, not duplicate, when the UUID matches")
        XCTAssertEqual(people[0].name, "New name")
        XCTAssertEqual(people[0].colorHex, "#34C759")
    }

    // MARK: - schema guard

    func testImportRejectsUnsupportedSchemaVersion() {
        let container = TestCoreDataFactory.makeContainer()

        let payload = ExportPayload(
            schemaVersion: 99,
            exportedAt: "2026-05-10T00:00:00.000Z",
            app: ExportAppMetadata(name: "MultiMenstrualAPP", platform: "ios", version: "1"),
            profiles: []
        )

        XCTAssertThrowsError(try payload.importInto(context: container.viewContext))
    }

    // MARK: - colour fallback

    func testImportFallsBackToDefaultColorOnInvalidHex() throws {
        let container = TestCoreDataFactory.makeContainer()
        let context = container.viewContext

        let payload = ExportPayload(
            schemaVersion: 1,
            exportedAt: "2026-05-10T00:00:00.000Z",
            app: ExportAppMetadata(name: "MultiMenstrualAPP", platform: "ios", version: "1"),
            profiles: [
                ExportProfile(
                    id: UUID().uuidString,
                    name: "Aiko",
                    colorHex: "totally-not-a-hex",
                    createdAt: nil,
                    periodRecords: []
                )
            ]
        )

        _ = try payload.importInto(context: context)
        try context.save()

        let stored = try context.fetch(Person.fetchRequest()) as! [Person]
        XCTAssertEqual(stored.first?.colorHex, Person.defaultColorHex)
    }

    // MARK: - helpers

    private func seedSource(_ context: NSManagedObjectContext) {
        let aiko = TestCoreDataFactory.makePerson(in: context, name: "Aiko", colorHex: "#FF6B6B")
        TestCoreDataFactory.makeRecord(in: context, person: aiko,
                                       start: day("2026-01-01"),
                                       end: day("2026-01-05"))
        TestCoreDataFactory.makeRecord(in: context, person: aiko,
                                       start: day("2026-02-01"),
                                       end: day("2026-02-04"))

        let mei = TestCoreDataFactory.makePerson(in: context, name: "Mei", colorHex: "#5AC8FA")
        TestCoreDataFactory.makeRecord(in: context, person: mei,
                                       start: day("2026-03-15"),
                                       end: nil,
                                       notes: "ongoing")
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
