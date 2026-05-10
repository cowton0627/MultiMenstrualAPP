//
//  AddPersonSheet.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/1.
//

import SwiftUI
import CoreData

/// 多人資訊管理頁之加號跳頁
struct AddPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: AddPersonViewModel
    @State private var alertError: AlertError?

    init(context: NSManagedObjectContext) {
        _vm = StateObject(wrappedValue: AddPersonViewModel(
            repository: PersonRepository(context: context)
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資料")) {
                    TextField("輸入姓名", text: $vm.name)

                    // 顏色選擇（即時預覽）
                    HStack(spacing: 12) {
                        Circle().fill(vm.color).frame(width: 28, height: 28)

                        ColorPicker("當前顏色",
                                    selection: $vm.color,
                                    supportsOpacity: false)
                        .onChange(of: vm.color) { newValue in
                            vm.updateColor(newValue)
                        }
                    }

                    // 常用色板，swatches
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8)
                    {
                        ForEach(vm.swatches, id: \.self) { hex in
                            Button {
                                vm.selectSwatch(hex: hex)
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle().stroke(
                                            vm.color.toHexString() == hex ? Color.primary : Color.secondary.opacity(0.2),
                                            lineWidth: vm.color.toHexString() == hex ? 2 : 1
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(hex))
                        }
                    }.padding(.vertical, 4)

                    // HEX 手動輸入（雙向同步）
                    HStack {
                        Text("HEX色碼")
                        Spacer()
                        TextField("#RRGGBB", text: $vm.colorHex)
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 120)
                        
                            .onChange(of: vm.colorHex) { new in
                                vm.updateHexInput(new)
                            }
                    }
                    
                    if let error = vm.hexError {   // 有錯誤才多一格顯示
                        Text(error).foregroundColor(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle("新增人物")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        do {
                            try vm.save()
                            dismiss()
                        } catch {
                            alertError = AlertError(error, title: "新增失敗")
                        }
                    }
                    .disabled(!vm.canSave)
                }
            }
            .errorAlert($alertError)
        }
    }
}
