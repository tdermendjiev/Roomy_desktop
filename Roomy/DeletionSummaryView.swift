//
//  DeletionSummaryView.swift
//  Roomy
//
//  S08 — Summary / done (roomy_10_s07_s08_deletion_summary).
//

import AppKit
import RoomyCore
import SwiftUI

struct DeletionSummaryView: View {
    let snapshot: DeletionRunSnapshot
    var onScanAgain: () -> Void
    var onViewTrash: () -> Void
    var onDone: () -> Void
    var onOpenSettings: () -> Void

    @AppStorage("roomy.hasSharedRoomy") private var hasSharedRoomy: Bool = false
    @State private var showShareStrip: Bool = true
    @State private var heroScale: CGFloat = 0.9

    private var totalGBStr: String {
        String(format: "%.1f", snapshot.totalGB)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)
            heroZone
                .scaleEffect(heroScale)
            if !snapshot.deletionFailures.isEmpty {
                deletionFailuresBanner
                    .padding(.top, 20)
            }
            Spacer().frame(height: 32)
            beforeAfterZone
            Spacer().frame(height: 32)
            breakdownZone
            Spacer().frame(height: 32)
            actionsZone
            if showShareStrip && !hasSharedRoomy {
                shareZone
                    .padding(.top, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Spacer().frame(height: 48)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.roomyBackground)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    if let img = NSApplication.shared.applicationIconImage {
                        Image(nsImage: img)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.roomyTextSecondary)
                    }
                    Text("Roomy")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.roomyTextSecondary)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape", action: onOpenSettings)
                    .help("Settings")
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.roomyTextSecondary)
            }
        })
        .onAppear {
            if hasSharedRoomy { showShareStrip = false }
            heroScale = 0.9
            withAnimation(.easeOut(duration: 0.6)) {
                heroScale = 1
            }
        }
    }

    private var heroZone: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(totalGBStr)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .monospacedDigit()
                Text("GB")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
            Text("reclaimed")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .padding(.top, 10)
            Text("Across \(snapshot.projectCount) projects · \(snapshot.folderCount) folders deleted")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
        .frame(maxWidth: 520)
    }

    private var deletionFailuresBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Some items could not be removed")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.roomyDanger)
            ForEach(snapshot.deletionFailures) { failure in
                Text("\(failure.path) — \(failure.message)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.roomyTextSecondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: 520, alignment: .leading)
        .padding(12)
        .background(Color.roomyDanger.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.roomyDanger.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var beforeAfterZone: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(String(format: "%.0f GB", snapshot.diskUsedBeforeGB))
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                    .monospacedDigit()
                    .frame(minWidth: 72)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                    .padding(.horizontal, 16)
                Text(String(format: "%.1f GB", snapshot.diskUsedAfterGB))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .monospacedDigit()
                    .frame(minWidth: 72)
            }
            HStack {
                Text("Before")
                    .frame(width: 104, alignment: .center)
                Spacer().frame(width: 16 + 16 + 16)
                Text("After")
                    .frame(width: 104, alignment: .center)
            }
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(Color.roomyTextTertiary)

            Text("−\(totalGBStr) GB freed")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roomyAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.roomyAccentSubtle)
                .clipShape(Capsule(style: .continuous))
        }
        .frame(maxWidth: 520)
    }

    private var breakdownZone: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(snapshot.ecosystemChunks.enumerated()), id: \.offset) { idx, chunk in
                    HStack(spacing: 4) {
                        if idx > 0 {
                            Text("·")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.roomyTextSecondary)
                                .padding(.horizontal, 6)
                        }
                        Image(systemName: chunk.iconSystemName)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.roomyTextSecondary)
                        Text("\(chunk.name) \(String(format: "%.1f GB", chunk.gigabytes))")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.roomyTextSecondary)
                    }
                }
            }
            .multilineTextAlignment(.center)

            if let line = snapshot.biggestSaveLine {
                HStack(spacing: 4) {
                    Image(systemName: "star")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                    Text("Biggest save: \(line)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 520)
            }
        }
    }

    private var actionsZone: some View {
        VStack(spacing: 8) {
            Button(action: onScanAgain) {
                Text("Scan again")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roomyOnAccent)
                    .frame(width: 240, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.roomyAccent)
                    )
            }
            .buttonStyle(.plain)
            if snapshot.moveToTrash {
                Button("View in Trash", action: onViewTrash)
                    .buttonStyle(.roomySecondary)
                    .frame(width: 240)
            }
            Button("Done", action: onDone)
                .buttonStyle(.roomyGhost)
                .font(.system(size: 13, weight: .regular))
                .frame(width: 240)
        }
    }

    private var shareZone: some View {
        VStack(spacing: 8) {
            Text("Enjoying Roomy? A tweet helps.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            HStack(spacing: 8) {
                Button("Share on X →", action: shareOnX)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.roomyBorderDefault, lineWidth: 1)
                    )
                    .foregroundStyle(Color.roomyTextPrimary)
                Button("Not now") {
                    withAnimation(.easeOut(duration: 0.15)) {
                        showShareStrip = false
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            }
        }
        .frame(maxWidth: 520)
    }

    private func shareOnX() {
        let body =
            "Just reclaimed \(totalGBStr) GB from dormant projects using Roomy — \(RoomyMarketingLinks.productPage)"
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://twitter.com/intent/tweet?text=\(encoded)") {
            NSWorkspace.shared.open(url)
            hasSharedRoomy = true
            withAnimation(.easeOut(duration: 0.15)) {
                showShareStrip = false
            }
        }
    }
}

#Preview {
    DeletionSummaryPreviewHost()
}

private struct DeletionSummaryPreviewHost: View {
    @StateObject private var session = ProjectBrowserSession()

    var body: some View {
        Group {
            if let snap = DeletionRunSnapshot.build(
                session: session,
                artifactIDs: Set(session.visibleProjects.flatMap(\.artifacts).map(\.id)),
                emptyTrashAfter: false,
                moveToTrash: true,
                diskUsedBeforeGB: RoomyVolumeSpaceReader.fallbackChartGigabytes.used,
                diskTotalGB: RoomyVolumeSpaceReader.fallbackChartGigabytes.total
            ) {
                DeletionSummaryView(
                    snapshot: snap,
                    onScanAgain: {},
                    onViewTrash: {},
                    onDone: {},
                    onOpenSettings: {}
                )
            } else {
                Color.roomyBackground
            }
        }
        .frame(width: 900, height: 600)
        .onAppear {
            session.load(from: .canonical, listEntry: .dormantPreSelected, useSyntheticWhenNoAggregate: true)
        }
    }
}
