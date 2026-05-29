//
//  GlobalPackageCacheProbe.swift
//  Roomy
//

import Foundation

struct GlobalPackageCacheProbe: SystemArtifactProbe {
    let categoryKey = "globalCaches"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        var candidates: [(URL, String, String, String)] = [
            (home.appendingPathComponent(".npm", isDirectory: true), "npm cache", "npm", "npm cache clean --force"),
            (home.appendingPathComponent(".npm/_cacache", isDirectory: true), "npm _cacache", "npm", "npm cache clean --force"),
            (home.appendingPathComponent(".cache/yarn", isDirectory: true), "yarn cache", "npm", "yarn cache clean"),
            (home.appendingPathComponent(".cache/pip", isDirectory: true), "pip cache", "py", "pip cache purge"),
            (home.appendingPathComponent("Library/Caches/pip", isDirectory: true), "pip cache (Library)", "py", "pip cache purge"),
            (home.appendingPathComponent("Library/Caches/pnpm", isDirectory: true), "pnpm cache", "npm", "pnpm store prune"),
            (home.appendingPathComponent(".local/share/pnpm/store", isDirectory: true), "pnpm store", "npm", "pnpm store prune"),
            (home.appendingPathComponent(".nuget/packages", isDirectory: true), "NuGet packages", "dotnet", "dotnet nuget locals all --clear"),
            (home.appendingPathComponent(".local/share/NuGet/http-cache", isDirectory: true), "NuGet HTTP cache", "dotnet", "dotnet nuget locals http-cache --clear"),
            (home.appendingPathComponent(".nuget/NuGet", isDirectory: true), "NuGet cache", "dotnet", "dotnet nuget locals all --clear"),
            (home.appendingPathComponent("Library/Caches/pypoetry", isDirectory: true), "Poetry cache", "py", "poetry cache clear --all"),
            (home.appendingPathComponent(".cache/uv", isDirectory: true), "uv cache", "py", "uv cache clean"),
            (home.appendingPathComponent("Library/Caches/uv", isDirectory: true), "uv cache (Library)", "py", "uv cache clean"),
        ]

        if let poetryCache = resolvePoetryCacheDir() {
            candidates.append((poetryCache, "Poetry cache (config)", "py", "poetry cache clear --all"))
        }

        let globalPnpm = home.appendingPathComponent(".pnpm-store", isDirectory: true)
        if SystemProbeHelpers.pathExists(globalPnpm.path),
           !isInsideProjectPath(globalPnpm.path, home: home) {
            candidates.append((globalPnpm, "pnpm global store", "npm", "pnpm store prune"))
        }

        var findings: [ScanArtifactFinding] = []
        var seenPaths: Set<String> = []

        for (url, label, eco, restore) in candidates {
            if shouldCancel() { break }
            let path = url.path
            guard !seenPaths.contains(path) else { continue }
            guard SystemProbeHelpers.pathExists(path) else { continue }
            if exclusionFilter.shouldExcludeDirectory(url: url) { continue }

            let size = await Task.detached {
                RoomyDirectorySizeReader.bytes(at: url)
            }.value
            guard let size, size >= SystemProbeHelpers.minBytes else { continue }

            seenPaths.insert(path)
            findings.append(
                SystemProbeHelpers.finding(
                    path: path,
                    label: label,
                    sizeBytes: size,
                    ecosystemTag: eco,
                    groupRoot: RoomySystemGroupRoot.caches,
                    restoreHint: restore
                )
            )
        }
        return findings
    }

    private func resolvePoetryCacheDir() -> URL? {
        guard let out = SystemProbeHelpers.runCommand(
            executable: "/usr/bin/env",
            arguments: ["poetry", "config", "cache-dir"],
            timeout: 5
        ), !out.isEmpty else { return nil }
        return URL(fileURLWithPath: out, isDirectory: true)
    }

    private func isInsideProjectPath(_ path: String, home: URL) -> Bool {
        let projects = ["Projects", "Developer", "workspace", "code", "src"]
        for name in projects {
            if path.contains("/\(name)/") { return true }
        }
        return false
    }
}
