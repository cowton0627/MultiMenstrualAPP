//
//  PeriodRange.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI

/// 多人經期的「區間」資料（把 Core Data 轉成這種結構就能畫）
struct PeriodRange: Identifiable, Hashable {
    let id = UUID()
    let personId: UUID
    let personName: String
    let color: Color        // 建議用品牌色或個人色
    let start: Date         // 含起
    let end: Date           // 含迄
}

/// 可選：預測視窗（例如 nextStart ±2 天）
struct PredictedWindow: Identifiable, Hashable {
    let id = UUID()
    let personId: UUID
    let color: Color
    let range: ClosedRange<Date> // 含首尾
}
