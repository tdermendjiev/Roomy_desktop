//
//  RoomyGitMetadataReader.swift
//  Roomy
//
//  Real git + disk metadata for S05 (off the main thread from the view).
//

import Foundation

enum RoomyGitMetadataReader {
    private static let gitTimeout: TimeInterval = 8
    private static let duTimeout: TimeInterval = 20

    /// Reads `.git`, last commit, status, and folder size for a project directory.
    static func metadata(forProjectPath displayPath: String, recoverableArtifactBytes: Int64) async -> ProjectGitMetadata {
        await Task.detached(priority: .utility) {
            metadataSync(forProjectPath: displayPath, recoverableArtifactBytes: recoverableArtifactBytes)
        }.value
    }

    private nonisolated static func metadataSync(forProjectPath displayPath: String, recoverableArtifactBytes: Int64) -> ProjectGitMetadata {
        let expanded = (displayPath as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue else {
            return nonRepoMetadata(
                recoverableArtifactBytes: recoverableArtifactBytes,
                folderURL: URL(fileURLWithPath: expanded, isDirectory: true)
            )
        }

        let folderURL = URL(fileURLWithPath: expanded, isDirectory: true)
        let gitMarker = folderURL.appendingPathComponent(".git").path
        guard FileManager.default.fileExists(atPath: gitMarker) else {
            return nonRepoMetadata(recoverableArtifactBytes: recoverableArtifactBytes, folderURL: folderURL)
        }

        let duTotal = diskUsageBytes(at: folderURL) ?? max(recoverableArtifactBytes, 0)
        let totalProject = max(duTotal, recoverableArtifactBytes)
        let status = porcelainStatus(in: folderURL)

        guard let commit = lastCommit(in: folderURL) else {
            return ProjectGitMetadata(
                isGitRepo: true,
                lastCommitDate: nil,
                commitSubject: "",
                isClean: status.isClean,
                gitStatusLine: status.summaryLine,
                totalProjectSizeBytes: totalProject,
                lastModified: nil
            )
        }

        return ProjectGitMetadata(
            isGitRepo: true,
            lastCommitDate: commit.date,
            commitSubject: commit.subject,
            isClean: status.isClean,
            gitStatusLine: status.summaryLine,
            totalProjectSizeBytes: totalProject,
            lastModified: nil
        )
    }

    // MARK: - Non-git

    private nonisolated static func nonRepoMetadata(recoverableArtifactBytes: Int64, folderURL: URL) -> ProjectGitMetadata {
        let duTotal = diskUsageBytes(at: folderURL) ?? max(recoverableArtifactBytes, 0)
        let mtime = (try? folderURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        return ProjectGitMetadata(
            isGitRepo: false,
            lastCommitDate: nil,
            commitSubject: "",
            isClean: false,
            gitStatusLine: "",
            totalProjectSizeBytes: max(duTotal, recoverableArtifactBytes),
            lastModified: mtime
        )
    }

    // MARK: - Git subprocess

    private struct ParsedCommit {
        var date: Date
        var subject: String
    }

    private nonisolated static func lastCommit(in workTree: URL) -> ParsedCommit? {
        guard let out = runGit(["log", "-1", "--pretty=format:%ct\u{1C}%s"], cwd: workTree, timeout: gitTimeout),
              !out.isEmpty else { return nil }
        let parts = out.split(separator: "\u{1C}", maxSplits: 1, omittingEmptySubsequences: false)
        guard let tsPart = parts.first,
              let ts = TimeInterval(String(tsPart)) else { return nil }
        let subject = parts.count > 1 ? String(parts[1]) : ""
        return ParsedCommit(date: Date(timeIntervalSince1970: ts), subject: subject)
    }

    private struct PorcelainStatus {
        var isClean: Bool
        var summaryLine: String
    }

    private nonisolated static func porcelainStatus(in workTree: URL) -> PorcelainStatus {
        guard let raw = runGit(["status", "--porcelain=v1"], cwd: workTree, timeout: gitTimeout) else {
            return PorcelainStatus(isClean: true, summaryLine: "Unable to read git status")
        }
        let lines = raw.split(whereSeparator: \.isNewline).filter { !$0.isEmpty }
        if lines.isEmpty {
            return PorcelainStatus(isClean: true, summaryLine: "Clean (no uncommitted changes)")
        }
        let n = lines.count
        let line: String
        if n == 1 {
            line = "1 uncommitted change"
        } else {
            line = "\(n) uncommitted changes"
        }
        return PorcelainStatus(isClean: false, summaryLine: line)
    }

    @discardableResult
    private nonisolated static func runGit(_ arguments: [String], cwd: URL, timeout: TimeInterval) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = arguments
        p.currentDirectoryURL = cwd
        var env = ProcessInfo.processInfo.environment
        env["GIT_OPTIONAL_LOCKS"] = "1"
        p.environment = env
        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        do {
            try p.run()
        } catch {
            return nil
        }
        let deadline = Date().addingTimeInterval(timeout)
        while p.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if p.isRunning {
            p.terminate()
            p.waitUntilExit()
            return nil
        }
        p.waitUntilExit()
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard p.terminationStatus == 0,
              let s = String(data: data, encoding: .utf8) else {
            return nil
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Disk usage

    private nonisolated static func diskUsageBytes(at url: URL) -> Int64? {
        RoomyDirectorySizeReader.bytes(at: url, timeout: duTimeout)
    }
}
