//
//  AppRoute.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/5/8.
//

import Foundation
import CoreData

enum AppRoute: Hashable {
    case calendar(NSManagedObjectID)
    case personSettings(NSManagedObjectID)
}

enum AppSheet: Identifiable {
    case addPerson
    case recordEditor(RecordEditorSheetContext)

    var id: String {
        switch self {
        case .addPerson:
            return "addPerson"
        case .recordEditor(let context):
            return "recordEditor-\(context.id.uuidString)"
        }
    }
}

struct RecordEditorSheetContext: Identifiable {
    let id = UUID()
    let personObjectID: NSManagedObjectID
    let recordObjectID: NSManagedObjectID?
    let defaultStart: Date
    let defaultEnd: Date
}
