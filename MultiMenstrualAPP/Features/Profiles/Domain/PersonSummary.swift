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
    let recordCount: Int
    let latestStartDate: Date?

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
        let records = person.records as? Set<PeriodRecord> ?? []

        self.objectID = person.objectID
        self.displayName = person.name ?? "未命名"
        self.colorHex = person.colorHex ?? "#FF6B6B"
        self.recordCount = records.count
        self.latestStartDate = records
            .compactMap { $0.startDate }
            .map { $0.stripTime() }
            .max()
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
