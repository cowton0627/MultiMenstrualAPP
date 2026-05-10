//
//  ExportPayload.swift
//  MultiMenstrualAPP
//

import Foundation
import CoreData
import SwiftUI

struct ImportSummary {
    let profileCount: Int
    let recordCount: Int
}

struct ExportPayload: Codable {
    let schemaVersion: Int
    let exportedAt: String
    let app: ExportAppMetadata
    let profiles: [ExportProfile]

    static func make(context: NSManagedObjectContext) throws -> ExportPayload {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Person.createdAt, ascending: true)
        ]

        let profiles = try context.fetch(request).map(ExportProfile.init(person:))

        return ExportPayload(
            schemaVersion: 1,
            exportedAt: ExportFormat.isoDateTimeFormatter.string(from: Date()),
            app: ExportAppMetadata.current,
            profiles: profiles
        )
    }

    func importInto(context: NSManagedObjectContext) throws -> ImportSummary {
        guard schemaVersion == 1 else {
            throw ImportError.unsupportedSchemaVersion(schemaVersion)
        }

        let peopleRequest: NSFetchRequest<Person> = Person.fetchRequest()
        let existingPeople = try context.fetch(peopleRequest)
        var peopleByID: [UUID: Person] = [:]
        for person in existingPeople {
            guard let id = person.id, peopleByID[id] == nil else { continue }
            peopleByID[id] = person
        }

        let recordsRequest: NSFetchRequest<PeriodRecord> = PeriodRecord.fetchRequest()
        let existingRecords = try context.fetch(recordsRequest)
        var recordsByID: [UUID: PeriodRecord] = [:]
        for record in existingRecords {
            guard let id = record.id, recordsByID[id] == nil else { continue }
            recordsByID[id] = record
        }

        var importedRecordCount = 0

        for profile in profiles {
            let profileID = try profile.uuid()
            let person = peopleByID[profileID] ?? Person(context: context)
            peopleByID[profileID] = person

            person.id = profileID
            person.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            person.colorHex = Color.tryFromHex(profile.colorHex) == nil ? "#FF6B6B" : profile.colorHex
            person.createdAt = profile.createdAtDate() ?? person.createdAt ?? Date()

            for exportRecord in profile.periodRecords {
                let recordID = try exportRecord.uuid()
                let record = recordsByID[recordID] ?? PeriodRecord(context: context)
                recordsByID[recordID] = record

                record.id = recordID
                record.person = person
                record.startDate = try exportRecord.start()
                record.endDate = try exportRecord.end()
                record.notes = exportRecord.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                importedRecordCount += 1
            }
        }

        return ImportSummary(profileCount: profiles.count,
                             recordCount: importedRecordCount)
    }
}

struct ExportAppMetadata: Codable {
    let name: String
    let platform: String
    let version: String

    static var current: ExportAppMetadata {
        ExportAppMetadata(
            name: "MultiMenstrualAPP",
            platform: "ios",
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        )
    }
}

struct ExportProfile: Codable {
    let id: String
    let name: String
    let colorHex: String
    let createdAt: String?
    let periodRecords: [ExportPeriodRecord]

    init(person: Person) {
        let records = (person.records as? Set<PeriodRecord> ?? [])
            .sorted { lhs, rhs in
                (lhs.startDate ?? .distantPast) < (rhs.startDate ?? .distantPast)
            }

        self.id = (person.id ?? UUID()).uuidString
        self.name = person.name ?? ""
        self.colorHex = person.colorHex ?? "#FF6B6B"
        self.createdAt = person.createdAt.map(ExportFormat.isoDateTimeFormatter.string(from:))
        self.periodRecords = records.map(ExportPeriodRecord.init(record:))
    }

    func uuid() throws -> UUID {
        guard let uuid = UUID(uuidString: id) else {
            throw ImportError.invalidUUID(id)
        }
        return uuid
    }

    func createdAtDate() -> Date? {
        guard let createdAt else { return nil }
        return ExportFormat.isoDateTimeFormatter.date(from: createdAt)
    }
}

struct ExportPeriodRecord: Codable {
    let id: String
    let startDate: String
    let endDate: String?
    let notes: String

    init(record: PeriodRecord) {
        self.id = (record.id ?? UUID()).uuidString
        self.startDate = ExportFormat.dateOnlyFormatter.string(from: record.startDate ?? Date())
        self.endDate = record.endDate.map(ExportFormat.dateOnlyFormatter.string(from:))
        self.notes = record.notes ?? ""
    }

    func uuid() throws -> UUID {
        guard let uuid = UUID(uuidString: id) else {
            throw ImportError.invalidUUID(id)
        }
        return uuid
    }

    func start() throws -> Date {
        guard let date = ExportFormat.dateOnlyFormatter.date(from: startDate) else {
            throw ImportError.invalidDate(startDate)
        }
        return date.stripTime()
    }

    func end() throws -> Date? {
        guard let endDate else { return nil }
        guard let date = ExportFormat.dateOnlyFormatter.date(from: endDate) else {
            throw ImportError.invalidDate(endDate)
        }
        return date.stripTime()
    }
}

enum ImportError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case invalidUUID(String)
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "不支援 schemaVersion \(version)。"
        case .invalidUUID(let value):
            return "匯入檔包含無效 UUID:\(value)"
        case .invalidDate(let value):
            return "匯入檔包含無效日期:\(value)"
        }
    }
}

enum ExportFormat {
    static let isoDateTimeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let dateOnlyFormatter: DateFormatter = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
