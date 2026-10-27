//
//  RoomyUpdater.swift
//  Roomy
//
//  Sparkle wrapper. Feed URL and EdDSA public key live in Config/Roomy-Info.plist;
//  updates are signed with the private key in the release machine's Keychain
//  (generate_keys --account roomy).
//

import Combine
import Sparkle

@MainActor
final class RoomyUpdater: ObservableObject {
    static let shared = RoomyUpdater()

    @Published private(set) var canCheckForUpdates = false

    private let controller: SPUStandardUpdaterController
    private var cancellable: AnyCancellable?

    private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        cancellable = controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.canCheckForUpdates = $0 }
    }

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            controller.updater.automaticallyChecksForUpdates = newValue
            objectWillChange.send()
        }
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
