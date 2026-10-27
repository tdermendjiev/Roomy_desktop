//
//  MainView.swift
//  Roomy
//
//  S04 — Project list (roomy_07_s04_project_list): two-column layout, selection summary, filters.
//

import SwiftUI
import RoomyCore

private enum ActivityFilterChip: String, CaseIterable {
    case all = "All"
    case dormant = "Dormant"
    case inactive = "Inactive"
    case recent = "Recent"
    case active = "Active"
}

private enum ProjectListSort: String, CaseIterable {
    case oldestFirst = "Oldest first"
    case largestFirst = "Largest first"
    case nameAZ = "Name A–Z"
}

private enum EcosystemMenuTag: String, CaseIterable {
    case all = "All ecosystems"
    case npm = "npm"
    case py = "py"
    case rust = "rust"
    case swift = "swift"
}

// MARK: - Main

struct MainView: View {
    var listEntry: ProjectListEntry = .reviewAll
    var footerSummary: ScanResultsSummary
    @ObservedObject var session: ProjectBrowserSession
    /// Aligns live list activity bands with S09 (folder mtime–based rows only).
    var activityDormantYears: Int = 2
    var activityInactiveMonths: Int = 6
    var onRescan: () -> Void
    var onChangeScanSettings: () -> Void
    var onOpenSettings: () -> Void
    var onBackToResults: () -> Void
    var onOpenProjectDetail: (UUID) -> Void
    var onReviewAndDelete: () -> Void

    @State private var expandedProjectIDs: Set<UUID> = []
    @State private var showArtifactHelpSheet = false
    @State private var artifactHelpName = ""
    @State private var artifactHelpExplanation = ""

    private var selectedArtifactsBinding: Binding<Set<UUID>> {
        Binding(
            get: { session.selectedArtifactIDs },
            set: { session.selectedArtifactIDs = $0 }
        )
    }
    @State private var searchText: String = ""
    @State private var ecosystemFilter: EcosystemMenuTag = .all
    @State private var sort: ProjectListSort = .oldestFirst
    @State private var activityChip: ActivityFilterChip = .all
    private var baseRows: [ProjectListRowModel] {
        let visible = session.visibleProjects
        switch listEntry {
        case .reviewAll, .dormantPreSelected:
            return visible
        case .deleteDormantOnly:
            return visible.filter { $0.activity == .dormant }
        }
    }

    private var filteredRows: [ProjectListRowModel] {
        var rows = baseRows

        switch activityChip {
        case .all: break
        case .dormant: rows = rows.filter { $0.activity == .dormant }
        case .inactive: rows = rows.filter { $0.activity == .inactive }
        case .recent: rows = rows.filter { $0.activity == .recent }
        case .active: rows = rows.filter { $0.activity == .active }
        }

        if ecosystemFilter != .all {
            let tag = ecosystemFilter.rawValue
            rows = rows.filter { $0.ecosystems.contains(tag) }
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            rows = rows.filter {
                $0.name.localizedCaseInsensitiveContains(q)
                    || $0.path.localizedCaseInsensitiveContains(q)
            }
        }

        switch sort {
        case .oldestFirst:
            rows.sort { lhs, rhs in
                if lhs.monthsAgo != rhs.monthsAgo { return lhs.monthsAgo > rhs.monthsAgo }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        case .largestFirst:
            rows.sort { lhs, rhs in
                if lhs.sizeBytes != rhs.sizeBytes { return lhs.sizeBytes > rhs.sizeBytes }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        case .nameAZ:
            rows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return rows
    }

    private var systemFilteredRows: [ProjectListRowModel] {
        filteredRows.filter { ProjectListFromScan.isSystemProject($0) }
    }

    private var projectFilteredRows: [ProjectListRowModel] {
        filteredRows.filter { !ProjectListFromScan.isSystemProject($0) }
    }

    private var homeDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    private var visibleArtifactIDs: [UUID] {
        filteredRows.flatMap { $0.artifacts.map(\.id) }
    }

    private var visibleArtifactsSelectedCount: Int {
        visibleArtifactIDs.reduce(0) { partial, id in
            partial + (session.selectedArtifactIDs.contains(id) ? 1 : 0)
        }
    }

    private var selectedProjectsInCurrentList: Int {
        filteredRows.filter { row in
            row.artifacts.contains { session.selectedArtifactIDs.contains($0.id) }
        }.count
    }

    private var selectionCountCaption: String? {
        guard selectedProjectsInCurrentList > 0 else { return nil }
        let denominator = isScanLevelFooterLeft ? footerSummary.projectCount : filteredRows.count
        return "\(selectedProjectsInCurrentList) of \(denominator) selected"
    }

    private var selectionStats: (projects: Int, artifacts: Int, bytes: Int64, breakdown: [(String, Double)]) {
        var perProject: Set<UUID> = []
        var bytes: Int64 = 0
        var byEco: [String: Int64] = [:]

        for row in session.visibleProjects {
            let selectedInRow = row.artifacts.filter { session.selectedArtifactIDs.contains($0.id) }
            guard !selectedInRow.isEmpty else { continue }
            perProject.insert(row.id)
            for a in selectedInRow {
                bytes += a.sizeBytes
                let tags = row.ecosystems.isEmpty ? ["general"] : row.ecosystems
                let share = Int64(Double(a.sizeBytes) / Double(max(1, tags.count)))
                for tag in tags {
                    byEco[tag, default: 0] += share
                }
            }
        }

        let breakdown: [(String, Double)] = byEco
            .map { key, value in (displayEcosystemName(key), Double(value) / 1_073_741_824) }
            .sorted { $0.1 > $1.1 }

        return (perProject.count, session.selectedArtifactIDs.count, bytes, breakdown)
    }

    private var selectedGB: Double {
        Double(selectionStats.bytes) / 1_073_741_824
    }

    private var visibleGB: Double {
        let sum = filteredRows.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return Double(sum) / 1_073_741_824
    }

    private var isScanLevelFooterLeft: Bool {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return listEntry != .deleteDormantOnly
            && activityChip == .all
            && ecosystemFilter == .all
            && q.isEmpty
    }

    private var bottomBarLeftTitle: String {
        if isScanLevelFooterLeft {
            let t = String(format: "%.1f", footerSummary.totalRecoverableGB)
            return "\(footerSummary.projectCount) projects · \(t) GB total found"
        }
        let t = String(format: "%.1f", visibleGB)
        return "\(filteredRows.count) projects visible · \(t) GB"
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let dividerW: CGFloat = 1
                let leftW = geo.size.width * 0.6 - dividerW / 2
                let rightW = geo.size.width - leftW - dividerW
                HStack(spacing: 0) {
                    projectListColumn(width: leftW)
                    Rectangle()
                        .fill(Color.roomyBorderSubtle)
                        .frame(width: dividerW)
                    selectionColumn(width: rightW)
                }
            }

            projectListBottomBar
        }
        .background(Color.roomyBackground)
        .sheet(isPresented: $showArtifactHelpSheet) {
            artifactHelpSheetContent
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                Button(action: onBackToResults) {
                    Text("← Results")
                }
                .help("Back to results summary")
            }
            ToolbarItem(placement: .principal) {
                Text("Results")
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
            session.activityDormantYears = activityDormantYears
            session.activityInactiveMonths = activityInactiveMonths
            session.load(from: footerSummary, listEntry: listEntry)
            ensureDefaultExpansion()
        }
        .onChange(of: listEntry) { newEntry in
            session.activityDormantYears = activityDormantYears
            session.activityInactiveMonths = activityInactiveMonths
            session.load(from: footerSummary, listEntry: newEntry)
            ensureDefaultExpansion()
        }
        .onChange(of: footerSummary) { newValue in
            session.activityDormantYears = activityDormantYears
            session.activityInactiveMonths = activityInactiveMonths
            session.load(from: newValue, listEntry: listEntry)
            ensureDefaultExpansion()
        }
        .onChange(of: activityDormantYears) { _ in
            session.activityDormantYears = activityDormantYears
            session.activityInactiveMonths = activityInactiveMonths
            session.load(from: footerSummary, listEntry: listEntry)
            ensureDefaultExpansion()
        }
        .onChange(of: activityInactiveMonths) { _ in
            session.activityDormantYears = activityDormantYears
            session.activityInactiveMonths = activityInactiveMonths
            session.load(from: footerSummary, listEntry: listEntry)
            ensureDefaultExpansion()
        }
    }

    // MARK: - Columns

    private func projectListColumn(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            listControlsBar
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    if filteredRows.isEmpty {
                        emptyFilterState
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                    } else {
                        if !systemFilteredRows.isEmpty {
                            listSectionHeader("System caches")
                            ForEach(systemFilteredRows) { project in
                                projectGroupRow(project)
                            }
                        }
                        if !projectFilteredRows.isEmpty {
                            if !systemFilteredRows.isEmpty {
                                listSectionHeader("Projects")
                            }
                            ForEach(projectFilteredRows) { project in
                                projectGroupRow(project)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.roomyBackground)
        }
        .frame(width: width, alignment: .leading)
    }

    private func selectionColumn(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if selectionStats.artifacts == 0 {
                selectionEmptyState
            } else {
                selectionActiveState
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(width: width, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.roomyBackground)
    }

    // MARK: - List controls

    private var listControlsBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                selectAllControl
                    .frame(width: 16, height: 16)

                if let caption = selectionCountCaption {
                    Text(caption)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .padding(.leading, 8)
                }

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    searchField
                    ecosystemPicker
                    sortPicker
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(Color.roomyElevated)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.roomyBorderSubtle)
                    .frame(height: 1)
            }

            HStack(spacing: 6) {
                ForEach(ActivityFilterChip.allCases, id: \.self) { chip in
                    filterChip(chip)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(Color.roomyBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.roomyBorderSubtle)
                    .frame(height: 1)
            }
        }
    }

    private var selectAllControl: some View {
        Button(action: toggleSelectAllVisible) {
            Image(systemName: selectAllIconName)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
        }
        .buttonStyle(.plain)
        .help("Select all visible rows")
    }

    private var selectAllIconName: String {
        let total = visibleArtifactIDs.count
        let sel = visibleArtifactsSelectedCount
        if total == 0 || sel == 0 { return "square" }
        if sel == total { return "checkmark.square.fill" }
        return "minus.square.fill"
    }

    private var searchField: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            TextField("Filter projects…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .regular))
                .frame(width: 160)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.roomyInset)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.roomyBorderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var ecosystemPicker: some View {
        Picker("", selection: $ecosystemFilter) {
            ForEach(EcosystemMenuTag.allCases, id: \.self) { tag in
                Text(tag.rawValue).tag(tag)
            }
        }
        .labelsHidden()
        .frame(minWidth: 118)
        .controlSize(.small)
    }

    private var sortPicker: some View {
        Picker("", selection: $sort) {
            ForEach(ProjectListSort.allCases, id: \.self) { s in
                Text(s.rawValue).tag(s)
            }
        }
        .labelsHidden()
        .frame(minWidth: 118)
        .controlSize(.small)
    }

    private func filterChip(_ chip: ActivityFilterChip) -> some View {
        let isOn = activityChip == chip
        let color: Color = {
            if !isOn { return Color.roomyTextSecondary }
            if chip == .dormant { return Color.roomyStatusDormant }
            if chip == .inactive { return Color.roomyStatusInactive }
            if chip == .recent { return Color.roomyStatusRecent }
            if chip == .active { return Color.roomyStatusActive }
            return Color.roomyTextPrimary
        }()
        return Button {
            activityChip = chip
        } label: {
            Text(chip.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(isOn ? color.opacity(0.14) : Color.roomyElevated)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isOn ? color.opacity(0.35) : Color.roomyBorderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyFilterState: some View {
        VStack(spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            Text("No projects match")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.roomyTextSecondary)
            Text("Try clearing search or filters.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    // MARK: - Selection panel

    private var selectionEmptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.circle.dashed")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            Text("Select projects to delete")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.roomyTextSecondary)
                .padding(.top, 8)
            Text("Check rows in the list to build your deletion set. When you have a selection, use Review and delete below.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .padding(.top, 4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectionActiveState: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Selected for deletion")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
                .padding(.top, 20)

            Text(formatSummaryGB(selectedGB))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.roomyTextPrimary)
                .monospacedDigit()
                .padding(.top, 12)
                .animation(.easeOut(duration: 0.08), value: selectedGB)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(selectionStats.breakdown.enumerated()), id: \.offset) { _, row in
                    HStack {
                        Text(row.0)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.roomyTextSecondary)
                        Spacer(minLength: 8)
                        Text(formatSummaryGB(row.1))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.roomyTextPrimary)
                            .monospacedDigit()
                    }
                    .frame(height: 24)
                }
            }
            .padding(.top, 12)

            Text("\(selectionStats.artifacts) artifact folders across \(selectionStats.projects) projects")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .padding(.top, 8)
                .animation(.easeOut(duration: 0.08), value: selectionStats.artifacts)

            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
                .padding(.vertical, 16)

            Button("Review and delete →", action: onReviewAndDelete)
            .buttonStyle(.roomyDestructiveLarge)
            .frame(maxWidth: .infinity)

            Button("Clear selection") {
                session.selectedArtifactIDs.removeAll()
            }
            .buttonStyle(.roomyGhost)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom bar

    private var projectListBottomBar: some View {
        HStack {
            Text(bottomBarLeftTitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            Spacer(minLength: 16)
            HStack(spacing: 4) {
                Text("\(selectionStats.projects) projects")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                Text("·")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                Text("\(formatSummaryGB(selectedGB)) selected")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .monospacedDigit()
                    .animation(.easeOut(duration: 0.08), value: selectedGB)
            }
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

    // MARK: - Actions

    private func toggleSelectAllVisible() {
        let ids = visibleArtifactIDs
        let allSelected = visibleArtifactsSelectedCount == ids.count && !ids.isEmpty
        if allSelected {
            session.selectedArtifactIDs.subtract(Set(ids))
        } else {
            session.selectedArtifactIDs.formUnion(ids)
        }
    }

    private func ensureDefaultExpansion() {
        if let first = filteredRows.first(where: { $0.name == "startup-2021" }) {
            expandedProjectIDs = [first.id]
        } else if let firstDormant = filteredRows.first(where: { $0.activity == .dormant }) {
            expandedProjectIDs = [firstDormant.id]
        } else if let first = filteredRows.first {
            expandedProjectIDs = [first.id]
        }
    }

    private func displayEcosystemName(_ tag: String) -> String {
        switch tag {
        case "npm": "Node.js"
        case "py": "Python"
        case "rust": "Rust"
        case "swift": "Swift"
        case "ai": "AI tools"
        default: tag.capitalized
        }
    }

    private func listSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.roomyTextTertiary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func projectGroupRow(_ project: ProjectListRowModel) -> some View {
        ProjectGroupView(
            project: project,
            isExpanded: expandedProjectIDs.contains(project.id),
            selectedArtifactIDs: selectedArtifactsBinding,
            homeDirectory: homeDirectory,
            onToggleExpand: {
                withAnimation(.easeOut(duration: 0.15)) {
                    if expandedProjectIDs.contains(project.id) {
                        expandedProjectIDs.remove(project.id)
                    } else {
                        expandedProjectIDs.insert(project.id)
                    }
                }
            },
            onOpenDetail: { onOpenProjectDetail(project.id) },
            onArtifactWhatIsThis: { presentArtifactHelp($0) }
        )
    }

    private func presentArtifactHelp(_ artifact: ArtifactRowModel) {
        artifactHelpName = artifact.name
        if let hint = artifact.restoreHint, !hint.isEmpty {
            artifactHelpExplanation = hint
        } else {
            artifactHelpExplanation = RoomyArtifactHelp.explanation(forDisplayName: artifact.name)
        }
        showArtifactHelpSheet = true
    }

    private var artifactHelpSheetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(artifactHelpName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
            Text(artifactHelpExplanation)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button("Done") {
                showArtifactHelpSheet = false
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 200)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Artifact help copy

private enum RoomyArtifactHelp {
    static func explanation(forDisplayName name: String) -> String {
        let n = name.lowercased()
        if n.contains("node_modules") {
            return "JavaScript and TypeScript dependencies installed by npm, yarn, or pnpm. Safe to delete; reinstall with your package manager when you work on the project again."
        }
        if n.contains("venv") || n.contains(".venv") {
            return "A Python virtual environment with installed packages. Safe to delete; recreate with your usual venv or poetry workflow."
        }
        if n == "target" || n.hasPrefix("target") {
            return "Rust or Java build output under this folder name. Cargo or Maven/Gradle can regenerate it from source."
        }
        if n.contains("build") || n.contains("dist") || n.contains(".build") {
            return "Compiled or bundled output. Usually safe to delete if source files remain; your build tool can recreate it."
        }
        if n.contains("__pycache__") || n.contains(".pytest_cache") || n.contains(".mypy_cache") {
            return "Python tooling caches. Safe to delete; linters and tests recreate them as needed."
        }
        if n.contains("pods") {
            return "CocoaPods dependencies. Safe to delete; run pod install to restore when you open the Xcode project again."
        }
        if n.contains("deriveddata") {
            return "Xcode build cache for a project. Safe to delete; Xcode rebuilds on next build (⌘B)."
        }
        if n.contains("devicesupport") {
            return "iOS device debugging symbols for a specific iOS version. Safe if you no longer debug devices on that version; Xcode re-downloads when needed."
        }
        if n.contains("simulator") {
            return "iOS Simulator data. Unavailable simulators are safe to remove; recent ones may need to be recreated in Xcode."
        }
        if n.contains("archive") {
            return "Xcode release archive — not regenerable from source alone. Only delete if you no longer need this build."
        }
        if n.contains("conda") {
            return "Conda package cache or environment. Unused packages mirror conda clean; environments require conda env create to restore."
        }
        if n.contains("npm cache") || n.contains("pip cache") || n.contains("yarn cache") || n.contains("nuget") || n.contains("pnpm") || n.contains("poetry") || n.contains("uv cache") {
            return "Global package manager download cache. Safe to delete; packages re-download on next install or build."
        }
        if n.contains("global npm") || n.contains("global yarn") {
            return "Globally installed CLI tools. Deleting removes commands like eslint or typescript until you reinstall with npm install -g or yarn global add."
        }
        if n.contains("homebrew") {
            return "Homebrew download cache or logs. Safe to delete; caches rebuild automatically."
        }
        if n.contains("docker") {
            return "Docker images, volumes, or build cache. Images re-download with docker pull; volumes may contain database data and are not recoverable."
        }
        if n.contains("pyenv") {
            return "A Python version installed via pyenv. Removing it requires pyenv install to use that version again."
        }
        if n.contains("unused pip") {
            return "Packages installed in this venv but not listed in requirements.txt. Review carefully — optional dependencies may appear here."
        }
        return "Roomy flags this as regenerable developer output or dependencies—not your source code. You can usually delete it and restore it with the project’s normal build or install commands. If unsure, open the project in its IDE before deleting."
    }
}

// MARK: - Row views

private struct ProjectGroupView: View {
    let project: ProjectListRowModel
    let isExpanded: Bool
    @Binding var selectedArtifactIDs: Set<UUID>
    var homeDirectory: URL
    var onToggleExpand: () -> Void
    var onOpenDetail: () -> Void
    var onArtifactWhatIsThis: (ArtifactRowModel) -> Void

    private var rowSelectedCount: Int {
        project.artifacts.reduce(0) { $0 + (selectedArtifactIDs.contains($1.id) ? 1 : 0) }
    }

    private var projectCheckboxIcon: String {
        let total = project.artifacts.count
        let sel = rowSelectedCount
        if sel == 0 { return "square" }
        if sel == total { return "checkmark.square.fill" }
        return "minus.square.fill"
    }

    private var statusAccent: Color {
        switch project.activity {
        case .dormant: .roomyStatusDormant
        case .inactive: .roomyStatusInactive
        case .recent: .roomyStatusRecent
        case .active: .roomyStatusActive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Button(action: toggleProjectArtifacts) {
                    Image(systemName: projectCheckboxIcon)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.roomyTextSecondary)
                        .frame(width: 28, height: 52, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button(action: onToggleExpand) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, height: 52)
                }
                .buttonStyle(.plain)

                Button(action: onOpenDetail) {
                    HStack(alignment: .center, spacing: 8) {
                        Circle()
                            .fill(project.activity.dotColor)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(project.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.roomyTextPrimary)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                ecosystemChips
                            }
                            HStack(spacing: 8) {
                                Text(project.path)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.roomyTextSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer(minLength: 4)
                                Text(project.ageLabel)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(project.activity.labelColor)
                                    .lineLimit(1)
                            }
                        }

                        Text(formatByteCount(project.sizeBytes))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roomyTextPrimary)
                            .frame(width: 72, alignment: .trailing)
                            .monospacedDigit()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .frame(height: 52)
            .background(rowBackground)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(project.artifacts) { artifact in
                        ArtifactSubRowView(
                            artifact: artifact,
                            isSelected: selectedArtifactIDs.contains(artifact.id),
                            homeDirectory: homeDirectory,
                            onToggle: { toggleArtifact(artifact.id) },
                            onWhatIsThis: { onArtifactWhatIsThis(artifact) }
                        )
                    }
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(statusAccent)
                        .frame(width: 2)
                }
                .padding(.leading, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: isExpanded)
    }

    private var rowBackground: Color {
        if project.activity == .active {
            return Color.roomyStatusActive.opacity(0.06)
        }
        return Color.clear
    }

    private var ecosystemChips: some View {
        HStack(spacing: 4) {
            ForEach(project.ecosystems, id: \.self) { eco in
                Text(eco)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.roomyElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.roomyBorderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
    }

    private func toggleArtifact(_ id: UUID) {
        if selectedArtifactIDs.contains(id) {
            selectedArtifactIDs.remove(id)
        } else {
            selectedArtifactIDs.insert(id)
        }
    }

    private func toggleProjectArtifacts() {
        let ids = project.artifacts.map(\.id)
        let allOn = rowSelectedCount == ids.count && !ids.isEmpty
        if allOn {
            selectedArtifactIDs.subtract(ids)
        } else {
            selectedArtifactIDs.formUnion(ids)
        }
    }
}

private struct ArtifactSubRowView: View {
    let artifact: ArtifactRowModel
    let isSelected: Bool
    var homeDirectory: URL
    var onToggle: () -> Void
    var onWhatIsThis: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextSecondary)
                    .frame(width: 28, height: 40, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer().frame(width: 20)

            HStack(spacing: 8) {
                Text(artifact.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .lineLimit(1)
                if artifact.safetyTier != .safe {
                    Text(artifact.safetyTier.displayLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(artifact.safetyTier.badgeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(artifact.safetyTier.badgeColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                Button("What is this?", action: onWhatIsThis)
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyAccent)
                Spacer(minLength: 8)
                Text(formatByteCount(artifact.sizeBytes))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .frame(width: 72, alignment: .trailing)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(width: 12)
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(height: 40)
        .background(Color.roomyInset.opacity(0.35))
    }
}

#Preview("S04 — dormant pre-selected") {
    MainViewPreviewHost(entry: .dormantPreSelected)
}

#Preview("S04 — review all") {
    MainViewPreviewHost(entry: .reviewAll)
}

private struct MainViewPreviewHost: View {
    @StateObject private var session = ProjectBrowserSession()
    var entry: ProjectListEntry

    var body: some View {
        MainView(
            listEntry: entry,
            footerSummary: .canonical,
            session: session,
            activityDormantYears: 2,
            activityInactiveMonths: 6,
            onRescan: {},
            onChangeScanSettings: {},
            onOpenSettings: {},
            onBackToResults: {},
            onOpenProjectDetail: { _ in },
            onReviewAndDelete: {}
        )
        .frame(width: 900, height: 600)
        .onAppear {
            session.load(from: .canonical, listEntry: entry, useSyntheticWhenNoAggregate: true)
        }
    }
}
