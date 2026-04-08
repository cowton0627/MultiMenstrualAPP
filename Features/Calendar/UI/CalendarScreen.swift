//
//  CalendarScreen.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI
import CoreData

// MARK: - 顯示與設定經期的畫面（使用 ElegantCalendarView）
struct CalendarScreen: View {
    @ObservedObject private var person: Person
    @StateObject private var vm: CalendarViewModel

    init(person: Person, context: NSManagedObjectContext) {
        self.person = person
        _vm = StateObject(wrappedValue: CalendarViewModel(ctx: context,
                                                          person: person))
    }

    var body: some View {
        VStack(spacing: 0) {
            ElegantCalendarView(
                visibleMonth: Binding(
                    get: { vm.state.visibleMonth },
                    set: { vm.send(.setVisibleMonth($0)) }
                ),
                periodRanges: vm.state.ranges,
                predictedWindows: vm.state.predicted,
                theme: CalendarTheme(),
                firstWeekday: 2
            ) { tappedDate in
                vm.send(.tapDay(tappedDate))
            }
        }
        .navigationTitle(vm.state.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("編輯") {
                    PersonSettingsView(person: person, context: vm.context)
                }
            }
        }
        .onAppear {
            vm.send(.appear)
        }
        .sheet(
            isPresented: Binding(
                get: { vm.state.showEditor },
                set: { if !$0 { vm.send(.closeEditor) } }
            )
        ) {
            NavigationView {
                RecordPeriodView(
                    person: person,
                    context: vm.context,
                    defaultStart: vm.state.editorStart,
                    defaultEnd: vm.state.editorEnd,
                    editing: vm.state.editing
                )
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct CalendarTheme {
    var background = Color(UIColor.systemBackground)
    var monthTitleColor = Color.primary
    var weekdayColor = Color.secondary
    var todayRing = Color.accentColor
    var gridSeparator = Color.secondary.opacity(0.12)
    var dayText = Color.primary
    var outMonthText = Color.secondary.opacity(0.5)
    var predictedDash = Color.orange
    var selectionCorner: CGFloat = 8
    var dayMinHeight: CGFloat = 44
    var contentPadding: CGFloat = 16
    var fontDay = Font.system(.subheadline, design: .rounded).weight(.semibold)
    var fontMonth = Font.system(.title2, design: .rounded).weight(.bold)
    var fontWeekday = Font.system(.caption2, design: .rounded).weight(.semibold)
}
