//
//  RoomyLicenseTests.swift
//  RoomyTests
//

import CryptoKit
import Foundation
import RoomyFleet
import Testing
@testable import Roomy

private final class MemoryStorage: RoomyLicenseStorage {
    var values: [String: String] = [:]
    func read(_ account: String) -> String? { values[account] }
    func write(_ account: String, _ value: String?) { values[account] = value }
}

@MainActor
struct RoomyLicenseTests {
    let signingKey = Curve25519.Signing.PrivateKey()
    var publicKeyBase64: String { signingKey.publicKey.rawRepresentation.base64EncodedString() }

    func emptyDefaults() -> UserDefaults {
        let name = "roomy.license.tests.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func token(edition: String = "mac", email: String = "buyer@example.com", key: Curve25519.Signing.PrivateKey? = nil) throws -> String {
        let payload = LicensePayload(org: email, edition: edition, maxHosts: 0,
                                     expiresAt: Date(timeIntervalSince1970: 4_102_444_800), features: ["mac"])
        return try LicenseVerifier.sign(payload: payload, privateKey: key ?? signingKey)
    }

    @Test func newUserIsUnlicensed() {
        let store = RoomyLicenseStore(storage: MemoryStorage(), defaults: emptyDefaults(), publicKeyBase64: publicKeyBase64)
        #expect(store.state == .unlicensed)
        #expect(!store.state.canClean)
    }

    @Test func earlierUserIsGrandfathered() {
        let defaults = emptyDefaults()
        defaults.set(true, forKey: "roomy.hasCompletedScan")
        let store = RoomyLicenseStore(storage: MemoryStorage(), defaults: defaults, publicKeyBase64: publicKeyBase64)
        #expect(store.state == .grandfathered)
        #expect(store.state.canClean)
    }

    @Test func grandfatheringIsDecidedOnlyOnce() {
        let storage = MemoryStorage()
        let defaults = emptyDefaults()
        _ = RoomyLicenseStore(storage: storage, defaults: defaults, publicKeyBase64: publicKeyBase64)
        // A new user scans with the licensed build; that must not grandfather them on the next launch.
        defaults.set(true, forKey: "roomy.hasCompletedScan")
        let relaunched = RoomyLicenseStore(storage: storage, defaults: defaults, publicKeyBase64: publicKeyBase64)
        #expect(relaunched.state == .unlicensed)
    }

    @Test func validKeyUnlocksAndPersists() throws {
        let storage = MemoryStorage()
        let store = RoomyLicenseStore(storage: storage, defaults: emptyDefaults(), publicKeyBase64: publicKeyBase64)
        #expect(store.activate(key: "  \(try token())\n") == nil)
        #expect(store.state == .licensed(email: "buyer@example.com"))
        let relaunched = RoomyLicenseStore(storage: storage, defaults: emptyDefaults(), publicKeyBase64: publicKeyBase64)
        #expect(relaunched.state == .licensed(email: "buyer@example.com"))
        relaunched.deactivate()
        #expect(relaunched.state == .unlicensed)
    }

    @Test func rejectsKeysFromAnotherIssuer() throws {
        let store = RoomyLicenseStore(storage: MemoryStorage(), defaults: emptyDefaults(), publicKeyBase64: publicKeyBase64)
        let foreign = try token(key: Curve25519.Signing.PrivateKey())
        #expect(store.activate(key: foreign) != nil)
        #expect(store.state == .unlicensed)
    }

    @Test func rejectsTamperedAndWrongEditionKeys() throws {
        let store = RoomyLicenseStore(storage: MemoryStorage(), defaults: emptyDefaults(), publicKeyBase64: publicKeyBase64)
        var parts = try token().split(separator: ".").map(String.init)
        parts[1] = Base64URL.encode(Data(#"{"edition":"mac","org":"someone@else"}"#.utf8))
        #expect(store.activate(key: parts.joined(separator: ".")) != nil)
        #expect(store.activate(key: try token(edition: "fleet")) == "This is not a Roomy for Mac license key.")
        #expect(store.activate(key: "not a key") != nil)
        #expect(store.state == .unlicensed)
    }

    @Test func shippedPublicKeyIsUsable() {
        let store = RoomyLicenseStore(storage: MemoryStorage(), defaults: emptyDefaults())
        #expect(store.state == .unlicensed)
    }
}
