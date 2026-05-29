//
//  CoreSimulatorProbe.swift
//  Roomy
//

import Foundation

struct CoreSimulatorProbe: SystemArtifactProbe {
    let categoryKey = "xcode"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        var findings: [ScanArtifactFinding] = []

        findings.append(contentsOf: await simulatorDevices(
            home: home,
            exclusionFilter: exclusionFilter,
            shouldCancel: shouldCancel
        ))

        let cachesURL = home.appendingPathComponent("Library/Developer/CoreSimulator/Caches", isDirectory: true)
        if SystemProbeHelpers.pathExists(cachesURL.path),
           !exclusionFilter.shouldExcludeDirectory(url: cachesURL) {
            let cacheSize = await Task.detached { RoomyDirectorySizeReader.bytes(at: cachesURL) }.value
            if let cacheSize, cacheSize >= SystemProbeHelpers.minBytes {
                findings.append(
                    SystemProbeHelpers.finding(
                        path: cachesURL.path,
                        label: "CoreSimulator Caches",
                        sizeBytes: cacheSize,
                        ecosystemTag: "swift",
                        groupRoot: RoomySystemGroupRoot.xcode,
                        safetyTier: .safe,
                        restoreHint: "Xcode recreates simulator caches as needed"
                    )
                )
            }
        }

        return findings
    }

    private func simulatorDevices(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        guard let json = SystemProbeHelpers.runCommand(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "list", "devices", "-j"],
            timeout: 10
        ), let data = json.data(using: .utf8),
           let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let devicesByRuntime = root["devices"] as? [String: [[String: Any]]] else {
            return []
        }

        let devicesRoot = home.appendingPathComponent("Library/Developer/CoreSimulator/Devices", isDirectory: true)
        var findings: [ScanArtifactFinding] = []

        for (_, devices) in devicesByRuntime {
            if shouldCancel() { break }
            for device in devices {
                if shouldCancel() { break }
                guard let udid = device["udid"] as? String,
                      let name = device["name"] as? String else { continue }

                let availability = (device["availability"] as? String) ?? (device["isAvailable"] as? Bool == true ? "available" : "unavailable")
                let isUnavailable = availability.lowercased().contains("unavailable") || availability == "(unavailable)"

                let deviceURL = devicesRoot.appendingPathComponent(udid, isDirectory: true)
                guard SystemProbeHelpers.pathExists(deviceURL.path) else { continue }
                if exclusionFilter.shouldExcludeDirectory(url: deviceURL) { continue }

                let size = await Task.detached {
                    RoomyDirectorySizeReader.bytes(at: deviceURL)
                }.value
                guard let size, size >= SystemProbeHelpers.minBytes else { continue }

                var lastBooted: Date?
                if let bootedStr = device["lastBootedAt"] as? String {
                    let formatter = ISO8601DateFormatter()
                    lastBooted = formatter.date(from: bootedStr)
                }

                let tier: ArtifactSafetyTier = isUnavailable ? .safe : .caution
                findings.append(
                    SystemProbeHelpers.finding(
                        path: deviceURL.path,
                        label: "Simulator: \(name)",
                        sizeBytes: size,
                        ecosystemTag: "swift",
                        groupRoot: RoomySystemGroupRoot.xcode,
                        safetyTier: tier,
                        restoreHint: "Create new simulator in Xcode → Devices & Simulators",
                        lastActivityDate: lastBooted ?? RoomyDirectorySizeReader.modificationDate(at: deviceURL)
                    )
                )
            }
        }
        return findings
    }
}
