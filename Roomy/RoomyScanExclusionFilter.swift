//
//  RoomyScanExclusionFilter.swift
//  Roomy
//
//  Applies S10 exclusions during filesystem scan (prefix paths + fnmatch globs).
//  v1 limitation: `**` in a pattern is simplified to `*` before matching, so recursive
//  “any depth” globs are not fully supported; prefer explicit path prefixes for deep trees.
//

import Darwin
import Foundation

struct RoomyScanExclusionFilter: Sendable {
    /// Longest first so nested paths match correctly when iterating.
    private let pathPrefixes: [String]
    private let globPatterns: [String]

    static let empty = RoomyScanExclusionFilter(pathPrefixes: [], globPatterns: [])

    init(entries: [ExclusionEntry], homeDirectory: URL) {
        var prefixes: [String] = []
        var globs: [String] = []
        let homePath = homeDirectory.path

        for entry in entries {
            let display = entry.pathDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !display.isEmpty else { continue }

            switch entry.kind {
            case .path, .project:
                let abs = Self.absoluteNormalizedPath(display: display, homePath: homePath)
                if !abs.isEmpty {
                    prefixes.append(abs)
                }
            case .pattern:
                if Self.looksLikeGlob(display) {
                    let expanded = Self.expandTildeInPattern(display, homePath: homePath)
                    let simplified = expanded.replacingOccurrences(of: "**", with: "*")
                    if !simplified.isEmpty {
                        globs.append(simplified)
                    }
                } else {
                    let abs = Self.absoluteNormalizedPath(display: display, homePath: homePath)
                    if !abs.isEmpty {
                        prefixes.append(abs)
                    }
                }
            }
        }

        pathPrefixes = Array(Set(prefixes)).sorted { $0.count > $1.count }
        globPatterns = Array(Set(globs))
    }

    private init(pathPrefixes: [String], globPatterns: [String]) {
        self.pathPrefixes = pathPrefixes
        self.globPatterns = globPatterns
    }

    func shouldExcludeDirectory(url: URL) -> Bool {
        let path = Self.normalizePath(url.standardizedFileURL.path)
        guard !path.isEmpty else { return false }

        for prefix in pathPrefixes {
            if path == prefix || path.hasPrefix(prefix + "/") {
                return true
            }
        }

        for pattern in globPatterns {
            if Self.pathMatchesGlob(pattern: pattern, path: path) {
                return true
            }
        }
        return false
    }

    // MARK: - Paths

    private static func absoluteNormalizedPath(display: String, homePath: String) -> String {
        let expanded: String
        if display == "~" {
            expanded = homePath
        } else if display.hasPrefix("~/") {
            expanded = homePath + "/" + String(display.dropFirst(2))
        } else {
            expanded = (display as NSString).expandingTildeInPath
        }
        let std = URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL.path
        return normalizePath(std)
    }

    private static func normalizePath(_ path: String) -> String {
        if path.isEmpty { return path }
        if path == "/" { return path }
        var p = path
        while p.hasSuffix("/") {
            p.removeLast()
        }
        return p
    }

    private static func expandTildeInPattern(_ pattern: String, homePath: String) -> String {
        if pattern == "~" { return homePath }
        if pattern.hasPrefix("~/") {
            return homePath + "/" + String(pattern.dropFirst(2))
        }
        return pattern
    }

    private static func looksLikeGlob(_ s: String) -> Bool {
        s.contains("*") || s.contains("?") || s.contains("[")
    }

    // MARK: - Glob (fnmatch + path tails)

    private static func pathMatchesGlob(pattern: String, path: String) -> Bool {
        let flags = FNM_PATHNAME
        if fnmatch(pattern, path, flags) == 0 {
            return true
        }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        if fnmatch(pattern, trimmed, flags) == 0 {
            return true
        }
        let parts = trimmed.split(separator: "/")
        guard parts.count > 1 else { return false }
        for drop in 1..<parts.count {
            let tail = parts.dropFirst(drop).joined(separator: "/")
            if fnmatch(pattern, tail, flags) == 0 {
                return true
            }
        }
        return false
    }
}
