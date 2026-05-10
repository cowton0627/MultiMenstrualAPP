//
//  ProfilesViewModelTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
@testable import MultiMenstrualAPP

final class ProfilesViewModelTests: XCTestCase {
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

    func testInitLoadsExistingPeopleSortedByCreatedAt() throws {
        let aiko = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        aiko.createdAt = day("2026-01-01")

        let mei = TestCoreDataFactory.makePerson(in: context, name: "Mei")
        mei.createdAt = day("2025-12-01")

        try context.save()

        let vm = ProfilesViewModel(context: context)

        XCTAssertEqual(vm.people.map(\.displayName), ["Mei", "Aiko"],
                       "FRC sorts by createdAt ascending")
    }

    func testInsertedPersonAppearsViaFRC() throws {
        let vm = ProfilesViewModel(context: context)
        XCTAssertTrue(vm.people.isEmpty)

        TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try context.save()

        XCTAssertEqual(vm.people.count, 1)
        XCTAssertEqual(vm.people.first?.displayName, "Aiko")
    }

    func testDeletedPersonDisappearsViaFRC() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try context.save()

        let vm = ProfilesViewModel(context: context)
        XCTAssertEqual(vm.people.count, 1)

        context.delete(person)
        try context.save()

        XCTAssertTrue(vm.people.isEmpty)
    }

    func testSummaryIncludesRecordCountAndLatestStartDate() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-01-01"),
                                       end: day("2026-01-05"))
        TestCoreDataFactory.makeRecord(in: context, person: person,
                                       start: day("2026-03-10"),
                                       end: day("2026-03-15"))
        try context.save()

        let vm = ProfilesViewModel(context: context)

        XCTAssertEqual(vm.people.count, 1)
        XCTAssertEqual(vm.people.first?.recordCount, 2)
        XCTAssertEqual(vm.people.first?.latestStartDate, day("2026-03-10"))
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
