//
//  RoomyDirectorySizeReader.swift
//  Roomy
//

import Foundation

enum RoomyDirectorySizeReader {
    static let defaultTimeout: TimeInterval = 20
    static let minimumBytes: Int64 = 1_048_576 // 1 MB

    /// Returns directory size in bytes via `du -sk`, or nil on failure.
    static func bytes(at url: URL, timeout: TimeInterval = defaultTimeout) -> Int64? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        p.arguments = ["-sk", url.path]
        let pipe = Pipe()
        p.standardOutput = pipe
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
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let line = String(data: data, encoding: .utf8)?
            .split(whereSeparator: \.isWhitespace)
            .first,
            let kb = Int64(line) else {
            return nil
        }
        return kb * 1024
    }

    /// Sizes multiple paths concurrently (max 8 at a time).
    static func bytesConcurrently(
        urls: [URL],
        maxConcurrent: Int = 8,
        timeout: TimeInterval = defaultTimeout,
        shouldCancel: @escaping @Sendable () -> Bool = { false }
    ) async -> [URL: Int64] {
        await withTaskGroup(of: (URL, Int64?).self) { group in
            var results: [URL: Int64] = [:]
            var index = 0
            var inFlight = 0

            func enqueueNext() {
                while inFlight < maxConcurrent, index < urls.count {
                    if shouldCancel() { return }
                    let url = urls[index]
                    index += 1
                    inFlight += 1
                    group.addTask {
                        let size = await Task.detached {
                            bytes(at: url, timeout: timeout)
                        }.value
                        return (url, size)
                    }
                }
            }

            enqueueNext()
            for await (url, size) in group {
                inFlight -= 1
                if let size, size >= minimumBytes {
                    results[url] = size
                }
                if shouldCancel() { break }
                enqueueNext()
            }
            return results
        }
    }

    static func modificationDate(at url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}
