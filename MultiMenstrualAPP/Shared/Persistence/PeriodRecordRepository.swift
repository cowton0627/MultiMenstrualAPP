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

struct PeriodRecordSnapshot: Identifiable, Equatable {
    let id: PeriodRecordID
    let startDate: Date?
    let endDate: Date?
    let notes: String

    init(record: PeriodRecord) {
        self.id = PeriodRecordID(record.objectID)
        self.startDate = record.startDate?.stripTime()
        self.endDate = record.endDate?.stripTime()
        self.notes = record.notes ?? ""
    }
}

protocol PeriodRecordRepositoryProtocol {
    func save(input: PeriodRecordInput,
              personID: PersonID,
              editingID: PeriodRecordID?) throws
    func fetchSnapshot(id: PeriodRecordID) -> PeriodRecordSnapshot?
}

final class PeriodRecordRepository: PeriodRecordRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func save(input: PeriodRecordInput,
              personID: PersonID,
              editingID: PeriodRecordID? = nil) throws {
        guard let person = try? context.existingObject(with: personID.raw) as? Person else {
            throw RepositoryError.notFound
        }
        let editing = editingID.flatMap { fetchRecord(objectID: $0.raw) }
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

    func fetchSnapshot(id: PeriodRecordID) -> PeriodRecordSnapshot? {
        fetchRecord(objectID: id.raw).map(PeriodRecordSnapshot.init(record:))
    }

    private func fetchRecord(objectID: NSManagedObjectID) -> PeriodRecord? {
        try? context.existingObject(with: objectID) as? PeriodRecord
    }
}
