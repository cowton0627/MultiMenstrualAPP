//
//  PersonSummary.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/5/8.
//

import Foundation
import CoreData

struct PersonSummary: Identifiable, Equatable {
    let id: PersonID
    let displayName: String
    let colorHex: String
    let recordCount: Int
    let latestStartDate: Date?
}

struct PersonProfile: Equatable {
    let id: PersonID
    let personUUID: UUID
    let displayName: String
    let colorHex: String
}

extension PersonSummary {
    init(person: Person) {
        let records = person.records as? Set<PeriodRecord> ?? []

        self.id = PersonID(person.objectID)
        self.displayName = person.name ?? "未命名"
        self.colorHex = person.colorHex ?? Person.defaultColorHex
        self.recordCount = records.count
        self.latestStartDate = records
            .compactMap { $0.startDate }
            .map { $0.stripTime() }
            .max()
    }
}

extension PersonProfile {
    init(person: Person) {
        self.id = PersonID(person.objectID)
        self.personUUID = person.id ?? UUID()
        self.displayName = person.name ?? "未命名"
        self.colorHex = person.colorHex ?? Person.defaultColorHex
    }
}
