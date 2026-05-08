//
//  RecordHitResolver.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/4/7.
//

import Foundation

struct RecordHitResolver {
    func records(on day: Date, in records: [PeriodRecord]) -> [PeriodRecord] {
        let targetDay = day.stripTime()

        return records.filter { record in
            guard let start = record.startDate?.stripTime() else { return false }

            if let end = record.endDate?.stripTime() {
                return targetDay >= start && targetDay <= end
            } else {
                return targetDay >= start
            }
        }
    }
}
