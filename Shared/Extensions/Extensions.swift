//
//  Extensions.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import SwiftUI

extension Person {
    var sortedRecords: [PeriodRecord] {
        (records as? Set<PeriodRecord> ?? [])
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
    }
}

enum BrandFont {
    static let name = "jf-openhuninn-2.1"   // 你印到的 PostScript name
    static func font(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(name, size: size, relativeTo: style)
    }
}


/// 印出現有字體
//for family in UIFont.familyNames.sorted() {
//let names = UIFont.fontNames(forFamilyName: family)
//print("Family: \(family) Font names: \(names)")
//}
