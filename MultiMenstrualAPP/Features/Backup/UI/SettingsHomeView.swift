//
//  SettingsHomeView.swift
//  MultiMenstrualAPP
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SettingsHomeView: View {
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

private struct DataTransferError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
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
