//
//  SettingsView.swift
//  Roomy
//
//  S09 — Settings (roomy_11_s09_s10).
//

import AppKit
import RoomyCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: RoomySettingsStore
    @ObservedObject var exclusionsStore: ExclusionsStore
    var dismissContext: SettingsDismissContext
    var onDismiss: () -> Void
    var onManageExclusions: () -> Void
    @ObservedObject private var updater = RoomyUpdater.shared
    @ObservedObject private var license = RoomyLicenseStore.shared
    @State private var showUnlockSheet = false

    private var backTitle: String {
        switch dismissContext {
        case .welcome: return "← Roomy"
        case .overview: return "← Results"
        case .projectList, .projectDetail, .selectionReview, .deletionSummary:
            return "← Back"
        }
    }

    private var exclusionsSummary: String {
        let n = exclusionsStore.count
        if n == 0 { return "No exclusions yet" }
        return "\(n) paths excluded"
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                scanPathsSection
                sectionDivider
                ecosystemsSection
                sectionDivider
                systemScanSection
                sectionDivider
                activitySection
                sectionDivider
                deletionSection
                sectionDivider
                exclusionsBridgeSection
                sectionDivider
                aboutSection
            }
            .frame(width: 560, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color.roomyBackground)
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                Button(backTitle, action: onDismiss)
            }
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
        })
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.roomyBorderSubtle)
            .frame(height: 1)
            .padding(.top, 24)
    }

    // MARK: - Scan paths

    private var scanPathsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Scan paths")
            VStack(alignment: .leading, spacing: 0) {
                Text("Default scan location")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(RoomyScanDefaultLocation.allCases) { loc in
                        radioRow(
                            title: loc.title,
                            selected: settingsStore.settings.defaultScanLocation == loc
                        ) {
                            var s = settingsStore.settings
                            s.defaultScanLocation = loc
                            settingsStore.settings = s
                        }
                        .padding(.leading, 16)
                        .frame(height: 32)
                    }
                }
                .padding(.top, 4)

                if settingsStore.settings.defaultScanLocation == .custom {
                    TextField("/Users/username/Projects", text: customPathBinding)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .frame(width: 320, alignment: .leading)
                        .background(Color.roomyInset)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.roomyBorderSubtle, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeOut(duration: 0.15), value: settingsStore.settings.defaultScanLocation == .custom)
                }

                preferenceRow(
                    title: "Ask me before each scan",
                    subtitle: "Override the default location at scan time",
                    control: {
                        Toggle("", isOn: askBeforeBinding)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                .padding(.top, 8)
            }
        }
    }

    private var customPathBinding: Binding<String> {
        Binding(
            get: { settingsStore.settings.customScanPath },
            set: { v in
                var s = settingsStore.settings
                s.customScanPath = v
                settingsStore.settings = s
            }
        )
    }

    private var askBeforeBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.askBeforeEachScan },
            set: { v in
                var s = settingsStore.settings
                s.askBeforeEachScan = v
                settingsStore.settings = s
            }
        )
    }

    private func radioRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(selected ? Color.roomyAccent : Color.roomyTextTertiary)
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ecosystems

    private var ecosystemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Ecosystems")
            Text("Choose which artifact types to scan for.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .padding(.bottom, 8)

            ForEach(Array(RoomySettingsEcosystems.all.enumerated()), id: \.offset) { _, row in
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: row.icon)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.roomyTextSecondary)
                            .frame(width: 18)
                        Text(row.name)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.roomyTextPrimary)
                    }
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { settingsStore.settings.ecosystemsEnabled[row.key, default: true] },
                            set: { settingsStore.setEcosystem(row.key, enabled: $0) }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                }
                .frame(height: 44)
            }

            HStack {
                Spacer()
                Button("Select all") {
                    settingsStore.setAllEcosystems(true)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyAccent)
                Text("·")
                    .foregroundStyle(Color.roomyTextTertiary)
                Button("None") {
                    settingsStore.setAllEcosystems(false)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyAccent)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - System caches

    private var systemScanSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("System caches")
            Text("Fixed-path developer caches scanned separately from your project folder.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .padding(.bottom, 8)

            ForEach(Array(RoomySystemScanCategories.all.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(row.name)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.roomyTextPrimary)
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { settingsStore.settings.systemScanEnabled[row.key, default: true] },
                                set: { settingsStore.setSystemScan(row.key, enabled: $0) }
                            )
                        )
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }
                    Text(row.detail)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                }
                .frame(minHeight: 44)
            }

            HStack {
                Spacer()
                Button("Select all") { settingsStore.setAllSystemScans(true) }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyAccent)
                Text("·").foregroundStyle(Color.roomyTextTertiary)
                Button("None") { settingsStore.setAllSystemScans(false) }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyAccent)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Activity thresholds")
            Text("Customize how Roomy classifies project activity.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .padding(.bottom, 8)

            preferenceRow(
                title: "Mark as dormant after",
                subtitle: "Projects older than this are shown in red and recommended for deletion",
                control: {
                    Picker("", selection: dormantYearsBinding) {
                        Text("1 year").tag(1)
                        Text("2 years").tag(2)
                        Text("3 years").tag(3)
                        Text("5 years").tag(5)
                    }
                    .labelsHidden()
                    .frame(width: 140)
                    .controlSize(.regular)
                }
            )

            preferenceRow(
                title: "Mark as inactive after",
                subtitle: "Projects in this range are shown in amber",
                control: {
                    Picker("", selection: inactiveMonthsBinding) {
                        Text("3 months").tag(3)
                        Text("6 months").tag(6)
                        Text("1 year").tag(12)
                    }
                    .labelsHidden()
                    .frame(width: 140)
                    .controlSize(.regular)
                }
            )
            .padding(.top, 8)
        }
    }

    private var dormantYearsBinding: Binding<Int> {
        Binding(
            get: { settingsStore.settings.dormantThresholdYears },
            set: { v in
                var s = settingsStore.settings
                s.dormantThresholdYears = v
                settingsStore.settings = s
            }
        )
    }

    private var inactiveMonthsBinding: Binding<Int> {
        Binding(
            get: { settingsStore.settings.inactiveThresholdMonths },
            set: { v in
                var s = settingsStore.settings
                s.inactiveThresholdMonths = v
                settingsStore.settings = s
            }
        )
    }

    // MARK: - Deletion

    private var deletionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Deletion behavior")
            Text("How to delete")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextPrimary)
            VStack(alignment: .leading, spacing: 0) {
                radioRow(
                    title: "Move to Trash (default and recommended)",
                    selected: settingsStore.settings.moveToTrash
                ) {
                    var s = settingsStore.settings
                    s.moveToTrash = true
                    settingsStore.settings = s
                }
                .padding(.leading, 16)
                .frame(height: 32)
                radioRow(
                    title: "Permanently delete",
                    selected: !settingsStore.settings.moveToTrash
                ) {
                    var s = settingsStore.settings
                    s.moveToTrash = false
                    settingsStore.settings = s
                }
                .padding(.leading, 16)
                .frame(height: 32)
                if !settingsStore.settings.moveToTrash {
                    Text("This cannot be undone. Files will not go to Trash.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyDanger)
                        .padding(.leading, 40)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
            .padding(.top, 4)
            .animation(.easeOut(duration: 0.15), value: settingsStore.settings.moveToTrash)

            if settingsStore.settings.moveToTrash {
                preferenceRow(
                    title: "Empty Trash after deletion",
                    subtitle: settingsStore.settings.emptyTrashAfterDeletion
                        ? "This cannot be undone."
                        : "Immediately empties Trash after Roomy moves files to it",
                    subtitleDanger: settingsStore.settings.emptyTrashAfterDeletion,
                    control: {
                        Toggle("", isOn: emptyTrashBinding)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                )
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: settingsStore.settings.moveToTrash)
    }

    private var emptyTrashBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.emptyTrashAfterDeletion },
            set: { v in
                var s = settingsStore.settings
                s.emptyTrashAfterDeletion = v
                settingsStore.settings = s
            }
        )
    }

    private var licenseSummary: String {
        switch license.state {
        case .licensed(let email): return "Licensed to \(email)"
        case .grandfathered: return "Free for you: you used Roomy before it went paid"
        case .unlicensed: return "Scanning is free. Cleaning needs a one-time license."
        }
    }

    private var automaticUpdatesBinding: Binding<Bool> {
        Binding(
            get: { updater.automaticallyChecksForUpdates },
            set: { updater.automaticallyChecksForUpdates = $0 }
        )
    }

    // MARK: - Exclusions bridge

    private var exclusionsBridgeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Exclusions")
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Excluded paths")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.roomyTextPrimary)
                    Text("Paths and projects that never appear in scan results")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                    Text("Glob patterns: `**` is treated like a single `*` (directory depth is not matched recursively).")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .padding(.top, 4)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text(exclusionsSummary)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                    Button("Manage →", action: onManageExclusions)
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roomyAccent)
                }
            }
            .frame(height: 44)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("About")
            HStack {
                Text("Version")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                Spacer()
                Text(versionString)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
            .frame(height: 44)
            HStack {
                Text("Check for updates")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                Spacer()
                Button("Check now →") {
                    updater.checkForUpdates()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyAccent)
                .disabled(!updater.canCheckForUpdates)
            }
            .frame(height: 44)
            preferenceRow(
                title: "Check for updates automatically",
                subtitle: "Once a day, from getroomy.dev. This is the only network request Roomy makes.",
                subtitleDanger: false,
                control: {
                    Toggle("", isOn: automaticUpdatesBinding)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            )
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("License")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.roomyTextPrimary)
                    Text(licenseSummary)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                }
                Spacer()
                switch license.state {
                case .licensed:
                    Button("Remove key") { license.deactivate() }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                case .grandfathered, .unlicensed:
                    Button(license.state == .unlicensed ? "Buy or enter key →" : "Enter key →") { showUnlockSheet = true }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.roomyAccent)
                }
            }
            .frame(height: 44)
            .sheet(isPresented: $showUnlockSheet) {
                RoomyUnlockSheet(
                    license: license,
                    pendingBytes: nil,
                    onUnlocked: { showUnlockSheet = false },
                    onCancel: { showUnlockSheet = false }
                )
            }
            HStack {
                Text("Terms")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                Spacer()
                Button("View terms (EULA) →") {
                    if let url = URL(string: RoomyMarketingLinks.eula) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyAccent)
            }
            .frame(height: 44)
            HStack {
                Text("Copyright")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                Spacer()
                Text("© 2026 Azbouki. All rights reserved.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
            }
            .frame(height: 44)

            HStack(spacing: 8) {
                linkPill("Documentation", url: RoomyMarketingLinks.documentation)
                Text("·")
                    .foregroundStyle(Color.roomyTextTertiary)
                linkPill("Privacy", url: RoomyMarketingLinks.privacy)
                Text("·")
                    .foregroundStyle(Color.roomyTextTertiary)
                linkPill("Contact", url: RoomyMarketingLinks.mailtoSupport)
            }
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color.roomyTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }

    private func linkPill(_ title: String, url: String) -> some View {
        Button(title) {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.roomyAccent)
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: - Building blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.roomyTextTertiary)
            .kerning(0.66)
            .padding(.bottom, 12)
    }

    private func preferenceRow(
        title: String,
        subtitle: String,
        subtitleDanger: Bool = false,
        @ViewBuilder control: () -> some View
    ) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.roomyTextPrimary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(subtitleDanger ? Color.roomyDanger : Color.roomyTextTertiary)
            }
            Spacer()
            control()
        }
        .frame(minHeight: 44)
    }
}

#Preview {
    SettingsView(
        settingsStore: RoomySettingsStore(),
        exclusionsStore: ExclusionsStore(),
        dismissContext: .welcome,
        onDismiss: {},
        onManageExclusions: {}
    )
    .frame(width: 900, height: 600)
}
