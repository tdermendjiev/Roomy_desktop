//
//  ProjectDetailView.swift
//  Roomy
//
//  S05 — Project detail (roomy_08_s05_project_detail).
//

import AppKit
import RoomyCore
import SwiftUI

struct ProjectDetailView: View {
    @ObservedObject var session: ProjectBrowserSession
    let projectID: UUID
    var onBack: () -> Void
    var onOpenSettings: () -> Void
    var onDeleteSelected: () -> Void
    var onExcludeProject: () -> Void

    @State private var expandedArtifactIDs: Set<UUID> = []
    @State private var gitMeta: ProjectGitMetadata?

    private var project: ProjectListRowModel? {
        session.project(id: projectID)
    }

    var body: some View {
        Group {
            if let project {
                detailContent(project)
                    .task(id: projectID) {
                        guard !ProjectListFromScan.isSystemProject(project) else { return }
                        await refreshGitMetadata(for: project)
                    }
            } else {
                Text("Project not found")
                    .foregroundStyle(Color.roomyTextSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.roomyBackground)
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                Button(action: onBack) {
                    Text("← Project list")
                }
                .help("Back to project list")
            }
            ToolbarItem(placement: .principal) {
                Text(project?.name ?? "Project")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roomyTextSecondary)
                    .lineLimit(1)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape", action: onOpenSettings)
                    .help("Settings")
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.roomyTextSecondary)
            }
        })
        .onAppear {
            guard let project else { return }
            if project.activity == .active {
                for a in project.artifacts {
                    session.selectedArtifactIDs.remove(a.id)
                }
            }
            if let node = project.artifacts.first(where: { $0.name == "node_modules" }) {
                expandedArtifactIDs = [node.id]
            } else if project.activity == .active, let first = project.artifacts.first {
                expandedArtifactIDs = [first.id]
            }
        }
    }

    @MainActor
    private func refreshGitMetadata(for project: ProjectListRowModel) async {
        gitMeta = nil
        let path = project.path
        let bytes = project.sizeBytes
        let meta = await RoomyGitMetadataReader.metadata(forProjectPath: path, recoverableArtifactBytes: bytes)
        guard session.project(id: projectID)?.path == path else { return }
        gitMeta = meta
    }

    private func placeholderGitMeta(for project: ProjectListRowModel) -> ProjectGitMetadata {
        ProjectGitMetadata(
            isGitRepo: false,
            lastCommitDate: nil,
            commitSubject: "",
            isClean: true,
            gitStatusLine: "Loading…",
            totalProjectSizeBytes: max(project.sizeBytes, 1),
            lastModified: nil
        )
    }

    private var isSystemGroup: Bool {
        guard let project else { return false }
        return ProjectListFromScan.isSystemProject(project)
    }

    @ViewBuilder
    private func detailContent(_ project: ProjectListRowModel) -> some View {
        let meta = gitMeta ?? placeholderGitMeta(for: project)
        let selectedBytes = project.artifacts
            .filter { session.selectedArtifactIDs.contains($0.id) }
            .reduce(Int64(0)) { $0 + $1.sizeBytes }

        VStack(spacing: 0) {
            projectHeader(project: project, meta: meta)
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    ForEach(Array(project.artifacts.enumerated()), id: \.element.id) { index, artifact in
                        if index > 0 {
                            Rectangle()
                                .fill(Color.roomyBorderSubtle)
                                .frame(height: 1)
                        }
                        ArtifactDetailRowView(
                            artifact: artifact,
                            homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
                            isExpanded: expandedArtifactIDs.contains(artifact.id),
                            isSelected: session.selectedArtifactIDs.contains(artifact.id),
                            onToggleSelect: { toggleArtifact(artifact.id) },
                            onToggleDisclosure: {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    if expandedArtifactIDs.contains(artifact.id) {
                                        expandedArtifactIDs.remove(artifact.id)
                                    } else {
                                        expandedArtifactIDs.insert(artifact.id)
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.bottom, 8)
            }
            if !isSystemGroup {
                Rectangle()
                    .fill(Color.roomyBorderSubtle)
                    .frame(height: 1)
                metadataSection(project: project, meta: meta)
            }
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
            actionsBar(project: project, selectedBytes: selectedBytes)
        }
    }

    private func projectHeader(project: ProjectListRowModel, meta: ProjectGitMetadata) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(project.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.roomyTextPrimary)

                Button(action: { revealInFinder(path: project.path) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.roomyTextTertiary)
                        Text(project.path)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.roomyTextSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                statusRow(project: project, meta: meta)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                if !isSystemGroup {
                    secondaryIconButton(title: "Open in Finder", systemImage: "folder") {
                        revealInFinder(path: project.path)
                    }
                    secondaryIconButton(title: "Open in Terminal", systemImage: "terminal") {
                        openInTerminal(path: project.path)
                    }
                }
            }
            .frame(width: 200, alignment: .trailing)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(Color.roomyBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
    }

    private func statusRow(project: ProjectListRowModel, meta: ProjectGitMetadata) -> some View {
        HStack(spacing: 8) {
            Text(project.activity.displayTitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(project.activity.labelColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(project.activity.dotColor.opacity(0.12))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(project.activity.dotColor.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))

            if meta.isGitRepo, let d = meta.lastCommitDate {
                Text("Last git commit: \(formattedGitDay(d))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(project.activity.labelColor)
            } else if !meta.isGitRepo, let d = meta.lastModified {
                Text("Last modified: \(formattedGitDay(d))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
        }
    }

    private func metadataSection(project: ProjectListRowModel, meta: ProjectGitMetadata) -> some View {
        let recoverable = project.artifacts.reduce(Int64(0)) { $0 + $1.sizeBytes }
        let total = meta.totalProjectSizeBytes
        let pct = total > 0 ? Int((Double(recoverable) / Double(total) * 100).rounded()) : 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 24) {
                metadataCell(
                    title: meta.isGitRepo ? "Last git commit" : "Last modified",
                    value: {
                        if meta.isGitRepo {
                            if let d = meta.lastCommitDate {
                                let msg = truncatedCommit(meta.commitSubject, maxChars: 40)
                                return "\(formattedGitDay(d)) · \"\(msg)\""
                            }
                            return "No commits yet"
                        }
                        if let d = meta.lastModified {
                            return formattedGitDay(d)
                        }
                        return "—"
                    }()
                )
                metadataCell(
                    title: "Git status",
                    value: meta.isGitRepo ? meta.gitStatusLine : "Not a git repo",
                    valueColor: meta.isGitRepo
                        ? (meta.isClean ? Color.roomyStatusActive : Color.roomyStatusInactive)
                        : Color.roomyTextTertiary
                )
            }
            HStack(alignment: .top, spacing: 24) {
                metadataCell(
                    title: "Total project size",
                    value: formatByteCount(total) + " (including source)"
                )
                metadataCell(
                    title: "Recoverable from this project",
                    value: "\(formatByteCount(recoverable)) (\(pct)% of total)",
                    valueColor: Color.roomyAccent
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roomyElevated)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
    }

    private func metadataCell(title: String, value: String, valueColor: Color = Color.roomyTextPrimary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .kerning(0.66)
            Text(value)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(valueColor)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionsBar(project: ProjectListRowModel, selectedBytes: Int64) -> some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Button(action: toggleSelectAllArtifacts) {
                    Image(systemName: selectAllArtifactsIcon(project: project))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.roomyTextSecondary)
                }
                .buttonStyle(.plain)
                Text("Select all artifacts in this project")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
            Spacer(minLength: 16)
            Button(action: onExcludeProject) {
                HStack(spacing: 4) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 12, weight: .regular))
                    Text("Add to exclusions")
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Color.roomyTextTertiary)
            .padding(.trailing, 8)
            Button {
                onDeleteSelected()
            } label: {
                Text(selectedBytes > 0
                    ? "Delete \(formatByteCount(selectedBytes)) from this project"
                    : "Delete selected from this project")
            }
            .buttonStyle(.roomyDestructiveLarge)
            .disabled(selectedBytes == 0)
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

    private func toggleArtifact(_ id: UUID) {
        if session.selectedArtifactIDs.contains(id) {
            session.selectedArtifactIDs.remove(id)
        } else {
            session.selectedArtifactIDs.insert(id)
        }
    }

    private func toggleSelectAllArtifacts() {
        guard let project else { return }
        let ids = project.artifacts.map(\.id)
        let allOn = ids.allSatisfy { session.selectedArtifactIDs.contains($0) } && !ids.isEmpty
        if allOn {
            session.selectedArtifactIDs.subtract(ids)
        } else {
            session.selectedArtifactIDs.formUnion(ids)
        }
    }

    private func selectAllArtifactsIcon(project: ProjectListRowModel) -> String {
        let ids = project.artifacts.map(\.id)
        let sel = ids.filter { session.selectedArtifactIDs.contains($0) }.count
        if sel == 0 { return "square" }
        if sel == ids.count { return "checkmark.square.fill" }
        return "minus.square.fill"
    }

    private func secondaryIconButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .regular))
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.roomyTextSecondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.roomyBorderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Artifact row

private struct ArtifactDetailRowView: View {
    let artifact: ArtifactRowModel
    var homeDirectory: URL
    let isExpanded: Bool
    let isSelected: Bool
    var onToggleSelect: () -> Void
    var onToggleDisclosure: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Button(action: onToggleSelect) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.roomyTextSecondary)
                        .frame(width: 16 + 16, height: 48, alignment: .leading)
                }
                .buttonStyle(.plain)

                Image(systemName: RoomyArtifactIcons.systemName(forArtifactName: artifact.name))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                    .frame(width: 16, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(artifact.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.roomyTextPrimary)
                        .lineLimit(1)
                    Text(ProjectListFromScan.displayArtifactPath(artifact.path, homeDirectory: homeDirectory))
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)

                Button("What is this?", action: onToggleDisclosure)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyAccent)

                Text(formatByteCount(artifact.sizeBytes))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .frame(width: 60, alignment: .trailing)
                    .monospacedDigit()
            }
            .padding(.horizontal, 32)
            .frame(minHeight: 48)

            if isExpanded {
                disclosurePanel(for: artifact)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: isExpanded)
    }

    @ViewBuilder
    private func disclosurePanel(for artifact: ArtifactRowModel) -> some View {
        let copy = disclosureCopy(for: artifact)
        VStack(alignment: .leading, spacing: 8) {
            Text(copy.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roomyTextPrimary)
            Text(copy.body)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                Text(copy.command)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.roomyElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.roomyBorderSubtle, lineWidth: 1)
                    )
            }
        }
        .padding(EdgeInsets(top: 12, leading: 44, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roomyInset)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.roomyAccent)
                .frame(width: 3)
        }
    }

    private func disclosureCopy(for artifact: ArtifactRowModel) -> (title: String, body: String, command: String) {
        switch artifact.name {
        case "node_modules":
            return (
                artifact.name,
                "npm dependency cache. Contains all installed packages from package.json. Nothing permanent lives here — your source code, package.json, and package-lock.json are all that matter.",
                "npm install"
            )
        case ".next/":
            return (
                artifact.name,
                "Next.js build output and cache. It is regenerated when you run the dev server or production build.",
                "npm run build"
            )
        case ".eslintcache":
            return (
                artifact.name,
                "ESLint cache speeds up repeated lint runs. Deleting it only means the next lint pass rebuilds the cache.",
                "npx eslint ."
            )
        case "__pycache__":
            return (
                artifact.name,
                "Python bytecode cache. Safe to remove; Python recreates these files when modules are imported again.",
                "python -m compileall ."
            )
        case ".venv/":
            return (
                artifact.name,
                "Isolated Python environment with installed packages. Recreate it from your requirements or lockfile.",
                "python -m venv .venv"
            )
        default:
            return (
                artifact.name,
                "Regenerable project artifact. Removing it frees disk space; restore it using your usual project workflow.",
                "—"
            )
        }
    }
}

// MARK: - Path helpers

private func expandingPath(_ path: String) -> String {
    (path as NSString).expandingTildeInPath
}

private func revealInFinder(path: String) {
    let full = expandingPath(path)
    let url = URL(fileURLWithPath: full, isDirectory: true)
    NSWorkspace.shared.activateFileViewerSelecting([url])
}

private func openInTerminal(path: String) {
    let full = expandingPath(path)
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    task.arguments = ["-a", "Terminal", full]
    try? task.run()
}

private func formattedGitDay(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f.string(from: date)
}

private func truncatedCommit(_ s: String, maxChars: Int) -> String {
    guard s.count > maxChars else { return s }
    let idx = s.index(s.startIndex, offsetBy: maxChars - 1)
    return String(s[..<idx]) + "…"
}

#Preview("S05 — startup-2021") {
    ProjectDetailPreviewHost()
}

private struct ProjectDetailPreviewHost: View {
    @StateObject private var session = ProjectBrowserSession()

    var body: some View {
        Group {
            if let id = session.projects.first(where: { $0.name == "startup-2021" })?.id {
                ProjectDetailView(
                    session: session,
                    projectID: id,
                    onBack: {},
                    onOpenSettings: {},
                    onDeleteSelected: {},
                    onExcludeProject: {}
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
