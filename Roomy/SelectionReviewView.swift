//
//  SelectionReviewView.swift
//  Roomy
//
//  S06 — Selection review (roomy_09_s06_selection_review).
//

import SwiftUI

enum SelectionReviewScope: Equatable {
    case allSelected
    case singleProject(UUID)
}

struct SelectionReviewView: View {
    @ObservedObject var session: ProjectBrowserSession
    var scope: SelectionReviewScope
    /// Directory whose volume supplies the disk chart (same as scan root).
    var volumeAnchorURL: URL
    /// Initial state for the per-run empty Trash toggle (from S09).
    var defaultEmptyTrashAfterDeletion: Bool
    /// When false, S06 explains permanent deletion and hides empty-trash.
    var deletionUsesTrash: Bool
    var onBack: () -> Void
    var onOpenSettings: () -> Void
    /// Invoked when countdown finished and user confirms delete (S07). Includes disk chart numbers for S07/S08.
    var onCommitDelete: (Set<UUID>, Bool, Double, Double) -> Void

    @State private var pendingArtifactIDs: Set<UUID> = []
    @State private var collapsedGroupIDs: Set<UUID> = []
    @State private var emptyTrashAfterDeletion: Bool = false
    @State private var countdownProgress: CGFloat = 0
    @State private var countdownComplete: Bool = false
    @State private var unlockPulse: Bool = false
    @State private var diskTotalGB: Double = RoomyVolumeSpaceReader.fallbackChartGigabytes.total
    @State private var diskUsedBeforeGB: Double = RoomyVolumeSpaceReader.fallbackChartGigabytes.used

    private struct ReviewGroup: Identifiable {
        var id: UUID { project.id }
        let project: ProjectListRowModel
        var artifacts: [ArtifactRowModel]
    }

    private var groups: [ReviewGroup] {
        session.visibleProjects.compactMap { project in
            let arts = project.artifacts.filter { pendingArtifactIDs.contains($0.id) }
            guard !arts.isEmpty else { return nil }
            return ReviewGroup(project: project, artifacts: arts)
        }
        .sorted { $0.project.name.localizedCaseInsensitiveCompare($1.project.name) == .orderedAscending }
    }

    private var pendingBytes: Int64 {
        groups.flatMap(\.artifacts).reduce(0) { $0 + $1.sizeBytes }
    }

    private var pendingGB: Double {
        Double(pendingBytes) / 1_073_741_824
    }

    private var folderCount: Int {
        groups.flatMap(\.artifacts).count
    }

    private var pendingArtifacts: [ArtifactRowModel] {
        groups.flatMap(\.artifacts)
    }

    private var hasWarningTier: Bool {
        pendingArtifacts.contains { $0.safetyTier == .warning }
    }

    private var hasDockerCLI: Bool {
        pendingArtifacts.contains { $0.source == .dockerCLI }
    }

    private var hasCondaCLI: Bool {
        pendingArtifacts.contains { $0.source == .condaCLI }
    }

    private var hasCLIOnlyDeletion: Bool {
        pendingArtifacts.contains { $0.source == .dockerCLI || $0.source == .condaCLI || $0.source == .pipCLI }
    }

    private var projectCount: Int {
        groups.count
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let divider: CGFloat = 1
                let leftW = geo.size.width * 0.65 - divider / 2
                let rightW = geo.size.width - leftW - divider
                HStack(spacing: 0) {
                    leftColumn(width: leftW)
                    Rectangle()
                        .fill(Color.roomyBorderSubtle)
                        .frame(width: divider)
                    rightPanel(width: rightW)
                }
            }
            footerBar
        }
        .background(Color.roomyBackground)
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                Button(action: syncBack) {
                    Text("← Project list")
                }
                .help("Back to project list")
            }
            ToolbarItem(placement: .principal) {
                Text("Review")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape", action: onOpenSettings)
                    .help("Settings")
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.roomyTextSecondary)
            }
        })
        .onAppear {
            emptyTrashAfterDeletion = defaultEmptyTrashAfterDeletion
            seedPending()
            seedCollapsedGroups()
            startCountdownIfNeeded()
        }
        .task(id: volumeAnchorURL) {
            let anchor = volumeAnchorURL
            let chart = await Task.detached(priority: .utility) {
                RoomyVolumeSpaceReader.chartGigabytes(forDirectory: anchor)
                    ?? RoomyVolumeSpaceReader.fallbackChartGigabytes
            }.value
            await MainActor.run {
                diskUsedBeforeGB = chart.used
                diskTotalGB = max(chart.total, 0.001)
            }
        }
    }

    private func seedPending() {
        switch scope {
        case .allSelected:
            pendingArtifactIDs = session.selectedArtifactIDs
        case .singleProject(let pid):
            guard let p = session.project(id: pid) else {
                pendingArtifactIDs = []
                return
            }
            let allowed = Set(p.artifacts.map(\.id))
            pendingArtifactIDs = session.selectedArtifactIDs.intersection(allowed)
        }
    }

    private func seedCollapsedGroups() {
        if let g = groups.first(where: { $0.project.name == "learning-rust" }) {
            collapsedGroupIDs.insert(g.project.id)
        }
    }

    private func syncBack() {
        session.syncSelectionFromReview(pendingArtifactIDs: pendingArtifactIDs)
        onBack()
    }

    // MARK: - Left column

    private func leftColumn(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            reviewHeader
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(groups) { group in
                        Section {
                            if !collapsedGroupIDs.contains(group.project.id) {
                                ForEach(Array(group.artifacts.enumerated()), id: \.element.id) { index, artifact in
                                    if index > 0 {
                                        Rectangle()
                                            .fill(Color.roomyBorderSubtle)
                                            .frame(height: 1)
                                    }
                                    artifactRow(group: group, artifact: artifact)
                                }
                            }
                        } header: {
                            groupHeader(group: group)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: width)
    }

    private var reviewHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Review before deleting")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.roomyTextPrimary)
                Text(deletionUsesTrash && !hasCLIOnlyDeletion
                    ? "These folders will be moved to Trash. You can restore them anytime."
                    : hasCLIOnlyDeletion
                        ? "Some items are removed immediately via Docker, Conda, or pip — not sent to Trash."
                        : "These folders will be permanently deleted.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
            Spacer(minLength: 16)
            Text(headerCountsLine)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .multilineTextAlignment(.trailing)
                .animation(.easeOut(duration: 0.08), value: pendingGB)
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color.roomyElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
    }

    private var headerCountsLine: String {
        let g = formatSummaryGB(pendingGB)
        return "\(g) across \(folderCount) folders in \(projectCount) projects"
    }

    private func groupHeader(group: ReviewGroup) -> some View {
        let total = group.artifacts.reduce(Int64(0)) { $0 + $1.sizeBytes }
        let expanded = !collapsedGroupIDs.contains(group.project.id)
        return HStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    if expanded {
                        collapsedGroupIDs.insert(group.project.id)
                    } else {
                        collapsedGroupIDs.remove(group.project.id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .frame(width: 12)
                    Text(group.project.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.roomyTextPrimary)
                    Text(group.project.path)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 8)
            Text(formatByteCount(total))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roomyTextPrimary)
                .monospacedDigit()
                .animation(.easeOut(duration: 0.08), value: total)
            Button("Remove all") {
                removeGroup(group)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color.roomyTextTertiary)
            .padding(.leading, 12)
        }
        .padding(.horizontal, 24)
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(Color.roomyElevated)
    }

    private func artifactRow(group: ReviewGroup, artifact: ArtifactRowModel) -> some View {
        HStack(spacing: 0) {
            Image(systemName: RoomyArtifactIcons.systemName(forArtifactName: artifact.name))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .frame(width: 24, alignment: .leading)

            Text(artifact.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roomyTextPrimary)
                .padding(.leading, 8)

            Text(middleTruncatePath(
                ProjectListFromScan.displayArtifactPath(
                    artifact.path,
                    homeDirectory: FileManager.default.homeDirectoryForCurrentUser
                )
            ))
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.roomyTextTertiary)
                .lineLimit(1)
                .padding(.leading, 6)

            Spacer(minLength: 8)

            Text(formatByteCount(artifact.sizeBytes))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .frame(width: 60, alignment: .trailing)
                .monospacedDigit()

            Button {
                removeArtifact(artifact.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
        .padding(.leading, 48)
        .padding(.trailing, 24)
        .frame(height: 40)
        .background(Color.roomyBackground)
    }

    private func removeArtifact(_ id: UUID) {
        withAnimation(.easeOut(duration: 0.15)) {
            pendingArtifactIDs.remove(id)
        }
    }

    private func removeGroup(_ group: ReviewGroup) {
        withAnimation(.easeOut(duration: 0.15)) {
            for a in group.artifacts {
                pendingArtifactIDs.remove(a.id)
            }
        }
    }

    // MARK: - Right panel

    private func rightPanel(width: CGFloat) -> some View {
        let cap = max(diskTotalGB, 0.001)
        let freeBefore = max(0, cap - diskUsedBeforeGB - pendingGB)

        return VStack(alignment: .leading, spacing: 0) {
            if hasWarningTier {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.roomyStatusDormantText)
                    Text("Selection includes irreversible items (e.g. Xcode archives or Docker volumes). Review carefully.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextSecondary)
                }
                .padding(.bottom, 12)
            }

            Text("After deletion")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.roomyTextTertiary)
                .kerning(0.66)
                .padding(.top, 4)

            diskBarBlock(
                title: "Now",
                usedGB: diskUsedBeforeGB,
                pendingGB: pendingGB,
                freeGB: freeBefore
            )
            .padding(.top, 12)

            Text("−\(formatSummaryGB(pendingGB))")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roomyAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .animation(.easeOut(duration: 0.08), value: pendingGB)

            let usedAfter = max(0, diskUsedBeforeGB - pendingGB)
            let freeAfter = cap - usedAfter

            diskBarBlockAfter(title: "After", usedGB: usedAfter, freeGB: freeAfter)
                .padding(.top, 8)

            if deletionUsesTrash {
                if hasDockerCLI {
                    Text("Docker items are removed immediately, not sent to Trash.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyStatusInactiveText)
                        .padding(.top, 16)
                }
                if hasCondaCLI {
                    Text("Conda clean targets run immediately (same as conda clean), not sent to Trash.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyStatusInactiveText)
                        .padding(.top, hasDockerCLI ? 4 : 16)
                }

                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                    Text("Items go to Trash, not permanently deleted")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                }
                .padding(.top, 20)

                Toggle(isOn: $emptyTrashAfterDeletion) {
                    Text("Empty Trash after deletion")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.roomyTextSecondary)
                }
                .toggleStyle(.switch)
                .disabled(hasCLIOnlyDeletion && pendingArtifacts.allSatisfy { $0.source == .dockerCLI || $0.source == .condaCLI || $0.source == .pipCLI })
                .padding(.top, 12)

                Text(emptyTrashAfterDeletion ? "This cannot be undone." : "Items can be restored from Trash")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(emptyTrashAfterDeletion ? Color.roomyDanger : Color.roomyTextTertiary)
                    .padding(.top, 4)
            } else {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.roomyDanger)
                    Text("Items will be permanently deleted. This cannot be undone.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 20)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: width, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.roomyElevated)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(width: 1)
        }
    }

    private func diskBarBlock(title: String, usedGB: Double, pendingGB: Double, freeGB: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.roomyTextSecondary)
            GeometryReader { geo in
                let w = geo.size.width
                let uFrac = CGFloat(usedGB / max(diskTotalGB, 0.001))
                let pFrac = CGFloat(pendingGB / max(diskTotalGB, 0.001))
                let fFrac = max(0, 1 - uFrac - pFrac)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.roomyTextTertiary.opacity(0.35))
                        .frame(width: w * uFrac)
                    Rectangle()
                        .fill(Color.roomyAccent)
                        .frame(width: w * pFrac)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: w * fFrac)
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.roomyBorderSubtle, lineWidth: 1)
                )
            }
            .frame(height: 12)
            .frame(width: 240)
            Text("\(String(format: "%.1f", usedGB)) GB used · \(String(format: "%.1f", freeGB)) GB free")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
        }
        .animation(.easeOut(duration: 0.08), value: pendingGB)
    }

    private func diskBarBlockAfter(title: String, usedGB: Double, freeGB: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.roomyTextSecondary)
            GeometryReader { geo in
                let w = geo.size.width
                let uFrac = CGFloat(usedGB / max(diskTotalGB, 0.001))
                let fFrac = max(0, 1 - uFrac)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.roomyTextTertiary.opacity(0.35))
                        .frame(width: w * uFrac)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: w * fFrac)
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.roomyBorderSubtle, lineWidth: 1)
                )
            }
            .frame(height: 12)
            .frame(width: 240)
            Text("\(String(format: "%.1f", usedGB)) GB used · \(String(format: "%.1f", freeGB)) GB free")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
        }
        .animation(.easeOut(duration: 0.08), value: pendingGB)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Button("← Back to results", action: syncBack)
                .buttonStyle(.roomySecondary)
            Spacer(minLength: 24)
            countdownDeleteButton
        }
        .padding(.horizontal, 32)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(Color.roomyElevated)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
    }

    private var countdownDeleteButton: some View {
        let enabled = countdownComplete && pendingGB > 0.0001
        return Button {
            guard enabled else { return }
            session.syncSelectionFromReview(pendingArtifactIDs: pendingArtifactIDs)
            onCommitDelete(pendingArtifactIDs, emptyTrashAfterDeletion, diskUsedBeforeGB, diskTotalGB)
        } label: {
            ZStack {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.roomyDanger.opacity(0.45))
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.roomyDanger)
                            .frame(width: geo.size.width * (session.deleteCountdownUnlockedForSession ? 1 : countdownProgress))
                    }
                }
                .allowsHitTesting(false)
                HStack(spacing: 6) {
                    if !countdownComplete {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .regular))
                    }
                    Text("Delete \(formatSummaryGB(pendingGB))")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
            }
            .frame(width: 220, height: 36)
            .brightness(unlockPulse ? 0.12 : 0)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(.easeOut(duration: 0.08), value: pendingGB)
    }

    private func startCountdownIfNeeded() {
        if session.deleteCountdownUnlockedForSession {
            countdownComplete = true
            countdownProgress = 1
            return
        }
        countdownProgress = 0
        countdownComplete = false
        withAnimation(.linear(duration: 2)) {
            countdownProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            session.deleteCountdownUnlockedForSession = true
            countdownComplete = true
            unlockPulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                unlockPulse = false
            }
        }
    }
}

private func middleTruncatePath(_ path: String, maxLength: Int = 42) -> String {
    guard path.count > maxLength else { return path }
    let keep = maxLength - 3
    let head = keep / 2
    let tail = keep - head
    let s = path
    let si = s.index(s.startIndex, offsetBy: head)
    let ei = s.index(s.endIndex, offsetBy: -tail)
    return String(s[..<si]) + "…" + String(s[ei...])
}

#Preview {
    SelectionReviewPreviewHost()
}

private struct SelectionReviewPreviewHost: View {
    @StateObject private var session = ProjectBrowserSession()

    var body: some View {
        SelectionReviewView(
            session: session,
            scope: .allSelected,
            volumeAnchorURL: FileManager.default.homeDirectoryForCurrentUser,
            defaultEmptyTrashAfterDeletion: false,
            deletionUsesTrash: true,
            onBack: {},
            onOpenSettings: {},
            onCommitDelete: { _, _, _, _ in }
        )
        .frame(width: 900, height: 600)
        .onAppear {
            session.load(from: .canonical, listEntry: .dormantPreSelected, useSyntheticWhenNoAggregate: true)
        }
    }
}
