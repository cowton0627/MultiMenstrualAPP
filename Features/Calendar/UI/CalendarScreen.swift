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
    private let person: PersonProfile
    @StateObject private var vm: CalendarViewModel
    @State private var pickerDay = Date().stripTime()
    @State private var pickerRecords: [PeriodRecord] = []
    private let onTapEditPerson: () -> Void
    private let onRequestRecordEditor: (RecordEditorSheetContext) -> Void

    init(person: PersonProfile,
         context: NSManagedObjectContext,
         onTapEditPerson: @escaping () -> Void = {},
         onRequestRecordEditor: @escaping (RecordEditorSheetContext) -> Void = { _ in }) {
        self.person = person
        self.onTapEditPerson = onTapEditPerson
        self.onRequestRecordEditor = onRequestRecordEditor
        _vm = StateObject(wrappedValue: CalendarViewModel(ctx: context, person: person))
    }

    var body: some View {
        VStack(spacing: 0) {
            ElegantCalendarView(
                visibleMonth: Binding(
                    get: { vm.state.visibleMonth },
                    set: { vm.send(.setVisibleMonth($0)) }
                ),
                periodRanges: vm.state.ranges,
                predictedWindows: vm.state.predicted,
                theme: CalendarTheme(),
                firstWeekday: 2
            ) { tappedDate in
                vm.send(.tapDay(tappedDate))
            }
        }
        .navigationTitle(vm.state.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編輯") {
                    onTapEditPerson()
                }
            }
        }
        .onAppear {
            vm.onAction = handleAction
            vm.send(.appear)
        }
        .confirmationDialog("選擇紀錄",
                            isPresented: Binding(
                                get: { !pickerRecords.isEmpty },
                                set: { if !$0 { pickerRecords = [] } }
                            ),
                            titleVisibility: .visible) {
            ForEach(pickerRecords) { record in
                Button(recordTitle(for: record)) {
                    handleAction(
                        .openEditor(
                            RecordEditorSheetContext(
                                personObjectID: person.objectID,
                                recordObjectID: record.objectID,
                                defaultStart: (record.startDate ?? pickerDay).stripTime(),
                                defaultEnd: (record.endDate ?? (record.startDate ?? pickerDay).addDays(5)).stripTime()
                            )
                        )
                    )
                }
            }

            Button("新增紀錄") {
                handleAction(
                    .openEditor(
                        RecordEditorSheetContext(
                            personObjectID: person.objectID,
                            recordObjectID: nil,
                            defaultStart: pickerDay,
                            defaultEnd: pickerDay.addDays(5)
                        )
                    )
                )
            }

            Button("取消", role: .cancel) {
                pickerRecords = []
            }
        }
    }

    private func handleAction(_ action: CalendarViewModel.Action) {
        switch action {
        case .openEditor(let context):
            pickerRecords = []
            onRequestRecordEditor(context)
        case .presentRecordPicker(let day, let records):
            pickerDay = day
            pickerRecords = records
        }
    }

    private func recordTitle(for record: PeriodRecord) -> String {
        let start = record.startDate?.stripTime() ?? pickerDay
        let end = (record.endDate ?? start).stripTime()
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct CalendarTheme {
    var background = Color(UIColor.systemBackground)
    var monthTitleColor = Color.primary
    var weekdayColor = Color.secondary
    var todayRing = Color.accentColor
    var gridSeparator = Color.secondary.opacity(0.12)
    var dayText = Color.primary
    var outMonthText = Color.secondary.opacity(0.5)
    var predictedDash = Color.orange
    var selectionCorner: CGFloat = 8
    var dayMinHeight: CGFloat = 44
    var contentPadding: CGFloat = 16
    var fontDay = Font.system(.subheadline, design: .rounded).weight(.semibold)
    var fontMonth = Font.system(.title2, design: .rounded).weight(.bold)
    var fontWeekday = Font.system(.caption2, design: .rounded).weight(.semibold)
}
