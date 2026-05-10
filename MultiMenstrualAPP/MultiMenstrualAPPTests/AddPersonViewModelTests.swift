//
//  AddPersonViewModelTests.swift
//  MultiMenstrualAPPTests
//

import XCTest
import CoreData
@testable import MultiMenstrualAPP

final class AddPersonViewModelTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var repository: PersonRepository!

    override func setUp() {
        super.setUp()
        container = TestCoreDataFactory.makeContainer()
        repository = PersonRepository(context: container.viewContext)
    }

    override func tearDown() {
        repository = nil
        container = nil
        super.tearDown()
    }

    // MARK: - canSave

    func testCanSaveBlocksWhenNameIsBlank() {
        let vm = AddPersonViewModel(repository: repository)
        vm.name = "   "
        XCTAssertFalse(vm.canSave)
    }

    func testCanSaveAllowsValidNonEmptyName() {
        let vm = AddPersonViewModel(repository: repository)
        vm.name = "Aiko"
        XCTAssertTrue(vm.canSave)
    }

    func testCanSaveBlocksWhileHexErrorIsSet() {
        let vm = AddPersonViewModel(repository: repository)
        vm.name = "Aiko"
        vm.updateHexInput("#ZZZZZZ")
        XCTAssertNotNil(vm.hexError)
        XCTAssertFalse(vm.canSave)
    }

    // MARK: - hex parsing

    func testUpdateHexInputAcceptsValidHexAndUppercases() {
        let vm = AddPersonViewModel(repository: repository)
        vm.updateHexInput("ff00aa")

        XCTAssertEqual(vm.colorHex, "#FF00AA")
        XCTAssertNil(vm.hexError)
    }

    func testUpdateHexInputKeepsColorOnInvalidInput() {
        let vm = AddPersonViewModel(repository: repository)
        let originalColor = vm.color

        vm.updateHexInput("not-a-hex")

        XCTAssertNotNil(vm.hexError)
        // Color should not have changed
        XCTAssertEqual(vm.color.toHexString(), originalColor.toHexString())
    }

    func testSelectSwatchSyncsBothColorAndHex() {
        let vm = AddPersonViewModel(repository: repository)
        vm.updateHexInput("#bad-input")
        XCTAssertNotNil(vm.hexError)

        vm.selectSwatch(hex: "#5AC8FA")

        XCTAssertEqual(vm.colorHex, "#5AC8FA")
        XCTAssertNil(vm.hexError, "selecting a swatch clears the previous hex error")
    }

    // MARK: - save

    func testSavePersistsTrimmedNameThroughRepository() throws {
        let vm = AddPersonViewModel(repository: repository)
        vm.name = "  Aiko  "
        vm.selectSwatch(hex: "#34C759")
        try vm.save()

        let stored = repository.fetchAllSummaries()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.displayName, "Aiko")
        XCTAssertEqual(stored.first?.colorHex, "#34C759")
    }

    func testSaveDoesNothingWhenCanSaveIsFalse() throws {
        let vm = AddPersonViewModel(repository: repository)
        vm.name = ""   // canSave == false
        try vm.save()

        XCTAssertEqual(repository.fetchAllSummaries().count, 0)
    }
}
