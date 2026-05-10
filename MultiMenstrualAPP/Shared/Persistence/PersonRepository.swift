//
//  PersonRepository.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import CoreData

enum RepositoryError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "找不到資料"
        }
    }
}

final class PersonRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() -> [Person] {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)
        ]
        return (try? context.fetch(request)) ?? []
    }

    func fetchAllSummaries() -> [PersonSummary] {
        fetchAll().map(PersonSummary.init(person:))
    }

    func fetchPerson(objectID: NSManagedObjectID) -> Person? {
        try? context.existingObject(with: objectID) as? Person
    }

    func fetchSummary(objectID: NSManagedObjectID) -> PersonSummary? {
        fetchPerson(objectID: objectID).map(PersonSummary.init(person:))
    }

    func fetchProfile(objectID: NSManagedObjectID) -> PersonProfile? {
        fetchPerson(objectID: objectID).map(PersonProfile.init(person:))
    }

    @discardableResult
    func add(name: String, colorHex: String) throws -> Person {
        let p = Person(context: context)
        p.id = UUID()
        p.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        p.colorHex = colorHex
        p.createdAt = Date()
        try context.save()
        return p
    }

    func update(_ person: Person, name: String, colorHex: String) throws {
        person.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        person.colorHex = colorHex
        try context.save()
    }

    func update(objectID: NSManagedObjectID, name: String, colorHex: String) throws {
        guard let person = fetchPerson(objectID: objectID) else {
            throw RepositoryError.notFound
        }
        try update(person, name: name, colorHex: colorHex)
    }

    func delete(_ person: Person) throws {
        context.delete(person)
        try context.save()
    }

    func delete(objectID: NSManagedObjectID) throws {
        guard let person = fetchPerson(objectID: objectID) else {
            throw RepositoryError.notFound
        }
        try delete(person)
    }

    func delete(offsets: IndexSet, from people: [Person]) throws {
        for index in offsets {
            context.delete(people[index])
        }
        try context.save()
    }
}
