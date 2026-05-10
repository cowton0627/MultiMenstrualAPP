//
//  CalendarViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import SwiftUI
import CoreData

final class CalendarViewModel: NSObject, ObservableObject {
    struct UiState: Equatable {
        var visibleMonth: Date = Date().startOfMonth()
        var ranges: [PeriodRange] = []
        var predicted: [PredictedWindow] = []
        var title: String = "無名"
    }

    enum Intent {
        case appear
        case tapDay(Date)
        case setVisibleMonth(Date)
    }

    enum Action {
        case openEditor(RecordEditorSheetContext)
        case presentRecordPicker(day: Date, records: [PeriodRecordSnapshot])
    }

    // MARK: - DI
    let context: NSManagedObjectContext
    private let person: PersonProfile
    private let recordHitResolver = RecordHitResolver()
    private let periodRangeMapper = PeriodRangeMapper()

    private var frc: NSFetchedResultsController<PeriodRecord>!

    @Published private(set) var state = UiState()
    var onAction: ((Action) -> Void)?

    init(ctx: NSManagedObjectContext, person: PersonProfile) {
        self.context = ctx
        self.person = person
        super.init()
        state.title = person.displayName
        configureFRC()
    }

    func send(_ intent: Intent) {
        switch intent {
        case .appear:
            recompute() // 初次載入
        case .tapDay(let day):
            let recs = records(on: day).map(PeriodRecordSnapshot.init(record:))
            if recs.count == 1 {
                onAction?(openEditorContext(for: recs[0], fallbackDay: day))
            } else if recs.count > 1 {
                onAction?(.presentRecordPicker(day: day.stripTime(), records: recs))
            } else {
                onAction?(
                    .openEditor(
                        RecordEditorSheetContext(
                            personObjectID: person.objectID,
                            recordObjectID: nil,
                            defaultStart: day.stripTime(),
                            defaultEnd: day.stripTime().addDays(5)
                        )
                    )
                )
            }

        case .setVisibleMonth(let d):
            state.visibleMonth = d.startOfMonth()
        }
    }

    // MARK: - Core Data 驅動
    private func configureFRC() {
        let req: NSFetchRequest<PeriodRecord> = PeriodRecord.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        guard let managedPerson = try? context.existingObject(with: person.objectID) as? Person else {
            frc = NSFetchedResultsController(fetchRequest: req,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
            return
        }
        req.predicate = NSPredicate(format: "person == %@", managedPerson)
        frc = NSFetchedResultsController(fetchRequest: req,
                                         managedObjectContext: context,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
        try? frc.performFetch()
    }

    private func allRecords() -> [PeriodRecord] {
        (frc.fetchedObjects ?? [])
    }

    private func records(on day: Date) -> [PeriodRecord] {
        recordHitResolver.records(on: day, in: allRecords())
    }

    private func recompute() {
        let recs = allRecords()
        state.title = person.displayName
        state.ranges = periodRangeMapper.makeRanges(from: recs, person: person)
        state.predicted = periodRangeMapper.makePredictedWindows(from: recs,
                                                                 person: person)
    }

    private func openEditorContext(for record: PeriodRecordSnapshot,
                                   fallbackDay: Date) -> Action {
        let start = record.startDate ?? fallbackDay.stripTime()
        let end = record.endDate ?? start.addDays(5)

        return .openEditor(
            RecordEditorSheetContext(
                personObjectID: person.objectID,
                recordObjectID: record.objectID,
                defaultStart: start,
                defaultEnd: end
            )
        )
    }
}

extension CalendarViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        recompute()
    }
}
