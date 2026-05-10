//
//  AppRoute.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/5/8.
//

import Foundation

enum AppRoute: Hashable {
    case calendar(PersonID)
    case personSettings(PersonID)
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
    let personID: PersonID
    let recordID: PeriodRecordID?
    let defaultStart: Date
    let defaultEnd: Date
}
