//
//  XcodeDerivedDataProbe.swift
//  Roomy
//

import Foundation

struct XcodeDerivedDataProbe: SystemArtifactProbe {
    let categoryKey = "xcode"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        let derivedData = home
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
        guard SystemProbeHelpers.pathExists(derivedData.path) else { return [] }
        if exclusionFilter.shouldExcludeDirectory(url: derivedData) { return [] }

        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: derivedData,
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
            let name = url.lastPathComponent
            return SystemProbeHelpers.finding(
                path: url.path,
                label: "DerivedData/\(name)",
                sizeBytes: size,
                ecosystemTag: "swift",
                groupRoot: RoomySystemGroupRoot.xcode,
                restoreHint: "Open project in Xcode and build (⌘B)"
            )
        }
    }
}
