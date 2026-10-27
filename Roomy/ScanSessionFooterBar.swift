//
//  ScanSessionFooterBar.swift
//  Roomy
//
//  Shared footer for S03 / S04 / S05 — scan context + re-scan + settings (roomy_06).
//

import SwiftUI
import RoomyCore

struct ScanSessionFooterBar: View {
    var summary: ScanResultsSummary
    var onRescan: () -> Void
    var onChangeScanSettings: () -> Void

    var body: some View {
        HStack {
            Text(leftCaption)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            Spacer(minLength: 16)
            HStack(spacing: 4) {
                Button("Re-scan", action: onRescan)
                    .buttonStyle(.roomyGhost)
                Text("·")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                Button("Change scan settings", action: onChangeScanSettings)
                    .buttonStyle(.roomyGhost)
            }
            .font(.system(size: 12, weight: .regular))
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(Color.roomyElevated)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
    }

    private var leftCaption: String {
        let path = summary.scannedPathLabel
        let total = String(format: "%.1f", summary.totalRecoverableGB)
        return "Scanned \(path) · \(summary.projectCount) projects · \(total) GB total"
    }
}
