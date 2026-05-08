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
    private let onSaved: (_ start: Date, _ end: Date?) -> Void
    
    init(person: Person,
         context: NSManagedObjectContext,
         defaultStart: Date,
         defaultEnd: Date,
         editing: PeriodRecord? = nil,
         onSaved: @escaping (_ start: Date, _ end: Date?) -> Void = { _,_  in }) {
        self.onSaved = onSaved
        _vm = StateObject(wrappedValue: RecordPeriodViewModel(person: person,
                                                              defaultStart: defaultStart,
                                                              defaultEnd: defaultEnd,
                                                              editing: editing,
                                                              context: context))
    }

    var body: some View {
        Form {
            Section(header: Text("日期")) {
                DatePicker("開始", selection: $vm.startDate, displayedComponents: .date)
                DatePicker("結束", selection: $vm.endDate,
                           in: vm.startDate...,
                           displayedComponents: .date)
                .disabled(vm.inProgress)
                Toggle("尚未結束", isOn: $vm.inProgress)
            }
            Section(header: Text("備註")) {
                TextField("可填寫症狀、用藥等", text: $vm.notes)
            }
        }
        .navigationTitle("經期紀錄")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { save() }
                .disabled(!vm.canSave)
            }
        }
    }
    
    private func save() {
        do {
            let record = try vm.save()
            onSaved(record.startDate!, record.endDate)
            dismiss()
        } catch {
            assertionFailure("Save record failed: \(error)")
        }
    }
}

//#Preview {
//    RecordEditorView(person: <#Person#>,
//                     defaultStart: <#Date#>,
//                     defaultEnd: <#Date#>)
//}
