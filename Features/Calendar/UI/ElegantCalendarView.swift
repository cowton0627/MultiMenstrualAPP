//
//  ElegantCalendarView.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI

struct ElegantCalendarView: View {
    @Binding var visibleMonth: Date
    var periodRanges: [PeriodRange]         // 多人經期區間
    var predictedWindows: [PredictedWindow] // 多人預測視窗
    var theme = CalendarTheme()
    var firstWeekday: Int = 1               // 1=週日, 2=週一
    var onDayTap: ((Date) -> Void)? = nil

    @State private var pageMonth: Date = Date() // 用於 page 切換
    @Namespace private var anim

    // 只保留「一個」 calendar，並在 init 設 firstWeekday
    private var calendar: Calendar

//    @State private var calendar: Calendar

    init(visibleMonth: Binding<Date>,
         periodRanges: [PeriodRange],
         predictedWindows: [PredictedWindow],
         theme: CalendarTheme = CalendarTheme(),
         firstWeekday: Int = 2,
         onDayTap: ((Date) -> Void)? = nil) {

        self._visibleMonth = visibleMonth
        self.periodRanges = periodRanges
        self.predictedWindows = predictedWindows
        self.theme = theme
        self.firstWeekday = firstWeekday
        self.onDayTap = onDayTap

        // 這裡一定要呼叫方法版本：startOfMonth()
        _pageMonth = State(initialValue: visibleMonth.wrappedValue.startOfMonth())

        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = firstWeekday
        self.calendar = cal
    }
    
    private var header: some View {
        HStack {
            Button {
                impact(.rigid)
                withAnimation(
                    .spring(response: 0.35, dampingFraction: 0.85)
                ) {
                    pageMonth = calendar.date(byAdding: .month,
                                              value: -1,
                                              to: pageMonth)!.startOfMonth()
                }
            } label: { Image(systemName: "chevron.left").font(.title3) }

            Spacer()

            Text(monthTitle(for: visibleMonth))
                .font(theme.fontMonth)
                .foregroundColor(theme.monthTitleColor)
                .matchedGeometryEffect(id: "monthTitle", in: anim)

            Spacer()

            Button {
                impact(.rigid)
                withAnimation(
                    .spring(response: 0.35, dampingFraction: 0.85)
                ) {
                    pageMonth = calendar.date(byAdding: .month,
                                              value: 1,
                                              to: pageMonth)!.startOfMonth()
                }
            } label: { Image(systemName: "chevron.right").font(.title3) }
        }
        .padding(.horizontal, theme.contentPadding)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            weekdaysRow
            Divider().background(theme.gridSeparator)

            TabView(selection: $pageMonth) {
                ForEach(monthStride(centeredAt: visibleMonth,
                                    count: 9),
                        id: \.self) { month in
                    monthGrid(month)
                        .tag(month)
                        .padding(.horizontal, theme.contentPadding)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: pageMonth) { newValue in
                impact(.light)
                withAnimation(
                    .spring(response: 0.32, dampingFraction: 0.88)
                ) {
                    visibleMonth = newValue.startOfMonth()
                }
            }
            .frame(maxHeight: .infinity)
            .background(theme.background)
        }
        .background(theme.background.ignoresSafeArea())
    }


    @ViewBuilder
    private func monthGrid(_ month: Date) -> some View {
        let days = monthDays(month)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(),
                                                     spacing: 6),
                                 count: 7),
                  spacing: 6) {
            ForEach(days, id: \.self) { day in
                DayCell(
                    date: day,
                    month: month,
                    today: Date().stripTime(calendar),
                    theme: theme,
                    inPeriodOverlays: periodOverlays(for: day),
                    predictedOverlay: predictedOverlay(for: day)
                )
                .contentShape(Rectangle())
                .onTapGesture { onDayTap?(day) }
            }
        }
        .padding(.vertical, 10)
    }
    
//    private var weekdaysRow: some View {
//        let symbols = weekdaySymbols(startingAt: firstWeekday)
//        return HStack {
//            ForEach(symbols, id: \.self) { s in
//                Text(s)
//                    .font(theme.fontWeekday)
//                    .foregroundColor(theme.weekdayColor)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 4)
//            }
//        }
//        .padding(.horizontal, theme.contentPadding)
//    }
    
    private var weekdaysRow: some View {
        let symbols = weekdaySymbols(startingAt: firstWeekday)
        return HStack {
            ForEach(Array(symbols.enumerated()), id: \.element) { offset, s in
                let weekdayIndex = (firstWeekday + offset - 1) % 7 + 1
                Text(s)
                    .font(theme.fontWeekday)
                    .foregroundColor((weekdayIndex == 1 || weekdayIndex == 7) ? .red : theme.weekdayColor) // 1=Sunday, 7=Saturday
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, theme.contentPadding)
    }


    // MARK: - Overlays（多人色帶 + 預測虛線）
    private func periodOverlays(for day: Date) -> [Color] {
        // 回傳所有覆蓋到這一天的人的顏色（上限 3 個小圓點）
        var hits: [Color] = []
        for r in periodRanges {
            if day.isWithin(r.start, r.end, calendar: calendar) {
                hits.append(r.color)
            }
        }
        return hits
    }

    private func predictedOverlay(for day: Date) -> Color? {
        for p in predictedWindows {
            if day.isWithin(p.range.lowerBound, p.range.upperBound, calendar: calendar) {
                return p.color
            }
        }
        return nil
    }

    // MARK: - Utils
    private func monthDays(_ month: Date) -> [Date] {
        let start = month.startOfMonth(using: calendar)
        let end = month.endOfMonth(using: calendar)
        let firstWeekdayOfMonth = calendar.component(.weekday, from: start)
        let leading = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7

        var grid: [Date] = []
        // 前導空格用前一月遞補
        if leading > 0 {
            for i in stride(from: leading, to: 0, by: -1) {
                grid.append(calendar.date(byAdding: .day, value: -i, to: start)!)
            }
        }
        var d = start
        while d <= end {
            grid.append(d)
            d = calendar.date(byAdding: .day, value: 1, to: d)!
        }
        while grid.count % 7 != 0 {
            grid.append(calendar.date(byAdding: .day, value: 1, to: grid.last!)!)
        }
        return grid
    }

    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy 年 M 月" // 用 yyyy
        return f.string(from: date)
    }

    private func monthStride(centeredAt center: Date, count: Int) -> [Date] {
        let half = count / 2
        return (-half...half).map {
            calendar.date(byAdding: .month, 
                          value: $0,
                          to: center.startOfMonth(using: calendar))!
        }
    }

    private func weekdaySymbols(startingAt first: Int) -> [String] {
        var syms = ["日","一","二","三","四","五","六"]
        if first == 2 { syms = ["一","二","三","四","五","六","日"] }  // 週一為首
        return syms
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare(); g.impactOccurred()
    }
    

    private struct DayCell: View {
        let date: Date
        let month: Date
        let today: Date
        let theme: CalendarTheme
        let inPeriodOverlays: [Color]    // 這天有哪些人的經期覆蓋
        let predictedOverlay: Color?     // 這天是否落在預測窗

        var body: some View {
            let inCurrentMonth = date.isSameMonth(as: month)
            let isToday = date == today

            ZStack {
                // 預測期虛線框
                if let predicted = predictedOverlay {
                    RoundedRectangle(cornerRadius: theme.selectionCorner)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4,4]))
                        .foregroundColor(predicted.opacity(0.8))
                }

                // 經期色帶（多人：用多層半透明）
                if !inPeriodOverlays.isEmpty {
                    RoundedRectangle(cornerRadius: theme.selectionCorner)
                        .fill(
                            LinearGradient(
                                colors: blendedColors(inPeriodOverlays),
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ).opacity(0.28)
                        )
                }

                VStack(spacing: 4) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(theme.fontDay)
                        .foregroundColor(inCurrentMonth ? theme.dayText : theme.outMonthText)
                        .padding(.top, 6)

                    // 多人小點點（最多 3 個）
                    HStack(spacing: 3) {
                        ForEach(inPeriodOverlays.prefix(3), id: \.self) { c in
                            Circle().fill(c).frame(width: 5, height: 5)
                        }
                    }
                    .padding(.bottom, 6)
                }

                // 今日細圈
                if isToday {
                    RoundedRectangle(cornerRadius: theme.selectionCorner)
                        .stroke(theme.todayRing, lineWidth: 1.5)
                }
            }
            .frame(minHeight: theme.dayMinHeight)
            .background(Color.clear)
            .overlay(
                Rectangle().frame(height: 1).foregroundColor(theme.gridSeparator),
                alignment: .bottom
            )
        }

        private func blendedColors(_ cs: [Color]) -> [Color] {
            if cs.count == 1 { return cs }
            if cs.count == 2 { return [cs[0], cs[1]] }
            return [cs[0], cs[1], cs[2]]
        }
    }


}
    
