//
//  SystemArtifactScanner.swift
//  Roomy
//

import Foundation

struct SystemArtifactScanner {
    struct ProgressTick: Sendable {
        var phaseLabel: String
        var artifactsFound: Int
        var recoverableBytes: Int64
        var latestFinding: ScanArtifactFinding?
    }

    static func scan(
        homeDirectory: URL,
        enabledCategories: Set<String>,
        enabledEcosystemTags: Set<String>,
        exclusionFilter: RoomyScanExclusionFilter,
        projectAggregate: ScanAggregate,
        shouldCancel: @escaping @Sendable () -> Bool,
        onProgress: @escaping @Sendable (ProgressTick) -> Void
    ) async -> ScanAggregate {
        let probes = buildProbes(enabledCategories: enabledCategories)
        var allFindings: [ScanArtifactFinding] = []
        var totalBytes: Int64 = 0

        for probe in probes {
            if shouldCancel() { break }
            onProgress(
                ProgressTick(
                    phaseLabel: "Checking system caches…",
                    artifactsFound: allFindings.count,
                    recoverableBytes: totalBytes,
                    latestFinding: allFindings.last
                )
            )

            let findings = await probe.scan(
                home: homeDirectory,
                exclusionFilter: exclusionFilter,
                shouldCancel: shouldCancel
            )
            let filtered = findings.filter { enabledEcosystemTags.contains($0.ecosystemTag) || $0.ecosystemTag == "general" }
            for f in filtered {
                allFindings.append(f)
                totalBytes += f.sizeBytes
                onProgress(
                    ProgressTick(
                        phaseLabel: "Checking system caches…",
                        artifactsFound: allFindings.count,
                        recoverableBytes: totalBytes,
                        latestFinding: f
                    )
                )
            }
        }

        if enabledCategories.contains("python"), !shouldCancel() {
            let pipFindings = await PipOrphanProbe().scan(
                projectAggregate: projectAggregate,
                shouldCancel: shouldCancel
            )
            let filtered = pipFindings.filter { enabledEcosystemTags.contains($0.ecosystemTag) }
            for f in filtered {
                allFindings.append(f)
                totalBytes += f.sizeBytes
            }
        }

        return aggregate(from: allFindings)
    }

    private static func buildProbes(enabledCategories: Set<String>) -> [any SystemArtifactProbe] {
        var probes: [any SystemArtifactProbe] = []
        if enabledCategories.contains("xcode") {
            probes.append(XcodeDerivedDataProbe())
            probes.append(XcodeDeviceSupportProbe())
            probes.append(XcodeArchivesProbe())
            probes.append(CoreSimulatorProbe())
        }
        if enabledCategories.contains("globalCaches") {
            probes.append(GlobalPackageCacheProbe())
        }
        if enabledCategories.contains("globalModules") {
            probes.append(GlobalModulesProbe())
        }
        if enabledCategories.contains("python") {
            probes.append(CondaProbe())
            probes.append(PyenvProbe())
        }
        if enabledCategories.contains("homebrew") {
            probes.append(HomebrewCacheProbe())
        }
        if enabledCategories.contains("docker") {
            probes.append(DockerArtifactProbe())
        }
        if enabledCategories.contains("aiTools") {
            probes.append(AIToolsProbe())
        }
        return probes
    }

    private static func aggregate(from findings: [ScanArtifactFinding]) -> ScanAggregate {
        var totalBytes: Int64 = 0
        var projectRoots: Set<String> = []
        var bytesByEcosystem: [String: Int64] = [:]
        var ecoProjects: [String: Set<String>] = [:]
        var artifactsByProjectRoot: [String: [ScanArtifactFinding]] = [:]

        for finding in findings {
            totalBytes += finding.sizeBytes
            let root = finding.groupRoot ?? finding.path
            projectRoots.insert(root)
            bytesByEcosystem[finding.ecosystemTag, default: 0] += finding.sizeBytes
            ecoProjects[finding.ecosystemTag, default: []].insert(root)
            artifactsByProjectRoot[root, default: []].append(finding)
        }

        let sortedSamples = findings.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(32)
        return ScanAggregate(
            totalBytes: totalBytes,
            projectRootPaths: projectRoots,
            artifactCount: findings.count,
            bytesByEcosystem: bytesByEcosystem,
            ecosystemProjectRoots: ecoProjects,
            sampleFindings: Array(sortedSamples),
            artifactsByProjectRoot: artifactsByProjectRoot
        )
    }
}
