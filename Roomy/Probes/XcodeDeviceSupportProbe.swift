//
//  XcodeDeviceSupportProbe.swift
//  Roomy
//

import Foundation

struct XcodeDeviceSupportProbe: SystemArtifactProbe {
    let categoryKey = "xcode"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        let deviceSupport = home
            .appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport", isDirectory: true)
        guard SystemProbeHelpers.pathExists(deviceSupport.path) else { return [] }
        if exclusionFilter.shouldExcludeDirectory(url: deviceSupport) { return [] }

        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: deviceSupport,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
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
            let mdate = RoomyDirectorySizeReader.modificationDate(at: url)
            return SystemProbeHelpers.finding(
                path: url.path,
                label: "DeviceSupport/\(name)",
                sizeBytes: size,
                ecosystemTag: "swift",
                groupRoot: RoomySystemGroupRoot.xcode,
                safetyTier: .caution,
                restoreHint: "Re-connect device; Xcode re-downloads automatically",
                lastActivityDate: mdate
            )
        }
    }
}
