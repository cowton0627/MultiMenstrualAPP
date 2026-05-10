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

struct PeriodRecordSnapshot: Equatable {
    let objectID: NSManagedObjectID
    let startDate: Date?
    let endDate: Date?
    let notes: String

    init(record: PeriodRecord) {
        self.objectID = record.objectID
        self.startDate = record.startDate?.stripTime()
        self.endDate = record.endDate?.stripTime()
        self.notes = record.notes ?? ""
    }
}

protocol PeriodRecordRepositoryProtocol {
    func save(input: PeriodRecordInput,
              personObjectID: NSManagedObjectID,
              editingObjectID: NSManagedObjectID?) throws
    func fetchSnapshot(objectID: NSManagedObjectID) -> PeriodRecordSnapshot?
}

final class PeriodRecordRepository: PeriodRecordRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func save(input: PeriodRecordInput,
              personObjectID: NSManagedObjectID,
              editingObjectID: NSManagedObjectID? = nil) throws {
        guard let person = try? context.existingObject(with: personObjectID) as? Person else {
            throw RepositoryError.notFound
        }
        let editing = editingObjectID.flatMap { fetchRecord(objectID: $0) }
        let record = editing ?? PeriodRecord(context: context)
        if editing == nil {
            record.id = UUID()
            record.person = person
        }

        record.startDate = input.startDate.stripTime()
        record.endDate = input.endDate?.stripTime()
        record.notes = input.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        try context.save()
    }

    func fetchSnapshot(objectID: NSManagedObjectID) -> PeriodRecordSnapshot? {
        fetchRecord(objectID: objectID).map(PeriodRecordSnapshot.init(record:))
    }

    private func fetchRecord(objectID: NSManagedObjectID) -> PeriodRecord? {
        try? context.existingObject(with: objectID) as? PeriodRecord
    }
}
