//
//  FilesystemArtifactScanner.swift
//  Roomy
//
//  Walks a directory tree, detects regenerable artifact folders, measures sizes.
//  Runs off the main thread; progress is reported on the caller’s schedule.
//

import Foundation

/// One discovered artifact directory (e.g. a `node_modules` tree).
struct ScanArtifactFinding: Sendable, Codable, Equatable {
    var path: String
    /// Last path component or display label (e.g. `node_modules`, `target/`).
    var label: String
    var sizeBytes: Int64
    /// Short tag for UI: npm, py, rust, swift, go, java, general, dotnet
    var ecosystemTag: String
    /// Synthetic group key for system artifacts; nil for project-walk findings.
    var groupRoot: String?
    var source: ArtifactSource
    var safetyTier: ArtifactSafetyTier
    var restoreHint: String?
    var lastActivityDate: Date?

    init(
        path: String,
        label: String,
        sizeBytes: Int64,
        ecosystemTag: String,
        groupRoot: String? = nil,
        source: ArtifactSource = .projectWalk,
        safetyTier: ArtifactSafetyTier = .safe,
        restoreHint: String? = nil,
        lastActivityDate: Date? = nil
    ) {
        self.path = path
        self.label = label
        self.sizeBytes = sizeBytes
        self.ecosystemTag = ecosystemTag
        self.groupRoot = groupRoot
        self.source = source
        self.safetyTier = safetyTier
        self.restoreHint = restoreHint
        self.lastActivityDate = lastActivityDate
    }

    enum CodingKeys: String, CodingKey {
        case path, label, sizeBytes, ecosystemTag, groupRoot, source, safetyTier, restoreHint, lastActivityDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = try c.decode(String.self, forKey: .path)
        label = try c.decode(String.self, forKey: .label)
        sizeBytes = try c.decode(Int64.self, forKey: .sizeBytes)
        ecosystemTag = try c.decode(String.self, forKey: .ecosystemTag)
        groupRoot = try c.decodeIfPresent(String.self, forKey: .groupRoot)
        source = try c.decodeIfPresent(ArtifactSource.self, forKey: .source) ?? .projectWalk
        safetyTier = try c.decodeIfPresent(ArtifactSafetyTier.self, forKey: .safetyTier) ?? .safe
        restoreHint = try c.decodeIfPresent(String.self, forKey: .restoreHint)
        lastActivityDate = try c.decodeIfPresent(Date.self, forKey: .lastActivityDate)
    }
}

/// Rolled-up numbers for S03 / summary.
struct ScanAggregate: Sendable, Codable, Equatable {
    var totalBytes: Int64
    /// Distinct “project” roots (parent folder of an artifact).
    var projectRootPaths: Set<String>
    var artifactCount: Int
    /// ecosystem tag -> (total bytes, distinct project roots touching that eco)
    var bytesByEcosystem: [String: Int64]
    var ecosystemProjectRoots: [String: Set<String>]
    var sampleFindings: [ScanArtifactFinding]
    /// Expanded filesystem path -> findings under that project root (drives S04+).
    var artifactsByProjectRoot: [String: [ScanArtifactFinding]]

    static let empty = ScanAggregate(
        totalBytes: 0,
        projectRootPaths: Set(),
        artifactCount: 0,
        bytesByEcosystem: [:],
        ecosystemProjectRoots: [:],
        sampleFindings: [],
        artifactsByProjectRoot: [:]
    )

    static func merge(_ a: ScanAggregate, _ b: ScanAggregate) -> ScanAggregate {
        if a.artifactCount == 0 { return b }
        if b.artifactCount == 0 { return a }

        var mergedRoots = a.projectRootPaths
        mergedRoots.formUnion(b.projectRootPaths)

        var mergedByRoot = a.artifactsByProjectRoot
        for (root, findings) in b.artifactsByProjectRoot {
            mergedByRoot[root, default: []].append(contentsOf: findings)
        }

        var allFindings: [ScanArtifactFinding] = []
        for findings in mergedByRoot.values {
            allFindings.append(contentsOf: findings)
        }

        var bytesByEco = a.bytesByEcosystem
        for (eco, bytes) in b.bytesByEcosystem {
            bytesByEco[eco, default: 0] += bytes
        }

        var ecoProjects = a.ecosystemProjectRoots
        for (eco, roots) in b.ecosystemProjectRoots {
            ecoProjects[eco, default: []].formUnion(roots)
        }

        let sortedSamples = allFindings.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(32)
        return ScanAggregate(
            totalBytes: a.totalBytes + b.totalBytes,
            projectRootPaths: mergedRoots,
            artifactCount: allFindings.count,
            bytesByEcosystem: bytesByEco,
            ecosystemProjectRoots: ecoProjects,
            sampleFindings: Array(sortedSamples),
            artifactsByProjectRoot: mergedByRoot
        )
    }
}

struct FilesystemArtifactScanner {

    struct ProgressTick: Sendable {
        var foldersScanned: Int
        /// Distinct project roots seen so far (parent of an artifact folder).
        var projectRootsFound: Int
        /// Tilde-shortened path for UI
        var currentPathDisplay: String
        var artifactsFound: Int
        var recoverableBytes: Int64
        var latestFinding: ScanArtifactFinding?
    }

    private struct Rule: Sendable {
        var folderName: String
        var label: String
        var ecosystem: String
    }

    /// Folder names (last path component) we treat as regenerable roots.
    private static let rules: [Rule] = [
        Rule(folderName: "node_modules", label: "node_modules", ecosystem: "npm"),
        Rule(folderName: ".pnpm-store", label: ".pnpm-store", ecosystem: "npm"),
        Rule(folderName: ".next", label: ".next", ecosystem: "npm"),
        Rule(folderName: ".nuxt", label: ".nuxt", ecosystem: "npm"),
        Rule(folderName: ".svelte-kit", label: ".svelte-kit", ecosystem: "npm"),
        Rule(folderName: ".turbo", label: ".turbo", ecosystem: "npm"),
        Rule(folderName: ".parcel-cache", label: ".parcel-cache", ecosystem: "npm"),
        Rule(folderName: "dist", label: "dist", ecosystem: "npm"),
        Rule(folderName: "build", label: "build", ecosystem: "java"), // refined below
        Rule(folderName: "target", label: "target/", ecosystem: "rust"),
        Rule(folderName: ".gradle", label: ".gradle", ecosystem: "java"),
        Rule(folderName: "__pycache__", label: "__pycache__", ecosystem: "py"),
        Rule(folderName: ".venv", label: ".venv", ecosystem: "py"),
        Rule(folderName: "venv", label: "venv", ecosystem: "py"),
        Rule(folderName: ".mypy_cache", label: ".mypy_cache", ecosystem: "py"),
        Rule(folderName: ".pytest_cache", label: ".pytest_cache", ecosystem: "py"),
        Rule(folderName: ".ruff_cache", label: ".ruff_cache", ecosystem: "py"),
        Rule(folderName: ".tox", label: ".tox", ecosystem: "py"),
        Rule(folderName: "vendor", label: "vendor/", ecosystem: "go"),
        Rule(folderName: "Pods", label: "Pods", ecosystem: "swift"),
        Rule(folderName: ".build", label: ".build", ecosystem: "swift"),
    ]

    private static let rulesByName: [String: Rule] = Dictionary(uniqueKeysWithValues: rules.map { ($0.folderName, $0) })

    /// Scan `root` and invoke `onProgress` periodically from a background task.
    /// `enabledEcosystemTags`: only artifact rules whose resolved ecosystem tag is in this set are counted; empty set skips all rules.
    static func scan(
        root: URL,
        homeDirectory: URL,
        enabledEcosystemTags: Set<String>,
        exclusionFilter: RoomyScanExclusionFilter = .empty,
        shouldCancel: @escaping @Sendable () -> Bool,
        onProgress: @escaping @Sendable (ProgressTick) -> Void
    ) async -> ScanAggregate {
        await Task.detached(priority: .userInitiated) {
            performScan(
                root: root,
                homeDirectory: homeDirectory,
                enabledEcosystemTags: enabledEcosystemTags,
                exclusionFilter: exclusionFilter,
                shouldCancel: shouldCancel,
                onProgress: onProgress
            )
        }.value
    }

    nonisolated private static func performScan(
        root: URL,
        homeDirectory: URL,
        enabledEcosystemTags: Set<String>,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool,
        onProgress: @escaping @Sendable (ProgressTick) -> Void
    ) -> ScanAggregate {
        var foldersScanned = 0
        var totalBytes: Int64 = 0
        var projectRoots: Set<String> = []
        var bytesByEcosystem: [String: Int64] = [:]
        var ecoProjects: [String: Set<String>] = [:]
        var findings: [ScanArtifactFinding] = []
        var artifactsByProjectRoot: [String: [ScanArtifactFinding]] = [:]
        var lastProgress = Date(timeIntervalSince1970: 0)

        let fm = FileManager.default
        if exclusionFilter.shouldExcludeDirectory(url: root) {
            return .empty
        }
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) as? FileManager.DirectoryEnumerator else {
            return .empty
        }

        while let url = enumerator.nextObject() as? URL {
            if shouldCancel() { break }

            if exclusionFilter.shouldExcludeDirectory(url: url) {
                enumerator.skipDescendants()
                continue
            }

            foldersScanned += 1
            let now = Date()
            if now.timeIntervalSince(lastProgress) >= 0.12 || foldersScanned % 64 == 0 {
                lastProgress = now
                let display = prettyPath(url, home: homeDirectory)
                onProgress(
                    ProgressTick(
                        foldersScanned: foldersScanned,
                        projectRootsFound: projectRoots.count,
                        currentPathDisplay: display,
                        artifactsFound: findings.count,
                        recoverableBytes: totalBytes,
                        latestFinding: findings.last
                    )
                )
            }

            let name = url.lastPathComponent
            guard let rule = rulesByName[name] else { continue }

            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDir else { continue }

            var eco = rule.ecosystem
            if name == "target" {
                let projectDir = url.deletingLastPathComponent()
                if fm.fileExists(atPath: projectDir.appendingPathComponent("Cargo.toml").path) {
                    eco = "rust"
                } else if fm.fileExists(atPath: projectDir.appendingPathComponent("pom.xml").path)
                    || fm.fileExists(atPath: projectDir.appendingPathComponent("build.gradle").path)
                    || fm.fileExists(atPath: projectDir.appendingPathComponent("build.gradle.kts").path) {
                    eco = "java"
                } else {
                    eco = "general"
                }
            }
            if name == "build" {
                let projectDir = url.deletingLastPathComponent()
                if fm.fileExists(atPath: projectDir.appendingPathComponent("build.gradle").path)
                    || fm.fileExists(atPath: projectDir.appendingPathComponent("build.gradle.kts").path) {
                    eco = "java"
                } else if fm.fileExists(atPath: projectDir.appendingPathComponent("Package.swift").path) {
                    eco = "swift"
                } else {
                    eco = "general"
                }
            }
            if name == "vendor" {
                let projectDir = url.deletingLastPathComponent()
                if fm.fileExists(atPath: projectDir.appendingPathComponent("go.mod").path) {
                    eco = "go"
                } else {
                    eco = "ruby"
                }
            }

            if !enabledEcosystemTags.contains(eco) {
                continue
            }

            let size: Int64
            do {
                size = try directorySize(at: url)
            } catch {
                enumerator.skipDescendants()
                continue
            }

            let projectRoot = url.deletingLastPathComponent().path
            projectRoots.insert(projectRoot)
            totalBytes += size
            bytesByEcosystem[eco, default: 0] += size
            ecoProjects[eco, default: []].insert(projectRoot)

            let finding = ScanArtifactFinding(
                path: url.path,
                label: rule.label,
                sizeBytes: size,
                ecosystemTag: eco
            )
            findings.append(finding)
            artifactsByProjectRoot[projectRoot, default: []].append(finding)

            onProgress(
                ProgressTick(
                    foldersScanned: foldersScanned,
                    projectRootsFound: projectRoots.count,
                    currentPathDisplay: prettyPath(url, home: homeDirectory),
                    artifactsFound: findings.count,
                    recoverableBytes: totalBytes,
                    latestFinding: finding
                )
            )

            enumerator.skipDescendants()
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

    nonisolated private static func directorySize(at root: URL) throws -> Int64 {
        var total: Int64 = 0
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants]
        ) else { return 0 }

        while let fileURL = enumerator.nextObject() as? URL {
            let v = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            if v.isRegularFile == true {
                total += Int64(v.fileSize ?? 0)
            }
        }
        return total
    }

    nonisolated private static func prettyPath(_ url: URL, home: URL) -> String {
        let path = url.path
        let homePath = home.path
        if path.hasPrefix(homePath), homePath != "/" {
            let rest = String(path.dropFirst(homePath.count))
            let trimmed = rest.hasPrefix("/") ? String(rest.dropFirst()) : rest
            return "~/" + trimmed
        }
        return path
    }

    /// For S02 ticker — tilde-shortened path (middle truncation in the view).
    static func shortenedDisplayPath(filePath: String, homeDirectory home: URL) -> String {
        prettyPath(URL(fileURLWithPath: filePath), home: home)
    }
}
