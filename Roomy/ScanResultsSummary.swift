//
//  ScanResultsSummary.swift
//  Roomy
//
//  Summary model for S03 — populated from real scans later.
//

import SwiftUI

struct ScanResultsSummary: Equatable, Codable {
    var totalRecoverableGB: Double
    var projectCount: Int
    /// Shown in footer, e.g. "~/Projects" or "~/"
    var scannedPathLabel: String
    var ecosystems: [EcosystemResultCard]
    /// Ordered dormant → inactive → recent → active (left to right in bar).
    var ageSegments: [AgeBreakdownSegment]
    /// GB from system cache groups (DerivedData, Conda, Docker, etc.)
    var systemCacheGB: Double

    var isEmpty: Bool {
        totalRecoverableGB < 0.05 && projectCount == 0
    }

    var dormantRecoverableGB: Double {
        ageSegments.first { $0.tier == .dormant }?.gigabytes ?? 0
    }

    /// Canonical demo from roomy_06_s03_results_overview.
    static let canonical = ScanResultsSummary(
        totalRecoverableGB: 47.3,
        projectCount: 84,
        scannedPathLabel: "~/Projects",
        ecosystems: [
            EcosystemResultCard(name: "Node.js", iconSystemName: "cube.box", sizeGB: 31.2, projectCount: 54, isLargest: true),
            EcosystemResultCard(name: "Python", iconSystemName: "doc.text", sizeGB: 9.8, projectCount: 22, isLargest: false),
            EcosystemResultCard(name: "Rust", iconSystemName: "gearshape.2", sizeGB: 4.1, projectCount: 6, isLargest: false),
            EcosystemResultCard(name: "Swift/Xcode", iconSystemName: "swift", sizeGB: 1.8, projectCount: 4, isLargest: false),
            EcosystemResultCard(name: "General", iconSystemName: "folder", sizeGB: 0.4, projectCount: 18, isLargest: false),
        ],
        ageSegments: [
            AgeBreakdownSegment(tier: .dormant, gigabytes: 28.4, projectCount: 31),
            AgeBreakdownSegment(tier: .inactive, gigabytes: 14.1, projectCount: 28),
            AgeBreakdownSegment(tier: .recent, gigabytes: 4.2, projectCount: 15),
            AgeBreakdownSegment(tier: .active, gigabytes: 0.6, projectCount: 10),
        ],
        systemCacheGB: 0
    )

    static let modest = ScanResultsSummary(
        totalRecoverableGB: 2.4,
        projectCount: 8,
        scannedPathLabel: "~/Projects",
        ecosystems: [
            EcosystemResultCard(name: "Node.js", iconSystemName: "cube.box", sizeGB: 1.6, projectCount: 5, isLargest: true),
            EcosystemResultCard(name: "Python", iconSystemName: "doc.text", sizeGB: 0.8, projectCount: 3, isLargest: false),
        ],
        ageSegments: [
            AgeBreakdownSegment(tier: .dormant, gigabytes: 1.1, projectCount: 3),
            AgeBreakdownSegment(tier: .inactive, gigabytes: 0.9, projectCount: 2),
            AgeBreakdownSegment(tier: .recent, gigabytes: 0.3, projectCount: 2),
            AgeBreakdownSegment(tier: .active, gigabytes: 0.1, projectCount: 1),
        ],
        systemCacheGB: 0
    )

    static let empty = ScanResultsSummary(
        totalRecoverableGB: 0,
        projectCount: 0,
        scannedPathLabel: "~/",
        ecosystems: [],
        ageSegments: [],
        systemCacheGB: 0
    )

    /// Builds S03 breakdown from live scan totals. When no aggregate exists (e.g. cancelled scan), ecosystem/age **shapes** are scaled from `canonical` proportions while totals match the live byte count.
    static func fromLiveScan(recoverableBytes: Int64, projectCount: Int, scannedPathLabel: String) -> ScanResultsSummary {
        let totalGB = Double(recoverableBytes) / 1_073_741_824
        if totalGB < 0.05, projectCount == 0 {
            var emptyResult = ScanResultsSummary.empty
            emptyResult.scannedPathLabel = scannedPathLabel
            return emptyResult
        }

        let ref = ScanResultsSummary.canonical
        let ecoTemplates = ref.ecosystems
        let ecoSizes = ecoTemplates.map(\.sizeGB)
        let ecoSizeSum = ecoSizes.reduce(0, +)
        let ecoFractions = ecoSizeSum > 0 ? ecoSizes.map { $0 / ecoSizeSum } : ecoSizes.map { _ in 1 / Double(ecoTemplates.count) }
        let ecoProjectInts = distributeProportional(total: projectCount, weights: ecoFractions)

        var ecosystems: [EcosystemResultCard] = []
        for (idx, card) in ecoTemplates.enumerated() {
            let size = totalGB * ecoFractions[idx]
            ecosystems.append(
                EcosystemResultCard(
                    name: card.name,
                    iconSystemName: card.iconSystemName,
                    sizeGB: max(0, size),
                    projectCount: ecoProjectInts[idx],
                    isLargest: false
                )
            )
        }
        if let maxI = ecosystems.indices.max(by: { ecosystems[$0].sizeGB < ecosystems[$1].sizeGB }) {
            for i in ecosystems.indices {
                ecosystems[i] = EcosystemResultCard(
                    name: ecosystems[i].name,
                    iconSystemName: ecosystems[i].iconSystemName,
                    sizeGB: ecosystems[i].sizeGB,
                    projectCount: ecosystems[i].projectCount,
                    isLargest: i == maxI
                )
            }
        }

        let ageTemplates = ref.ageSegments
        let ageGBTemplate = ageTemplates.map(\.gigabytes)
        let ageGBSum = ageGBTemplate.reduce(0, +)
        let ageGBFractions = ageGBSum > 0 ? ageGBTemplate.map { $0 / ageGBSum } : ageGBTemplate.map { _ in 0.25 }
        let ageProjTemplate = ageTemplates.map { Double($0.projectCount) }
        let ageProjSum = ageProjTemplate.reduce(0, +)
        let ageProjFractions = ageProjSum > 0 ? ageProjTemplate.map { $0 / ageProjSum } : ageProjTemplate.map { _ in 0.25 }
        let ageProjectInts = distributeProportional(total: projectCount, weights: ageProjFractions)

        var ageSegments: [AgeBreakdownSegment] = []
        for (idx, seg) in ageTemplates.enumerated() {
            let gb = totalGB * ageGBFractions[idx]
            ageSegments.append(
                AgeBreakdownSegment(tier: seg.tier, gigabytes: max(0, gb), projectCount: ageProjectInts[idx])
            )
        }

        return ScanResultsSummary(
            totalRecoverableGB: max(0, totalGB),
            projectCount: projectCount,
            scannedPathLabel: scannedPathLabel,
            ecosystems: ecosystems,
            ageSegments: ageSegments,
            systemCacheGB: 0
        )
    }

    /// S03 summary from a real scan aggregate (ecosystem + age totals from disk; age uses folder mtimes vs S09 thresholds).
    static func from(
        aggregate: ScanAggregate,
        scannedPathLabel: String,
        dormantYears: Int = 2,
        inactiveMonths: Int = 6
    ) -> ScanResultsSummary {
        let totalGB = Double(aggregate.totalBytes) / 1_073_741_824
        let projectCount = aggregate.projectRootPaths.count
        if totalGB < 0.05, projectCount == 0 {
            var emptyResult = ScanResultsSummary.empty
            emptyResult.scannedPathLabel = scannedPathLabel
            return emptyResult
        }

        var ecosystems = buildEcosystemCardsFromAggregate(aggregate, totalGB: totalGB)
        if ecosystems.isEmpty, aggregate.totalBytes > 0 {
            let pc = max(1, aggregate.projectRootPaths.count)
            ecosystems = [
                EcosystemResultCard(
                    name: "General",
                    iconSystemName: "folder",
                    sizeGB: totalGB,
                    projectCount: pc,
                    isLargest: true
                ),
            ]
        } else if let maxI = ecosystems.indices.max(by: { ecosystems[$0].sizeGB < ecosystems[$1].sizeGB }) {
            ecosystems = ecosystems.enumerated().map { i, card in
                EcosystemResultCard(
                    name: card.name,
                    iconSystemName: card.iconSystemName,
                    sizeGB: card.sizeGB,
                    projectCount: card.projectCount,
                    isLargest: i == maxI
                )
            }
        }

        let ageSegments: [AgeBreakdownSegment]
        if aggregate.artifactsByProjectRoot.isEmpty {
            ageSegments = scaledAgeSegmentsFromTemplate(totalGB: totalGB, projectCount: projectCount)
        } else {
            ageSegments = ageSegmentsFromAggregateProjectRoots(
                aggregate,
                dormantYears: dormantYears,
                inactiveMonths: inactiveMonths
            )
        }

        return ScanResultsSummary(
            totalRecoverableGB: max(0, totalGB),
            projectCount: projectCount,
            scannedPathLabel: scannedPathLabel,
            ecosystems: ecosystems,
            ageSegments: ageSegments,
            systemCacheGB: systemCacheGB(from: aggregate)
        )
    }

    private static func systemCacheGB(from aggregate: ScanAggregate) -> Double {
        let bytes = aggregate.artifactsByProjectRoot
            .filter { RoomySystemGroupRoot.isSystemRoot($0.key) }
            .values
            .flatMap { $0 }
            .reduce(Int64(0)) { $0 + $1.sizeBytes }
        return Double(bytes) / 1_073_741_824
    }

    enum CodingKeys: String, CodingKey {
        case totalRecoverableGB, projectCount, scannedPathLabel, ecosystems, ageSegments, systemCacheGB
    }

    init(
        totalRecoverableGB: Double,
        projectCount: Int,
        scannedPathLabel: String,
        ecosystems: [EcosystemResultCard],
        ageSegments: [AgeBreakdownSegment],
        systemCacheGB: Double
    ) {
        self.totalRecoverableGB = totalRecoverableGB
        self.projectCount = projectCount
        self.scannedPathLabel = scannedPathLabel
        self.ecosystems = ecosystems
        self.ageSegments = ageSegments
        self.systemCacheGB = systemCacheGB
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalRecoverableGB = try c.decode(Double.self, forKey: .totalRecoverableGB)
        projectCount = try c.decode(Int.self, forKey: .projectCount)
        scannedPathLabel = try c.decode(String.self, forKey: .scannedPathLabel)
        ecosystems = try c.decode([EcosystemResultCard].self, forKey: .ecosystems)
        ageSegments = try c.decode([AgeBreakdownSegment].self, forKey: .ageSegments)
        systemCacheGB = try c.decodeIfPresent(Double.self, forKey: .systemCacheGB) ?? 0
    }

    /// Sums recoverable bytes and project counts per age tier using the same rules as `ProjectListFromScan`.
    private static func ageSegmentsFromAggregateProjectRoots(
        _ aggregate: ScanAggregate,
        dormantYears: Int,
        inactiveMonths: Int
    ) -> [AgeBreakdownSegment] {
        let dormantM = max(1, dormantYears) * 12
        let inactiveM = max(1, inactiveMonths)

        var bytesByTier: [AgeBreakdownTier: Int64] = [
            .dormant: 0, .inactive: 0, .recent: 0, .active: 0,
        ]
        var countByTier: [AgeBreakdownTier: Int] = [
            .dormant: 0, .inactive: 0, .recent: 0, .active: 0,
        ]

        for (projectPath, findings) in aggregate.artifactsByProjectRoot {
            guard !findings.isEmpty else { continue }
            if RoomySystemGroupRoot.isSystemRoot(projectPath) { continue }
            let projectBytes = findings.reduce(Int64(0)) { $0 + $1.sizeBytes }
            let months = ScanActivityClassification.modificationMonthsAgo(projectPath: projectPath)
            let tier = ScanActivityClassification.ageTier(
                monthsAgo: months,
                dormantMonths: dormantM,
                inactiveMonths: inactiveM
            )
            bytesByTier[tier, default: 0] += projectBytes
            countByTier[tier, default: 0] += 1
        }

        let order: [AgeBreakdownTier] = [.dormant, .inactive, .recent, .active]
        return order.map { tier -> AgeBreakdownSegment in
            let gb = Double(bytesByTier[tier] ?? 0) / 1_073_741_824
            return AgeBreakdownSegment(tier: tier, gigabytes: gb, projectCount: countByTier[tier] ?? 0)
        }
    }

    private static func buildEcosystemCardsFromAggregate(_ aggregate: ScanAggregate, totalGB: Double) -> [EcosystemResultCard] {
        let order = ["ai", "npm", "py", "rust", "swift", "go", "java", "ruby", "dotnet", "general"]
        var cards: [EcosystemResultCard] = []
        for tag in order {
            guard let bytes = aggregate.bytesByEcosystem[tag], bytes > 0 else { continue }
            let roots = aggregate.ecosystemProjectRoots[tag] ?? []
            let meta = ecosystemCardMeta(forTag: tag)
            cards.append(
                EcosystemResultCard(
                    name: meta.name,
                    iconSystemName: meta.icon,
                    sizeGB: Double(bytes) / 1_073_741_824,
                    projectCount: roots.count,
                    isLargest: false
                )
            )
        }
        return cards
    }

    private static func ecosystemCardMeta(forTag tag: String) -> (name: String, icon: String) {
        switch tag {
        case "npm": ("Node.js", "cube.box")
        case "py": ("Python", "doc.text")
        case "rust": ("Rust", "gearshape.2")
        case "swift": ("Swift/Xcode", "swift")
        case "go": ("Go", "hare")
        case "java": ("Java/Kotlin", "cup.and.saucer")
        case "dotnet": (".NET / NuGet", "chevron.left.forwardslash.chevron.right")
        case "ruby": ("Ruby", "diamond")
        case "ai": ("AI tools", "sparkles")
        default: ("General", "folder")
        }
    }

    private static func scaledAgeSegmentsFromTemplate(totalGB: Double, projectCount: Int) -> [AgeBreakdownSegment] {
        let ref = ScanResultsSummary.canonical.ageSegments
        let ageGBSum = ref.reduce(0.0) { $0 + $1.gigabytes }
        let ageGBFractions = ageGBSum > 0 ? ref.map { $0.gigabytes / ageGBSum } : ref.map { _ in 0.25 }
        let ageProjTemplate = ref.map { Double($0.projectCount) }
        let ageProjSum = ageProjTemplate.reduce(0, +)
        let ageProjFractions = ageProjSum > 0 ? ageProjTemplate.map { $0 / ageProjSum } : ageProjTemplate.map { _ in 0.25 }
        let ageProjectInts = distributeProportional(total: projectCount, weights: ageProjFractions)

        return zip(ref, zip(ageGBFractions, ageProjectInts)).map { seg, pair in
            AgeBreakdownSegment(tier: seg.tier, gigabytes: max(0, totalGB * pair.0), projectCount: pair.1)
        }
    }

    /// Integer counts that sum exactly to `total` using positive `weights`.
    private static func distributeProportional(total: Int, weights: [Double]) -> [Int] {
        guard total > 0, !weights.isEmpty else { return weights.map { _ in 0 } }
        let wsum = weights.reduce(0, +)
        guard wsum > 0 else { return weights.map { _ in total / max(1, weights.count) } }
        let raw = weights.map { Double(total) * $0 / wsum }
        var ints = raw.map { Int($0.rounded(.towardZero)) }
        var remainder = total - ints.reduce(0, +)
        guard remainder != 0 else { return ints }
        let order = weights.indices.sorted {
            raw[$0] - Double(ints[$0]) > raw[$1] - Double(ints[$1])
        }
        var o = 0
        while remainder > 0, o < order.count * 2 {
            ints[order[o % order.count]] += 1
            remainder -= 1
            o += 1
        }
        return ints
    }
}

struct EcosystemResultCard: Identifiable, Equatable, Codable {
    var id: String { name }
    var name: String
    var iconSystemName: String
    var sizeGB: Double
    var projectCount: Int
    var isLargest: Bool
}

enum AgeBreakdownTier: String, CaseIterable, Identifiable, Codable {
    case dormant
    case inactive
    case recent
    case active

    var id: String { rawValue }

    var legendTitle: String {
        switch self {
        case .dormant: "Dormant · 2+ years"
        case .inactive: "Inactive · 6 months – 2 years"
        case .recent: "Recent · 1–6 months"
        case .active: "Active · under 1 month"
        }
    }

    var swatchColor: Color {
        switch self {
        case .dormant: .roomyStatusDormant
        case .inactive: .roomyStatusInactive
        case .recent: .roomyStatusRecent
        case .active: .roomyStatusActive
        }
    }
}

struct AgeBreakdownSegment: Identifiable, Equatable, Codable {
    var id: AgeBreakdownTier { tier }
    var tier: AgeBreakdownTier
    var gigabytes: Double
    var projectCount: Int
}
