//
//  PersonSettingsViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/4/7.
//

import SwiftUI
import CoreData

final class PersonSettingsViewModel: ObservableObject {
    @Published var name: String
    @Published var color: Color

    private let objectID: NSManagedObjectID
    private let repository: PersonRepositoryProtocol

    init(profile: PersonProfile, repository: PersonRepositoryProtocol) {
        self.objectID = profile.objectID
        self.repository = repository
        self.name = profile.displayName
        self.color = Color(hex: profile.colorHex)
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() throws {
        try repository.update(objectID: objectID,
                              name: name,
                              colorHex: color.toHexString())
    }

    func delete() throws {
        try repository.delete(objectID: objectID)
    }
}
