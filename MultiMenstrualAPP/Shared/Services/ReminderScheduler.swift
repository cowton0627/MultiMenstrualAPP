//
//  ReminderScheduler.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import UserNotifications

enum ReminderScheduler {
    static func requestAuth() async throws {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    static func schedulePeriodReminder(for personName: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "經期提醒"
        content.body = "\(personName) 可能即將來潮，記得關心與準備喔～"
        content.sound = .default

        var comp = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date.addDays(-1).addingTimeInterval(9*3600)) // 前一天上午九點
        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
        let req = UNNotificationRequest(identifier: "period.\(personName).\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
