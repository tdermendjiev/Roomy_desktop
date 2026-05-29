//
//  RoomyDeletionService.swift
//  Roomy
//
//  S07 — move to Trash or permanent delete; CLI targets for Docker/Conda/pip.
//

import Foundation

struct RoomyDeletionFailure: Equatable, Identifiable {
    var id: String { path }
    let path: String
    let message: String
}

enum RoomyDeletionService {
    /// Deletes a single item — filesystem folder or CLI-managed target.
    static func deleteItem(path: String, moveToTrash: Bool) async -> [RoomyDeletionFailure] {
        await Task.detached(priority: .userInitiated) {
            deleteItemSync(path: path, moveToTrash: moveToTrash)
        }.value
    }

    /// Deletes each path in order on a background thread; reports per-path failures.
    static func delete(folderPaths: [String], moveToTrash: Bool) async -> [RoomyDeletionFailure] {
        await Task.detached(priority: .userInitiated) {
            var failures: [RoomyDeletionFailure] = []
            for path in folderPaths {
                failures.append(contentsOf: deleteItemSync(path: path, moveToTrash: moveToTrash))
            }
            return failures
        }.value
    }

    private nonisolated static func deleteItemSync(path: String, moveToTrash: Bool) -> [RoomyDeletionFailure] {
        if path.hasPrefix("docker:") {
            return deleteDockerTarget(path: path)
        }
        if path.hasPrefix("conda:") {
            return deleteCondaTarget(path: path)
        }
        if path.hasPrefix("pip:orphan:") {
            return deletePipOrphanTarget(path: path)
        }
        return deleteFilesystemPath(path: path, moveToTrash: moveToTrash)
    }

    private nonisolated static func deleteFilesystemPath(path: String, moveToTrash: Bool) -> [RoomyDeletionFailure] {
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded, isDirectory: true)
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: expanded, isDirectory: &isDir) else {
            return [RoomyDeletionFailure(path: path, message: "Path not found")]
        }
        if moveToTrash {
            var trashURL: NSURL?
            do {
                try fm.trashItem(at: url, resultingItemURL: &trashURL)
            } catch {
                return [RoomyDeletionFailure(path: path, message: error.localizedDescription)]
            }
        } else {
            do {
                try fm.removeItem(at: url)
            } catch {
                return [RoomyDeletionFailure(path: path, message: error.localizedDescription)]
            }
        }
        return []
    }

    // MARK: - Docker

    private nonisolated static func deleteDockerTarget(path: String) -> [RoomyDeletionFailure] {
        guard let docker = resolveDocker() else {
            return [RoomyDeletionFailure(path: path, message: "Docker not found")]
        }
        if path == "docker:prune:dangling" {
            return runCLI(executable: docker, args: ["image", "prune", "-f"], path: path)
        }
        if path == "docker:prune:buildcache" {
            return runCLI(executable: docker, args: ["builder", "prune", "-f"], path: path)
        }
        if path.hasPrefix("docker:volume:") {
            let name = String(path.dropFirst("docker:volume:".count))
            return runCLI(executable: docker, args: ["volume", "rm", name], path: path)
        }
        return [RoomyDeletionFailure(path: path, message: "Unknown Docker target")]
    }

    // MARK: - Conda

    private nonisolated static func deleteCondaTarget(path: String) -> [RoomyDeletionFailure] {
        if path == "conda:clean:packages" {
            return runCLI(executable: "/usr/bin/env", args: ["conda", "clean", "--packages", "-y"], path: path)
        }
        if path == "conda:clean:tarballs" {
            return runCLI(executable: "/usr/bin/env", args: ["conda", "clean", "--tarballs", "-y"], path: path)
        }
        if path == "conda:clean:index-cache" {
            return runCLI(executable: "/usr/bin/env", args: ["conda", "clean", "--index-cache", "-y"], path: path)
        }
        if path.hasPrefix("conda:env:") {
            let name = String(path.dropFirst("conda:env:".count))
            return runCLI(executable: "/usr/bin/env", args: ["conda", "env", "remove", "-n", name, "-y"], path: path)
        }
        return [RoomyDeletionFailure(path: path, message: "Unknown Conda target")]
    }

    // MARK: - pip orphans

    private nonisolated static func deletePipOrphanTarget(path: String) -> [RoomyDeletionFailure] {
        let venvPath = String(path.dropFirst("pip:orphan:".count))
        let pip = URL(fileURLWithPath: venvPath, isDirectory: true)
            .appendingPathComponent("bin/pip").path
        guard FileManager.default.isExecutableFile(atPath: pip) else {
            return [RoomyDeletionFailure(path: path, message: "pip not found in venv")]
        }
        return runCLI(executable: pip, args: ["cache", "purge"], path: path)
    }

    private nonisolated static func resolveDocker() -> String? {
        ["/opt/homebrew/bin/docker", "/usr/local/bin/docker", SystemProbeHelpers.which("docker")]
            .compactMap { $0 }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private nonisolated static func runCLI(executable: String, args: [String], path: String) -> [RoomyDeletionFailure] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: executable)
        p.arguments = args
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        do {
            try p.run()
        } catch {
            return [RoomyDeletionFailure(path: path, message: error.localizedDescription)]
        }
        p.waitUntilExit()
        if p.terminationStatus == 0 { return [] }
        return [RoomyDeletionFailure(path: path, message: "Command failed (exit \(p.terminationStatus))")]
    }

    /// Empties the user Trash via Finder (may prompt for permissions on some macOS versions).
    static func emptyTrashViaFinder() async -> Bool {
        await Task.detached(priority: .userInitiated) {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            p.arguments = ["-e", #"tell application "Finder" to empty trash"#]
            let err = Pipe()
            p.standardOutput = Pipe()
            p.standardError = err
            do {
                try p.run()
            } catch {
                return false
            }
            p.waitUntilExit()
            return p.terminationStatus == 0
        }.value
    }
}
