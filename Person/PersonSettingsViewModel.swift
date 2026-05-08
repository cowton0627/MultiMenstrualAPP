//
//  PersonSettingsViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/4/7.
//

import SwiftUI
import CoreData

final class PersonSettingsViewModel: ObservableObject {
    @Published var name: String
    @Published var color: Color

    private let person: Person
    private let repository: PersonRepository

    init(person: Person, context: NSManagedObjectContext) {
        self.person = person
        self.repository = PersonRepository(context: context)
        self.name = person.name ?? ""
        self.color = Color(hex: person.colorHex ?? "#FF6B6B")
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() throws {
        try repository.update(person,
                              name: name,
                              colorHex: color.toHexString())
    }

    func delete() throws {
        try repository.delete(person)
    }
}
