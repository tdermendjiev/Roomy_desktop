//
//  RoomyApp.swift
//  Roomy
//
//  Created by Teodor Dermendzhiev on 17.04.26.
//

import SwiftUI
import RoomyCore

@main
struct RoomyApp: App {
    @StateObject private var updater = RoomyUpdater.shared

    init() {
        // Grandfathering looks for defaults left by earlier versions, so decide before this launch writes any.
        _ = RoomyLicenseStore.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 780, minHeight: 520)
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheckForUpdates)
            }
        }
    }
}
