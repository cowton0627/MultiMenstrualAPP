//
//  PersonSettingsView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI
import CoreData

/// 個人月曆頁之編輯跳頁
struct PersonSettingsView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var person: Person
//    var onDeleted: () -> Void

    @State private var name: String
    @State private var color: Color
    @State private var showDeleteAlert = false

    init(person: Person
//         , onDeleted: @escaping () -> Void
    ) {
        self.person = person
//        self.onDeleted = onDeleted
        _name  = State(initialValue: person.name ?? "")
        _color = State(initialValue: Color(hex: person.colorHex ?? "#FF6B6B"))
    }

    var body: some View {
        Form {
            Section(header: Text("基本資料")) {
                TextField("姓名", text: $name)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(Color.init(hex: color.toHexString()))

                ColorPicker("當前顏色",
                            selection: $color,
                            supportsOpacity: false)

                HStack {
                    Text("HEX色碼")
                    Spacer()
                    // Text 沒有 .monospaced() 修飾器；要在 Font 上套 monospaced
                    Text(color.toHexString())
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("刪除人物", systemImage: "trash")
                }
            }
        }
        .navigationTitle("編輯")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
//                Button("") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { savePerson() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .alert(Text("確定要刪除？"), isPresented: $showDeleteAlert) {
            Button("刪除", role: .destructive) { deletePerson() }
            Button("取消", role: .cancel) { print("什麼事也沒做") }
        } message: {
            Text("此人的所有經期紀錄也會一併刪除。")
            //（因為 Person.records 設為 Cascade）
        }
    }

    
    private func savePerson() {
        person.name = name
        person.colorHex = color.toHexString()
        do {
            try ctx.save()
            dismiss()
        } catch { print("Save error:", error) }
    }

    private func deletePerson() {
        ctx.delete(person)
        do {
            try ctx.save()
//            onDeleted()   // 通知上一層 pop
            dismiss()     // 關閉設定頁
        } catch { print("Delete error:", error) }
    }
}

