//
//  CalendarViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import SwiftUI
import CoreData

//@available(iOS 17.0, *)
//@Observable
final class CalendarViewModel: NSObject, ObservableObject {
    // MARK: - UiState
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

        var title: String = "對象"
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
    private let ctx: NSManagedObjectContext
    private let person: Person
    private let ongoingFallbackDays = 5

    // FRC 讓 Core Data 更新自動推進 UiState
    private var frc: NSFetchedResultsController<PeriodRecord>!

    // 暴露不可變狀態（View 只讀取）
//    @Published private(set) var state = UiState()
    @Published var state = UiState()


    init(ctx: NSManagedObjectContext, person: Person) {
        self.ctx = ctx
        self.person = person
        super.init()
        state.title = person.name ?? "對象"
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
                                         managedObjectContext: ctx,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
        try? frc.performFetch()
    }

    private func allRecords() -> [PeriodRecord] {
        (frc.fetchedObjects ?? [])
    }

    private func records(on day: Date) -> [PeriodRecord] {
        let d = day.stripTime()
        return allRecords().filter { r in
            guard let s = r.startDate?.stripTime() else { return false }
            if let e = r.endDate?.stripTime() {
                return d >= s && d <= e
            } else { return d >= s } // 進行中視為持續
        }
    }

    private func recompute() {
        let recs = allRecords()
        state.ranges = makeRanges(from: recs)
        state.predicted = makePredictedWindows(from: recs)
    }

    private func makeRanges(from recs: [PeriodRecord]) -> [PeriodRange] {
        let color = Color(hex: person.colorHex ?? "#FF6B6B")
        return recs.compactMap { r in
            guard let s = r.startDate?.stripTime() else { return nil }
            let e = (r.endDate ?? s.addDays(ongoingFallbackDays)).stripTime()
            guard e >= s else { return nil }
            return PeriodRange(personId: person.id ?? UUID(),
                               personName: person.name ?? "未命名",
                               color: color, start: s, end: e)
        }
    }

    private func makePredictedWindows(from recs: [PeriodRecord]) -> [PredictedWindow] {
        let predictor = CyclePredictor(records: recs)
        guard let next = predictor.predictedNextStart else { return [] }
        let left  = next.addDays(-2).stripTime()
        let right = next.addDays( 2).stripTime()
        return [PredictedWindow(personId: person.id ?? UUID(),
                                color: Color(hex: person.colorHex ?? "#FF6B6B"),
                                range: left...right)]
    }
}

//@available(iOS 17.0, *)
extension CalendarViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Core Data 有變動 → 重新計算 UiState
        recompute()
    }
}
