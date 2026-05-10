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

    private let personObjectID: NSManagedObjectID
    private let editingObjectID: NSManagedObjectID?
    private let repository: PeriodRecordRepository

    init(person: PersonProfile,
         defaultStart: Date,
         defaultEnd: Date,
         editing: PeriodRecordSnapshot? = nil,
         context: NSManagedObjectContext) {
        self.personObjectID = person.objectID
        self.editingObjectID = editing?.objectID
        self.repository = PeriodRecordRepository(context: context)

        if let snapshot = editing {
            self.startDate = snapshot.startDate ?? defaultStart.stripTime()
            self.endDate = snapshot.endDate ?? defaultEnd.stripTime()
            self.inProgress = snapshot.endDate == nil
            self.notes = snapshot.notes
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

    func save() throws {
        try repository.save(
            input: PeriodRecordInput(
                startDate: startDate,
                endDate: inProgress ? nil : endDate,
                notes: notes
            ),
            personObjectID: personObjectID,
            editingObjectID: editingObjectID
        )
    }
}
