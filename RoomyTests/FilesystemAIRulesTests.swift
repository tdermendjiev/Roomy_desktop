//
//  FilesystemAIRulesTests.swift
//  RoomyTests
//

import Foundation
import Testing
@testable import Roomy

struct FilesystemAIRulesTests {

    @Test func projectLevelAIFoldersAreFoundWithTiers() async throws {
        let root = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let project = root.appendingPathComponent("my-app", isDirectory: true)
        try writeFile(at: project.appendingPathComponent(".aider.tags.cache.v3/cache.db"), bytes: 4096)
        try writeFile(at: project.appendingPathComponent(".crush/crush.db"), bytes: 4096)
        try writeFile(at: project.appendingPathComponent(".chroma/chroma.sqlite3"), bytes: 4096)
        try writeFile(at: project.appendingPathComponent("chroma_db/chroma.sqlite3"), bytes: 4096)
        try writeFile(at: project.appendingPathComponent(".lancedb/t.lance/data"), bytes: 4096)
        try writeFile(at: project.appendingPathComponent("src/main.py"), bytes: 10)

        let aggregate = await FilesystemArtifactScanner.scan(
            root: root,
            homeDirectory: root,
            enabledEcosystemTags: ["ai"],
            shouldCancel: { false },
            onProgress: { _ in }
        )

        #expect(aggregate.artifactCount == 5)
        // The enumerator reports /private/var/… while temporaryDirectory resolves to /var/…, so match by suffix.
        let findings = aggregate.artifactsByProjectRoot.first { $0.key.hasSuffix("/my-app") }?.value ?? []
        let byLabel = Dictionary(uniqueKeysWithValues: findings.map { ($0.label, $0) })

        #expect(findings.count == 5)
        #expect(findings.allSatisfy { $0.ecosystemTag == "ai" && $0.source == .projectWalk })

        let aider = try #require(byLabel[".aider.tags.cache"])
        #expect(aider.safetyTier == .safe)
        #expect(aider.restoreHint == "Rebuilt by aider on next run")

        let crush = try #require(byLabel[".crush"])
        #expect(crush.safetyTier == .warning)
        #expect(!RoomyArtifactSafety.isEligibleForBulkDormantSelection(tier: crush.safetyTier))

        for label in [".chroma", "chroma_db", ".lancedb"] {
            let f = try #require(byLabel[label])
            #expect(f.safetyTier == .caution)
            #expect(f.restoreHint?.contains("re-embedding") == true)
        }

        let aiBytes = try #require(aggregate.bytesByEcosystem["ai"])
        #expect(aiBytes == Int64(5 * 4096))
    }

    @Test func aiRulesAreSkippedWhenEcosystemDisabled() async throws {
        let root = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try writeFile(at: root.appendingPathComponent("my-app/.crush/crush.db"), bytes: 4096)
        try writeFile(at: root.appendingPathComponent("my-app/node_modules/x/index.js"), bytes: 4096)

        let aggregate = await FilesystemArtifactScanner.scan(
            root: root,
            homeDirectory: root,
            enabledEcosystemTags: ["npm"],
            shouldCancel: { false },
            onProgress: { _ in }
        )

        #expect(aggregate.artifactCount == 1)
        #expect(aggregate.bytesByEcosystem["ai"] == nil)
    }

    @Test func existingRulesStillDefaultToSafeTier() async throws {
        let root = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try writeFile(at: root.appendingPathComponent("my-app/node_modules/x/index.js"), bytes: 4096)

        let aggregate = await FilesystemArtifactScanner.scan(
            root: root,
            homeDirectory: root,
            enabledEcosystemTags: ["npm"],
            shouldCancel: { false },
            onProgress: { _ in }
        )

        let f = try #require(aggregate.sampleFindings.first)
        #expect(f.safetyTier == .safe)
        #expect(f.restoreHint == nil)
    }

    private func makeTempRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("roomy-fsai-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.resolvingSymlinksInPath()
    }

    private func writeFile(at url: URL, bytes: Int) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(count: bytes).write(to: url)
    }
}
