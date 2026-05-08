//
//  PeriodRecordRepository.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/4/7.
//

import CoreData

struct PeriodRecordInput {
    let startDate: Date
    let endDate: Date?
    let notes: String
}

final class PeriodRecordRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    @discardableResult
    func save(input: PeriodRecordInput,
              for person: Person,
              editing: PeriodRecord? = nil) throws -> PeriodRecord {
        let record = editing ?? PeriodRecord(context: context)
        if editing == nil {
            record.id = UUID()
            record.person = person
        }

        record.startDate = input.startDate.stripTime()
        record.endDate = input.endDate?.stripTime()
        record.notes = input.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        try context.save()
        return record
    }

    func fetchRecord(objectID: NSManagedObjectID) -> PeriodRecord? {
        try? context.existingObject(with: objectID) as? PeriodRecord
    }
}
