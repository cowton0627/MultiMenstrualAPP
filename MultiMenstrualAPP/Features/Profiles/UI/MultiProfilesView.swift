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

    init(context: NSManagedObjectContext,
         onTapAdd: (() -> Void)? = nil,
         onSelectPerson: ((PersonSummary) -> Void)? = nil,
         reloadToken: UUID = UUID()) {
        self.onTapAdd = onTapAdd
        self.onSelectPerson = onSelectPerson
        self.reloadToken = reloadToken
        _vm = StateObject(wrappedValue: ProfilesViewModel(context: context))
    }

    @State private var showingAdd = false

    var body: some View {
        ZStack {
            MainBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("經期管理")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(.primary)

                        Text("為每個人保留獨立紀錄與預測")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 18)

                    if vm.people.isEmpty {
                        EmptyProfilesView(onTapAdd: onTapAdd ?? { showingAdd = true })
                    } else {
                        VStack(spacing: 12) {
                            ForEach(vm.people) { person in
                                Button {
                                    if let onSelectPerson {
                                        onSelectPerson(person)
                                    }
                                } label: {
                                    ProfileRow(person: person)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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

private struct ProfileRow: View {
    let person: PersonSummary

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: person.colorHex).opacity(0.18))

                Circle()
                    .fill(Color(hex: person.colorHex))
                    .frame(width: 18, height: 18)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 5) {
                Text(person.displayName)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)

                Text(detailText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleStroke, lineWidth: 1)
        )
        .shadow(color: AppTheme.softShadow, radius: 14, x: 0, y: 8)
    }

    private var detailText: String {
        if person.recordCount == 0 {
            return "尚未建立經期紀錄"
        }

        if let latestStartDate {
            return "\(person.recordCount) 筆紀錄 · 最近 \(Self.formatter.string(from: latestStartDate))"
        }

        return "\(person.recordCount) 筆紀錄"
    }

    private var latestStartDate: Date? {
        person.latestStartDate
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M 月 d 日"
        return formatter
    }()
}

private struct EmptyProfilesView: View {
    let onTapAdd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 76, height: 76)
                .background(AppTheme.fieldBackground, in: Circle())

            VStack(spacing: 6) {
                Text("還沒有 profile")
                    .font(.system(.title3, design: .rounded).weight(.semibold))

                Text("新增第一個人後，就可以開始記錄經期區間。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onTapAdd()
            } label: {
                Label("新增人物", systemImage: "plus")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleStroke, lineWidth: 1)
        )
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
