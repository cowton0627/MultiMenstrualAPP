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
        var showEditor = false
        var editorStart = Date().stripTime()
        var editorEnd   = Date().stripTime().addDays(5)
        var editing: PeriodRecord? = nil

        var showPicker = false
        var candidates: [PeriodRecord] = []
        var picked: PeriodRecord? = nil

        var title: String = "無名"
    }

    enum Intent {
        case appear
        case tapDay(Date)
        case tapAdd
        case pickRecord(PeriodRecord)
        case closePicker
        case closeEditor
        case setVisibleMonth(Date)
    }

    // MARK: - DI
    let context: NSManagedObjectContext
    private let person: Person
    private let recordHitResolver = RecordHitResolver()
    private let periodRangeMapper = PeriodRangeMapper()

    private var frc: NSFetchedResultsController<PeriodRecord>!

    @Published private(set) var state = UiState()

    init(ctx: NSManagedObjectContext, person: Person) {
        self.context = ctx
        self.person = person
        super.init()
        state.title = person.name ?? "無名"
        configureFRC()
    }

    func send(_ intent: Intent) {
        switch intent {
        case .appear:
            recompute() // 初次載入
        case .tapDay(let day):
            let recs = records(on: day)
            if recs.count == 1 {
                let r = recs[0]
                state.editing = r
                state.editorStart = (r.startDate ?? day).stripTime()
                state.editorEnd   = (r.endDate ?? (r.startDate ?? day).addDays(5)).stripTime()
                state.showEditor = true
            } else if recs.count > 1 {
                state.candidates = recs
                state.picked = recs.first
                state.showPicker = true
            } else {
                state.editing = nil
                state.editorStart = day.stripTime()
                state.editorEnd   = day.stripTime().addDays(5)
                state.showEditor = true
            }

        case .tapAdd:
            state.editing = nil
            state.editorStart = Date().stripTime()
            state.editorEnd   = state.editorStart.addDays(5)
            state.showEditor = true

        case .pickRecord(let rec):
            let s = rec.startDate?.stripTime() ?? Date.distantPast
            let e = rec.endDate?.stripTime()
            state.editing = rec
            state.editorStart = s
            state.editorEnd   = (e ?? s.addDays(5))
            state.showPicker = false
            state.showEditor = true

        case .closePicker:
            state.showPicker = false

        case .closeEditor:
            state.showEditor = false

        case .setVisibleMonth(let d):
            state.visibleMonth = d.startOfMonth()
        }
    }

    // MARK: - Core Data 驅動
    private func configureFRC() {
        let req: NSFetchRequest<PeriodRecord> = PeriodRecord.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        req.predicate = NSPredicate(format: "person == %@", person)
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
        state.title = person.name ?? "無名"
        state.ranges = periodRangeMapper.makeRanges(from: recs, person: person)
        state.predicted = periodRangeMapper.makePredictedWindows(from: recs,
                                                                 person: person)
    }
}

extension CalendarViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        recompute()
    }
}
