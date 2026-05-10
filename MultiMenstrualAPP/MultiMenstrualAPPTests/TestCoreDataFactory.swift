//
//  TestCoreDataFactory.swift
//  MultiMenstrualAPPTests
//
//  Created by Codex on 2026/4/7.
//

import CoreData
@testable import MultiMenstrualAPP

enum TestCoreDataFactory {
    static func makeContainer() -> NSPersistentContainer {
        PersistenceController(inMemory: true).container
    }

    @discardableResult
    static func makePerson(in context: NSManagedObjectContext,
                           name: String = "Tester",
                           colorHex: String = "#FF6B6B") -> Person {
        let person = NSEntityDescription.insertNewObject(forEntityName: "Person",
                                                         into: context) as! Person
        person.id = UUID()
        person.createdAt = Date()
        person.name = name
        person.colorHex = colorHex
        return person
    }

    @discardableResult
    static func makeRecord(in context: NSManagedObjectContext,
                           person: Person,
                           start: Date,
                           end: Date? = nil,
                           notes: String = "") -> PeriodRecord {
        let record = NSEntityDescription.insertNewObject(forEntityName: "PeriodRecord",
                                                         into: context) as! PeriodRecord
        record.id = UUID()
        record.person = person
        record.startDate = start
        record.endDate = end
        record.notes = notes
        return record
    }
}
