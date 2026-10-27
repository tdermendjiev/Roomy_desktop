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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 780, minHeight: 520)
        }
        .defaultSize(width: 900, height: 600)
    }
}
