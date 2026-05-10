//
//  ProfilesViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import SwiftUI
import CoreData

final class ProfilesViewModel: NSObject, ObservableObject {
    @Published private(set) var people: [PersonSummary] = []

    private let context: NSManagedObjectContext
    private var frc: NSFetchedResultsController<Person>!

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        configureFRC()
    }

    private func configureFRC() {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)
        ]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: context,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
        try? frc.performFetch()
        recompute()
    }

    private func recompute() {
        people = (frc.fetchedObjects ?? []).map(PersonSummary.init(person:))
    }
}

extension ProfilesViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        recompute()
    }
}
