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

struct PersonAttributes {
    let name: String
    let colorHex: String
}

protocol PersonRepositoryProtocol {
    func fetchAllSummaries() -> [PersonSummary]
    func fetchProfile(objectID: NSManagedObjectID) -> PersonProfile?
    func add(_ attributes: PersonAttributes) throws
    func update(objectID: NSManagedObjectID, attributes: PersonAttributes) throws
    func delete(objectID: NSManagedObjectID) throws
}

final class PersonRepository: PersonRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAllSummaries() -> [PersonSummary] {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)
        ]
        return ((try? context.fetch(request)) ?? []).map(PersonSummary.init(person:))
    }

    func fetchProfile(objectID: NSManagedObjectID) -> PersonProfile? {
        fetchPerson(objectID: objectID).map(PersonProfile.init(person:))
    }

    func add(_ attributes: PersonAttributes) throws {
        let person = Person(context: context)
        person.id = UUID()
        person.name = attributes.name.trimmingCharacters(in: .whitespacesAndNewlines)
        person.colorHex = attributes.colorHex
        person.createdAt = Date()
        try context.save()
    }

    func update(objectID: NSManagedObjectID, attributes: PersonAttributes) throws {
        guard let person = fetchPerson(objectID: objectID) else {
            throw RepositoryError.notFound
        }
        person.name = attributes.name.trimmingCharacters(in: .whitespacesAndNewlines)
        person.colorHex = attributes.colorHex
        try context.save()
    }

    func delete(objectID: NSManagedObjectID) throws {
        guard let person = fetchPerson(objectID: objectID) else {
            throw RepositoryError.notFound
        }
        context.delete(person)
        try context.save()
    }

    private func fetchPerson(objectID: NSManagedObjectID) -> Person? {
        try? context.existingObject(with: objectID) as? Person
    }
}
