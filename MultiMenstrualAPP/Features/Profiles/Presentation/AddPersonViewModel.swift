//
//  AddPersonViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import SwiftUI
import CoreData

final class AddPersonViewModel: ObservableObject {
    @Published var name = ""
    @Published var color: Color = Color(hex: Person.defaultColorHex)
    @Published var colorHex = Person.defaultColorHex
    @Published var hexError: String?

    let swatches: [String] = [
        Person.defaultColorHex, "#FF9F0A", "#FFB020", "#34C759",
        "#5AC8FA", "#007AFF", "#AF52DE", "#FF2D55"
    ]

    private let repository: PersonRepository

    init(context: NSManagedObjectContext) {
        self.repository = PersonRepository(context: context)
    }

    func selectSwatch(hex: String) {
        color = Color(hex: hex)
        colorHex = hex
        hexError = nil
    }

    func updateColor(_ newValue: Color) {
        color = newValue
        colorHex = newValue.toHexString()
        hexError = nil
    }

    func updateHexInput(_ newValue: String) {
        let normalized = normalizeHex(newValue)
        if let parsed = Color.tryFromHex(normalized) {
            color = parsed
            colorHex = normalized
            hexError = nil
        } else {
            colorHex = normalized
            hexError = "格式需為 #RRGGBB"
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hexError == nil
    }

    func save() throws {
        guard canSave else { return }
        try repository.add(name: name, colorHex: colorHex)
    }

    private func normalizeHex(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !value.hasPrefix("#") {
            value = "#\(value)"
        }
        return value
    }
}
