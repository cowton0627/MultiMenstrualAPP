//
//  MultiProfilesViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import SwiftUI

final class MultiProfilesViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var showingAdd = false

//    private let repository: PersonRepository
    let repository: PersonRepository

    init(repository: PersonRepository) {
        self.repository = repository
        fetchPeople()
    }

    func fetchPeople() {
        people = repository.fetchAll()
    }

    func delete(at offsets: IndexSet) {
        repository.delete(offsets: offsets, from: people)
        fetchPeople()
    }

    func addPerson(name: String, colorHex: String) {
        repository.add(name: name, colorHex: colorHex)
        fetchPeople()
    }
}
