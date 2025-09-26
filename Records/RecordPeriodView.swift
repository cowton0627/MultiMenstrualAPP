//
//  RecordEditorView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI

struct RecordPeriodView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let person: Person
    let defaultStart: Date
    let defaultEnd: Date
    var editing: PeriodRecord? = nil    // 新增：編輯中的物件
    var onSaved: (_ start: Date, _ end: Date?) -> Void = { _,_  in }
    
//    @State var endDate = Date().addDays(5)
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var inProgress: Bool = false   // 有打勾就把 endDate 存成 nil
    @State private var notes = ""
    
    init(person: Person,
         defaultStart: Date,
         defaultEnd: Date,
         editing: PeriodRecord? = nil) {
        self.person = person
        self.defaultStart = defaultStart
        self.defaultEnd = defaultEnd
        self.editing = editing
        // 根據是否為編輯模式帶初值
        if let r = editing {
            _startDate = State(initialValue: r.startDate?.stripTime() ?? defaultStart)
            _endDate   = State(initialValue: (r.endDate ?? defaultEnd).stripTime())
            _inProgress = State(initialValue: r.endDate == nil)
            _notes = State(initialValue: r.notes ?? "")
        } else {
            _startDate = State(initialValue: defaultStart.stripTime())
            _endDate   = State(initialValue: defaultEnd.stripTime())
        }
//        _startDate = State(initialValue: defaultStart)
//        _endDate   = State(initialValue: defaultEnd)
    }
    
    // 只要「尚未結束」或 「end >= start」就允許儲存
    private var canSave: Bool {
        inProgress || endDate.stripTime() >= startDate.stripTime()
    }

    var body: some View {
        Form {
            Section(header: Text("日期")) {
                DatePicker("開始", selection: $startDate, displayedComponents: .date)
                DatePicker("結束", selection: $endDate,
                           in: startDate...,
                           displayedComponents: .date)
                .disabled(inProgress)
                Toggle("尚未結束", isOn: $inProgress)
            }
            Section(header: Text("備註")) {
                TextField("可填寫症狀、用藥等", text: $notes)
            }
        }
        .navigationTitle("經期紀錄")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { save() }
                .disabled(!canSave)
            }
        }
        // 底部工具列：在某些機型/情境下上面按鈕不好點，這個一定看得到也點得到
//        .toolbar {
//            ToolbarItemGroup(placement: .bottomBar) {
//                Button("取消") { dismiss() }
//                Spacer()
//                Button { save() } label: {
//                    Label("儲存", systemImage: "checkmark.circle.fill")
//                }
//                .disabled(!canSave)
//            }
//        }
    }
    
    private func save() {
        // 強制滿足資料模型：必填 person（Optional = NO）
        let r: PeriodRecord = editing ?? PeriodRecord(context: ctx)
        if editing == nil {
            r.id = UUID()
            r.person = person
        }
        r.startDate = startDate.stripTime()
        r.endDate = inProgress ? nil : endDate.stripTime()
        r.notes = notes

        do {
            try ctx.save()
            onSaved(r.startDate!, r.endDate)
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
