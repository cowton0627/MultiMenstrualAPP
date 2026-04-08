//
//  PersonRepository.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import CoreData

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

    func delete(_ person: Person) throws {
        context.delete(person)
        try context.save()
    }

    func delete(offsets: IndexSet, from people: [Person]) throws {
        for index in offsets {
            context.delete(people[index])
        }
        try context.save()
    }
}
