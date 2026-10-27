//
//  LicenseTool.swift
//  roomy-licensetool
//
//  Issuer-side tool. Not shipped in packages. Keep the private key offline.
//

import ArgumentParser
import Crypto
import Foundation
import RoomyFleet

@main
struct LicenseTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "roomy-licensetool",
        abstract: "Mint and verify Roomy Fleet license tokens (Ed25519).",
        subcommands: [Keygen.self, Sign.self, Verify.self, Inspect.self]
    )

    struct Keygen: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Generate a signing key pair. Prints the public key to embed in RoomyFleet/License.swift.")
        @Option(name: .long, help: "Where to write the private key (base64 raw, mode 0600).") var out: String

        func run() throws {
            let key = Curve25519.Signing.PrivateKey()
            let url = URL(fileURLWithPath: (out as NSString).expandingTildeInPath)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try key.rawRepresentation.base64EncodedString().write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            print("private key written to \(url.path)")
            print("public key (base64): \(key.publicKey.rawRepresentation.base64EncodedString())")
        }
    }

    struct Sign: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Issue a license token.")
        @Option(name: .long, help: "Private key file from keygen.") var key: String
        @Option(name: .long) var org: String
        @Option(name: .long) var maxHosts: Int = 25
        @Option(name: .long, help: "Validity in days.") var days: Int = 365
        @Option(name: .long) var edition: String = "fleet"
        @Option(name: .long, help: "License id. Default: random UUID.") var id: String?
        @Option(name: .long, parsing: .upToNextOption) var features: [String] = ["policy", "audit", "metrics", "serve"]

        func run() throws {
            let raw = try String(contentsOf: URL(fileURLWithPath: (key as NSString).expandingTildeInPath), encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = Data(base64Encoded: raw) else { throw ValidationError("key file is not base64") }
            let priv = try Curve25519.Signing.PrivateKey(rawRepresentation: data)
            let payload = LicensePayload(id: id ?? UUID().uuidString.lowercased(), org: org, edition: edition, maxHosts: maxHosts,
                                         issuedAt: Date(), expiresAt: Date().addingTimeInterval(Double(days) * 86_400), features: features)
            print(try LicenseVerifier.sign(payload: payload, privateKey: priv))
        }
    }

    struct Verify: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Verify a token against the compiled-in public key (or --public-key).")
        @Argument var token: String
        @Option(name: .long, help: "Base64 public key to verify against instead of the compiled-in one.") var publicKey: String?

        func run() throws {
            let payload: LicensePayload
            if let pk = publicKey, let data = Data(base64Encoded: pk) {
                payload = try LicenseVerifier.verify(token: token, publicKey: try Curve25519.Signing.PublicKey(rawRepresentation: data))
            } else {
                payload = try LicenseVerifier.verify(token: token)
            }
            let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]; e.dateEncodingStrategy = .iso8601
            print("valid"); print(String(decoding: try e.encode(payload), as: UTF8.self))
        }
    }

    struct Inspect: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Decode a token's payload without verifying it.")
        @Argument var token: String
        func run() throws {
            let parts = token.split(separator: ".")
            guard parts.count == 3, let data = Base64URL.decode(String(parts[1])), let s = String(data: data, encoding: .utf8) else {
                throw ValidationError("malformed token")
            }
            print(s)
        }
    }
}
