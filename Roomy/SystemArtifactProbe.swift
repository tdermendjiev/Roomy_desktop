//
//  SystemArtifactProbe.swift
//  Roomy
//

import Foundation

protocol SystemArtifactProbe: Sendable {
    var categoryKey: String { get }
    func scan(
        home: URL,
        exclusionFilter: RoomyScanExclusionFilter,
        shouldCancel: @escaping @Sendable () -> Bool
    ) async -> [ScanArtifactFinding]
}

enum SystemProbeHelpers {
    static let minBytes = RoomyDirectorySizeReader.minimumBytes

    static func finding(
        path: String,
        label: String,
        sizeBytes: Int64,
        ecosystemTag: String,
        groupRoot: String,
        source: ArtifactSource = .systemProbe,
        safetyTier: ArtifactSafetyTier = .safe,
        restoreHint: String? = nil,
        lastActivityDate: Date? = nil
    ) -> ScanArtifactFinding {
        ScanArtifactFinding(
            path: path,
            label: label,
            sizeBytes: sizeBytes,
            ecosystemTag: ecosystemTag,
            groupRoot: groupRoot,
            source: source,
            safetyTier: safetyTier,
            restoreHint: restoreHint,
            lastActivityDate: lastActivityDate
        )
    }

    static func pathExists(_ path: String, isDirectory: Bool = true) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { return false }
        return isDirectory ? isDir.boolValue : true
    }

    static func runCommand(
        executable: String,
        arguments: [String],
        timeout: TimeInterval = 8
    ) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: executable)
        p.arguments = arguments
        let outPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = Pipe()
        do {
            try p.run()
        } catch {
            return nil
        }
        let deadline = Date().addingTimeInterval(timeout)
        while p.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if p.isRunning {
            p.terminate()
            p.waitUntilExit()
            return nil
        }
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func which(_ name: String) -> String? {
        runCommand(executable: "/usr/bin/which", arguments: [name], timeout: 3)
    }

    static func parseSizeFromCondaDryRun(_ output: String) -> Int64? {
        // "Will remove 123 (456 MB)" or "There are no ..."
        let lower = output.lowercased()
        if lower.contains("there are no") || lower.contains("nothing to") { return 0 }
        if let mbRange = lower.range(of: #"(\d+(?:\.\d+)?)\s*mb"#, options: .regularExpression) {
            let snippet = String(lower[mbRange])
            let digits = snippet.filter { $0.isNumber || $0 == "." }
            if let mb = Double(digits) { return Int64(mb * 1_048_576) }
        }
        if let gbRange = lower.range(of: #"(\d+(?:\.\d+)?)\s*gb"#, options: .regularExpression) {
            let snippet = String(lower[gbRange])
            let digits = snippet.filter { $0.isNumber || $0 == "." }
            if let gb = Double(digits) { return Int64(gb * 1_073_741_824) }
        }
        return nil
    }
}
