//
//  ProjectBrowserSession.swift
//  Roomy
//
//  Holds project list data and artifact selection across S04–S06.
//

import Foundation
import SwiftUI

final class ProjectBrowserSession: ObservableObject {
    @Published var projects: [ProjectListRowModel] = []
    @Published var selectedArtifactIDs: Set<UUID> = []
    @Published var excludedProjectIDs: Set<UUID> = []
    /// After the first delete countdown completes, skip on further deletes this session.
    @Published var deleteCountdownUnlockedForSession: Bool = false
    /// Latest scan payload; when present, S04 rows are built from disk instead of demo data.
    var scanAggregate: ScanAggregate?
    /// Mirrors S09 activity thresholds for classifying rows from real folder mtimes.
    var activityDormantYears: Int = 2
    var activityInactiveMonths: Int = 6

    var visibleProjects: [ProjectListRowModel] {
        projects.filter { !excludedProjectIDs.contains($0.id) }
    }

    /// - Parameter useSyntheticWhenNoAggregate: Pass `true` only in SwiftUI previews when no `scanAggregate` is set.
    func load(from summary: ScanResultsSummary, listEntry: ProjectListEntry, useSyntheticWhenNoAggregate: Bool = false) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if let aggregate = scanAggregate, !aggregate.artifactsByProjectRoot.isEmpty {
            projects = ProjectListFromScan.rows(
                from: aggregate,
                homeDirectory: home,
                dormantYears: activityDormantYears,
                inactiveMonths: activityInactiveMonths
            )
        } else if useSyntheticWhenNoAggregate {
            projects = ProjectListSyntheticData.rows(for: summary)
        } else {
            projects = []
        }
        excludedProjectIDs.removeAll()
        selectedArtifactIDs.removeAll()
        deleteCountdownUnlockedForSession = false
        switch listEntry {
        case .reviewAll:
            break
        case .dormantPreSelected, .deleteDormantOnly:
            for row in projects where row.activity == .dormant {
                if ProjectListFromScan.isSystemProject(row) { continue }
                for a in row.artifacts where a.safetyTier == .safe {
                    selectedArtifactIDs.insert(a.id)
                }
            }
        }
    }

    func project(id: UUID) -> ProjectListRowModel? {
        projects.first { $0.id == id }
    }

    func excludeProject(id: UUID) {
        excludedProjectIDs.insert(id)
        for a in projects.first(where: { $0.id == id })?.artifacts ?? [] {
            selectedArtifactIDs.remove(a.id)
        }
    }

    func syncSelectionFromReview(pendingArtifactIDs: Set<UUID>) {
        selectedArtifactIDs = pendingArtifactIDs
    }
}
