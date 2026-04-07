//
//  ProfilesViewModel.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/5.
//

import SwiftUI
import CoreData

final class ProfilesViewModel: ObservableObject {
    @Published var people: [Person] = []
    private let ctx: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.ctx = context
        fetchPeople()
    }

    func fetchPeople() {
        let request = Person.fetchRequest()
        request.sortDescriptors = 
        [NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)]
        
        do {
            people = try ctx.fetch(request)
        } catch { print("Fetch error:", error) }
    }
    
    /// 新增人物
    func addPerson(name: String, colorHex: String) {
        let p = Person(context: ctx)
        p.id = UUID()
        p.createdAt = .now
        p.name = name
        p.colorHex = colorHex
        do {
            try ctx.save()
            fetchPeople()
        } catch { print("Save error:", error) }
    }

    /// 刪除人物
    func delete(at offsets: IndexSet) {
        for index in offsets {
            ctx.delete(people[index])
        }
        do {
            try ctx.save()
            fetchPeople()
        } catch { print("Delete error:", error) }
    }

    
}

