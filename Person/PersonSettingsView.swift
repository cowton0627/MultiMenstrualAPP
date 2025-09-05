//
//  PersonSettingsView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI
import CoreData
import UIKit

struct PersonSettingsView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var person: Person

    @State private var name: String
    @State private var color: Color
    @State private var showDeleteAlert = false

    init(person: Person) {
        self.person = person
        _name  = State(initialValue: person.name ?? "")
        _color = State(initialValue: Color(hex: person.colorHex ?? "#FF6B6B"))
    }

    var body: some View {
        Form {
            Section(header: Text("基本資料")) {
                TextField("姓名", text: $name)

                // iOS15 可用，selection 要用 $color（Binding<Color>）
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
                    Label("刪除這位對象", systemImage: "trash")
                }
            }
        }
        .navigationTitle("編輯")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
//                Button("取消") { dismiss() }
                Button("") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { savePerson() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        // iOS15 的 alert 簽名如下（標題 + 兩個 trailing closures）
        .alert(Text("確定要刪除？"), isPresented: $showDeleteAlert) {
            Button("刪除", role: .destructive) { deletePerson() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此對象的所有經期紀錄也會一併刪除。")
            //（因為 Person.records 設為 Cascade）
        }
    }

    private func savePerson() {
        person.name = name
        person.colorHex = color.toHexString()
        try? ctx.save()
        dismiss()
    }

    private func deletePerson() {
        ctx.delete(person)
        try? ctx.save()
        dismiss()
    }
}

