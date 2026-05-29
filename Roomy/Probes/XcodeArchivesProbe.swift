//
//  XcodeArchivesProbe.swift
//  Roomy
//

import Foundation

struct XcodeArchivesProbe: SystemArtifactProbe {
    let categoryKey = "xcode"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        let archivesRoot = home
            .appendingPathComponent("Library/Developer/Xcode/Archives", isDirectory: true)
        guard SystemProbeHelpers.pathExists(archivesRoot.path) else { return [] }
        if exclusionFilter.shouldExcludeDirectory(url: archivesRoot) { return [] }

        var xcarchives: [URL] = []
        collectXCArchives(under: archivesRoot, into: &xcarchives, shouldCancel: shouldCancel)
        if xcarchives.isEmpty { return [] }

        let sizes = await RoomyDirectorySizeReader.bytesConcurrently(
            urls: xcarchives,
            shouldCancel: shouldCancel
        )

        return xcarchives.compactMap { url in
            guard let size = sizes[url] else { return nil }
            let name = url.deletingPathExtension().lastPathComponent
            let mdate = RoomyDirectorySizeReader.modificationDate(at: url)
            return SystemProbeHelpers.finding(
                path: url.path,
                label: "Archive: \(name)",
                sizeBytes: size,
                ecosystemTag: "swift",
                groupRoot: RoomySystemGroupRoot.xcode,
                safetyTier: .warning,
                restoreHint: "Cannot be restored — re-archive from Xcode if needed",
                lastActivityDate: mdate
            )
        }
    }

    private func collectXCArchives(under url: URL, into result: inout [URL], shouldCancel: () -> Bool) {
        if shouldCancel() { return }
        if url.pathExtension == "xcarchive" {
            result.append(url)
            return
        }
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        for entry in entries {
            if shouldCancel() { return }
            let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                collectXCArchives(under: entry, into: &result, shouldCancel: shouldCancel)
            }
        }
    }
}
