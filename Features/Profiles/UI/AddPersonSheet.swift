//
//  AddPersonSheet.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/1.
//

import SwiftUI

struct AddPersonSheet: View {
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.managedObjectContext) private var ctx
//    @State private var name = ""
//    @State private var color: Color = Color(hex: "#FF6B6B") // 預設當前顏色
//    @State private var colorHex = "#FF6B6B" // 預設當前顏色色碼
//    @State private var hexError: String?
    
//    // 預設色板
//    private let swatches: [String] = [
//        "#FF6B6B", "#FF9F0A", "#FFB020", "#34C759",
//        "#5AC8FA", "#007AFF", "#AF52DE", "#FF2D55"
//    ]
    
    @ObservedObject var vm: AddPersonViewModel
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資料")) {
//                    TextField("輸入姓名", text: $name)
                    TextField("輸入姓名", text: $vm.name)


                    // 顏色選擇（即時預覽）
                    HStack(spacing: 12) {
                        Circle()
//                            .fill(color)
                            .fill(vm.color)
                            .frame(width: 28, height: 28)
//                            .overlay(Circle().stroke(Color.secondary.opacity(0.2),
//                                                     lineWidth: 1))

                        ColorPicker("當前顏色",
                                    selection: $vm.color,
                                    supportsOpacity: false)
                        .onChange(of: vm.color) { newValue in
                            vm.colorHex = newValue.toHexString()
                            vm.hexError = nil
                            }
                    }

                    // 常用色板，swatches
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(),
                                                                 spacing: 8),
                                             count: 8),
                              spacing: 8) {
                        ForEach(vm.swatches, id: \.self) { hex in
                            Button {
//                                color = Color(hex: hex)
//                                colorHex = hex
//                                hexError = nil
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
                    }
                    .padding(.vertical, 4)

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
                            .onChange(of: vm.colorHex, perform: vm.updateHexInput)
//                        { new in
//                                let normalized = normalizeHex(new)
//                                if let parsed = Color.tryFromHex(normalized) {
//                                    color = parsed
//                                    colorHex = normalized
//                                    hexError = nil
//                                } else {
//                                    hexError = "格式需為 #RRGGBB"
//                                }
//                            }
                    }
                    if let error = vm.hexError {
                        Text(error).foregroundColor(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle("新增對象")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("取消", action: onCancel)
//                    { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        vm.save()
                        onSave()
//                        let p = Person(context: ctx)
//                        p.id = UUID()
//                        p.createdAt = .now
//                        p.name = name
//                        p.colorHex = colorHex
//                        try? ctx.save()
//                        dismiss()
                    }
//                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || hexError != nil)
                    .disabled(!vm.canSave)

                }
            }
        }
    }

    // ---- Helpers ----
    private func normalizeHex(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.hasPrefix("#") { t = "#"+t }
        if t.count == 7 { return t.uppercased() }
        return t.uppercased()
    }
}


