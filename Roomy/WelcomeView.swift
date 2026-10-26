//
//  WelcomeView.swift
//  Roomy
//
//  S01 — Welcome / empty state (roomy_04_s01_welcome).
//

import AppKit
import SwiftUI

// MARK: - Models

private enum ScanPathChoice: String, CaseIterable, Identifiable {
    case home
    case custom
    case entireMac

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .home: "house"
        case .custom: "folder.badge.plus"
        case .entireMac: "desktopcomputer"
        }
    }

    var label: String {
        switch self {
        case .home: "Home folder"
        case .custom: "Custom folder…"
        case .entireMac: "Entire Mac"
        }
    }

    var sublabel: String {
        switch self {
        case .home: "~/"
        case .custom: "Choose a path"
        case .entireMac: "/"
        }
    }
}

private enum EcosystemKind: String, CaseIterable, Identifiable, Hashable {
    case ai = "AI tools"
    case node = "Node.js"
    case python = "Python"
    case rust = "Rust"
    case ruby = "Ruby"
    case go = "Go"
    case java = "Java/Kotlin"
    case swift = "Swift/Xcode"
    case dotnet = ".NET / NuGet"
    case general = "General"

    var id: String { rawValue }

    /// Keys in `RoomyAppSettings.ecosystemsEnabled`.
    var settingsKey: String {
        switch self {
        case .node: "npm"
        case .python: "py"
        case .rust: "rust"
        case .ruby: "ruby"
        case .go: "go"
        case .java: "java"
        case .swift: "swift"
        case .dotnet: "dotnet"
        case .ai: "ai"
        case .general: "general"
        }
    }

    var iconName: String {
        switch self {
        case .node: "cube.box"
        case .python: "doc.text"
        case .rust: "gearshape.2"
        case .ruby: "diamond"
        case .go: "hare"
        case .java: "cup.and.saucer"
        case .swift: "swift"
        case .dotnet: "chevron.left.forwardslash.chevron.right"
        case .ai: "sparkles"
        case .general: "folder"
        }
    }
}

// MARK: - Welcome

struct WelcomeView: View {
    @ObservedObject var settingsStore: RoomySettingsStore
    /// Display label for the scan UI, and filesystem root to scan.
    var onStartScan: (String, URL) -> Void
    var onViewLastScan: () -> Void
    var onOpenSettings: () -> Void

    @AppStorage("roomy.hasCompletedScan") private var hasCompletedScan = false
    @AppStorage("roomy.lastScanEnd") private var lastScanEndTimestamp: Double = 0

    @State private var pathChoice: ScanPathChoice = .home
    @State private var customFolderURL: URL?
    @State private var advancedExpanded = false
    @State private var enabledEcosystems: Set<EcosystemKind> = Set(EcosystemKind.allCases)
    @State private var hoveredPath: ScanPathChoice?
    @State private var confirmScanPresented = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                identityBlock
                    .padding(.bottom, 40)

                scanSection
            }
            .frame(width: 480)
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
            .padding(.bottom, 48)
        }
        .background(Color.roomyBackground)
        .onAppear {
            applySettingsToLocalState()
        }
        .onChange(of: settingsStore.settings) { _ in
            applySettingsToLocalState()
        }
        .confirmationDialog(
            "Start scan?",
            isPresented: $confirmScanPresented,
            titleVisibility: .visible
        ) {
            Button("Start scan") {
                commitStartScan()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Roomy will scan \(pillContent.0) for regenerable developer artifacts.")
        }
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                Text("Roomy")
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
    }

    // MARK: Identity

    private var identityBlock: some View {
        VStack(spacing: 0) {
            RoomyWelcomeIcon()
                .padding(.bottom, 8)
            Text("Roomy")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
                .padding(.bottom, 4)
            Text("Reclaim disk space from dormant projects.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Scan path & CTA

    private var scanSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Where should I look?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
                .padding(.bottom, 12)

            HStack(spacing: 8) {
                ForEach(ScanPathChoice.allCases) { choice in
                    pathOptionButton(choice)
                }
            }
            .padding(.bottom, 12)

            selectedPathPill
                .padding(.bottom, 8)

            reassuranceNote
                .padding(.bottom, 32)

            advancedSection
                .padding(.bottom, 32)

            VStack(spacing: 8) {
                Button(action: handleStartScanTap) {
                    Text("Start scan →")
                }
                .buttonStyle(.roomyPrimaryLarge)
                .disabled(!canStartScan)

                Text("Usually under 60 seconds")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                    .frame(maxWidth: .infinity)

                if hasCompletedScan, lastScanDate != nil {
                    Button(action: onViewLastScan) {
                        Text(lastScanLinkTitle)
                    }
                    .buttonStyle(.roomyGhost)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var lastScanDate: Date? {
        guard lastScanEndTimestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: lastScanEndTimestamp)
    }

    private var lastScanLinkTitle: String {
        guard let date = lastScanDate else {
            return "View last scan"
        }
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        f.locale = Locale.autoupdatingCurrent
        return "View last scan from \(f.string(from: date))"
    }

    private var canStartScan: Bool {
        if pathChoice == .custom { return customFolderURL != nil }
        return true
    }

    private func applySettingsToLocalState() {
        let s = settingsStore.settings
        switch s.defaultScanLocation {
        case .home:
            pathChoice = .home
        case .custom:
            pathChoice = .custom
            let path = s.customScanPath.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty {
                let expanded = (path as NSString).expandingTildeInPath
                customFolderURL = URL(fileURLWithPath: expanded, isDirectory: true)
            }
        case .entireMac:
            pathChoice = .entireMac
        }
        enabledEcosystems = Set(
            EcosystemKind.allCases.filter { s.ecosystemsEnabled[$0.settingsKey, default: true] }
        )
    }

    private func handleStartScanTap() {
        guard canStartScan else { return }
        syncScanLocationToSettings()
        syncEcosystemsToSettings()
        if settingsStore.settings.askBeforeEachScan {
            confirmScanPresented = true
        } else {
            commitStartScan()
        }
    }

    private func syncScanLocationToSettings() {
        var s = settingsStore.settings
        switch pathChoice {
        case .home:
            s.defaultScanLocation = .home
        case .custom:
            s.defaultScanLocation = .custom
            if let url = customFolderURL {
                s.customScanPath = url.path
            }
        case .entireMac:
            s.defaultScanLocation = .entireMac
        }
        settingsStore.settings = s
    }

    private func syncEcosystemsToSettings() {
        for kind in EcosystemKind.allCases {
            settingsStore.setEcosystem(kind.settingsKey, enabled: enabledEcosystems.contains(kind))
        }
    }

    private func commitStartScan() {
        guard canStartScan else { return }
        syncScanLocationToSettings()
        syncEcosystemsToSettings()
        let resolved = RoomyScanRootResolver.resolve(from: settingsStore.settings)
        onStartScan(resolved.label, resolved.rootURL)
    }

    // MARK: Path cards

    private func pathOptionButton(_ choice: ScanPathChoice) -> some View {
        let isSelected = pathChoice == choice
        let isHovered = hoveredPath == choice

        return Button {
            selectPath(choice)
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Image(systemName: choice.iconName)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(isSelected ? Color.roomyAccent : Color.roomyTextSecondary)
                        .padding(.bottom, 6)
                    Text(choice.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? Color.roomyAccent : Color.roomyTextPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 2)
                    Text(choice.sublabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.roomyAccent)
                        .padding(8)
                }
            }
            .frame(height: 72)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.roomyAccentSubtle : (isHovered ? Color.roomyHover : Color.roomyElevated))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected ? Color.roomyAccent : (isHovered ? Color.roomyBorderDefault : Color.roomyBorderSubtle),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                hoveredPath = choice
            } else if hoveredPath == choice {
                hoveredPath = nil
            }
        }
    }

    private func selectPath(_ choice: ScanPathChoice) {
        pathChoice = choice
        var s = settingsStore.settings
        switch choice {
        case .home:
            s.defaultScanLocation = .home
        case .custom:
            s.defaultScanLocation = .custom
        case .entireMac:
            s.defaultScanLocation = .entireMac
        }
        settingsStore.settings = s
        guard choice == .custom else { return }
        presentFolderPicker()
    }

    private func presentFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            customFolderURL = url
            var s = settingsStore.settings
            s.customScanPath = url.path
            s.defaultScanLocation = .custom
            settingsStore.settings = s
        }
    }

    // MARK: Pill

    @ViewBuilder
    private var selectedPathPill: some View {
        let (text, isGhost) = pillContent
        HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(isGhost ? Color.roomyTextTertiary : Color.roomyTextSecondary)
                .lineLimit(2)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.roomyInset)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.roomyBorderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var pillContent: (String, Bool) {
        switch pathChoice {
        case .home:
            return ("~/", false)
        case .custom:
            if let url = customFolderURL {
                return (url.path, false)
            }
            return ("No folder selected", true)
        case .entireMac:
            return ("All user-accessible paths", false)
        }
    }

    private var reassuranceNote: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "shield.checkmark")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            Text("Scans only regenerable files — nothing permanent will be found.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Advanced

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    advancedExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .rotationEffect(.degrees(advancedExpanded ? 90 : 0))
                    Text("Advanced · Choose ecosystems")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if advancedExpanded {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4),
                    spacing: 4
                ) {
                    ForEach(EcosystemKind.allCases) { kind in
                        ecosystemCell(kind)
                    }
                }
                .padding(.top, 12)

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Button("Select all") {
                        enabledEcosystems = Set(EcosystemKind.allCases)
                    }
                    .buttonStyle(.roomyGhost)
                    Text(" · ")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                    Button("None") {
                        enabledEcosystems = []
                    }
                    .buttonStyle(.roomyGhost)
                }
                .padding(.top, 8)

                Text("System caches")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.roomyTextSecondary)
                    .padding(.top, 16)

                ForEach(RoomySystemScanCategories.all, id: \.key) { row in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color.roomyTextPrimary)
                            Text(row.detail)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(Color.roomyTextTertiary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settingsStore.settings.systemScanEnabled[row.key, default: true] },
                            set: { settingsStore.setSystemScan(row.key, enabled: $0) }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ecosystemCell(_ kind: EcosystemKind) -> some View {
        let binding = Binding(
            get: { enabledEcosystems.contains(kind) },
            set: { newValue in
                if newValue {
                    enabledEcosystems.insert(kind)
                } else {
                    enabledEcosystems.remove(kind)
                }
                settingsStore.setEcosystem(kind.settingsKey, enabled: newValue)
            }
        )

        return Toggle(isOn: binding) {
            HStack(spacing: 6) {
                Image(systemName: kind.iconName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.roomyTextSecondary)
                    .frame(width: 16, alignment: .center)
                Text(kind.rawValue)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .lineLimit(1)
            }
        }
        .toggleStyle(.checkbox)
        .frame(height: 32, alignment: .center)
    }
}

// MARK: - Placeholder app icon (64×64)

private struct RoomyWelcomeIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.roomyInset)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.roomyBorderDefault, lineWidth: 1)
                )
            if let img = NSApplication.shared.applicationIconImage {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            } else {
                Image(systemName: "square.dashed")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
        }
        .frame(width: 64, height: 64)
        .accessibilityLabel("Roomy")
    }
}

#Preview("S01 — first launch") {
    WelcomeView(
        settingsStore: RoomySettingsStore(),
        onStartScan: { _, _ in },
        onViewLastScan: {},
        onOpenSettings: {}
    )
    .frame(width: 900, height: 600)
}
