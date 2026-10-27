//
//  LastScanPersistence.swift
//  Roomy
//
//  Persists the last scan summary for “View last scan” and cold launch.
//

import Foundation
import RoomyCore

enum LastScanPersistence {
    private static let summaryKey = "roomy.lastScanSummary.v1"
    private static let partialKey = "roomy.lastScanPartial.v1"
    private static let aggregateKey = "roomy.lastScanAggregate.v2"
    private static let aggregateFileBookmarkKey = "roomy.lastScanAggregate.file.v2"
    private static let aggregateFileName = "lastScanAggregate.v2.data"
    private static let legacyAggregateKey = "roomy.lastScanAggregate.v1"
    private static let legacyAggregateFileBookmarkKey = "roomy.lastScanAggregate.file.v1"
    private static let legacyAggregateFileName = "lastScanAggregate.v1.data"
    private static let maxInlineAggregateBytes = 480_000

    private static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return base.appendingPathComponent("com.azbouki.Roomy", isDirectory: true)
    }

    private static var aggregateFileURL: URL {
        supportDirectory.appendingPathComponent(aggregateFileName, isDirectory: false)
    }

    static func save(summary: ScanResultsSummary, aggregate: ScanAggregate?, isPartial: Bool) {
        guard let data = try? JSONEncoder().encode(summary) else { return }
        UserDefaults.standard.set(data, forKey: summaryKey)
        UserDefaults.standard.set(isPartial, forKey: partialKey)

        if let aggregate, let aggData = try? JSONEncoder().encode(aggregate) {
            if aggData.count <= maxInlineAggregateBytes {
                UserDefaults.standard.set(aggData, forKey: aggregateKey)
                UserDefaults.standard.set(false, forKey: aggregateFileBookmarkKey)
                try? FileManager.default.removeItem(at: aggregateFileURL)
            } else {
                UserDefaults.standard.removeObject(forKey: aggregateKey)
                UserDefaults.standard.set(true, forKey: aggregateFileBookmarkKey)
                try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
                try? aggData.write(to: aggregateFileURL, options: .atomic)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: aggregateKey)
            UserDefaults.standard.set(false, forKey: aggregateFileBookmarkKey)
            try? FileManager.default.removeItem(at: aggregateFileURL)
        }
    }

    static func load() -> (summary: ScanResultsSummary, isPartial: Bool, aggregate: ScanAggregate?)? {
        guard let data = UserDefaults.standard.data(forKey: summaryKey),
              let summary = try? JSONDecoder().decode(ScanResultsSummary.self, from: data) else {
            return nil
        }
        let isPartial = UserDefaults.standard.bool(forKey: partialKey)
        let aggregate: ScanAggregate?
        let useFile = UserDefaults.standard.bool(forKey: aggregateFileBookmarkKey)
        if useFile, FileManager.default.fileExists(atPath: aggregateFileURL.path),
           let aggData = try? Data(contentsOf: aggregateFileURL) {
            aggregate = try? JSONDecoder().decode(ScanAggregate.self, from: aggData)
        } else if let aggData = UserDefaults.standard.data(forKey: aggregateKey) {
            aggregate = try? JSONDecoder().decode(ScanAggregate.self, from: aggData)
        } else {
            aggregate = loadLegacyAggregate()
        }
        return (summary, isPartial, aggregate)
    }

    private static func loadLegacyAggregate() -> ScanAggregate? {
        let legacyFileURL = supportDirectory.appendingPathComponent(legacyAggregateFileName, isDirectory: false)
        let useLegacyFile = UserDefaults.standard.bool(forKey: legacyAggregateFileBookmarkKey)
        if useLegacyFile, FileManager.default.fileExists(atPath: legacyFileURL.path),
           let aggData = try? Data(contentsOf: legacyFileURL) {
            return try? JSONDecoder().decode(ScanAggregate.self, from: aggData)
        }
        if let aggData = UserDefaults.standard.data(forKey: legacyAggregateKey) {
            return try? JSONDecoder().decode(ScanAggregate.self, from: aggData)
        }
        return nil
    }
}
