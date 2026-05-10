//
//  RecordPeriodView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI
import CoreData

/// 個人月曆頁之下方新增紀錄頁
struct RecordPeriodView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm: RecordPeriodViewModel
    @State private var alertError: AlertError?
    private let onSaved: () -> Void

    init(person: PersonProfile,
         context: NSManagedObjectContext,
         defaultStart: Date,
         defaultEnd: Date,
         editing: PeriodRecordSnapshot? = nil,
         onSaved: @escaping () -> Void = {}) {
        self.onSaved = onSaved
        _vm = StateObject(wrappedValue: RecordPeriodViewModel(
            person: person,
            defaultStart: defaultStart,
            defaultEnd: defaultEnd,
            editing: editing,
            repository: PeriodRecordRepository(context: context)
        ))
    }

    var body: some View {
        ZStack {
            MainBackground()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("日期", systemImage: "calendar")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            DatePicker("開始", selection: $vm.startDate, displayedComponents: .date)
                                .padding(.vertical, 12)

                            Divider()

                            DatePicker("結束",
                                       selection: $vm.endDate,
                                       in: vm.startDate...,
                                       displayedComponents: .date)
                            .disabled(vm.inProgress)
                            .opacity(vm.inProgress ? 0.45 : 1)
                            .padding(.vertical, 12)

                            Divider()

                            Toggle("尚未結束", isOn: $vm.inProgress)
                                .tint(AppTheme.accent)
                                .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 14)
                        .background(AppTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(16)
                    .cardSurface()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("備註", systemImage: "note.text")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(.primary)

                        TextField("可填寫症狀、用藥等", text: $vm.notes)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(AppTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(16)
                    .cardSurface()
                }
                .padding(16)
            }
        }
        .navigationTitle("經期紀錄")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { save() }
                .disabled(!vm.canSave)
            }
        }
        .errorAlert($alertError)
    }

    private func save() {
        do {
            try vm.save()
            onSaved()
            dismiss()
        } catch {
            alertError = AlertError(error, title: "儲存失敗")
        }
    }
}

//#Preview {
//    RecordEditorView(person: <#Person#>,
//                     defaultStart: <#Date#>,
//                     defaultEnd: <#Date#>)
//}
