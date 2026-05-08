//
//  CyclePredictor.swift
//  MultiMenstrualAPP
//
//  Created by Chun-Li Cheng on 2025/8/27.
//

import Foundation

final class CyclePredictor {
    private let records: [PeriodRecord]
    init(records: [PeriodRecord]) { self.records = records }

    var predictedNextStart: Date? {
        let starts = records.compactMap { $0.startDate?.stripTime() }.sorted()
        // 預設 28 天
        guard starts.count >= 2 else { return starts.last?.addDays(28) }
        // 取最近 3 次週期平均
        let deltas = zip(starts.dropFirst(), starts).map { $0.timeIntervalSince($1) / 86400.0 }
        let last3 = Array(deltas.suffix(3))
        let avg = last3.reduce(0, +) / Double(last3.count)
        return starts.last!.addDays(Int(avg.rounded()))
    }
    
    
}

