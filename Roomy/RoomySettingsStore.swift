//
//  RoomySettingsStore.swift
//  Roomy
//
//  S09 — persisted app preferences (roomy_11_s09_s10).
//

import Foundation
import RoomyCore
import SwiftUI

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
