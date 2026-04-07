//
//  Date+Utils.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/9/1.
//

import Foundation

extension Date {
//    var startOfMonth: Date { startOfMonth(using: Calendar.current) }
    
    func startOfMonth() -> Date {   // 無參數版
        startOfMonth(using: Calendar.current)
    }
    
    func startOfMonth(using cal: Calendar) -> Date {   // 有參數版
        let comps = cal.dateComponents([.year, .month], from: self)
        return cal.date(from: comps)!
    }

    func endOfMonth(using cal: Calendar) -> Date {
        let start = startOfMonth(using: cal)
        let comps = DateComponents(month: 1, day: -1)
        return cal.date(byAdding: comps, to: start)!
    }
    
    func stripTime() -> Date {  // 無參數版
        Calendar.current.startOfDay(for: self)
    }

    func stripTime(_ cal: Calendar) -> Date {   // 有參數版
        cal.startOfDay(for: self)
    }

    func isSameMonth(as other: Date, calendar cal: Calendar = .current) -> Bool {
        let a = cal.dateComponents([.year, .month], from: self)
        let b = cal.dateComponents([.year, .month], from: other)
        return a.year == b.year && a.month == b.month
    }

    func isWithin(_ start: Date,
                  _ end: Date,
                  calendar cal: Calendar = .current) -> Bool {
        let d = stripTime(cal)
        return d >= start.stripTime(cal) && d <= end.stripTime(cal)
    }
    
    func addDays(_ n: Int) -> Date { Calendar.current.date(byAdding: .day,
                                                           value: n,
                                                           to: self)! }
    
//    func addMonths(_ n: Int) -> Date { Calendar.current.date(byAdding: .month,
//                                                             value: n,
//                                                             to: self)! }
    
}
