//
//  RoomySettingsStore.swift
//  Roomy
//
//  S09 — persisted app preferences (roomy_11_s09_s10).
//

import Foundation
import SwiftUI

enum RoomyScanDefaultLocation: String, Codable, CaseIterable, Identifiable {
    case home
    case custom
    case entireMac

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home folder (~/)"
        case .custom: "Custom path"
        case .entireMac: "Entire Mac"
        }
    }
}

struct RoomyAppSettings: Codable, Equatable {
    var defaultScanLocation: RoomyScanDefaultLocation
    var customScanPath: String
    var askBeforeEachScan: Bool
    /// Ecosystem keys: npm, py, rust, ruby, go, java, swift, dotnet, general
    var ecosystemsEnabled: [String: Bool]
    var dormantThresholdYears: Int
    var inactiveThresholdMonths: Int
    /// When true, use Trash; when false, permanent delete via `RoomyDeletionService`.
    var moveToTrash: Bool
    var emptyTrashAfterDeletion: Bool
    /// System cache categories: xcode, globalCaches, globalModules, python, homebrew, docker
    var systemScanEnabled: [String: Bool]

    enum CodingKeys: String, CodingKey {
        case defaultScanLocation, customScanPath, askBeforeEachScan, ecosystemsEnabled
        case dormantThresholdYears, inactiveThresholdMonths, moveToTrash, emptyTrashAfterDeletion
        case systemScanEnabled
    }

    init(
        defaultScanLocation: RoomyScanDefaultLocation,
        customScanPath: String,
        askBeforeEachScan: Bool,
        ecosystemsEnabled: [String: Bool],
        dormantThresholdYears: Int,
        inactiveThresholdMonths: Int,
        moveToTrash: Bool,
        emptyTrashAfterDeletion: Bool,
        systemScanEnabled: [String: Bool]
    ) {
        self.defaultScanLocation = defaultScanLocation
        self.customScanPath = customScanPath
        self.askBeforeEachScan = askBeforeEachScan
        self.ecosystemsEnabled = ecosystemsEnabled
        self.dormantThresholdYears = dormantThresholdYears
        self.inactiveThresholdMonths = inactiveThresholdMonths
        self.moveToTrash = moveToTrash
        self.emptyTrashAfterDeletion = emptyTrashAfterDeletion
        self.systemScanEnabled = systemScanEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        defaultScanLocation = try c.decode(RoomyScanDefaultLocation.self, forKey: .defaultScanLocation)
        customScanPath = try c.decode(String.self, forKey: .customScanPath)
        askBeforeEachScan = try c.decode(Bool.self, forKey: .askBeforeEachScan)
        ecosystemsEnabled = try c.decode([String: Bool].self, forKey: .ecosystemsEnabled)
        dormantThresholdYears = try c.decode(Int.self, forKey: .dormantThresholdYears)
        inactiveThresholdMonths = try c.decode(Int.self, forKey: .inactiveThresholdMonths)
        moveToTrash = try c.decode(Bool.self, forKey: .moveToTrash)
        emptyTrashAfterDeletion = try c.decode(Bool.self, forKey: .emptyTrashAfterDeletion)
        systemScanEnabled = try c.decodeIfPresent([String: Bool].self, forKey: .systemScanEnabled)
            ?? RoomySystemScanCategories.defaultEnabledMap()
    }

    static let `default` = RoomyAppSettings(
        defaultScanLocation: .home,
        customScanPath: "",
        askBeforeEachScan: false,
        ecosystemsEnabled: Dictionary(uniqueKeysWithValues: RoomySettingsEcosystems.all.map { ($0.key, true) }),
        dormantThresholdYears: 2,
        inactiveThresholdMonths: 6,
        moveToTrash: true,
        emptyTrashAfterDeletion: false,
        systemScanEnabled: RoomySystemScanCategories.defaultEnabledMap()
    )

    /// Ecosystem keys still enabled for scanning (S09 → `FilesystemArtifactScanner`).
    var enabledEcosystemKeysForScan: Set<String> {
        Set(ecosystemsEnabled.compactMap { key, on in on ? key : nil })
    }

    var enabledSystemScanKeys: Set<String> {
        Set(systemScanEnabled.compactMap { key, on in on ? key : nil })
    }
}

enum RoomySettingsEcosystems {
    static let all: [(key: String, name: String, icon: String)] = [
        ("npm", "Node.js / npm", "cube.box"),
        ("py", "Python", "doc.text"),
        ("rust", "Rust", "gearshape.2"),
        ("ruby", "Ruby", "diamond"),
        ("go", "Go", "hare"),
        ("java", "Java / Kotlin", "cup.and.saucer"),
        ("swift", "Swift / Xcode", "swift"),
        ("dotnet", ".NET / NuGet", "chevron.left.forwardslash.chevron.right"),
        ("general", "General (logs, .DS_Store, temp)", "folder"),
    ]
}

/// Where Settings should return when dismissed.
enum SettingsDismissContext: Equatable {
    case welcome
    case overview
    case projectList(ProjectListEntry)
    case projectDetail(UUID)
    case selectionReview(SelectionReviewScope)
    case deletionSummary(DeletionRunSnapshot)
}

final class RoomySettingsStore: ObservableObject {
    @Published var settings: RoomyAppSettings {
        didSet {
            save()
        }
    }

    private let defaultsKey = "roomy.appSettings.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           var decoded = try? JSONDecoder().decode(RoomyAppSettings.self, from: data) {
            let defaults = RoomyAppSettings.default.ecosystemsEnabled
            for (k, v) in defaults where decoded.ecosystemsEnabled[k] == nil {
                decoded.ecosystemsEnabled[k] = v
            }
            let systemDefaults = RoomyAppSettings.default.systemScanEnabled
            for (k, v) in systemDefaults where decoded.systemScanEnabled[k] == nil {
                decoded.systemScanEnabled[k] = v
            }
            settings = decoded
        } else {
            settings = .default
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    func setEcosystem(_ key: String, enabled: Bool) {
        var s = settings
        s.ecosystemsEnabled[key] = enabled
        settings = s
    }

    func setAllEcosystems(_ enabled: Bool) {
        var s = settings
        for k in RoomySettingsEcosystems.all.map(\.key) {
            s.ecosystemsEnabled[k] = enabled
        }
        settings = s
    }

    func setSystemScan(_ key: String, enabled: Bool) {
        var s = settings
        s.systemScanEnabled[key] = enabled
        settings = s
    }

    func setAllSystemScans(_ enabled: Bool) {
        var s = settings
        for k in RoomySystemScanCategories.all.map(\.key) {
            s.systemScanEnabled[k] = enabled
        }
        settings = s
    }
}
