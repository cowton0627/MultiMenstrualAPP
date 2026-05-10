//
//  EntityIDs.swift
//  MultiMenstrualAPP
//
//  Type-safe wrappers around NSManagedObjectID so view / view-model
//  code never touches Core Data identifiers directly.
//
//  `raw` is module-internal because the persistence layer (which
//  spans two files) needs to unwrap it; treat it as private to
//  Shared/Persistence/ in spirit and don't reach for it from view code.
//

import CoreData

struct PersonID: Hashable {
    let raw: NSManagedObjectID

    init(_ raw: NSManagedObjectID) {
        self.raw = raw
    }
}

struct PeriodRecordID: Hashable {
    let raw: NSManagedObjectID

    init(_ raw: NSManagedObjectID) {
        self.raw = raw
    }
}
