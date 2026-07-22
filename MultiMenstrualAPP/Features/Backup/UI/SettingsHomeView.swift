//
//  SettingsHomeView.swift
//  MultiMenstrualAPP
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SettingsHomeView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var exportDocument = JSONBackupDocument(text: "{}")
    @State private var showingExporter = false
    @State private var showingExportConfirmation = false
    @State private var showingImporter = false
    @State private var showingImportConfirmation = false
    @State private var showingDemoConfirmation = false
    @State private var alertError: AlertError?
    @State private var importMessage: String?
    @State private var settingsInfo: SettingsInfo?

    var body: some View {
        ZStack {
            MainBackground()

            ScrollView {
                VStack(spacing: 14) {
                    SettingsPanel(title: "資料") {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "匯出資料",
                            subtitle: "JSON 備份，可供跨平台匯入",
                            action: { showingExportConfirmation = true }
                        )
                        SettingsRow(
                            icon: "square.and.arrow.down",
                            title: "匯入資料",
                            subtitle: "讀取 schemaVersion 1 JSON 備份",
                            action: { showingImportConfirmation = true }
                        )
                    }

                    SettingsPanel(title: "作品展示") {
                        SettingsRow(
                            icon: "sparkles",
                            title: "載入展示資料",
                            subtitle: "以 3 位虛構人物與週期紀錄取代現有資料",
                            action: { showingDemoConfirmation = true }
                        )
                    }

                    SettingsPanel(title: "隱私") {
                        SettingsRow(
                            icon: "externaldrive.badge.checkmark",
                            title: "離線使用",
                            subtitle: "不需登入，經期資料只儲存在此裝置",
                            action: { settingsInfo = .offline }
                        )
                        SettingsRow(
                            icon: "lock.shield",
                            title: "隱私與安全",
                            subtitle: "查看資料儲存與備份注意事項",
                            action: { settingsInfo = .privacy }
                        )
                    }

                    SettingsPanel(title: "偏好") {
                        SettingsRow(
                            icon: "bell",
                            title: "經期提醒",
                            subtitle: "通知尚未接入預測流程",
                            accessoryText: "規劃中"
                        )
                        SettingsRow(
                            icon: "circle.lefthalf.filled",
                            title: "外觀",
                            subtitle: "自動配合 iPhone 的淺色或深色模式",
                            accessoryText: "跟隨系統"
                        )
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("設定")
        .alert("匯出私人資料？", isPresented: $showingExportConfirmation) {
            Button("取消", role: .cancel) {}
            Button("匯出") { exportJSON() }
        } message: {
            Text("匯出檔會包含人物名稱、經期日期與備註。請只儲存在你信任的位置。")
        }
        .alert("匯入資料？", isPresented: $showingImportConfirmation) {
            Button("取消", role: .cancel) {}
            Button("選擇檔案") { showingImporter = true }
        } message: {
            Text("匯入會依 UUID 更新既有人物與紀錄，或新增不存在的資料。建議先匯出一份備份。")
        }
        .confirmationDialog(
            "載入展示資料？",
            isPresented: $showingDemoConfirmation,
            titleVisibility: .visible
        ) {
            Button("取代為虛構展示資料", role: .destructive) {
                loadDemoData()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("這會刪除目前所有人物與經期紀錄。若資料需要保留，請先匯出備份。")
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultExportFilename
        ) { result in
            if case .failure(let error) = result {
                alertError = AlertError(error, title: "匯出失敗")
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importJSON(result)
        }
        .errorAlert($alertError)
        .alert("匯入完成", isPresented: Binding(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { importMessage = nil }
        } message: {
            Text(importMessage ?? "")
        }
        .alert(item: $settingsInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private var defaultExportFilename: String {
        "MultiMenstrualAPP-\(Self.filenameDateFormatter.string(from: Date()))"
    }

    private func exportJSON() {
        do {
            let payload = try ExportPayload.make(context: context)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(payload)
            guard let text = String(data: data, encoding: .utf8) else {
                alertError = AlertError(title: "匯出失敗", message: "無法建立 UTF-8 JSON 內容。")
                return
            }
            exportDocument = JSONBackupDocument(text: text)
            showingExporter = true
        } catch {
            alertError = AlertError(error, title: "匯出失敗")
        }
    }

    private func importJSON(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(ExportPayload.self, from: data)
            let summary = try payload.importInto(context: context)
            try context.save()
            importMessage = "已匯入 \(summary.profileCount) 個人物與 \(summary.recordCount) 筆經期紀錄。"
        } catch {
            alertError = AlertError(error, title: "匯入失敗")
        }
    }

    private func loadDemoData() {
        do {
            let summary = try DemoDataSeeder.replaceAll(in: context)
            importMessage = "展示資料已就緒：\(summary.profileCount) 個人物、\(summary.recordCount) 筆紀錄。"
        } catch {
            alertError = AlertError(error, title: "載入展示資料失敗")
        }
    }

    private static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}

private enum SettingsInfo: String, Identifiable {
    case offline
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .offline: return "目前採離線模式"
        case .privacy: return "隱私與安全"
        }
    }

    var message: String {
        switch self {
        case .offline:
            return "羽時目前不需建立帳號，也不會將經期資料上傳到伺服器。換機前請先匯出 JSON 備份；刪除 App 會一併移除本機資料。"
        case .privacy:
            return "人物名稱、經期日期與備註儲存在裝置本機。App 不含廣告或第三方分析；匯出的 JSON 含敏感資料，請只存放在你信任的位置。"
        }
    }
}

struct DemoDataSummary: Equatable {
    let profileCount: Int
    let recordCount: Int
}

enum DemoDataSeeder {
    private struct ProfileSeed {
        let name: String
        let colorHex: String
        let cycleLength: Int
        let daysSinceLatestStart: Int
        let note: String
    }

    static func replaceAll(in context: NSManagedObjectContext,
                           today: Date = Date()) throws -> DemoDataSummary {
        let calendar = Calendar.current
        let normalizedToday = calendar.startOfDay(for: today)
        let profiles = [
            ProfileSeed(name: "小羽", colorHex: "#D8647C", cycleLength: 28,
                        daysSinceLatestStart: 18, note: "精神狀態不錯"),
            ProfileSeed(name: "安然", colorHex: "#5AC8FA", cycleLength: 30,
                        daysSinceLatestStart: 8, note: "有輕微腹痛"),
            ProfileSeed(name: "米亞", colorHex: "#AF52DE", cycleLength: 26,
                        daysSinceLatestStart: 20, note: "提早休息、多喝水")
        ]

        do {
            let existingRecords = try context.fetch(PeriodRecord.fetchRequest()) as! [PeriodRecord]
            existingRecords.forEach(context.delete)
            let existingPeople = try context.fetch(Person.fetchRequest()) as! [Person]
            existingPeople.forEach(context.delete)

            var recordCount = 0
            var insertedObjects: [NSManagedObject] = []
            for (profileIndex, seed) in profiles.enumerated() {
                let person = Person(context: context)
                insertedObjects.append(person)
                person.id = UUID()
                person.name = seed.name
                person.colorHex = seed.colorHex
                person.createdAt = calendar.date(byAdding: .minute,
                                                  value: profileIndex,
                                                  to: normalizedToday) ?? normalizedToday

                for cycleIndex in (0..<4).reversed() {
                    let daysAgo = seed.daysSinceLatestStart + cycleIndex * seed.cycleLength
                    guard let startDate = calendar.date(byAdding: .day,
                                                        value: -daysAgo,
                                                        to: normalizedToday),
                          let endDate = calendar.date(byAdding: .day,
                                                      value: 4,
                                                      to: startDate) else {
                        continue
                    }

                    let record = PeriodRecord(context: context)
                    insertedObjects.append(record)
                    record.id = UUID()
                    record.person = person
                    record.startDate = startDate
                    record.endDate = endDate
                    record.notes = cycleIndex == 0 ? seed.note : ""
                    recordCount += 1
                }
            }

            // ProfilesViewModel may already be observing this context. Give every
            // inserted object a permanent ID before FRC snapshots are rebuilt, so
            // tapping a freshly seeded profile never routes with a stale temporary ID.
            try context.obtainPermanentIDs(for: insertedObjects)
            context.processPendingChanges()
            try context.save()
            return DemoDataSummary(profileCount: profiles.count, recordCount: recordCount)
        } catch {
            context.rollback()
            throw error
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var accessoryText: String? = nil
    var action: (() -> Void)? = nil

    @ViewBuilder
    var body: some View {
        if let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundColor(AppTheme.accent)
                .frame(width: 34, height: 34)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary.opacity(0.7))
            } else if let accessoryText {
                Text(accessoryText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct JSONBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let text = String(data: data, encoding: .utf8) {
            self.text = text
        } else {
            self.text = "{}"
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
