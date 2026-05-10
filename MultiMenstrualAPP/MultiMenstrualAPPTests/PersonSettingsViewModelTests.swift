//
//  PersonSettingsViewModelTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
import SwiftUI
@testable import MultiMenstrualAPP

final class PersonSettingsViewModelTests: XCTestCase {
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

    func testInitSeedsNameAndColorFromProfile() {
        let person = TestCoreDataFactory.makePerson(in: context,
                                                    name: "Aiko",
                                                    colorHex: "#5AC8FA")
        try! context.save()

        let vm = PersonSettingsViewModel(profile: PersonProfile(person: person),
                                         repository: repository)

        XCTAssertEqual(vm.name, "Aiko")
        XCTAssertEqual(vm.color.toHexString(), "#5AC8FA")
    }

    func testCanSaveRejectsBlankAndAllowsTrimmedNonEmpty() {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try! context.save()
        let vm = PersonSettingsViewModel(profile: PersonProfile(person: person),
                                         repository: repository)

        vm.name = "    "
        XCTAssertFalse(vm.canSave)

        vm.name = "  Mei  "
        XCTAssertTrue(vm.canSave)
    }

    func testSaveWritesNewNameAndColorBack() throws {
        let person = TestCoreDataFactory.makePerson(in: context,
                                                    name: "Aiko",
                                                    colorHex: "#FF6B6B")
        try! context.save()
        let vm = PersonSettingsViewModel(profile: PersonProfile(person: person),
                                         repository: repository)
        vm.name = "  Mei "
        vm.color = Color(hex: "#34C759")

        try vm.save()

        let updated = repository.fetchProfile(objectID: person.objectID)
        XCTAssertEqual(updated?.displayName, "Mei",
                       "Repository trims whitespace before persisting")
        XCTAssertEqual(updated?.colorHex, "#34C759")
    }

    func testDeleteRemovesThePersonFromTheStore() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try! context.save()
        XCTAssertEqual(repository.fetchAllSummaries().count, 1)

        let vm = PersonSettingsViewModel(profile: PersonProfile(person: person),
                                         repository: repository)
        try vm.delete()

        XCTAssertEqual(repository.fetchAllSummaries().count, 0)
    }

    func testSaveSurfacesNotFoundWhenObjectIDNoLongerExists() throws {
        let person = TestCoreDataFactory.makePerson(in: context, name: "Aiko")
        try! context.save()
        let vm = PersonSettingsViewModel(profile: PersonProfile(person: person),
                                         repository: repository)

        // Delete the underlying entity behind the VM's back, then try to save.
        context.delete(person)
        try context.save()

        XCTAssertThrowsError(try vm.save()) { error in
            guard case RepositoryError.notFound = error else {
                XCTFail("expected RepositoryError.notFound, got \(error)")
                return
            }
        }
    }
}
