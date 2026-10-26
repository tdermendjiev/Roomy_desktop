//
//  DeletionRunSnapshot.swift
//  Roomy
//
//  Payload for S07 / S08 after committing deletion from S06.
//

import Foundation

struct DeletionEcosystemChunk: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let iconSystemName: String
    let gigabytes: Double
}

struct DeletionRunSnapshot: Equatable {
    let artifactIDs: Set<UUID>
    let folderPaths: [String]
    let totalBytes: Int64
    let projectCount: Int
    let folderCount: Int
    /// Disk model aligned with S06 review panel (live volume when available).
    let diskUsedBeforeGB: Double
    let diskTotalGB: Double
    let emptyTrashAfter: Bool
    /// Mirrors S09 “Move to Trash” vs permanent delete.
    let moveToTrash: Bool
    let ecosystemChunks: [DeletionEcosystemChunk]
    /// Full caption line, or nil when no artifact is ≥10% of total.
    let biggestSaveLine: String?
    /// Populated after S07 when some paths could not be removed.
    let deletionFailures: [RoomyDeletionFailure]

    var totalGB: Double {
        Double(totalBytes) / 1_073_741_824
    }

    var diskUsedAfterGB: Double {
        max(0, diskUsedBeforeGB - totalGB)
    }

    func withDeletionFailures(_ failures: [RoomyDeletionFailure]) -> DeletionRunSnapshot {
        DeletionRunSnapshot(
            artifactIDs: artifactIDs,
            folderPaths: folderPaths,
            totalBytes: totalBytes,
            projectCount: projectCount,
            folderCount: folderCount,
            diskUsedBeforeGB: diskUsedBeforeGB,
            diskTotalGB: diskTotalGB,
            emptyTrashAfter: emptyTrashAfter,
            moveToTrash: moveToTrash,
            ecosystemChunks: ecosystemChunks,
            biggestSaveLine: biggestSaveLine,
            deletionFailures: failures
        )
    }

    static func build(
        session: ProjectBrowserSession,
        artifactIDs: Set<UUID>,
        emptyTrashAfter: Bool,
        moveToTrash: Bool,
        diskUsedBeforeGB: Double,
        diskTotalGB: Double
    ) -> DeletionRunSnapshot? {
        guard !artifactIDs.isEmpty else { return nil }

        var paths: [String] = []
        var total: Int64 = 0
        var projectIDs: Set<UUID> = []
        var byEco: [String: Int64] = [:]
        var bestArtifact: ArtifactRowModel?
        var bestProject: ProjectListRowModel?

        for project in session.visibleProjects {
            for artifact in project.artifacts where artifactIDs.contains(artifact.id) {
                paths.append(artifact.path)
                total += artifact.sizeBytes
                projectIDs.insert(project.id)

                let tags = project.ecosystems.isEmpty ? ["general"] : project.ecosystems
                let share = artifact.sizeBytes / Int64(max(1, tags.count))
                for tag in tags {
                    byEco[tag, default: 0] += share
                }

                if bestArtifact == nil || artifact.sizeBytes > bestArtifact!.sizeBytes {
                    bestArtifact = artifact
                    bestProject = project
                }
            }
        }

        paths.sort()

        let chunks: [DeletionEcosystemChunk] = byEco
            .map { tag, bytes in
                DeletionEcosystemChunk(
                    name: roomyEcosystemDisplayName(tag),
                    iconSystemName: roomyEcosystemIcon(tag),
                    gigabytes: Double(bytes) / 1_073_741_824
                )
            }
            .sorted { $0.gigabytes > $1.gigabytes }

        let threshold = Double(total) * 0.10
        let biggestLine: String? = {
            guard let a = bestArtifact, let p = bestProject, Double(a.sizeBytes) >= threshold else { return nil }
            let gb = Double(a.sizeBytes) / 1_073_741_824
            return "\(a.name) in \(p.path) — \(String(format: "%.1f GB", gb))"
        }()

        return DeletionRunSnapshot(
            artifactIDs: artifactIDs,
            folderPaths: paths,
            totalBytes: total,
            projectCount: projectIDs.count,
            folderCount: paths.count,
            diskUsedBeforeGB: diskUsedBeforeGB,
            diskTotalGB: diskTotalGB,
            emptyTrashAfter: emptyTrashAfter,
            moveToTrash: moveToTrash,
            ecosystemChunks: chunks,
            biggestSaveLine: biggestLine,
            deletionFailures: []
        )
    }
}

private func roomyEcosystemDisplayName(_ tag: String) -> String {
    switch tag.lowercased() {
    case "npm": "Node.js"
    case "py": "Python"
    case "rust": "Rust"
    case "swift": "Swift"
    case "dotnet": ".NET"
    case "ai": "AI tools"
    default: tag.capitalized
    }
}

private func roomyEcosystemIcon(_ tag: String) -> String {
    switch tag.lowercased() {
    case "npm": "cube.box"
    case "py": "doc.text"
    case "rust": "gearshape.2"
    case "swift": "swift"
    case "ai": "sparkles"
    default: "folder"
    }
}

extension ProjectBrowserSession {
    /// Updates the session and optional live aggregate after deletion. Only `succeededArtifactIDs` are removed so failed paths stay visible.
    func applyDeletionCleanup(succeededArtifactIDs: Set<UUID>) {
        var pathsToRemove: Set<String> = []
        for p in projects {
            for a in p.artifacts where succeededArtifactIDs.contains(a.id) {
                pathsToRemove.insert(a.path)
            }
        }
        selectedArtifactIDs.subtract(succeededArtifactIDs)
        for i in projects.indices {
            var p = projects[i]
            p.artifacts.removeAll { succeededArtifactIDs.contains($0.id) }
            p.sizeBytes = p.artifacts.reduce(0) { $0 + $1.sizeBytes }
            projects[i] = p
        }
        projects.removeAll { $0.artifacts.isEmpty }
        trimScanAggregate(removingArtifactPaths: pathsToRemove)
    }

    private func trimScanAggregate(removingArtifactPaths: Set<String>) {
        guard var agg = scanAggregate, !agg.artifactsByProjectRoot.isEmpty else { return }
        var newMap: [String: [ScanArtifactFinding]] = [:]
        for (root, findings) in agg.artifactsByProjectRoot {
            let kept = findings.filter { !removingArtifactPaths.contains($0.path) }
            if !kept.isEmpty {
                newMap[root] = kept
            }
        }
        var totalBytes: Int64 = 0
        var projectRoots: Set<String> = []
        var bytesByEcosystem: [String: Int64] = [:]
        var ecoProjects: [String: Set<String>] = [:]
        var allFindings: [ScanArtifactFinding] = []
        for (root, findings) in newMap {
            projectRoots.insert(root)
            for f in findings {
                totalBytes += f.sizeBytes
                bytesByEcosystem[f.ecosystemTag, default: 0] += f.sizeBytes
                ecoProjects[f.ecosystemTag, default: []].insert(root)
                allFindings.append(f)
            }
        }
        let sortedSamples = allFindings.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(32)
        agg = ScanAggregate(
            totalBytes: totalBytes,
            projectRootPaths: projectRoots,
            artifactCount: allFindings.count,
            bytesByEcosystem: bytesByEcosystem,
            ecosystemProjectRoots: ecoProjects,
            sampleFindings: Array(sortedSamples),
            artifactsByProjectRoot: newMap
        )
        scanAggregate = agg
    }
}
