//
//  CalendarTheme.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI

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
