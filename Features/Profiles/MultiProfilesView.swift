//
//  MultiProfilesView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI
import CoreData

struct MultiProfilesView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.createdAt, 
                                           ascending: true)],
        animation: .default
    )
    private var people: FetchedResults<Person>

    @State private var showingAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                WarmPastelBackground() // 客製化背景

                List {
                    ForEach(people) { p in
                        NavigationLink {
                            CalendarScreen(person: p)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: p.colorHex ?? "#FF6B6B"))
                                    .frame(width: 14, height: 14)

                                Text(p.name ?? "未命名")
                                    .font(.body)              // 動態字級
                                    .fontWeight(.medium)      // 權重分開設
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 6)
                        }
                        // 霧面半透明列底，讓漸層可透出
                        .listRowBackground(Color.white.opacity(0.28))
                    }
                    .onDelete { idx in
                        idx.map { people[$0] }.forEach(ctx.delete)
                        try? ctx.save()
                    }
                }
                .listStyle(.insetGrouped)
                .applyTransparentListBackground()   // 加這段才能用客製化背景色
            }
            .navigationTitle("經期管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddPersonSheet()
                    .environment(\.managedObjectContext, ctx)
            }
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
                    UITableView.appearance().backgroundColor = .systemGroupedBackground
                    UITableViewCell.appearance().backgroundColor = .secondarySystemGroupedBackground
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


