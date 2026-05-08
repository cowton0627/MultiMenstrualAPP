//
//  ProfilesViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import SwiftUI
import CoreData

final class ProfilesViewModel: ObservableObject {
    @Published private(set) var people: [PersonSummary] = []
    private let repository: PersonRepository

    init(context: NSManagedObjectContext) {
        self.repository = PersonRepository(context: context)
        fetchPeople()
    }

    func fetchPeople() {
        people = repository.fetchAllSummaries()
    }
}
