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
    @State private var pickerRecords: [PeriodRecordSnapshot] = []
    @State private var pickerSheetRecords: [PeriodRecordSnapshot] = []
    private let onTapEditPerson: () -> Void
    private let onRequestRecordEditor: (RecordEditorSheetContext) -> Void

    private let pickerSheetThreshold = 5

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
        ZStack {
            MainBackground()

            VStack(spacing: 14) {
                CalendarSummaryHeader(
                    person: person,
                    recordCount: vm.state.ranges.count,
                    nextPrediction: vm.state.predicted.first
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)

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
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.subtleStroke, lineWidth: 1)
                )
                .shadow(color: AppTheme.softShadow, radius: 18, x: 0, y: 10)
                .padding(.horizontal, 12)
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
        }
        .confirmationDialog("選擇紀錄",
                            isPresented: Binding(
                                get: { !pickerRecords.isEmpty },
                                set: { if !$0 { pickerRecords = [] } }
                            ),
                            titleVisibility: .visible) {
            ForEach(pickerRecords) { record in
                Button(recordTitle(for: record)) {
                    let start = record.startDate ?? pickerDay
                    let end = record.endDate ?? start.addDays(5)
                    handleAction(
                        .openEditor(
                            RecordEditorSheetContext(
                                personID: person.id,
                                recordID: record.id,
                                defaultStart: start,
                                defaultEnd: end
                            )
                        )
                    )
                }
            }

            Button("新增紀錄") {
                handleAction(
                    .openEditor(
                        RecordEditorSheetContext(
                            personID: person.id,
                            recordID: nil,
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
        .sheet(isPresented: Binding(
            get: { !pickerSheetRecords.isEmpty },
            set: { if !$0 { pickerSheetRecords = [] } }
        )) {
            RecordPickerSheet(
                day: pickerDay,
                records: pickerSheetRecords,
                onSelect: { record in
                    let start = record.startDate ?? pickerDay
                    let end = record.endDate ?? start.addDays(5)
                    handleAction(
                        .openEditor(
                            RecordEditorSheetContext(
                                personID: person.id,
                                recordID: record.id,
                                defaultStart: start,
                                defaultEnd: end
                            )
                        )
                    )
                },
                onTapAdd: {
                    handleAction(
                        .openEditor(
                            RecordEditorSheetContext(
                                personID: person.id,
                                recordID: nil,
                                defaultStart: pickerDay,
                                defaultEnd: pickerDay.addDays(5)
                            )
                        )
                    )
                },
                onCancel: { pickerSheetRecords = [] }
            )
        }
    }

    private func handleAction(_ action: CalendarViewModel.Action) {
        switch action {
        case .openEditor(let context):
            pickerRecords = []
            pickerSheetRecords = []
            onRequestRecordEditor(context)
        case .presentRecordPicker(let day, let records):
            pickerDay = day
            if records.count >= pickerSheetThreshold {
                pickerSheetRecords = records
            } else {
                pickerRecords = records
            }
        }
    }

    private func recordTitle(for record: PeriodRecordSnapshot) -> String {
        let start = record.startDate ?? pickerDay
        let end = record.endDate ?? start
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

private struct CalendarSummaryHeader: View {
    let person: PersonProfile
    let recordCount: Int
    let nextPrediction: PredictedWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hex: person.colorHex).opacity(0.16))

                    Circle()
                        .fill(Color(hex: person.colorHex))
                        .frame(width: 20, height: 20)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summaryTitle)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.primary)

                    Text(summarySubtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                LegendPill(title: "已記錄", color: Color(hex: person.colorHex), style: .filled)
                LegendPill(title: "預測", color: Color.orange, style: .outlined)
            }
        }
        .padding(16)
        .elevatedCardSurface()
    }

    private var summaryTitle: String {
        if recordCount == 0 {
            return "準備開始記錄"
        }

        return "\(recordCount) 段經期紀錄"
    }

    private var summarySubtitle: String {
        guard let nextPrediction else {
            return "累積更多紀錄後，這裡會顯示下一次預測區間。"
        }

        return "下次預測 \(Self.formatter.string(from: nextPrediction.range.lowerBound)) - \(Self.formatter.string(from: nextPrediction.range.upperBound))"
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

private struct LegendPill: View {
    enum Style {
        case filled
        case outlined
    }

    let title: String
    let color: Color
    let style: Style

    var body: some View {
        HStack(spacing: 7) {
            marker

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(AppTheme.fieldBackground, in: Capsule())
    }

    @ViewBuilder
    private var marker: some View {
        switch style {
        case .filled:
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        case .outlined:
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                .foregroundColor(color)
                .frame(width: 9, height: 9)
        }
    }
}

struct CalendarTheme {
    var background = AppTheme.elevatedBackground
    var monthTitleColor = Color.primary
    var weekdayColor = Color.secondary
    var todayRing = AppTheme.accent
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

private struct RecordPickerSheet: View {
    let day: Date
    let records: [PeriodRecordSnapshot]
    let onSelect: (PeriodRecordSnapshot) -> Void
    let onTapAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            List {
                Section("編輯既有紀錄") {
                    ForEach(records) { record in
                        Button {
                            onSelect(record)
                        } label: {
                            recordRow(record)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button(action: onTapAdd) {
                        Label("在這天新增紀錄", systemImage: "plus.circle.fill")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .navigationTitle(dayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var dayTitle: String {
        "\(Self.headerFormatter.string(from: day)) 的紀錄"
    }

    private func recordRow(_ record: PeriodRecordSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rangeText(record))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.primary)
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    private func rangeText(_ record: PeriodRecordSnapshot) -> String {
        let start = record.startDate ?? day
        if let end = record.endDate {
            return "\(Self.rowFormatter.string(from: start)) - \(Self.rowFormatter.string(from: end))"
        } else {
            return "\(Self.rowFormatter.string(from: start)) 開始（進行中）"
        }
    }

    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M 月 d 日"
        return formatter
    }()

    private static let rowFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}
