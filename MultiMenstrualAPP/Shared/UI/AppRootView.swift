//
//  AppRootView.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/5/8.
//

import SwiftUI
import CoreData

struct AppRootView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var activeSheet: AppSheet?
    @State private var profilesReloadToken = UUID()

    var body: some View {
        TabView {
            NavigationView {
                ProfilesFlowView(
                    reloadToken: profilesReloadToken,
                    onTapAdd: {
                        activeSheet = .addPerson
                    },
                    onRequestRecordEditor: { context in
                        activeSheet = .recordEditor(context)
                    }
                )
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("首頁", systemImage: "person.2")
            }

            NavigationView {
                InsightsHomeView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("總覽", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationView {
                SettingsHomeView {
                    profilesReloadToken = UUID()
                }
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
        .accentColor(AppTheme.accent)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addPerson:
                AddPersonSheet(context: context) {
                    profilesReloadToken = UUID()
                }
            case .recordEditor(let editor):
                RecordEditorSheetView(
                    context: context,
                    editor: editor
                )
            }
        }
    }
}

private struct ProfilesFlowView: View {
    @Environment(\.managedObjectContext) private var context

    let reloadToken: UUID
    let onTapAdd: () -> Void
    let onRequestRecordEditor: (RecordEditorSheetContext) -> Void

    @State private var route: AppRoute?

    var body: some View {
        ZStack {
            MultiProfilesView(
                context: context,
                onTapAdd: onTapAdd,
                onSelectPerson: { person in
                    route = .calendar(person.id)
                },
                reloadToken: reloadToken
            )

            NavigationLink(
                destination: routeDestination,
                isActive: Binding(
                    get: { route != nil },
                    set: { isActive in
                        if !isActive { route = nil }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
    }

    @ViewBuilder
    private var routeDestination: some View {
        switch route {
        case .calendar(let personID):
            CalendarFlowView(
                personObjectID: personID,
                onRequestRecordEditor: onRequestRecordEditor
            )
        case .personSettings:
            EmptyView()
        case .none:
            EmptyView()
        }
    }
}

private struct CalendarFlowView: View {
    @Environment(\.managedObjectContext) private var context

    let personObjectID: NSManagedObjectID
    let onRequestRecordEditor: (RecordEditorSheetContext) -> Void

    @State private var route: AppRoute?

    var body: some View {
        ZStack {
            if let person = personProfile {
                CalendarScreen(
                    person: person,
                    context: context,
                    onTapEditPerson: {
                        route = .personSettings(personObjectID)
                    },
                    onRequestRecordEditor: onRequestRecordEditor
                )
            } else {
                Text("找不到人物資料")
                    .font(.headline)
                    .padding(24)
            }

            NavigationLink(
                destination: settingsDestination,
                isActive: Binding(
                    get: {
                        if case .personSettings = route { return true }
                        return false
                    },
                    set: { isActive in
                        if !isActive { route = nil }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
    }

    private var repository: PersonRepository {
        PersonRepository(context: context)
    }

    private var personProfile: PersonProfile? {
        repository.fetchProfile(objectID: personObjectID)
    }

    @ViewBuilder
    private var settingsDestination: some View {
        switch route {
        case .personSettings(let personID):
            if let person = repository.fetchPerson(objectID: personID) {
                PersonSettingsView(person: person, context: context)
            } else {
                Text("找不到人物資料")
                    .font(.headline)
                    .padding(24)
            }
        default:
            EmptyView()
        }
    }
}

private struct RecordEditorSheetView: View {
    let context: NSManagedObjectContext
    let editor: RecordEditorSheetContext

    var body: some View {
        if let person = person {
            NavigationView {
                RecordPeriodView(
                    person: person,
                    context: context,
                    defaultStart: editor.defaultStart,
                    defaultEnd: editor.defaultEnd,
                    editing: record,
                    onSaved: { _, _ in }
                )
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(.stack)
        } else {
            Text("找不到資料")
                .font(.headline)
                .padding(24)
        }
    }

    private var repository: PersonRepository {
        PersonRepository(context: context)
    }

    private var recordRepository: PeriodRecordRepository {
        PeriodRecordRepository(context: context)
    }

    private var person: Person? {
        repository.fetchPerson(objectID: editor.personObjectID)
    }

    private var record: PeriodRecord? {
        guard let objectID = editor.recordObjectID else { return nil }
        return recordRepository.fetchRecord(objectID: objectID)
    }
}
