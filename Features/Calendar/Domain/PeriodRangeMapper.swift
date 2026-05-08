//
//  PeriodRangeMapper.swift
//  MultiMenstrualAPP
//
//  Created by Codex on 2026/4/7.
//

import SwiftUI

struct PeriodRangeMapper {
    var ongoingFallbackDays = 5

    func makeRanges(from records: [PeriodRecord], person: Person) -> [PeriodRange] {
        makeRanges(from: records, person: PersonProfile(person: person))
    }

    func makeRanges(from records: [PeriodRecord], person: PersonProfile) -> [PeriodRange] {
        let color = Color(hex: person.colorHex)

        return records.compactMap { record in
            guard let start = record.startDate?.stripTime() else { return nil }
            let end = (record.endDate ?? start.addDays(ongoingFallbackDays)).stripTime()
            guard end >= start else { return nil }

            return PeriodRange(personId: person.personID,
                               personName: person.displayName,
                               color: color,
                               start: start,
                               end: end)
        }
    }

    func makePredictedWindows(from records: [PeriodRecord], person: Person) -> [PredictedWindow] {
        makePredictedWindows(from: records, person: PersonProfile(person: person))
    }

    func makePredictedWindows(from records: [PeriodRecord], person: PersonProfile) -> [PredictedWindow] {
        let predictor = CyclePredictor(records: records)
        guard let next = predictor.predictedNextStart else { return [] }

        return [
            PredictedWindow(
                personId: person.personID,
                color: Color(hex: person.colorHex),
                range: next.addDays(-2).stripTime()...next.addDays(2).stripTime()
            )
        ]
    }
}
