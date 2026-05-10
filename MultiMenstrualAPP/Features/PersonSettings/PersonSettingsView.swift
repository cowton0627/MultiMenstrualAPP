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
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm: PersonSettingsViewModel
    @State private var showDeleteAlert = false

    init(profile: PersonProfile, context: NSManagedObjectContext) {
        _vm = StateObject(wrappedValue: PersonSettingsViewModel(
            profile: profile,
            repository: PersonRepository(context: context)
        ))
    }

    var body: some View {
        Form {
            Section(header: Text("基本資料")) {
                TextField("姓名", text: $vm.name)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(Color.init(hex: vm.color.toHexString()))

                ColorPicker("當前顏色",
                            selection: $vm.color,
                            supportsOpacity: false)

                HStack {
                    Text("HEX色碼")
                    Spacer()
                    // Text 沒有 .monospaced() 修飾器；要在 Font 上套 monospaced
                    Text(vm.color.toHexString())
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
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { savePerson() }
                    .disabled(!vm.canSave)
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
        do {
            try vm.save()
            dismiss()
        } catch { print("Save error:", error) }
    }

    private func deletePerson() {
        do {
            try vm.delete()
            dismiss()
        } catch { print("Delete error:", error) }
    }
}
