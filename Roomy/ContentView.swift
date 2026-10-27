//
//  ContentView.swift
//  Roomy
//
//  Created by Teodor Dermendzhiev on 17.04.26.
//

import AppKit
import RoomyCore
import SwiftUI

private enum RootPhase: Equatable {
    case welcome
    case scanning(pathLabel: String)
    case overview
    case projectList(ProjectListEntry)
    case projectDetail(projectID: UUID)
    case selectionReview(SelectionReviewScope)
    case deletionProgress(DeletionRunSnapshot)
    case deletionSummary(DeletionRunSnapshot)
    case settings(SettingsDismissContext)
    case exclusions(ExclusionsDismissParent)
}

struct ContentView: View {
    @State private var phase: RootPhase = .welcome
    @StateObject private var browserSession = ProjectBrowserSession()
    @StateObject private var settingsStore = RoomySettingsStore()
    @StateObject private var exclusionsStore = ExclusionsStore()
    @State private var markScanCompleteAfterTransition = false
    @State private var overviewShowsPartialBanner = false
    @State private var scanPathForFooter = "~/"
    @State private var scanRootURL = FileManager.default.homeDirectoryForCurrentUser
    @State private var resultsSummary: ScanResultsSummary = .empty
    @State private var lastListEntry: ProjectListEntry = .reviewAll
    @ObservedObject private var license = RoomyLicenseStore.shared
    /// Cleanup waiting on the unlock sheet (unlicensed users).
    @State private var pendingDeletion: DeletionRunSnapshot?

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
            case .welcome:
                WelcomeView(
                    settingsStore: settingsStore,
                    onStartScan: { pathLabel, rootURL in
                        overviewShowsPartialBanner = false
                        scanPathForFooter = pathLabel
                        scanRootURL = rootURL
                        phase = .scanning(pathLabel: pathLabel)
                    },
                    onViewLastScan: {
                        markScanCompleteAfterTransition = false
                        if let stored = LastScanPersistence.load() {
                            overviewShowsPartialBanner = stored.isPartial
                            scanPathForFooter = stored.summary.scannedPathLabel
                            scanRootURL = RoomyScanRootResolver.rootURL(fromDisplayLabel: stored.summary.scannedPathLabel)
                            browserSession.scanAggregate = stored.aggregate
                            Self.applyActivitySettings(from: settingsStore.settings, to: browserSession)
                            resultsSummary = Self.reconciledSummary(
                                current: stored.summary,
                                aggregate: stored.aggregate,
                                settings: settingsStore.settings
                            )
                        } else {
                            overviewShowsPartialBanner = false
                            browserSession.scanAggregate = nil
                            var summary = ScanResultsSummary.empty
                            let r = RoomyScanRootResolver.resolve(from: settingsStore.settings)
                            summary.scannedPathLabel = r.label
                            resultsSummary = summary
                            Self.applyActivitySettings(from: settingsStore.settings, to: browserSession)
                        }
                        phase = .overview
                    },
                    onOpenSettings: {
                        phase = .settings(.welcome)
                    }
                )
            case .scanning(let pathLabel):
                ScanningView(
                    rootPathLabel: pathLabel,
                    scanRootURL: scanRootURL,
                    dormantYears: settingsStore.settings.dormantThresholdYears,
                    inactiveMonths: settingsStore.settings.inactiveThresholdMonths,
                    exclusionEntries: exclusionsStore.entries,
                    enabledEcosystemTags: settingsStore.settings.enabledEcosystemKeysForScan,
                    enabledSystemScanKeys: settingsStore.settings.enabledSystemScanKeys,
                    onCompleted: { summary, aggregate in
                        overviewShowsPartialBanner = false
                        markScanCompleteAfterTransition = true
                        resultsSummary = summary
                        scanPathForFooter = summary.scannedPathLabel
                        browserSession.scanAggregate = aggregate
                        Self.applyActivitySettings(from: settingsStore.settings, to: browserSession)
                        LastScanPersistence.save(summary: summary, aggregate: aggregate, isPartial: false)
                        phase = .overview
                    },
                    onCancelled: { summary, aggregate in
                        overviewShowsPartialBanner = true
                        markScanCompleteAfterTransition = false
                        resultsSummary = summary
                        scanPathForFooter = summary.scannedPathLabel
                        browserSession.scanAggregate = aggregate
                        Self.applyActivitySettings(from: settingsStore.settings, to: browserSession)
                        LastScanPersistence.save(summary: summary, aggregate: aggregate, isPartial: true)
                        phase = .overview
                    },
                    onOpenSettings: {
                        // S09 — Settings (disabled during scan in UI)
                    }
                )
            case .overview:
                ResultsOverviewView(
                    model: resultsSummary,
                    showPartialBanner: overviewShowsPartialBanner,
                    onDeleteDormantOnly: {
                        lastListEntry = .deleteDormantOnly
                        Self.applyActivitySettings(from: settingsStore.settings, to: browserSession)
                        browserSession.load(from: resultsSummary, listEntry: .deleteDormantOnly)
                        phase = .projectList(.deleteDormantOnly)
                    },
                    onReviewAllFindings: {
                        lastListEntry = .reviewAll
                        Self.applyActivitySettings(from: settingsStore.settings, to: browserSession)
                        browserSession.load(from: resultsSummary, listEntry: .reviewAll)
                        phase = .projectList(.reviewAll)
                    },
                    onSelectDormantProjects: {
                        lastListEntry = .dormantPreSelected
                        Self.applyActivitySettings(from: settingsStore.settings, to: browserSession)
                        browserSession.load(from: resultsSummary, listEntry: .dormantPreSelected)
                        phase = .projectList(.dormantPreSelected)
                    },
                    onRescan: {
                        beginScanFromSettings()
                    },
                    onChangeScanSettings: {
                        phase = .settings(.overview)
                    },
                    onOpenSettings: {
                        phase = .settings(.overview)
                    }
                )
                .onAppear {
                    if markScanCompleteAfterTransition {
                        UserDefaults.standard.set(true, forKey: "roomy.hasCompletedScan")
                        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "roomy.lastScanEnd")
                        markScanCompleteAfterTransition = false
                    }
                }
            case .projectList(let entry):
                MainView(
                    listEntry: entry,
                    footerSummary: resultsSummary,
                    session: browserSession,
                    activityDormantYears: settingsStore.settings.dormantThresholdYears,
                    activityInactiveMonths: settingsStore.settings.inactiveThresholdMonths,
                    onRescan: {
                        beginScanFromSettings()
                    },
                    onChangeScanSettings: {
                        phase = .settings(.projectList(entry))
                    },
                    onOpenSettings: {
                        phase = .settings(.projectList(entry))
                    },
                    onBackToResults: {
                        phase = .overview
                    },
                    onOpenProjectDetail: { projectID in
                        phase = .projectDetail(projectID: projectID)
                    },
                    onReviewAndDelete: {
                        phase = .selectionReview(.allSelected)
                    }
                )
            case .projectDetail(let projectID):
                ProjectDetailView(
                    session: browserSession,
                    projectID: projectID,
                    onBack: {
                        phase = .projectList(lastListEntry)
                    },
                    onOpenSettings: {
                        phase = .settings(.projectDetail(projectID))
                    },
                    onDeleteSelected: {
                        phase = .selectionReview(.singleProject(projectID))
                    },
                    onExcludeProject: {
                        if let p = browserSession.project(id: projectID) {
                            exclusionsStore.addExcludedProject(path: p.path)
                        }
                        browserSession.excludeProject(id: projectID)
                        phase = .projectList(lastListEntry)
                    }
                )
            case .selectionReview(let scope):
                SelectionReviewView(
                    session: browserSession,
                    scope: scope,
                    volumeAnchorURL: scanRootURL,
                    defaultEmptyTrashAfterDeletion: settingsStore.settings.emptyTrashAfterDeletion,
                    deletionUsesTrash: settingsStore.settings.moveToTrash,
                    onBack: {
                        phase = .projectList(lastListEntry)
                    },
                    onOpenSettings: {
                        phase = .settings(.selectionReview(scope))
                    },
                    onCommitDelete: { artifactIDs, emptyTrash, diskUsedGB, diskTotalGB in
                        guard let snap = DeletionRunSnapshot.build(
                            session: browserSession,
                            artifactIDs: artifactIDs,
                            emptyTrashAfter: emptyTrash,
                            moveToTrash: settingsStore.settings.moveToTrash,
                            diskUsedBeforeGB: diskUsedGB,
                            diskTotalGB: diskTotalGB
                        ) else { return }
                        if license.state.canClean {
                            phase = .deletionProgress(snap)
                        } else {
                            pendingDeletion = snap
                        }
                    }
                )
            case .deletionProgress(let snapshot):
                DeletionProgressView(snapshot: snapshot) { failures in
                    let failedPaths = Set(failures.map(\.path))
                    var succeededIDs: Set<UUID> = []
                    for p in browserSession.projects {
                        for a in p.artifacts where snapshot.artifactIDs.contains(a.id) {
                            if !failedPaths.contains(a.path) {
                                succeededIDs.insert(a.id)
                            }
                        }
                    }
                    browserSession.applyDeletionCleanup(succeededArtifactIDs: succeededIDs)
                    resultsSummary = Self.reconciledSummary(
                        current: resultsSummary,
                        aggregate: browserSession.scanAggregate,
                        settings: settingsStore.settings
                    )
                    LastScanPersistence.save(
                        summary: resultsSummary,
                        aggregate: browserSession.scanAggregate,
                        isPartial: false
                    )
                    let finalSnapshot = snapshot.withDeletionFailures(failures)
                    withAnimation(.easeInOut(duration: 0.18)) {
                        phase = .deletionSummary(finalSnapshot)
                    }
                }
            case .deletionSummary(let snapshot):
                DeletionSummaryView(
                    snapshot: snapshot,
                    onScanAgain: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            beginScanFromSettings()
                        }
                    },
                    onViewTrash: {
                        let trash = FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent(".Trash", isDirectory: true)
                        NSWorkspace.shared.open(trash)
                    },
                    onDone: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            phase = .welcome
                        }
                    },
                    onOpenSettings: {
                        phase = .settings(.deletionSummary(snapshot))
                    }
                )
            case .settings(let ctx):
                SettingsView(
                    settingsStore: settingsStore,
                    exclusionsStore: exclusionsStore,
                    dismissContext: ctx,
                    onDismiss: {
                        phase = Self.phaseAfterSettingsDismiss(ctx)
                    },
                    onManageExclusions: {
                        phase = .exclusions(.settings(ctx))
                    }
                )
            case .exclusions(let parent):
                ExclusionsManagerView(
                    exclusionsStore: exclusionsStore,
                    parent: parent,
                    onDismiss: {
                        phase = Self.phaseAfterExclusionsDismiss(parent)
                    }
                )
            }
            }
        }
        .sheet(isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )) {
            RoomyUnlockSheet(
                license: license,
                pendingBytes: pendingDeletion?.totalBytes,
                onUnlocked: {
                    let snap = pendingDeletion
                    pendingDeletion = nil
                    if let snap { phase = .deletionProgress(snap) }
                },
                onCancel: { pendingDeletion = nil }
            )
        }
        .onChange(of: settingsStore.settings) { newSettings in
            resultsSummary = Self.reconciledSummary(
                current: resultsSummary,
                aggregate: browserSession.scanAggregate,
                settings: newSettings
            )
        }
    }

    private func beginScanFromSettings() {
        let r = RoomyScanRootResolver.resolve(from: settingsStore.settings)
        overviewShowsPartialBanner = false
        scanPathForFooter = r.label
        scanRootURL = r.rootURL
        phase = .scanning(pathLabel: r.label)
    }

    /// Rebuilds S03 numbers from the live aggregate when thresholds or stored scan change so the age bar matches S04.
    private static func reconciledSummary(
        current: ScanResultsSummary,
        aggregate: ScanAggregate?,
        settings: RoomyAppSettings
    ) -> ScanResultsSummary {
        guard let aggregate else { return current }
        return ScanResultsSummary.from(
            aggregate: aggregate,
            scannedPathLabel: current.scannedPathLabel,
            dormantYears: settings.dormantThresholdYears,
            inactiveMonths: settings.inactiveThresholdMonths
        )
    }

    private static func phaseAfterSettingsDismiss(_ ctx: SettingsDismissContext) -> RootPhase {
        switch ctx {
        case .welcome: .welcome
        case .overview: .overview
        case .projectList(let e): .projectList(e)
        case .projectDetail(let id): .projectDetail(projectID: id)
        case .selectionReview(let s): .selectionReview(s)
        case .deletionSummary(let d): .deletionSummary(d)
        }
    }

    private static func phaseAfterExclusionsDismiss(_ parent: ExclusionsDismissParent) -> RootPhase {
        switch parent {
        case .settings(let ctx): .settings(ctx)
        case .projectDetail(let id): .projectDetail(projectID: id)
        }
    }

    private static func applyActivitySettings(from settings: RoomyAppSettings, to session: ProjectBrowserSession) {
        session.activityDormantYears = settings.dormantThresholdYears
        session.activityInactiveMonths = settings.inactiveThresholdMonths
    }

}

#Preview {
    ContentView()
}
