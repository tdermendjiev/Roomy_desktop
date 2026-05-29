//
//  RoomySystemScanCategories.swift
//  Roomy
//

import Foundation

/// Synthetic project-root keys for system artifact groups in `artifactsByProjectRoot`.
enum RoomySystemGroupRoot {
    static let xcode = "__roomy:system:xcode__"
    static let caches = "__roomy:system:caches__"
    static let globalModules = "__roomy:system:global_modules__"
    static let homebrew = "__roomy:system:homebrew__"
    static let python = "__roomy:system:python__"
    static let docker = "__roomy:system:docker__"

    static let allKeys: Set<String> = [xcode, caches, globalModules, homebrew, python, docker]

    static func displayName(for rootKey: String) -> String {
        switch rootKey {
        case xcode: "Xcode & iOS tooling"
        case caches: "Global package caches"
        case globalModules: "Global CLI packages"
        case homebrew: "Homebrew"
        case python: "Python tooling"
        case docker: "Docker"
        default: URL(fileURLWithPath: rootKey).lastPathComponent
        }
    }

    static func isSystemRoot(_ path: String) -> Bool {
        allKeys.contains(path)
    }
}

enum RoomySystemScanCategories {
    static let all: [(key: String, name: String, detail: String)] = [
        ("xcode", "Xcode & iOS tooling", "DerivedData, simulators, device support, archives"),
        ("globalCaches", "Global package caches", "npm, pip, yarn, pnpm, NuGet, Poetry, uv"),
        ("globalModules", "Global CLI packages", "npm and yarn globally installed tools"),
        ("python", "Python / Conda", "Conda unused packages, tarballs, dormant envs, pyenv"),
        ("homebrew", "Homebrew", "Download caches and logs"),
        ("docker", "Docker", "Unused images, volumes, build cache"),
    ]

    static func defaultEnabledMap() -> [String: Bool] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.key, true) })
    }
}
