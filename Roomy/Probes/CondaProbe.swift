//
//  CondaProbe.swift
//  Roomy
//

import Foundation

struct CondaProbe: SystemArtifactProbe {
    let categoryKey = "python"

    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        guard resolveCondaExecutable(home: home) != nil else { return [] }
        if shouldCancel() { return [] }

        var findings: [ScanArtifactFinding] = []

        let cleanTargets: [(args: [String], label: String, deletionKey: String)] = [
            (["clean", "--packages", "--dry-run"], "Conda unused packages", "conda:clean:packages"),
            (["clean", "--tarballs", "--dry-run"], "Conda tarballs", "conda:clean:tarballs"),
            (["clean", "--index-cache", "--dry-run"], "Conda index cache", "conda:clean:index-cache"),
        ]

        for target in cleanTargets {
            if shouldCancel() { break }
            if let finding = await condaCleanFinding(
                args: target.args,
                label: target.label,
                deletionKey: target.deletionKey
            ) {
                findings.append(finding)
            }
        }

        findings.append(contentsOf: await dormantCondaEnvironments(
            exclusionFilter: exclusionFilter,
            shouldCancel: shouldCancel
        ))

        return findings
    }

    private func resolveCondaExecutable(home: URL) -> String? {
        if let path = SystemProbeHelpers.which("conda") { return path }
        let candidates = [
            home.appendingPathComponent("miniconda3/bin/conda").path,
            home.appendingPathComponent("anaconda3/bin/conda").path,
            home.appendingPathComponent("miniforge3/bin/conda").path,
            home.appendingPathComponent("mambaforge/bin/conda").path,
            home.appendingPathComponent("micromamba/bin/conda").path,
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func runConda(_ arguments: [String]) -> String? {
        SystemProbeHelpers.runCommand(executable: "/usr/bin/env", arguments: ["conda"] + arguments, timeout: 15)
    }

    private func condaCleanFinding(args: [String], label: String, deletionKey: String) async -> ScanArtifactFinding? {
        guard let output = runConda(args) else { return nil }
        let lower = output.lowercased()
        if lower.contains("there are no") || lower.contains("nothing to") { return nil }

        let parsedSize = SystemProbeHelpers.parseSizeFromCondaDryRun(output)
        let size = parsedSize ?? SystemProbeHelpers.minBytes
        guard size >= SystemProbeHelpers.minBytes else { return nil }

        return SystemProbeHelpers.finding(
            path: deletionKey,
            label: label,
            sizeBytes: size,
            ecosystemTag: "py",
            groupRoot: RoomySystemGroupRoot.python,
            source: .condaCLI,
            restoreHint: "conda install or conda env update re-downloads as needed"
        )
    }

    private func dormantCondaEnvironments(
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding] {
        guard let json = runConda(["env", "list", "--json"]),
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let envs = object["envs"] as? [String] else { return [] }

        var findings: [ScanArtifactFinding] = []
        for envPath in envs {
            if shouldCancel() { break }
            let url = URL(fileURLWithPath: envPath, isDirectory: true)
            if exclusionFilter.shouldExcludeDirectory(url: url) { continue }
            guard SystemProbeHelpers.pathExists(envPath) else { continue }

            let size = await Task.detached {
                RoomyDirectorySizeReader.bytes(at: url)
            }.value
            guard let size, size >= SystemProbeHelpers.minBytes else { continue }

            let envName: String
            if let base = runConda(["info", "--base"])?.trimmingCharacters(in: .whitespacesAndNewlines),
               envPath == base {
                continue // never offer base env deletion
            } else {
                envName = URL(fileURLWithPath: envPath).lastPathComponent
            }

            findings.append(
                SystemProbeHelpers.finding(
                    path: "conda:env:\(envName)",
                    label: "conda env: \(envName)",
                    sizeBytes: size,
                    ecosystemTag: "py",
                    groupRoot: RoomySystemGroupRoot.python,
                    source: .condaCLI,
                    safetyTier: .caution,
                    restoreHint: "conda env create -f environment.yml if you exported one",
                    lastActivityDate: RoomyDirectorySizeReader.modificationDate(at: url)
                )
            )
        }
        return findings
    }
}
