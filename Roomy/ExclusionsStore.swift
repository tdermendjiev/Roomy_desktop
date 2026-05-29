//
//  ExclusionsStore.swift
//  Roomy
//
//  S10 — excluded paths / patterns (roomy_11_s09_s10).
//

import Foundation
import SwiftUI

enum ExclusionRowKind: String, Codable, CaseIterable, Equatable {
    case project
    case path
    case pattern

    var title: String {
        switch self {
        case .project: "Project"
        case .path: "Path"
        case .pattern: "Pattern"
        }
    }
}

struct ExclusionEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var pathDisplay: String
    var kind: ExclusionRowKind
    var addedAt: Date

    init(id: UUID = UUID(), pathDisplay: String, kind: ExclusionRowKind, addedAt: Date = Date()) {
        self.id = id
        self.pathDisplay = pathDisplay
        self.kind = kind
        self.addedAt = addedAt
    }
}

/// Parent screen when leaving Exclusions (S10).
enum ExclusionsDismissParent: Equatable {
    case settings(SettingsDismissContext)
    case projectDetail(UUID)
}

final class ExclusionsStore: ObservableObject {
    @Published var entries: [ExclusionEntry] {
        didSet {
            save()
        }
    }

    private let defaultsKey = "roomy.exclusions.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([ExclusionEntry].self, from: data) {
            entries = decoded
        } else {
            entries = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    var count: Int { entries.count }

    func addPath(_ path: String, kind: ExclusionRowKind = .path) {
        let entry = ExclusionEntry(pathDisplay: path, kind: kind)
        entries.append(entry)
    }

    func addPattern(_ pattern: String) {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }
        let entry = ExclusionEntry(pathDisplay: trimmed, kind: .pattern)
        entries.insert(entry, at: 0)
    }

    /// Adds a project folder to exclusions using a filesystem path (tilde form when under the user home).
    func addExcludedProject(path: String) {
        let display = Self.displayPathWithTilde(path)
        entries.insert(ExclusionEntry(pathDisplay: display, kind: .project), at: 0)
    }

    private static func displayPathWithTilde(_ path: String) -> String {
        let expanded = (path as NSString).expandingTildeInPath
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if expanded == home { return "~" }
        if expanded.hasPrefix(home + "/") {
            return "~/" + String(expanded.dropFirst(home.count + 1))
        }
        return expanded
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
    }

    /// Demo / design parity — optional seed (not called automatically).
    static func designSampleEntries() -> [ExclusionEntry] {
        let cal = Calendar(identifier: .gregorian)
        func d(_ month: Int, _ day: Int) -> Date {
            var c = DateComponents()
            c.year = 2026
            c.month = month
            c.day = day
            return cal.date(from: c) ?? Date()
        }
        return [
            ExclusionEntry(id: UUID(), pathDisplay: "~/work/company-project", kind: .project, addedAt: d(1, 8)),
            ExclusionEntry(id: UUID(), pathDisplay: "~/dev/client-contracts", kind: .path, addedAt: d(1, 8)),
            ExclusionEntry(id: UUID(), pathDisplay: "~/projects/ios-app", kind: .project, addedAt: d(2, 22)),
            ExclusionEntry(id: UUID(), pathDisplay: "*/vendor/*", kind: .pattern, addedAt: d(2, 22)),
            ExclusionEntry(id: UUID(), pathDisplay: "~/code/personal-site", kind: .project, addedAt: d(3, 1)),
            ExclusionEntry(id: UUID(), pathDisplay: "~/Desktop/archive", kind: .path, addedAt: d(3, 14)),
        ]
    }
}
