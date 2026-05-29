//
//  HomebrewCacheProbe.swift
//  Roomy
//

import Foundation

struct HomebrewCacheProbe: SystemArtifactProbe {
    let categoryKey = "homebrew"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        guard SystemProbeHelpers.which("brew") != nil else { return [] }
        if shouldCancel() { return [] }

        var candidates: [(URL, String)] = [
            (home.appendingPathComponent("Library/Caches/Homebrew", isDirectory: true), "Homebrew cache"),
            (home.appendingPathComponent("Library/Logs/Homebrew", isDirectory: true), "Homebrew logs"),
        ]

        if SystemProbeHelpers.which("brew") != nil,
           let prefixOut = SystemProbeHelpers.runCommand(
               executable: "/usr/bin/env",
               arguments: ["brew", "--prefix"],
               timeout: 5
           ) {
            let cachePath = URL(fileURLWithPath: prefixOut, isDirectory: true)
                .appendingPathComponent("var/homebrew/cache", isDirectory: true)
            candidates.append((cachePath, "Homebrew formula cache"))
        }

        var findings: [ScanArtifactFinding] = []
        for (url, label) in candidates {
            if shouldCancel() { break }
            guard SystemProbeHelpers.pathExists(url.path) else { continue }
            if exclusionFilter.shouldExcludeDirectory(url: url) { continue }
            let size = await Task.detached {
                RoomyDirectorySizeReader.bytes(at: url)
            }.value
            guard let size, size >= SystemProbeHelpers.minBytes else { continue }

            findings.append(
                SystemProbeHelpers.finding(
                    path: url.path,
                    label: label,
                    sizeBytes: size,
                    ecosystemTag: "general",
                    groupRoot: RoomySystemGroupRoot.homebrew,
                    restoreHint: "Caches rebuild automatically; use brew reinstall for removed downloads"
                )
            )
        }
        return findings
    }
}
