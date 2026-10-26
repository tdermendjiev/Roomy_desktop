//
//  AIToolsProbeTests.swift
//  RoomyTests
//

import Foundation
import Testing
@testable import Roomy

struct AIToolsProbeTests {

    // MARK: Registration

    @Test func aiToolsCategoryIsRegistered() {
        #expect(RoomySystemScanCategories.all.contains { $0.key == "aiTools" })
        #expect(RoomySystemGroupRoot.allKeys.contains(RoomySystemGroupRoot.aiTools))
        #expect(RoomySystemGroupRoot.isSystemRoot(RoomySystemGroupRoot.aiTools))
        #expect(RoomySystemGroupRoot.displayName(for: RoomySystemGroupRoot.aiTools) == "AI coding tools")
        #expect(RoomySystemScanCategories.defaultEnabledMap()["aiTools"] == true)
    }

    @Test func aiEcosystemTagIsEnabledByDefault() {
        #expect(RoomySettingsEcosystems.all.contains { $0.key == "ai" })
        #expect(RoomyAppSettings.default.ecosystemsEnabled["ai"] == true)
        #expect(RoomyAppSettings.default.enabledEcosystemKeysForScan.contains("ai"))
    }

    // MARK: Claude project folder decoding

    @Test func claudeProjectPathEncoding() {
        #expect(AIToolsProbe.encodeClaudeProjectPath("/Users/me/workspace/my_app") == "-Users-me-workspace-my-app")
    }

    @Test func claudeProjectDisplayNameStripsHome() {
        let home = "-Users-me"
        #expect(AIToolsProbe.claudeProjectDisplayName(folderName: "-Users-me-workspace-app", encodedHome: home) == "workspace-app")
        #expect(AIToolsProbe.claudeProjectDisplayName(folderName: "-Users-me", encodedHome: home) == "Home")
        #expect(AIToolsProbe.claudeProjectDisplayName(folderName: "-Volumes-ext-proj", encodedHome: home) == "Volumes-ext-proj")
    }

    // MARK: Scan

    @Test func scanFindsModelsCachesAndPerProjectSessions() async throws {
        let home = try makeTempHome()
        defer { try? FileManager.default.removeItem(at: home) }

        let twoMB = 2 * 1_048_576
        try writeFile(at: home.appendingPathComponent(".ollama/models/blobs/sha256-abc"), bytes: twoMB)
        try writeFile(at: home.appendingPathComponent("Library/Application Support/Cursor/CachedData/x.bin"), bytes: twoMB)
        try writeFile(at: home.appendingPathComponent(".cache/huggingface/hub/tiny.txt"), bytes: 16) // below 1 MB, must be dropped

        let encodedHome = AIToolsProbe.encodeClaudeProjectPath(home.path)
        let oldProject = home.appendingPathComponent(".claude/projects/\(encodedHome)-workspace-old")
        let newProject = home.appendingPathComponent(".claude/projects/\(encodedHome)-workspace-new")
        try writeFile(at: oldProject.appendingPathComponent("a.jsonl"), bytes: twoMB)
        try writeFile(at: newProject.appendingPathComponent("b.jsonl"), bytes: twoMB)
        let twoYearsAgo = Date().addingTimeInterval(-2 * 365 * 86_400)
        try FileManager.default.setAttributes([.modificationDate: twoYearsAgo], ofItemAtPath: oldProject.appendingPathComponent("a.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: twoYearsAgo], ofItemAtPath: oldProject.path)

        let findings = await AIToolsProbe().scan(home: home, exclusionFilter: .empty, shouldCancel: { false })

        #expect(findings.allSatisfy { $0.groupRoot == RoomySystemGroupRoot.aiTools })
        #expect(findings.allSatisfy { $0.ecosystemTag == "ai" })
        #expect(findings.allSatisfy { $0.source == .systemProbe })
        #expect(!findings.contains { $0.path.hasSuffix("huggingface/hub") })

        let ollama = try #require(findings.first { $0.label == "Ollama models" })
        #expect(ollama.safetyTier == .safe)
        #expect(ollama.restoreHint == "ollama pull <model>")
        #expect(ollama.sizeBytes >= Int64(twoMB))
        #expect(ollama.lastActivityDate == nil)

        let cursor = try #require(findings.first { $0.label == "Cursor CachedData" })
        #expect(cursor.safetyTier == .safe)

        let old = try #require(findings.first { $0.label == "Claude Code sessions · workspace-old" })
        let new = try #require(findings.first { $0.label == "Claude Code sessions · workspace-new" })
        #expect(old.safetyTier == .warning)
        #expect(new.safetyTier == .warning)
        #expect(!RoomyArtifactSafety.isEligibleForBulkDormantSelection(tier: old.safetyTier))
        let oldDate = try #require(old.lastActivityDate)
        let newDate = try #require(new.lastActivityDate)
        #expect(oldDate < newDate)
        #expect(oldDate.timeIntervalSinceNow < -1.5 * 365 * 86_400)
    }

    @Test func scanRespectsExclusions() async throws {
        let home = try makeTempHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeFile(at: home.appendingPathComponent(".ollama/models/blob"), bytes: 2 * 1_048_576)

        let filter = RoomyScanExclusionFilter(
            entries: [ExclusionEntry(pathDisplay: home.appendingPathComponent(".ollama").path, kind: .path)],
            homeDirectory: home
        )
        let findings = await AIToolsProbe().scan(home: home, exclusionFilter: filter, shouldCancel: { false })
        #expect(findings.isEmpty)
    }

    @Test func scanReturnsNothingWhenCancelled() async throws {
        let home = try makeTempHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeFile(at: home.appendingPathComponent(".ollama/models/blob"), bytes: 2 * 1_048_576)

        let findings = await AIToolsProbe().scan(home: home, exclusionFilter: .empty, shouldCancel: { true })
        #expect(findings.isEmpty)
    }

    @Test func scanOnEmptyHomeIsEmpty() async throws {
        let home = try makeTempHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let findings = await AIToolsProbe().scan(home: home, exclusionFilter: .empty, shouldCancel: { false })
        #expect(findings.isEmpty)
    }

    // MARK: Helpers

    private func makeTempHome() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("roomy-aitools-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.resolvingSymlinksInPath()
    }

    private func writeFile(at url: URL, bytes: Int) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(count: bytes).write(to: url)
    }
}
