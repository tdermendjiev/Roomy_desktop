//
//  AIToolsProbe.swift
//  Roomy
//

import Foundation

/// Finds disk used by AI coding tools and local model runtimes:
/// downloaded models, app/sandbox caches, MCP tooling, and agent session history.
///
/// Three kinds of findings with different safety tiers:
/// - Models and caches: regenerable, `.safe`.
/// - App storage that mixes caches with user data: `.caution`.
/// - Agent session transcripts and checkpoints: not regenerable, `.warning`.
struct AIToolsProbe: SystemArtifactProbe {
    let categoryKey = "aiTools"

    private struct Candidate {
        var relativePath: String
        var label: String
        var tier: ArtifactSafetyTier
        var restoreHint: String
    }

    // MARK: Fixed-path candidates

    private static let modelCandidates: [Candidate] = [
        Candidate(relativePath: ".ollama/models", label: "Ollama models", tier: .safe,
                  restoreHint: "ollama pull <model>"),
        Candidate(relativePath: ".lmstudio/models", label: "LM Studio models", tier: .safe,
                  restoreHint: "Re-download in LM Studio"),
        Candidate(relativePath: ".cache/lm-studio/models", label: "LM Studio models (legacy)", tier: .safe,
                  restoreHint: "Re-download in LM Studio"),
        Candidate(relativePath: ".cache/huggingface/hub", label: "Hugging Face model cache", tier: .safe,
                  restoreHint: "Models re-download on next use"),
        Candidate(relativePath: ".cache/huggingface/xet", label: "Hugging Face download cache", tier: .safe,
                  restoreHint: "Rebuilt on next download"),
        Candidate(relativePath: ".cache/huggingface/datasets", label: "Hugging Face datasets cache", tier: .safe,
                  restoreHint: "Datasets re-download on next use"),
        Candidate(relativePath: "Library/Caches/llama.cpp", label: "llama.cpp model cache", tier: .safe,
                  restoreHint: "Models re-download on next run"),
        Candidate(relativePath: ".cache/torch/hub", label: "PyTorch Hub checkpoints", tier: .safe,
                  restoreHint: "Re-downloaded by torch.hub on next use"),
        Candidate(relativePath: ".cache/whisper", label: "Whisper models", tier: .safe,
                  restoreHint: "Re-downloaded on next transcription"),
        Candidate(relativePath: ".cache/vllm", label: "vLLM cache", tier: .safe,
                  restoreHint: "Rebuilt on next run"),
        Candidate(relativePath: "Library/Application Support/nomic.ai/GPT4All", label: "GPT4All models & chats", tier: .caution,
                  restoreHint: "Models re-download; chat history is lost"),
        Candidate(relativePath: "Library/Application Support/Jan", label: "Jan models & threads", tier: .caution,
                  restoreHint: "Models re-download; threads are lost"),
    ]

    private static let cacheCandidates: [Candidate] = [
        Candidate(relativePath: "Library/Application Support/Claude/vm_bundles", label: "Claude desktop sandbox VM bundles", tier: .safe,
                  restoreHint: "Re-downloaded when a sandboxed session starts"),
        Candidate(relativePath: "Library/Application Support/Claude/claude-code-vm", label: "Claude desktop Claude Code VM", tier: .safe,
                  restoreHint: "Re-downloaded when Claude Code runs in the app"),
        Candidate(relativePath: ".npm/_npx", label: "npx cache (MCP servers)", tier: .safe,
                  restoreHint: "Re-downloaded on next npx run"),
        Candidate(relativePath: "Library/Caches/ms-playwright", label: "Playwright browsers", tier: .safe,
                  restoreHint: "npx playwright install"),
        Candidate(relativePath: ".cache/puppeteer", label: "Puppeteer browsers", tier: .safe,
                  restoreHint: "Re-downloaded on next npm install"),
        Candidate(relativePath: ".continue/index", label: "Continue codebase index", tier: .safe,
                  restoreHint: "Rebuilt on next index"),
        Candidate(relativePath: ".claude/debug", label: "Claude Code debug logs", tier: .safe,
                  restoreHint: "Recreated on next session"),
        Candidate(relativePath: ".claude/paste-cache", label: "Claude Code paste cache", tier: .safe,
                  restoreHint: "Recreated on next session"),
        Candidate(relativePath: ".codex/log", label: "Codex CLI logs", tier: .safe,
                  restoreHint: "Recreated on next session"),
    ]

    /// Electron-based AI editors and apps; each gets the standard cache subfolders.
    private static let electronApps: [(appSupportName: String, displayName: String)] = [
        ("Claude", "Claude desktop"),
        ("Cursor", "Cursor"),
        ("Windsurf", "Windsurf"),
        ("Kiro", "Kiro"),
        ("Trae", "Trae"),
        ("Void", "Void"),
    ]
    private static let electronCacheSubdirs = ["Cache", "CachedData", "Code Cache", "GPUCache", "DawnWebGPUCache", "DawnGraphiteCache"]

    private static let sessionCandidates: [Candidate] = [
        Candidate(relativePath: ".claude/file-history", label: "Claude Code file history", tier: .warning,
                  restoreHint: "Needed to rewind edits in past sessions"),
        Candidate(relativePath: ".codex/sessions", label: "Codex CLI sessions", tier: .warning,
                  restoreHint: "Past Codex sessions cannot be resumed"),
        Candidate(relativePath: ".gemini/tmp", label: "Gemini CLI checkpoints", tier: .warning,
                  restoreHint: "Past Gemini conversations cannot be restored"),
        Candidate(relativePath: ".gemini/history", label: "Gemini CLI checkpoint repos", tier: .warning,
                  restoreHint: "File snapshots from past Gemini sessions are lost"),
        Candidate(relativePath: ".local/share/opencode/storage", label: "OpenCode session storage", tier: .warning,
                  restoreHint: "Past OpenCode sessions cannot be resumed"),
        Candidate(relativePath: "Library/Application Support/goose", label: "Goose sessions", tier: .warning,
                  restoreHint: "Past Goose sessions cannot be resumed"),
        Candidate(relativePath: ".qwen", label: "Qwen Code sessions", tier: .warning,
                  restoreHint: "Past Qwen Code sessions cannot be resumed"),
    ]

    /// VS Code-family editors whose globalStorage can hold agent extension checkpoints.
    private static let vsCodeFamily: [(appSupportName: String, displayName: String)] = [
        ("Code", "VS Code"),
        ("Code - Insiders", "VS Code Insiders"),
        ("Cursor", "Cursor"),
        ("Windsurf", "Windsurf"),
    ]
    private static let agentExtensions: [(id: String, displayName: String)] = [
        ("saoudrizwan.claude-dev", "Cline"),
        ("rooveterinaryinc.roo-cline", "Roo Code"),
        ("kilocode.kilo-code", "Kilo Code"),
    ]

    // MARK: Scan

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        var candidates: [(url: URL, candidate: Candidate)] = []

        for c in Self.modelCandidates + Self.cacheCandidates + Self.sessionCandidates {
            candidates.append((home.appendingPathComponent(c.relativePath, isDirectory: true), c))
        }

        for app in Self.electronApps {
            let base = home.appendingPathComponent("Library/Application Support/\(app.appSupportName)", isDirectory: true)
            for sub in Self.electronCacheSubdirs {
                candidates.append((
                    base.appendingPathComponent(sub, isDirectory: true),
                    Candidate(relativePath: "", label: "\(app.displayName) \(sub)", tier: .safe,
                              restoreHint: "Rebuilt by \(app.displayName) on next launch")
                ))
            }
        }

        for editor in Self.vsCodeFamily {
            let globalStorage = home.appendingPathComponent(
                "Library/Application Support/\(editor.appSupportName)/User/globalStorage", isDirectory: true)
            for ext in Self.agentExtensions {
                candidates.append((
                    globalStorage.appendingPathComponent(ext.id, isDirectory: true),
                    Candidate(relativePath: "", label: "\(ext.displayName) tasks & checkpoints (\(editor.displayName))", tier: .warning,
                              restoreHint: "Past \(ext.displayName) tasks cannot be resumed")
                ))
            }
        }

        var seen: Set<String> = []
        var toSize: [(url: URL, candidate: Candidate, activity: Date?)] = []
        for (url, c) in candidates {
            if shouldCancel() { return [] }
            guard !seen.contains(url.path) else { continue }
            guard SystemProbeHelpers.pathExists(url.path) else { continue }
            if exclusionFilter.shouldExcludeDirectory(url: url) { continue }
            seen.insert(url.path)
            let activity = c.tier == .warning ? Self.newestModificationDate(in: url) : nil
            toSize.append((url, c, activity))
        }

        // Claude Code keeps one transcript folder per project; surface each so age can be judged per project.
        let claudeProjects = home.appendingPathComponent(".claude/projects", isDirectory: true)
        if SystemProbeHelpers.pathExists(claudeProjects.path),
           !exclusionFilter.shouldExcludeDirectory(url: claudeProjects) {
            for entry in Self.claudeProjectFolders(in: claudeProjects, home: home) {
                if shouldCancel() { return [] }
                guard !seen.contains(entry.url.path) else { continue }
                if exclusionFilter.shouldExcludeDirectory(url: entry.url) { continue }
                seen.insert(entry.url.path)
                toSize.append((
                    entry.url,
                    Candidate(relativePath: "", label: "Claude Code sessions · \(entry.displayName)", tier: .warning,
                              restoreHint: "Past Claude Code sessions for this project cannot be resumed"),
                    Self.newestModificationDate(in: entry.url)
                ))
            }
        }

        if toSize.isEmpty || shouldCancel() { return [] }

        let sizes = await RoomyDirectorySizeReader.bytesConcurrently(
            urls: toSize.map(\.url),
            shouldCancel: shouldCancel
        )

        var findings: [ScanArtifactFinding] = []
        for (url, c, activity) in toSize {
            guard let size = sizes[url], size >= SystemProbeHelpers.minBytes else { continue }
            findings.append(
                SystemProbeHelpers.finding(
                    path: url.path,
                    label: c.label,
                    sizeBytes: size,
                    ecosystemTag: "ai",
                    groupRoot: RoomySystemGroupRoot.aiTools,
                    safetyTier: c.tier,
                    restoreHint: c.restoreHint,
                    lastActivityDate: activity
                )
            )
        }
        return findings
    }

    // MARK: Helpers

    struct ClaudeProjectFolder: Equatable {
        var url: URL
        var displayName: String
    }

    /// Claude Code encodes a project path by replacing every non-alphanumeric character with `-`.
    /// Strip the encoded home prefix so `-Users-me-workspace-app` reads as `workspace-app`.
    static func claudeProjectFolders(in projectsDir: URL, home: URL) -> [ClaudeProjectFolder] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: projectsDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let encodedHome = encodeClaudeProjectPath(home.path)
        return entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map { url in
                ClaudeProjectFolder(url: url, displayName: claudeProjectDisplayName(folderName: url.lastPathComponent, encodedHome: encodedHome))
            }
            .sorted { $0.url.path < $1.url.path }
    }

    static func encodeClaudeProjectPath(_ path: String) -> String {
        String(path.map { $0.isLetter || $0.isNumber ? $0 : "-" })
    }

    static func claudeProjectDisplayName(folderName: String, encodedHome: String) -> String {
        if folderName == encodedHome { return "Home" }
        if folderName.hasPrefix(encodedHome + "-") {
            let rest = folderName.dropFirst(encodedHome.count + 1)
            return rest.isEmpty ? "Home" : String(rest)
        }
        return folderName.hasPrefix("-") ? String(folderName.dropFirst()) : folderName
    }

    /// Newest modification date among the directory itself and its direct children.
    /// Non-recursive on purpose: session folders can hold thousands of files.
    static func newestModificationDate(in dir: URL) -> Date? {
        var newest = RoomyDirectorySizeReader.modificationDate(at: dir)
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return newest }
        for child in children {
            if let d = RoomyDirectorySizeReader.modificationDate(at: child), newest == nil || d > newest! {
                newest = d
            }
        }
        return newest
    }
}
