//
//  CalendarScreen.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI
import CoreData

// MARK: - 顯示與設定經期的畫面（使用 ElegantCalendarView）
struct CalendarScreen: View {
    @Environment(\.managedObjectContext) private var ctx
    @ObservedObject var person: Person

    // 1) 月起點（會被日曆內左右切換更新）
    @State private var visibleMonth = Date().startOfMonth()

    // 2) 控制新增/編輯 sheet
    @State private var showEditor = false
    @State private var editorPresetStart = Date().stripTime()
    @State private var editorPresetEnd = Date().stripTime().addDays(5)
    @State private var editingRecord: PeriodRecord? = nil   // 不為 nil 時代表「編輯模式」

    // 多筆選擇（同一天若撞到多筆）
    @State private var showPicker = false
    @State private var candidates: [PeriodRecord] = []
    @State private var picked: PeriodRecord?

    // 3) 針對「此人」的紀錄做 fetch；任何新增/刪除會自動刷新 UI
    @FetchRequest private var myRecords: FetchedResults<PeriodRecord>
    
    // 進行中（沒有 endDate）的臨時顯示長度
    private let ongoingFallbackDays = 5

    init(person: Person) {
        self.person = person
        // 只抓這個人的紀錄並依開始日排序
        let req: NSFetchRequest<PeriodRecord> = PeriodRecord.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        req.predicate = NSPredicate(format: "person == %@", person)
        _myRecords = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        let recs = Array(myRecords)
        let ranges = makeRanges(from: Array(myRecords))
        let preds  = makePredictedWindows(from: Array(myRecords))

        VStack(spacing: 0) {
            ElegantCalendarView(
                visibleMonth: $visibleMonth,
                periodRanges: ranges,
                predictedWindows: preds,
                theme: CalendarTheme(),
                firstWeekday: 2 // 週一開頭
            ) { tappedDate in
//                let hits = records(on: tappedDate, in: Array(myRecords))
                // 檢查這天是否有紀錄
                let hits = records(on: tappedDate, in: recs)
                if hits.count == 1 {
//                    editingRecord = hits.first
                    // 單筆，直接進編輯並帶入原值
                    let r = hits[0]
                    editingRecord = r
                    editorPresetStart = (r.startDate ?? tappedDate).stripTime()
                    editorPresetEnd   = (r.endDate ?? (r.startDate ?? tappedDate).addDays(5)).stripTime()
                    showEditor = true
                } else if hits.count > 1 {
                    candidates = hits
                    picked = hits.first
                    showPicker = true
                } else {
                    // 沒有則新增；用該日做預設
                    editingRecord = nil
                    editorPresetStart = tappedDate.stripTime()
                    editorPresetEnd   = tappedDate.stripTime().addDays(5)
                    showEditor = true
                }
            }

            Button {
                editingRecord = nil
                editorPresetStart = Date().stripTime()
                editorPresetEnd   = editorPresetStart.addDays(5)
                showEditor = true
            } label: {
                Label("新增一次經期紀錄", systemImage: "plus.circle.fill")
            }
            .padding(.vertical, 12)
        }
        .navigationTitle(person.name ?? "對象")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("編輯") { PersonSettingsView(person: person) }
            }
        }
        // 多筆時的挑選對話框（iOS 15 可用）
        .confirmationDialog("選擇要編輯的紀錄",
                            isPresented: $showPicker,
                            titleVisibility: .visible) {
            ForEach(candidates, id: \.objectID) { rec in
                let s = rec.startDate?.stripTime() ?? Date.distantPast
                let e = rec.endDate?.stripTime()
                Button(dateRangeTitle(start: s, end: e)) {
                    // 帶入被選那筆的預設值並進編輯
                    editingRecord = rec
                    editorPresetStart = s
                    editorPresetEnd   = (e ?? s.addDays(5))
                    showEditor = true
                }
            }
            Button("取消", role: .cancel) {}
        }
        // 開啟編輯器；儲存後 FetchRequest 會自動更新，日曆立即反映
        .sheet(isPresented: $showEditor) {
            NavigationView {   // iOS 16 請改用 NavigationStack
                RecordEditorView(person: person,
                                 defaultStart: editorPresetStart,
                                 defaultEnd: editorPresetEnd,
                                 editing: editingRecord)
                .navigationBarTitleDisplayMode(.inline)
            }
            .environment(\.managedObjectContext, ctx)
        }
    }

    // MARK: - Helpers
    private func records(on day: Date, in recs: [PeriodRecord]) -> [PeriodRecord] {
        let d = day.stripTime()
        return recs.filter { r in
            guard let s = r.startDate?.stripTime() else { return false }
            if let e = r.endDate?.stripTime() {
                return d >= s && d <= e
            } else {
                // 進行中（沒有 endDate）→ 視為從 start 當天開始都算
                return d >= s
            }
        }
    }

    private func dateRangeTitle(start: Date, end: Date?) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "MM/dd"
        if let e = end { return "\(f.string(from: start)) - \(f.string(from: e))" }
        return "\(f.string(from: start)) - 進行中"
    }

    // 將 Core Data 轉給 ElegantCalendarView（區間）
    private func makeRanges(from recs: [PeriodRecord]) -> [PeriodRange] {
        let color = Color(hex: person.colorHex ?? "#FF6B6B")
        return recs.compactMap { r in
            guard let s = r.startDate?.stripTime() else { return nil }
            // 進行中用 fallback（若真的要只畫有結束日，可改回原本的 guard）
            let e = (r.endDate ?? s.addDays(ongoingFallbackDays)).stripTime()
            // 防呆：若資料壞掉（end < start），直接跳過避免整格不畫
            guard e >= s else { return nil }
//            let end = (r.endDate ?? s.addDays(ongoingFallbackDays)).stripTime()
            // 只畫有結束日的區間；若要畫進行中可把 e = Date() 或 s+5天
//            guard let e = r.endDate?.stripTime()   else { return nil }
            return PeriodRange(personId: person.id ?? UUID(),
                               personName: person.name ?? "未命名",
                               color: color, start: s, end: e)
        }
    }

    // 將 Core Data 轉成預測窗
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

