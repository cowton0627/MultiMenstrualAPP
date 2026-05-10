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

    var body: some View {
        TabView {
            NavigationView {
                ProfilesFlowView(
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
                SettingsHomeView()
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
                AddPersonSheet(context: context)
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
                }
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
                personID: personID,
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

    let personID: PersonID
    let onRequestRecordEditor: (RecordEditorSheetContext) -> Void

    @State private var route: AppRoute?

    var body: some View {
        ZStack {
            if let person = personProfile {
                CalendarScreen(
                    person: person,
                    context: context,
                    onTapEditPerson: {
                        route = .personSettings(personID)
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
        repository.fetchProfile(id: personID)
    }

    @ViewBuilder
    private var settingsDestination: some View {
        switch route {
        case .personSettings(let id):
            if let profile = repository.fetchProfile(id: id) {
                PersonSettingsView(profile: profile, context: context)
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
        if let profile = personProfile {
            NavigationView {
                RecordPeriodView(
                    person: profile,
                    context: context,
                    defaultStart: editor.defaultStart,
                    defaultEnd: editor.defaultEnd,
                    editing: snapshot
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

    private var personRepo: PersonRepository {
        PersonRepository(context: context)
    }

    private var recordRepo: PeriodRecordRepository {
        PeriodRecordRepository(context: context)
    }

    private var personProfile: PersonProfile? {
        personRepo.fetchProfile(id: editor.personID)
    }

    private var snapshot: PeriodRecordSnapshot? {
        guard let recordID = editor.recordID else { return nil }
        return recordRepo.fetchSnapshot(id: recordID)
    }
}
