//
//  InsightsHomeView.swift
//  MultiMenstrualAPP
//

import SwiftUI
import CoreData

struct InsightsHomeView: View {
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
        .cardSurface()
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
        .cardSurface()
    }
}
