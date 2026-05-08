//
//  MultiProfilesView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI
import CoreData

/// 多人資訊管理頁
struct MultiProfilesView: View {
    @Environment(\.managedObjectContext) private var ctx
    @StateObject private var vm: ProfilesViewModel
    private let onTapAdd: (() -> Void)?
    private let onSelectPerson: ((PersonSummary) -> Void)?
    private let reloadToken: UUID

    init(onTapAdd: (() -> Void)? = nil,
         onSelectPerson: ((PersonSummary) -> Void)? = nil,
         reloadToken: UUID = UUID(),
         context: NSManagedObjectContext? = nil) {
        self.onTapAdd = onTapAdd
        self.onSelectPerson = onSelectPerson
        self.reloadToken = reloadToken
        let resolvedContext = context ?? PersistenceController.shared.container.viewContext
        _vm = StateObject(wrappedValue: ProfilesViewModel(context: resolvedContext))
    }


    @State private var showingAdd = false
    
//    @StateObject private var vm: ProfilesViewModel
//    init(context: NSManagedObjectContext) {
//        _vm = StateObject(wrappedValue: ProfilesViewModel(context: context))
//    }

    var body: some View {
        ZStack {
            MainBackground() // 客製化背景

            List {
                ForEach(vm.people) { person in
                    Button {
                        if let onSelectPerson {
                            onSelectPerson(person)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: person.colorHex))
                                .frame(width: 14, height: 14)

                            Text(person.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.white.opacity(0.28))
                }
            }
            .listStyle(.insetGrouped)
            .applyTransparentListBackground()   // 加這段才可套用客製化背景色
        }
        .navigationTitle("經期管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let onTapAdd {
                        onTapAdd()
                    } else {
                        showingAdd = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddPersonSheet(context: ctx) {
                vm.fetchPeople()
            }
        }
        .onAppear(perform: vm.fetchPeople)
        .onChange(of: reloadToken) { _ in
            vm.fetchPeople()
        }
    }
}

/// iOS 16 用 scrollContentBackground(.hidden)
/// iOS 15 退回使用 UITableView 外觀清空（只在此畫面作用）
private struct TransparentListBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                    UITableViewCell.appearance().backgroundColor = .clear
                }
                .onDisappear {
                    UITableView.appearance().backgroundColor = 
                        .systemGroupedBackground
                    UITableViewCell.appearance().backgroundColor =
                        .secondarySystemGroupedBackground
                }
        }
    }
}

private extension View {
    /// 隱藏系統 List 背景
    func applyTransparentListBackground() -> some View {
        modifier(TransparentListBackground())
    }
}
