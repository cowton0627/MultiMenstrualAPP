//
//  RecordPeriodViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/4/7.
//

import Foundation
import CoreData

final class RecordPeriodViewModel: ObservableObject {
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var inProgress: Bool
    @Published var notes: String

    private let person: Person
    private let editing: PeriodRecord?
    private let repository: PeriodRecordRepository

    init(person: Person,
         defaultStart: Date,
         defaultEnd: Date,
         editing: PeriodRecord? = nil,
         context: NSManagedObjectContext) {
        self.person = person
        self.editing = editing
        self.repository = PeriodRecordRepository(context: context)

        if let record = editing {
            self.startDate = record.startDate?.stripTime() ?? defaultStart.stripTime()
            self.endDate = (record.endDate ?? defaultEnd).stripTime()
            self.inProgress = record.endDate == nil
            self.notes = record.notes ?? ""
        } else {
            self.startDate = defaultStart.stripTime()
            self.endDate = defaultEnd.stripTime()
            self.inProgress = false
            self.notes = ""
        }
    }

    var canSave: Bool {
        inProgress || endDate.stripTime() >= startDate.stripTime()
    }

    func save() throws -> PeriodRecord {
        try repository.save(
            input: PeriodRecordInput(
                startDate: startDate,
                endDate: inProgress ? nil : endDate,
                notes: notes
            ),
            for: person,
            editing: editing
        )
    }
}
