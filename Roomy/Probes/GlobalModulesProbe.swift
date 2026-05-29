//
//  GlobalModulesProbe.swift
//  Roomy
//

import Foundation

struct GlobalModulesProbe: SystemArtifactProbe {
    let categoryKey = "globalModules"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        var moduleRoots: [(URL, String)] = []

        if let npmGlobal = resolveNpmGlobalModules(home: home) {
            moduleRoots.append((npmGlobal, "Global npm modules"))
        }
        if let yarnGlobal = resolveYarnGlobalModules(home: home) {
            moduleRoots.append((yarnGlobal, "Global yarn modules"))
        }

        var findings: [ScanArtifactFinding] = []
        var seen: Set<String> = []

        for (url, label) in moduleRoots {
            if shouldCancel() { break }
            let path = url.path
            guard !seen.contains(path), SystemProbeHelpers.pathExists(path) else { continue }
            if exclusionFilter.shouldExcludeDirectory(url: url) { continue }

            let size = await Task.detached {
                RoomyDirectorySizeReader.bytes(at: url)
            }.value
            guard let size, size >= SystemProbeHelpers.minBytes else { continue }

            seen.insert(path)
            let packageCount = countTopLevelPackages(at: url)
            let displayLabel = packageCount > 0 ? "\(label) (\(packageCount) packages)" : label

            findings.append(
                SystemProbeHelpers.finding(
                    path: path,
                    label: displayLabel,
                    sizeBytes: size,
                    ecosystemTag: "npm",
                    groupRoot: RoomySystemGroupRoot.globalModules,
                    safetyTier: .caution,
                    restoreHint: "Reinstall with npm install -g or yarn global add",
                    lastActivityDate: RoomyDirectorySizeReader.modificationDate(at: url)
                )
            )
        }
        return findings
    }

    private func resolveNpmGlobalModules(home: URL) -> URL? {
        if let prefix = SystemProbeHelpers.runCommand(
            executable: "/usr/bin/env",
            arguments: ["npm", "prefix", "-g"],
            timeout: 5
        ) {
            let modules = URL(fileURLWithPath: prefix, isDirectory: true)
                .appendingPathComponent("lib/node_modules", isDirectory: true)
            if SystemProbeHelpers.pathExists(modules.path) { return modules }
        }

        let fallbacks = [
            URL(fileURLWithPath: "/opt/homebrew/lib/node_modules", isDirectory: true),
            URL(fileURLWithPath: "/usr/local/lib/node_modules", isDirectory: true),
            home.appendingPathComponent(".npm-global/lib/node_modules", isDirectory: true),
        ]
        for url in fallbacks where SystemProbeHelpers.pathExists(url.path) {
            return url
        }

        let nvmRoot = home.appendingPathComponent(".nvm/versions/node", isDirectory: true)
        if let versions = try? FileManager.default.contentsOfDirectory(at: nvmRoot, includingPropertiesForKeys: nil) {
            for versionDir in versions {
                let modules = versionDir.appendingPathComponent("lib/node_modules", isDirectory: true)
                if SystemProbeHelpers.pathExists(modules.path) { return modules }
            }
        }
        return nil
    }

    private func resolveYarnGlobalModules(home: URL) -> URL? {
        if let globalDir = SystemProbeHelpers.runCommand(
            executable: "/usr/bin/env",
            arguments: ["yarn", "global", "dir"],
            timeout: 5
        ) {
            let modules = URL(fileURLWithPath: globalDir, isDirectory: true)
                .appendingPathComponent("node_modules", isDirectory: true)
            if SystemProbeHelpers.pathExists(modules.path) { return modules }
        }

        if let folder = SystemProbeHelpers.runCommand(
            executable: "/usr/bin/env",
            arguments: ["yarn", "config", "get", "globalFolder"],
            timeout: 5
        ) {
            let modules = URL(fileURLWithPath: folder, isDirectory: true)
                .appendingPathComponent("node_modules", isDirectory: true)
            if SystemProbeHelpers.pathExists(modules.path) { return modules }
        }

        let classic = home.appendingPathComponent(".config/yarn/global/node_modules", isDirectory: true)
        if SystemProbeHelpers.pathExists(classic.path) { return classic }
        return nil
    }

    private func countTopLevelPackages(at url: URL) -> Int {
        (try? FileManager.default.contentsOfDirectory(atPath: url.path))?.filter { name in
            !name.hasPrefix(".")
        }.count ?? 0
    }
}
