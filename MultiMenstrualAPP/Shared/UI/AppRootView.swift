//
//  AppRootView.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/5/8.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

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

private struct InsightsHomeView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)
        ],
        animation: .default
    )
    private var people: FetchedResults<Person>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PeriodRecord.startDate, ascending: false)
        ],
        animation: .default
    )
    private var records: FetchedResults<PeriodRecord>

    var body: some View {
        ZStack {
            MainBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: statColumns, spacing: 12) {
                        DashboardStatCard(
                            icon: "person.2",
                            title: "人物",
                            value: "\(people.count)",
                            tint: AppTheme.accent
                        )
                        DashboardStatCard(
                            icon: "calendar",
                            title: "紀錄",
                            value: "\(records.count)",
                            tint: AppTheme.prediction
                        )
                    }

                    if people.isEmpty {
                        EmptyInsightsView()
                    } else {
                        SettingsPanel(title: "下一次預測") {
                            let predictions = upcomingPredictions

                            if predictions.isEmpty {
                                DashboardEmptyRow(
                                    icon: "calendar.badge.exclamationmark",
                                    title: "還沒有足夠紀錄",
                                    subtitle: "新增至少一筆經期開始日後，這裡會顯示預測日期。"
                                )
                            } else {
                                ForEach(predictions) { prediction in
                                    UpcomingPredictionRow(prediction: prediction)
                                }
                            }
                        }

                        SettingsPanel(title: "最近紀錄") {
                            let recentRecords = records.prefix(5).map { $0 }

                            if recentRecords.isEmpty {
                                DashboardEmptyRow(
                                    icon: "clock.badge.questionmark",
                                    title: "尚無經期紀錄",
                                    subtitle: "到首頁選擇人物後即可新增紀錄。"
                                )
                            } else {
                                ForEach(recentRecords, id: \.objectID) { record in
                                    RecentRecordRow(record: record)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("總覽")
    }

    private var statColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var upcomingPredictions: [DashboardPrediction] {
        let today = Date().stripTime()

        return people.compactMap { person in
            guard let date = CyclePredictor(records: person.sortedRecords).predictedNextStart?.stripTime(),
                  date >= today.addDays(-2) else {
                return nil
            }

            return DashboardPrediction(
                id: person.objectID,
                personName: person.name ?? "未命名",
                color: person.uiColor,
                date: date
            )
        }
        .sorted { $0.date < $1.date }
        .prefix(5)
        .map { $0 }
    }
}

private struct SettingsHomeView: View {
    @Environment(\.managedObjectContext) private var context

    let onDataChanged: () -> Void

    @State private var exportDocument = JSONBackupDocument(text: "{}")
    @State private var showingExporter = false
    @State private var showingExportConfirmation = false
    @State private var showingImporter = false
    @State private var showingImportConfirmation = false
    @State private var transferError: DataTransferError?
    @State private var importMessage: String?

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

                    SettingsPanel(title: "帳號") {
                        SettingsRow(icon: "person.crop.circle.badge.plus", title: "登入與雲端備份", subtitle: "可選功能，不影響離線使用")
                        SettingsRow(icon: "lock.shield", title: "隱私與安全", subtitle: "管理敏感資料與匯出提醒")
                    }

                    SettingsPanel(title: "偏好") {
                        SettingsRow(icon: "bell", title: "提醒", subtitle: "經期與預測通知")
                        SettingsRow(icon: "circle.lefthalf.filled", title: "外觀", subtitle: "跟隨系統 Light / Dark Mode")
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
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultExportFilename
        ) { result in
            if case .failure(let error) = result {
                transferError = DataTransferError(title: "匯出失敗", message: error.localizedDescription)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importJSON(result)
        }
        .alert(transferError?.title ?? "資料處理失敗", isPresented: Binding(
            get: { transferError != nil },
            set: { if !$0 { transferError = nil } }
        )) {
            Button("知道了", role: .cancel) { transferError = nil }
        } message: {
            Text(transferError?.message ?? "")
        }
        .alert("匯入完成", isPresented: Binding(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { importMessage = nil }
        } message: {
            Text(importMessage ?? "")
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
                transferError = DataTransferError(title: "匯出失敗", message: "無法建立 UTF-8 JSON 內容。")
                return
            }
            exportDocument = JSONBackupDocument(text: text)
            showingExporter = true
        } catch {
            transferError = DataTransferError(title: "匯出失敗", message: error.localizedDescription)
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
            onDataChanged()
            importMessage = "已匯入 \(summary.profileCount) 個人物與 \(summary.recordCount) 筆經期紀錄。"
        } catch {
            transferError = DataTransferError(title: "匯入失敗", message: error.localizedDescription)
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

private struct DashboardPrediction: Identifiable {
    let id: NSManagedObjectID
    let personName: String
    let color: Color
    let date: Date
}

private struct DashboardStatCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleStroke, lineWidth: 1)
        )
    }
}

private struct UpcomingPredictionRow: View {
    let prediction: DashboardPrediction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(prediction.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 3) {
                Text(prediction.personName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(Self.dateFormatter.string(from: prediction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(relativeText)
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.prediction)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.prediction.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var relativeText: String {
        let days = Calendar.current.dateComponents([.day],
                                                   from: Date().stripTime(),
                                                   to: prediction.date.stripTime()).day ?? 0
        if days == 0 { return "今天" }
        if days > 0 { return "\(days) 天後" }
        return "\(abs(days)) 天前"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M 月 d 日"
        return formatter
    }()
}

private struct RecentRecordRow: View {
    let record: PeriodRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(record.person?.uiColor ?? AppTheme.accent)
                .frame(width: 34, height: 34)
                .background((record.person?.uiColor ?? AppTheme.accent).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(record.person?.name ?? "未命名")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(dateRangeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var dateRangeText: String {
        guard let startDate = record.startDate else { return "日期未設定" }
        let start = Self.dateFormatter.string(from: startDate)

        guard let endDate = record.endDate else {
            return "\(start) 開始"
        }

        return "\(start) - \(Self.dateFormatter.string(from: endDate))"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

private struct DashboardEmptyRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: 34, height: 34)
                .background(AppTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct EmptyInsightsView: View {
    var body: some View {
        InfoPanel(
            icon: "chart.line.uptrend.xyaxis",
            title: "先建立第一位人物",
            subtitle: "總覽會在有資料後整理下一次預測、最近紀錄與跨人物統計。"
        )
    }
}

private struct DataTransferError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct InfoPanel: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.accent)
                .frame(width: 38, height: 38)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))

                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleStroke, lineWidth: 1)
        )
    }
}

private struct SettingsPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.subtleStroke, lineWidth: 1)
            )
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
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

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary.opacity(0.7))
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

private struct ExportPayload: Codable {
    let schemaVersion: Int
    let exportedAt: String
    let app: ExportAppMetadata
    let profiles: [ExportProfile]

    static func make(context: NSManagedObjectContext) throws -> ExportPayload {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)
        ]

        let profiles = try context.fetch(request).map(ExportProfile.init(person:))

        return ExportPayload(
            schemaVersion: 1,
            exportedAt: ExportFormat.isoDateTimeFormatter.string(from: Date()),
            app: ExportAppMetadata.current,
            profiles: profiles
        )
    }

    func importInto(context: NSManagedObjectContext) throws -> ImportSummary {
        guard schemaVersion == 1 else {
            throw ImportError.unsupportedSchemaVersion(schemaVersion)
        }

        let peopleRequest: NSFetchRequest<Person> = Person.fetchRequest()
        let existingPeople = try context.fetch(peopleRequest)
        var peopleByID: [UUID: Person] = [:]
        for person in existingPeople {
            guard let id = person.id, peopleByID[id] == nil else { continue }
            peopleByID[id] = person
        }

        let recordsRequest: NSFetchRequest<PeriodRecord> = PeriodRecord.fetchRequest()
        let existingRecords = try context.fetch(recordsRequest)
        var recordsByID: [UUID: PeriodRecord] = [:]
        for record in existingRecords {
            guard let id = record.id, recordsByID[id] == nil else { continue }
            recordsByID[id] = record
        }

        var importedRecordCount = 0

        for profile in profiles {
            let profileID = try profile.uuid()
            let person = peopleByID[profileID] ?? Person(context: context)
            peopleByID[profileID] = person

            person.id = profileID
            person.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            person.colorHex = Color.tryFromHex(profile.colorHex) == nil ? "#FF6B6B" : profile.colorHex
            person.createdAt = profile.createdAtDate() ?? person.createdAt ?? Date()

            for exportRecord in profile.periodRecords {
                let recordID = try exportRecord.uuid()
                let record = recordsByID[recordID] ?? PeriodRecord(context: context)
                recordsByID[recordID] = record

                record.id = recordID
                record.person = person
                record.startDate = try exportRecord.start()
                record.endDate = try exportRecord.end()
                record.notes = exportRecord.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                importedRecordCount += 1
            }
        }

        return ImportSummary(profileCount: profiles.count,
                             recordCount: importedRecordCount)
    }
}

private struct ImportSummary {
    let profileCount: Int
    let recordCount: Int
}

private struct ExportAppMetadata: Codable {
    let name: String
    let platform: String
    let version: String

    static var current: ExportAppMetadata {
        ExportAppMetadata(
            name: "MultiMenstrualAPP",
            platform: "ios",
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        )
    }
}

private struct ExportProfile: Codable {
    let id: String
    let name: String
    let colorHex: String
    let createdAt: String?
    let periodRecords: [ExportPeriodRecord]

    init(person: Person) {
        let records = (person.records as? Set<PeriodRecord> ?? [])
            .sorted { lhs, rhs in
                (lhs.startDate ?? .distantPast) < (rhs.startDate ?? .distantPast)
            }

        self.id = (person.id ?? UUID()).uuidString
        self.name = person.name ?? ""
        self.colorHex = person.colorHex ?? "#FF6B6B"
        self.createdAt = person.createdAt.map(ExportFormat.isoDateTimeFormatter.string(from:))
        self.periodRecords = records.map(ExportPeriodRecord.init(record:))
    }

    func uuid() throws -> UUID {
        guard let uuid = UUID(uuidString: id) else {
            throw ImportError.invalidUUID(id)
        }
        return uuid
    }

    func createdAtDate() -> Date? {
        guard let createdAt else { return nil }
        return ExportFormat.isoDateTimeFormatter.date(from: createdAt)
    }
}

private struct ExportPeriodRecord: Codable {
    let id: String
    let startDate: String
    let endDate: String?
    let notes: String

    init(record: PeriodRecord) {
        self.id = (record.id ?? UUID()).uuidString
        self.startDate = ExportFormat.dateOnlyFormatter.string(from: record.startDate ?? Date())
        self.endDate = record.endDate.map(ExportFormat.dateOnlyFormatter.string(from:))
        self.notes = record.notes ?? ""
    }

    func uuid() throws -> UUID {
        guard let uuid = UUID(uuidString: id) else {
            throw ImportError.invalidUUID(id)
        }
        return uuid
    }

    func start() throws -> Date {
        guard let date = ExportFormat.dateOnlyFormatter.date(from: startDate) else {
            throw ImportError.invalidDate(startDate)
        }
        return date.stripTime()
    }

    func end() throws -> Date? {
        guard let endDate else { return nil }
        guard let date = ExportFormat.dateOnlyFormatter.date(from: endDate) else {
            throw ImportError.invalidDate(endDate)
        }
        return date.stripTime()
    }
}

private enum ImportError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case invalidUUID(String)
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "不支援 schemaVersion \(version)。"
        case .invalidUUID(let value):
            return "匯入檔包含無效 UUID：\(value)"
        case .invalidDate(let value):
            return "匯入檔包含無效日期：\(value)"
        }
    }
}

private enum ExportFormat {
    static let isoDateTimeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let dateOnlyFormatter: DateFormatter = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct ProfilesFlowView: View {
    let reloadToken: UUID
    let onTapAdd: () -> Void
    let onRequestRecordEditor: (RecordEditorSheetContext) -> Void

    @State private var route: AppRoute?

    var body: some View {
        ZStack {
            MultiProfilesView(
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
