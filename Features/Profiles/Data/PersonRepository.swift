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
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func add(name: String, colorHex: String) {
        let p = Person(context: context)
        p.id = UUID()
        p.name = name
        p.colorHex = colorHex
        p.createdAt = Date()
        try? context.save()
    }

    func delete(offsets: IndexSet, from people: [Person]) {
        for index in offsets {
            context.delete(people[index])
        }
        try? context.save()
    }
}
