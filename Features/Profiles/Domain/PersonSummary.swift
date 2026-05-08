//
//  PersonSummary.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/5/8.
//

import Foundation
import CoreData

struct PersonSummary: Identifiable, Equatable {
    let objectID: NSManagedObjectID
    let displayName: String
    let colorHex: String

    var id: NSManagedObjectID { objectID }
}

struct PersonProfile: Equatable {
    let objectID: NSManagedObjectID
    let personID: UUID
    let displayName: String
    let colorHex: String
}

extension PersonSummary {
    init(person: Person) {
        self.objectID = person.objectID
        self.displayName = person.name ?? "未命名"
        self.colorHex = person.colorHex ?? "#FF6B6B"
    }
}

extension PersonProfile {
    init(person: Person) {
        self.objectID = person.objectID
        self.personID = person.id ?? UUID()
        self.displayName = person.name ?? "未命名"
        self.colorHex = person.colorHex ?? "#FF6B6B"
    }
}
