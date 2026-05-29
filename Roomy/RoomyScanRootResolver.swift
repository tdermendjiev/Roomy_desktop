//
//  RoomyScanRootResolver.swift
//  Roomy
//
//  Maps S09 scan location settings to a filesystem root and display label (S01/S02/S03).
//

import Foundation

enum RoomyScanRootResolver {
    /// Label shown in scanning/results UI; URL is the enumerator root.
    static func resolve(from settings: RoomyAppSettings) -> (label: String, rootURL: URL) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch settings.defaultScanLocation {
        case .home:
            return ("~/", home)
        case .custom:
            let path = settings.customScanPath.trimmingCharacters(in: .whitespacesAndNewlines)
            if path.isEmpty {
                return ("~/", home)
            }
            let expanded = (path as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
            return (url.path, url)
        case .entireMac:
            // Sandbox is off in current target; scan from volume root. Full-disk scans may require user permission for some paths.
            let root = URL(fileURLWithPath: "/", isDirectory: true)
            return ("Entire Mac", root)
        }
    }

    /// Restores a scan root from a persisted or legacy display label (e.g. last scan).
    static func rootURL(fromDisplayLabel label: String) -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if label == "~/" { return home }
        if label.hasPrefix("~/") {
            let rest = String(label.dropFirst(2)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if rest.isEmpty { return home }
            return home.appendingPathComponent(rest, isDirectory: true)
        }
        if label == "Entire Mac" || label == "/" {
            return URL(fileURLWithPath: "/", isDirectory: true)
        }
        if label == "All user-accessible paths" {
            return URL(fileURLWithPath: "/Users", isDirectory: true)
        }
        if label.hasPrefix("/") {
            return URL(fileURLWithPath: label, isDirectory: true)
        }
        return home
    }
}
