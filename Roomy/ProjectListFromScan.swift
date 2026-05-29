//
//  ProjectListFromScan.swift
//  Roomy
//
//  Builds S04 project rows from a real ScanAggregate (paths, artifacts, sizes).
//

import CryptoKit
import Foundation

/// Shared folder-mtime → activity rules for S03 and S04 (matches S09 thresholds).
enum ScanActivityClassification {
    static func modificationMonthsAgo(projectPath: String) -> Int {
        if RoomySystemGroupRoot.isSystemRoot(projectPath) {
            return 12
        }
        let url = URL(fileURLWithPath: projectPath)
        guard let vals = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
              let date = vals.contentModificationDate else {
            return 36
        }
        return monthsBetween(date, and: Date())
    }

    static func modificationMonthsAgo(date: Date?) -> Int {
        guard let date else { return 12 }
        return monthsBetween(date, and: Date())
    }

    static func activity(
        monthsAgo: Int,
        dormantMonths: Int,
        inactiveMonths: Int
    ) -> ProjectActivity {
        if monthsAgo >= dormantMonths { return .dormant }
        if monthsAgo >= inactiveMonths { return .inactive }
        if monthsAgo >= 1 { return .recent }
        return .active
    }

    static func ageTier(
        monthsAgo: Int,
        dormantMonths: Int,
        inactiveMonths: Int
    ) -> AgeBreakdownTier {
        switch activity(monthsAgo: monthsAgo, dormantMonths: dormantMonths, inactiveMonths: inactiveMonths) {
        case .dormant: return .dormant
        case .inactive: return .inactive
        case .recent: return .recent
        case .active: return .active
        }
    }

    private static func monthsBetween(_ from: Date, and to: Date) -> Int {
        let comps = Calendar.current.dateComponents([.month], from: from, to: to)
        return max(0, comps.month ?? 0)
    }
}

enum RoomyDeterministicUUID {
    /// Stable UUID from a filesystem path or other key (for selection + navigation).
    static func uuid(for string: String) -> UUID {
        let digest = SHA256.hash(data: Data(string.utf8))
        let bytes = Array(digest.prefix(16))
        return UUID(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
    }
}

enum ProjectListFromScan {
    private static let systemRootOrder: [String] = [
        RoomySystemGroupRoot.xcode,
        RoomySystemGroupRoot.caches,
        RoomySystemGroupRoot.globalModules,
        RoomySystemGroupRoot.python,
        RoomySystemGroupRoot.homebrew,
        RoomySystemGroupRoot.docker,
    ]

    static func rows(
        from aggregate: ScanAggregate,
        homeDirectory: URL,
        dormantYears: Int,
        inactiveMonths: Int
    ) -> [ProjectListRowModel] {
        guard !aggregate.artifactsByProjectRoot.isEmpty else { return [] }

        let dormantMonths = max(1, dormantYears) * 12
        let inactiveM = max(1, inactiveMonths)

        var systemRows: [ProjectListRowModel] = []
        var projectRows: [ProjectListRowModel] = []

        let sortedRoots = aggregate.artifactsByProjectRoot.keys.sorted()

        for projectPath in sortedRoots {
            guard let findings = aggregate.artifactsByProjectRoot[projectPath], !findings.isEmpty else { continue }

            let row = buildRow(
                projectPath: projectPath,
                findings: findings,
                homeDirectory: homeDirectory,
                dormantMonths: dormantMonths,
                inactiveM: inactiveM
            )

            if RoomySystemGroupRoot.isSystemRoot(projectPath) {
                systemRows.append(row)
            } else {
                projectRows.append(row)
            }
        }

        systemRows.sort { lhs, rhs in
            let li = systemRootOrder.firstIndex(of: lhs.path) ?? 999
            let ri = systemRootOrder.firstIndex(of: rhs.path) ?? 999
            if li != ri { return li < ri }
            return lhs.sizeBytes > rhs.sizeBytes
        }

        projectRows.sort {
            if $0.monthsAgo != $1.monthsAgo { return $0.monthsAgo > $1.monthsAgo }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        return systemRows + projectRows
    }

    static func displayPath(for path: String, homeDirectory: URL) -> String {
        if RoomySystemGroupRoot.isSystemRoot(path) {
            return RoomySystemGroupRoot.displayName(for: path)
        }
        return FilesystemArtifactScanner.shortenedDisplayPath(filePath: path, homeDirectory: homeDirectory)
    }

    static func displayArtifactPath(_ path: String, homeDirectory: URL) -> String {
        if path.hasPrefix("docker:") || path.hasPrefix("conda:") || path.hasPrefix("pip:") {
            return path
        }
        return FilesystemArtifactScanner.shortenedDisplayPath(filePath: path, homeDirectory: homeDirectory)
    }

    private static func buildRow(
        projectPath: String,
        findings: [ScanArtifactFinding],
        homeDirectory: URL,
        dormantMonths: Int,
        inactiveM: Int
    ) -> ProjectListRowModel {
        let sortedFindings = findings.sorted { $0.sizeBytes > $1.sizeBytes }

        let latestActivity = sortedFindings.compactMap(\.lastActivityDate).max()
        let monthsAgo: Int
        if RoomySystemGroupRoot.isSystemRoot(projectPath) {
            monthsAgo = ScanActivityClassification.modificationMonthsAgo(date: latestActivity)
        } else {
            monthsAgo = ScanActivityClassification.modificationMonthsAgo(projectPath: projectPath)
        }

        let activity = ScanActivityClassification.activity(
            monthsAgo: monthsAgo,
            dormantMonths: dormantMonths,
            inactiveMonths: inactiveM
        )
        let ageLabel = formatAgeLabel(activity: activity, monthsAgo: monthsAgo)
        var ecoTags = Array(Set(findings.map(\.ecosystemTag))).sorted()
        if ecoTags.isEmpty { ecoTags = ["general"] }

        let displayPath = displayPath(for: projectPath, homeDirectory: homeDirectory)
        let name = RoomySystemGroupRoot.isSystemRoot(projectPath)
            ? RoomySystemGroupRoot.displayName(for: projectPath)
            : URL(fileURLWithPath: projectPath).lastPathComponent
        let totalBytes = findings.reduce(Int64(0)) { $0 + $1.sizeBytes }

        let artifacts: [ArtifactRowModel] = sortedFindings.map { f in
            ArtifactRowModel(
                id: RoomyDeterministicUUID.uuid(for: f.path),
                name: f.label.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
                path: f.path,
                sizeBytes: f.sizeBytes,
                source: f.source,
                safetyTier: f.safetyTier,
                restoreHint: f.restoreHint
            )
        }

        return ProjectListRowModel(
            id: RoomyDeterministicUUID.uuid(for: projectPath),
            name: name,
            path: displayPath,
            activity: activity,
            monthsAgo: monthsAgo,
            ageLabel: ageLabel,
            ecosystems: ecoTags,
            sizeBytes: totalBytes,
            artifacts: artifacts
        )
    }

    static func isSystemProject(_ project: ProjectListRowModel) -> Bool {
        RoomySystemGroupRoot.allKeys.contains { key in
            project.id == RoomyDeterministicUUID.uuid(for: key)
        }
    }

    private static func formatAgeLabel(activity: ProjectActivity, monthsAgo: Int) -> String {
        switch activity {
        case .dormant:
            if monthsAgo >= 36 { return "Dormant · \(monthsAgo / 12) years ago" }
            return "Dormant · \(monthsAgo) months ago"
        case .inactive:
            return monthsAgo >= 12
                ? "Inactive · \(monthsAgo / 12) years ago"
                : "Inactive · \(monthsAgo) months ago"
        case .recent:
            return "Recent · \(max(1, monthsAgo)) months ago"
        case .active:
            return "Active · recently modified"
        }
    }
}
