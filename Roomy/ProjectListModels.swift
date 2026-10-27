//
//  ProjectListModels.swift
//  Roomy
//
//  Shared project / artifact models and synthetic scan data for S04–S06.
//

import Foundation
import RoomyCore

struct ArtifactRowModel: Identifiable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var sizeBytes: Int64
    var source: ArtifactSource = .projectWalk
    var safetyTier: ArtifactSafetyTier = .safe
    var restoreHint: String?
}

struct ProjectListRowModel: Identifiable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var activity: ProjectActivity
    var monthsAgo: Int
    var ageLabel: String
    var ecosystems: [String]
    var sizeBytes: Int64
    var artifacts: [ArtifactRowModel]
}

func formatByteCount(_ bytes: Int64) -> String {
    let gb = Double(bytes) / 1_073_741_824
    if gb >= 1 {
        return String(format: "%.1f GB", gb)
    }
    let mb = Double(bytes) / 1_048_576
    if mb >= 1 {
        return String(format: "%.0f MB", mb)
    }
    let kb = Double(bytes) / 1024
    return String(format: "%.0f KB", kb)
}

func formatSummaryGB(_ gb: Double) -> String {
    String(format: "%.1f GB", gb)
}

enum ProjectListSyntheticData {
    static func rows(for summary: ScanResultsSummary) -> [ProjectListRowModel] {
        var built: [ProjectListRowModel] = []
        var runningIndex = 0

        for seg in summary.ageSegments {
            let activity = activity(for: seg.tier)
            let count = max(0, seg.projectCount)
            guard count > 0 else { continue }
            let gbEach = seg.gigabytes / Double(count)

            for slot in 0..<count {
                let months = monthsAgo(for: activity, slot: slot, tierCount: count, global: runningIndex)
                let ecosystems = ecosystems(for: activity, slot: slot, global: runningIndex)
                let (name, path, artifacts, sizeBytes, ageLabel) = rowPayload(
                    activity: activity,
                    gbEach: gbEach,
                    months: months,
                    ecosystems: ecosystems,
                    global: runningIndex
                )
                built.append(
                    ProjectListRowModel(
                        id: stableID(global: runningIndex),
                        name: name,
                        path: path,
                        activity: activity,
                        monthsAgo: months,
                        ageLabel: ageLabel,
                        ecosystems: ecosystems,
                        sizeBytes: sizeBytes,
                        artifacts: artifacts
                    )
                )
                runningIndex += 1
            }
        }

        var rows = built.sorted { lhs, rhs in
            if lhs.monthsAgo != rhs.monthsAgo { return lhs.monthsAgo > rhs.monthsAgo }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        applyCuratedFrontMatter(to: &rows)
        return rows
    }

    private static func activity(for tier: AgeBreakdownTier) -> ProjectActivity {
        switch tier {
        case .dormant: .dormant
        case .inactive: .inactive
        case .recent: .recent
        case .active: .active
        }
    }

    private static func monthsAgo(for activity: ProjectActivity, slot: Int, tierCount: Int, global: Int) -> Int {
        let spread = max(1, tierCount)
        switch activity {
        case .dormant:
            return 24 + (slot * 37 / spread) + (global % 11)
        case .inactive:
            return 6 + (slot * 12 / spread) + (global % 5)
        case .recent:
            return 1 + (slot * 4 / spread) + (global % 2)
        case .active:
            return 0
        }
    }

    private static func ecosystems(for activity: ProjectActivity, slot: Int, global: Int) -> [String] {
        let packs: [[String]] = [
            ["npm"], ["py"], ["rust"], ["swift"], ["npm", "py"], ["npm", "rust"],
        ]
        return packs[(slot + global) % packs.count]
    }

    private static func rowPayload(
        activity: ProjectActivity,
        gbEach: Double,
        months: Int,
        ecosystems: [String],
        global: Int
    ) -> (String, String, [ArtifactRowModel], Int64, String) {
        let sizeBytes = Int64(gbEach * 1_073_741_824)
        let ageLabel = ageLabel(activity: activity, months: months)

        let name = "project-\(global + 1)"
        let path = "~/Developer/\(name)"
        let artifact = ArtifactRowModel(
            id: stableArtifactID(projectSeed: global, slot: 0),
            name: "Artifacts",
            path: "\(path)/.roomy-cache",
            sizeBytes: sizeBytes
        )
        return (name, path, [artifact], sizeBytes, ageLabel)
    }

    private static func ageLabel(activity: ProjectActivity, months: Int) -> String {
        switch activity {
        case .dormant:
            if months >= 36 { return "Dormant · \(months / 12) years ago" }
            return "Dormant · \(months) months ago"
        case .inactive:
            return months >= 12
                ? "Inactive · \(months / 12) years ago"
                : "Inactive · \(months) months ago"
        case .recent:
            return "Recent · \(max(1, months)) months ago"
        case .active:
            return "Active · 2 days ago"
        }
    }

    private static func applyCuratedFrontMatter(to rows: inout [ProjectListRowModel]) {
        guard rows.count >= 8 else { return }

        let curated: [ProjectListRowModel] = [
            curatedRow(
                seed: 0,
                name: "client-portal-v1",
                path: "~/projects/clients/portal",
                activity: .dormant,
                monthsAgo: 48,
                ageLabel: "Dormant · 4 years ago",
                ecosystems: ["npm", "py"],
                sizeBytes: Int64(2.9 * 1_073_741_824)
            ),
            curatedRow(
                seed: 1,
                name: "startup-2021",
                path: "~/projects/startup-2021",
                activity: .dormant,
                monthsAgo: 36,
                ageLabel: "Dormant · 3 years ago",
                ecosystems: ["npm"],
                sizeBytes: Int64(4.2 * 1_073_741_824),
                artifacts: [
                    ArtifactRowModel(
                        id: stableArtifactID(projectSeed: 10_001, slot: 0),
                        name: "node_modules",
                        path: "~/projects/startup-2021/node_modules",
                        sizeBytes: Int64(3.9 * 1_073_741_824)
                    ),
                    ArtifactRowModel(
                        id: stableArtifactID(projectSeed: 10_001, slot: 1),
                        name: ".next/",
                        path: "~/projects/startup-2021/.next",
                        sizeBytes: Int64(340 * 1_048_576)
                    ),
                    ArtifactRowModel(
                        id: stableArtifactID(projectSeed: 10_001, slot: 2),
                        name: ".eslintcache",
                        path: "~/projects/startup-2021/.eslintcache",
                        sizeBytes: Int64(2.1 * 1_048_576)
                    ),
                ]
            ),
            curatedRow(
                seed: 2,
                name: "ml-experiments",
                path: "~/code/ml-experiments",
                activity: .dormant,
                monthsAgo: 30,
                ageLabel: "Dormant · 2.5 years ago",
                ecosystems: ["py"],
                sizeBytes: Int64(3.8 * 1_073_741_824),
                artifacts: [
                    ArtifactRowModel(
                        id: stableArtifactID(projectSeed: 10_002, slot: 0),
                        name: "__pycache__",
                        path: "~/code/ml-experiments/__pycache__",
                        sizeBytes: Int64(890 * 1_048_576)
                    ),
                    ArtifactRowModel(
                        id: stableArtifactID(projectSeed: 10_002, slot: 1),
                        name: ".venv/",
                        path: "~/code/ml-experiments/.venv",
                        sizeBytes: Int64(2.9 * 1_073_741_824)
                    ),
                ]
            ),
            curatedRow(
                seed: 3,
                name: "learning-rust",
                path: "~/rust/learning-rust",
                activity: .dormant,
                monthsAgo: 24,
                ageLabel: "Dormant · 2 years ago",
                ecosystems: ["rust"],
                sizeBytes: Int64(4.1 * 1_073_741_824)
            ),
            curatedRow(
                seed: 4,
                name: "portfolio-2020",
                path: "~/projects/portfolio-2020",
                activity: .inactive,
                monthsAgo: 14,
                ageLabel: "Inactive · 14 months ago",
                ecosystems: ["npm"],
                sizeBytes: Int64(890 * 1_048_576)
            ),
            curatedRow(
                seed: 5,
                name: "data-analysis",
                path: "~/code/data-analysis",
                activity: .inactive,
                monthsAgo: 8,
                ageLabel: "Inactive · 8 months ago",
                ecosystems: ["py"],
                sizeBytes: Int64(2.3 * 1_073_741_824)
            ),
            curatedRow(
                seed: 6,
                name: "ios-prototype",
                path: "~/dev/ios-prototype",
                activity: .recent,
                monthsAgo: 3,
                ageLabel: "Recent · 3 months ago",
                ecosystems: ["swift"],
                sizeBytes: Int64(1.8 * 1_073_741_824)
            ),
            curatedRow(
                seed: 7,
                name: "current-project",
                path: "~/projects/current",
                activity: .active,
                monthsAgo: 0,
                ageLabel: "Active · 2 days ago",
                ecosystems: ["npm", "rust"],
                sizeBytes: Int64(340 * 1_048_576)
            ),
        ]

        for i in 0..<8 {
            rows[i] = curated[i]
        }
        rows.sort { lhs, rhs in
            if lhs.monthsAgo != rhs.monthsAgo { return lhs.monthsAgo > rhs.monthsAgo }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private static func curatedRow(
        seed: Int,
        name: String,
        path: String,
        activity: ProjectActivity,
        monthsAgo: Int,
        ageLabel: String,
        ecosystems: [String],
        sizeBytes: Int64,
        artifacts: [ArtifactRowModel]? = nil
    ) -> ProjectListRowModel {
        let arts = artifacts ?? [
            ArtifactRowModel(
                id: stableArtifactID(projectSeed: 10_000 + seed, slot: 0),
                name: "Artifacts",
                path: "\(path)/.roomy-cache",
                sizeBytes: sizeBytes
            ),
        ]
        let sum = arts.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return ProjectListRowModel(
            id: stableID(global: 900 + seed),
            name: name,
            path: path,
            activity: activity,
            monthsAgo: monthsAgo,
            ageLabel: ageLabel,
            ecosystems: ecosystems,
            sizeBytes: sum,
            artifacts: arts
        )
    }

    private static func stableID(global: Int) -> UUID {
        let u = UInt64(bitPattern: Int64(global)) & 0xFFFF_FFFF_FFFF
        return UUID(uuidString: String(format: "F0000000-0000-4000-8000-%012llx", u)) ?? UUID()
    }

    static func stableArtifactID(projectSeed: Int, slot: Int) -> UUID {
        let u = (UInt64(bitPattern: Int64(projectSeed)) & 0xFFFFFFFF) << 8 | (UInt64(slot) & 0xFF)
        return UUID(uuidString: String(format: "E0000000-0000-4000-8000-%012llx", u)) ?? UUID()
    }
}

enum RoomyArtifactIcons {
    static func systemName(forArtifactName name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("node_modules") { return "shippingbox" }
        if lower.contains(".venv") || lower == "venv" || lower.hasSuffix("venv/") { return "flask" }
        if lower.contains("target/") { return "gearshape" }
        if lower.contains("__pycache__") { return "bolt" }
        if lower.contains(".next") { return "chevron.right.2" }
        if lower.contains("deriveddata") { return "hammer" }
        if lower.contains("model") || lower.contains("ollama") || lower.contains("hugging face") { return "cpu" }
        if lower.contains("session") || lower.contains("transcript") || lower.contains("checkpoint") { return "text.bubble" }
        if lower.contains("claude") || lower.contains("cursor") || lower.contains("codex") || lower.contains("windsurf") { return "sparkles" }
        if lower.contains("conda") || lower.contains("pyenv") { return "flask" }
        if lower.contains("docker") { return "shippingbox" }
        if lower.contains("homebrew") { return "mug" }
        if lower.contains("nuget") || lower.contains("dotnet") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("cache") { return "externaldrive" }
        return "folder"
    }
}

