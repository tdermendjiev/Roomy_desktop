//
//  DeletionProgressView.swift
//  Roomy
//
//  S07 — Deletion progress (roomy_10_s07_s08_deletion_summary).
//

import SwiftUI
import RoomyCore

struct DeletionProgressView: View {
    let snapshot: DeletionRunSnapshot
    /// After filesystem work completes; includes any paths that could not be removed.
    var onFinished: ([RoomyDeletionFailure]) -> Void

    @State private var progress: Double = 0
    @State private var foldersDone: Int = 0
    @State private var showCurrentPath: Bool = true
    @State private var runComplete: Bool = false

    private var currentPathDisplay: String {
        guard showCurrentPath, !snapshot.folderPaths.isEmpty else { return "" }
        let idx = min(foldersDone, max(0, snapshot.folderPaths.count - 1))
        return middleTruncateDeletionPath(snapshot.folderPaths[idx])
    }

    private var freedGB: Double {
        progress * snapshot.totalGB
    }

    private var usedNowGB: Double {
        max(0, snapshot.diskUsedBeforeGB - freedGB)
    }

    private var headlineTitle: String {
        snapshot.moveToTrash ? "Moving to Trash…" : "Deleting…"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)
            Text(headlineTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
                .multilineTextAlignment(.center)

            if showCurrentPath && !currentPathDisplay.isEmpty {
                Text(currentPathDisplay)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.roomyTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 480)
                    .padding(.top, 8)
                    .transition(.opacity)
            } else {
                Spacer().frame(height: 21)
            }

            deletionBar
                .padding(.top, 32)

            HStack {
                Spacer()
                Text("\(foldersDone) of \(snapshot.folderCount) folders")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
            .frame(width: 360)
            .padding(.top, 6)

            statsBlock
                .padding(.top, 32)

            diskIndicator
                .padding(.top, 28)

            Spacer().frame(height: 60)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.roomyBackground)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                Text(snapshot.moveToTrash ? "Moving to Trash" : "Deleting")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape") {}
                    .help("Settings")
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.roomyTextTertiary)
                    .disabled(true)
            }
        })
        .task {
            await runDeletionSequence()
        }
    }

    private var deletionBar: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.roomyInset)
                .frame(width: 360, height: 8)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.roomyAccent, Color.roomyAccent.opacity(0.55)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(0, 360 * progress), height: 8)
        }
        .frame(width: 360, height: 8)
        .animation(.easeInOut(duration: 0.2), value: progress)
    }

    private var statsBlock: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(runComplete ? snapshot.folderCount : foldersDone)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .monospacedDigit()
                    .animation(.easeOut(duration: 0.08), value: foldersDone)
                Text(snapshot.moveToTrash ? "Folders moved" : "Folders removed")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
            .frame(width: 120)

            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(width: 1, height: 32)

            VStack(spacing: 4) {
                Text(String(format: "%.1f GB", runComplete ? snapshot.totalGB : freedGB))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.roomyAccent)
                    .monospacedDigit()
                    .animation(.easeOut(duration: 0.08), value: freedGB)
                Text("Space freed so far")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
            .frame(width: 120)
        }
        .frame(width: 240)
    }

    private var diskIndicator: some View {
        let total = snapshot.diskTotalGB
        let usedFrac = usedNowGB / total
        let freedFrac = freedGB / total
        let freeFrac = max(0, 1 - usedFrac - freedFrac)

        return VStack(spacing: 8) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.roomyTextTertiary.opacity(0.35))
                    .frame(width: 320 * CGFloat(usedFrac), height: 6)
                Rectangle()
                    .fill(Color.roomyAccent)
                    .frame(width: 320 * CGFloat(freedFrac), height: 6)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 320 * CGFloat(freeFrac), height: 6)
            }
            .frame(width: 320, height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.roomyBorderSubtle, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: progress)

            Text(String(format: "%.1f GB used → %.1f GB", snapshot.diskUsedBeforeGB, usedNowGB))
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .monospacedDigit()
        }
    }

    private func runDeletionSequence() async {
        let paths = snapshot.folderPaths
        let n = max(1, paths.count)
        var allFailures: [RoomyDeletionFailure] = []

        for (idx, path) in paths.enumerated() {
            let stepFailures = await RoomyDeletionService.deleteItem(
                path: path,
                moveToTrash: snapshot.moveToTrash
            )
            allFailures.append(contentsOf: stepFailures)
            let p = Double(idx + 1) / Double(n)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.12)) {
                    progress = p
                    foldersDone = idx + 1
                }
            }
        }

        if snapshot.emptyTrashAfter && snapshot.moveToTrash {
            let hadFailures = !allFailures.isEmpty
            if !hadFailures {
                _ = await RoomyDeletionService.emptyTrashViaFinder()
            }
        }

        await MainActor.run {
            runComplete = true
            progress = 1
            foldersDone = snapshot.folderCount
            withAnimation(.easeOut(duration: 0.2)) {
                showCurrentPath = false
            }
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            onFinished(allFailures)
        }
    }
}

private func middleTruncateDeletionPath(_ path: String, maxLength: Int = 52) -> String {
    guard path.count > maxLength else { return path }
    let keep = maxLength - 3
    let head = keep / 2
    let tail = keep - head
    let si = path.index(path.startIndex, offsetBy: head)
    let ei = path.index(path.endIndex, offsetBy: -tail)
    return String(path[..<si]) + "…" + String(path[ei...])
}

#Preview {
    DeletionProgressPreviewHost()
}

private struct DeletionProgressPreviewHost: View {
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
                DeletionProgressView(snapshot: snap, onFinished: { _ in })
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
