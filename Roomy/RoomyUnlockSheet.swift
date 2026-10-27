//
//  RoomyUnlockSheet.swift
//  Roomy
//
//  Shown when an unlicensed user commits a cleanup. Scanning and review stay free.
//

import AppKit
import SwiftUI

struct RoomyUnlockSheet: View {
    @ObservedObject var license: RoomyLicenseStore
    /// Bytes the pending cleanup would free; nil when opened from Settings.
    var pendingBytes: Int64?
    var onUnlocked: () -> Void
    var onCancel: () -> Void

    @State private var key = ""
    @State private var error: String?

    private var headline: String {
        guard let pendingBytes, pendingBytes > 0 else { return "Unlock cleaning" }
        let size = ByteCountFormatter.string(fromByteCount: pendingBytes, countStyle: .file)
        return "Free up \(size) with Roomy"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(headline)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
            Text("Scanning is free. Cleaning needs a one-time license: \(RoomyMarketingLinks.price), no subscription, free updates through 2.x, and a 14-day refund.")
                .font(.system(size: 13))
                .foregroundStyle(Color.roomyTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Button {
                if let url = URL(string: RoomyMarketingLinks.buy) { NSWorkspace.shared.open(url) }
            } label: {
                Text("Buy Roomy · \(RoomyMarketingLinks.price)").frame(maxWidth: .infinity)
            }
            .buttonStyle(.roomyPrimary)
            .padding(.top, 20)

            Divider().padding(.vertical, 20)

            Text("Already bought it? Paste the key from your purchase email.")
                .font(.system(size: 12))
                .foregroundStyle(Color.roomyTextTertiary)
            HStack(spacing: 8) {
                TextField("ROOMY1.…", text: $key)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onSubmit(activate)
                Button("Activate", action: activate)
                    .buttonStyle(.roomySecondary)
                    .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 8)
            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.roomyDanger)
                    .padding(.top, 6)
            }

            HStack {
                Button("Lost your key?") {
                    if let url = URL(string: "\(RoomyMarketingLinks.mailtoSupport)?subject=Roomy%20license%20key") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.roomyAccent)
                Spacer()
                Button("Not now", action: onCancel)
                    .buttonStyle(.roomyGhost)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.top, 20)
        }
        .padding(28)
        .frame(width: 440)
        .background(Color.roomyElevated)
    }

    private func activate() {
        error = license.activate(key: key)
        if error == nil { onUnlocked() }
    }
}
