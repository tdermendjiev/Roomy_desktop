//
//  PyenvProbe.swift
//  Roomy
//

import Foundation

struct PyenvProbe: SystemArtifactProbe {
    let categoryKey = "python"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        let versionsRoot = home.appendingPathComponent(".pyenv/versions", isDirectory: true)
        guard SystemProbeHelpers.pathExists(versionsRoot.path) else { return [] }
        if exclusionFilter.shouldExcludeDirectory(url: versionsRoot) { return [] }

        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: versionsRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let dirs = entries.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
        if dirs.isEmpty || shouldCancel() { return [] }

        let sizes = await RoomyDirectorySizeReader.bytesConcurrently(
            urls: dirs,
            shouldCancel: shouldCancel
        )

        return dirs.compactMap { url in
            guard let size = sizes[url] else { return nil }
            let version = url.lastPathComponent
            return SystemProbeHelpers.finding(
                path: url.path,
                label: "pyenv \(version)",
                sizeBytes: size,
                ecosystemTag: "py",
                groupRoot: RoomySystemGroupRoot.python,
                safetyTier: .caution,
                restoreHint: "pyenv install \(version)",
                lastActivityDate: RoomyDirectorySizeReader.modificationDate(at: url)
            )
        }
    }
}
