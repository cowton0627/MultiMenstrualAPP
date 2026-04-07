//
//  AddPersonViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

//import Foundation
//import SwiftUI


//final class AddPersonViewModel: ObservableObject {
//    @Published var name: String = ""
//    @Published var color: Color = Color(hex: "#FF6B6B")
//    @Published var colorHex: String = "#FF6B6B"
//    @Published var hexError: String?
//
//
//    let swatches: [String] = [
//        "#FF6B6B", "#FF9F0A", "#FFB020", "#34C759",
//        "#5AC8FA", "#007AFF", "#AF52DE", "#FF2D55"
//    ]
//
//
//    private let repository: PersonRepository
//
//
//    init(repository: PersonRepository) {
//        self.repository = repository
//    }
//
//
//    func selectSwatch(hex: String) {
//        color = Color(hex: hex)
//        colorHex = hex
//        hexError = nil
//    }
//
//
//    func updateHexInput(_ new: String) {
//        let normalized = normalizeHex(new)
//        if let parsed = Color.tryFromHex(normalized) {
//            color = parsed
//            colorHex = normalized
//            hexError = nil
//        } else {
//            hexError = "格式需為 #RRGGBB"
//        }
//    }
//
//
//    func save() {
//        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty, hexError == nil else { return }
//        repository.add(name: trimmed, colorHex: colorHex)
//    }
//
//
//    var canSave: Bool {
//        !name.trimmingCharacters(in: .whitespaces).isEmpty && hexError == nil
//    }
//
//
//    private func normalizeHex(_ s: String) -> String {
//        var t = s.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//        if !t.hasPrefix("#") { t = "#\(t)" }
//        return t.count == 7 ? t : "#FFFFFF"
//    }
//}
