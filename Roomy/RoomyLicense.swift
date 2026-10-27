//
//  RoomyLicense.swift
//  Roomy
//
//  Mac app license: scanning is free, cleaning needs a license. Keys are `ROOMY1.` tokens
//  (RoomyFleet's format) with edition "mac", signed by a Mac-only key pair so the
//  purchase backend never holds the Fleet issuing key. Checked offline.
//  Anyone who used Roomy before licensing shipped (1.3 and earlier) is grandfathered.
//

import Combine
import CryptoKit
import Foundation
import RoomyFleet
import Security

enum RoomyLicenseState: Equatable {
    case licensed(email: String)
    case grandfathered
    case unlicensed

    var canClean: Bool { self != .unlicensed }
}

/// Where the token and the grandfathering decision are kept. Keychain in the app, memory in tests.
protocol RoomyLicenseStorage {
    func read(_ account: String) -> String?
    func write(_ account: String, _ value: String?)
}

@MainActor
final class RoomyLicenseStore: ObservableObject {
    static let shared = RoomyLicenseStore()

    /// Public half of the Mac license key pair (`roomy-licensetool keygen`). The private
    /// half lives only with the purchase backend.
    static let publicKeyBase64 = "ytxbqqV6lsP9wEpKBfmo9ryEsoAFpS5gfdg2R8OXMcY="
    static let edition = "mac"

    /// UserDefaults keys that only exist if a pre-license version of Roomy ran on this Mac.
    static let priorUseDefaultsKeys = ["roomy.hasCompletedScan", "roomy.appSettings.v1", "roomy.lastScanSummary.v1"]

    private static let tokenAccount = "license-token"
    private static let originAccount = "license-origin"

    @Published private(set) var state: RoomyLicenseState = .unlicensed

    private let storage: RoomyLicenseStorage
    private let publicKey: Curve25519.Signing.PublicKey

    init(
        storage: RoomyLicenseStorage = RoomyKeychainStorage(),
        defaults: UserDefaults = .standard,
        publicKeyBase64: String = RoomyLicenseStore.publicKeyBase64
    ) {
        self.storage = storage
        // The key is a compile-time constant; a bad one is a build mistake, not a runtime condition.
        self.publicKey = try! Curve25519.Signing.PublicKey(rawRepresentation: Data(base64Encoded: publicKeyBase64)!)

        // Decide once, on the first launch of a licensing-aware build, before this launch writes any defaults.
        if storage.read(Self.originAccount) == nil {
            let usedBefore = Self.priorUseDefaultsKeys.contains { defaults.object(forKey: $0) != nil }
            storage.write(Self.originAccount, usedBefore ? "grandfathered" : "new")
        }
        state = resolveState()
    }

    /// Validates and stores a pasted key. Returns a user-facing error message on failure.
    @discardableResult
    func activate(key: String) -> String? {
        let token = key.trimmingCharacters(in: .whitespacesAndNewlines)
        switch verify(token) {
        case .success:
            storage.write(Self.tokenAccount, token)
            state = resolveState()
            return nil
        case .failure(let message):
            return message
        }
    }

    func deactivate() {
        storage.write(Self.tokenAccount, nil)
        state = resolveState()
    }

    var storedKey: String? { storage.read(Self.tokenAccount) }

    private enum Verification {
        case success(LicensePayload)
        case failure(String)
    }

    private func verify(_ token: String) -> Verification {
        guard !token.isEmpty else { return .failure("Paste the license key from your purchase email.") }
        do {
            let payload = try LicenseVerifier.verify(token: token, publicKey: publicKey)
            guard payload.edition == Self.edition else {
                return .failure("This is not a Roomy for Mac license key.")
            }
            return .success(payload)
        } catch LicenseError.malformed, LicenseError.badSignature {
            return .failure("This license key is not valid. Check that you copied all of it.")
        } catch {
            return .failure((error as? LocalizedError)?.errorDescription ?? "This license key could not be checked.")
        }
    }

    private func resolveState() -> RoomyLicenseState {
        if let token = storage.read(Self.tokenAccount), case .success(let payload) = verify(token) {
            return .licensed(email: payload.org)
        }
        return storage.read(Self.originAccount) == "grandfathered" ? .grandfathered : .unlicensed
    }
}

/// Generic-password items under the app's bundle identifier. Kept in the Keychain rather than
/// UserDefaults so reinstalling or deleting preferences does not change the license state.
struct RoomyKeychainStorage: RoomyLicenseStorage {
    var service = Bundle.main.bundleIdentifier ?? "com.teodordermendzhiev.roomy"

    func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func write(_ account: String, _ value: String?) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        guard let value else { return }
        var add = base
        add[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(add as CFDictionary, nil)
    }
}
