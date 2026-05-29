//
//  ScanningView.swift
//  Roomy
//
//  S02 — Scanning progress (roomy_05_s02_scanning).
//

import Foundation
import SwiftUI

// MARK: - View model

@MainActor
final class ScanningViewModel: ObservableObject {
    @Published var isIndeterminate = true
    @Published var progress: Double = 0
    @Published var foldersScanned = 0
    @Published var projectsFound = 0
    @Published var artifactsFound = 0
    @Published var recoverableBytes: Int64 = 0
    @Published var livePath: String = ""
    @Published var tickerRows: [ScanningTickerRow] = []
    @Published var completionPulse = false
    @Published var phaseLabel = "Scanning your projects…"

    private var scanTask: Task<Void, Never>?
    private var hasEnded = false
    private var scanAggregate: ScanAggregate?
    private var lastTickerPath: String?
    private let rootPathLabel: String
    private let scanRootURL: URL
    private let homeDirectoryURL: URL
    private let dormantYears: Int
    private let inactiveMonths: Int
    private let exclusionEntries: [ExclusionEntry]
    private let enabledEcosystemTags: Set<String>
    private let enabledSystemScanKeys: Set<String>
    private let onCompleted: (ScanResultsSummary, ScanAggregate) -> Void
    private let onCancelled: (ScanResultsSummary, ScanAggregate) -> Void

    init(
        rootPathLabel: String,
        scanRootURL: URL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        dormantYears: Int = 2,
        inactiveMonths: Int = 6,
        exclusionEntries: [ExclusionEntry] = [],
        enabledEcosystemTags: Set<String>,
        enabledSystemScanKeys: Set<String> = Set(RoomySystemScanCategories.all.map(\.key)),
        onCompleted: @escaping (ScanResultsSummary, ScanAggregate) -> Void,
        onCancelled: @escaping (ScanResultsSummary, ScanAggregate) -> Void
    ) {
        self.rootPathLabel = rootPathLabel
        self.scanRootURL = scanRootURL
        self.homeDirectoryURL = homeDirectory
        self.dormantYears = dormantYears
        self.inactiveMonths = inactiveMonths
        self.exclusionEntries = exclusionEntries
        self.enabledEcosystemTags = enabledEcosystemTags
        self.enabledSystemScanKeys = enabledSystemScanKeys
        self.onCompleted = onCompleted
        self.onCancelled = onCancelled
        livePath = rootPathLabel
    }

    func start() {
        scanTask?.cancel()
        scanTask = Task { @MainActor in
            await self.runScan()
        }
    }

    func cancel() {
        scanTask?.cancel()
    }

    private func finishCancelled() {
        guard !hasEnded else { return }
        hasEnded = true
        scanTask = nil
        onCancelled(makeSummary(), scanAggregate ?? .empty)
    }

    private func finishCompleted() {
        guard !hasEnded else { return }
        hasEnded = true
        scanTask = nil
        onCompleted(makeSummary(), scanAggregate ?? .empty)
    }

    private func makeSummary() -> ScanResultsSummary {
        if let aggregate = scanAggregate {
            return ScanResultsSummary.from(
                aggregate: aggregate,
                scannedPathLabel: rootPathLabel,
                dormantYears: dormantYears,
                inactiveMonths: inactiveMonths
            )
        }
        return ScanResultsSummary.fromLiveScan(
            recoverableBytes: recoverableBytes,
            projectCount: projectsFound,
            scannedPathLabel: rootPathLabel
        )
    }

    private func runScan() async {
        scanAggregate = nil
        lastTickerPath = nil
        isIndeterminate = true
        progress = 0

        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled else {
            finishCancelled()
            return
        }

        let exclusionFilter = RoomyScanExclusionFilter(
            entries: exclusionEntries,
            homeDirectory: homeDirectoryURL
        )
        phaseLabel = "Scanning your projects…"
        let projectAggregate = await FilesystemArtifactScanner.scan(
            root: scanRootURL,
            homeDirectory: homeDirectoryURL,
            enabledEcosystemTags: enabledEcosystemTags,
            exclusionFilter: exclusionFilter,
            shouldCancel: { Task.isCancelled },
            onProgress: { [weak self] tick in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.foldersScanned = tick.foldersScanned
                    self.projectsFound = tick.projectRootsFound
                    self.livePath = tick.currentPathDisplay
                    self.artifactsFound = tick.artifactsFound
                    self.recoverableBytes = tick.recoverableBytes
                    if let finding = tick.latestFinding, finding.path != self.lastTickerPath {
                        self.lastTickerPath = finding.path
                        self.pushTickerRow(finding)
                    }
                }
            }
        )

        if Task.isCancelled {
            scanAggregate = projectAggregate
            finishCancelled()
            return
        }

        var merged = projectAggregate
        if !enabledSystemScanKeys.isEmpty {
            phaseLabel = "Checking system caches…"
            livePath = "System caches"
            let systemAggregate = await SystemArtifactScanner.scan(
                homeDirectory: homeDirectoryURL,
                enabledCategories: enabledSystemScanKeys,
                enabledEcosystemTags: enabledEcosystemTags,
                exclusionFilter: exclusionFilter,
                projectAggregate: projectAggregate,
                shouldCancel: { Task.isCancelled },
                onProgress: { [weak self] tick in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.livePath = tick.phaseLabel
                        self.artifactsFound = projectAggregate.artifactCount + tick.artifactsFound
                        self.recoverableBytes = projectAggregate.totalBytes + tick.recoverableBytes
                        if let finding = tick.latestFinding, finding.path != self.lastTickerPath {
                            self.lastTickerPath = finding.path
                            self.pushTickerRow(finding)
                        }
                    }
                }
            )
            merged = ScanAggregate.merge(projectAggregate, systemAggregate)
        }

        scanAggregate = merged
        projectsFound = merged.projectRootPaths.count
        artifactsFound = merged.artifactCount
        recoverableBytes = merged.totalBytes
        foldersScanned = max(foldersScanned, 1)
        livePath = rootPathLabel

        if Task.isCancelled {
            finishCancelled()
            return
        }

        isIndeterminate = false
        progress = 1

        completionPulse = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        completionPulse = false

        try? await Task.sleep(nanoseconds: 800_000_000)
        guard !Task.isCancelled else {
            finishCancelled()
            return
        }

        finishCompleted()
    }

    private func pushTickerRow(_ finding: ScanArtifactFinding) {
        let path = FilesystemArtifactScanner.shortenedDisplayPath(filePath: finding.path, homeDirectory: homeDirectoryURL)
        let row = ScanningTickerRow(
            ecosystemTag: finding.ecosystemTag,
            artifact: finding.label.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
            path: path,
            size: formatByteCount(finding.sizeBytes)
        )
        withAnimation(.easeOut(duration: 0.15)) {
            tickerRows.insert(row, at: 0)
            if tickerRows.count > 12 {
                tickerRows.removeLast(tickerRows.count - 12)
            }
        }
    }

    private func formatByteCount(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}

struct ScanningTickerRow: Identifiable, Equatable {
    let id = UUID()
    let ecosystemTag: String
    let artifact: String
    let path: String
    let size: String
}

// MARK: - Screen

struct ScanningView: View {
    var rootPathLabel: String
    var scanRootURL: URL
    var dormantYears: Int
    var inactiveMonths: Int
    var exclusionEntries: [ExclusionEntry]
    var enabledEcosystemTags: Set<String>
    var enabledSystemScanKeys: Set<String>
    var onCompleted: (ScanResultsSummary, ScanAggregate) -> Void
    var onCancelled: (ScanResultsSummary, ScanAggregate) -> Void
    var onOpenSettings: () -> Void

    @StateObject private var model: ScanningViewModel

    init(
        rootPathLabel: String,
        scanRootURL: URL,
        dormantYears: Int = 2,
        inactiveMonths: Int = 6,
        exclusionEntries: [ExclusionEntry] = [],
        enabledEcosystemTags: Set<String>,
        enabledSystemScanKeys: Set<String> = Set(RoomySystemScanCategories.all.map(\.key)),
        onCompleted: @escaping (ScanResultsSummary, ScanAggregate) -> Void,
        onCancelled: @escaping (ScanResultsSummary, ScanAggregate) -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.rootPathLabel = rootPathLabel
        self.scanRootURL = scanRootURL
        self.dormantYears = dormantYears
        self.inactiveMonths = inactiveMonths
        self.exclusionEntries = exclusionEntries
        self.enabledEcosystemTags = enabledEcosystemTags
        self.enabledSystemScanKeys = enabledSystemScanKeys
        self.onCompleted = onCompleted
        self.onCancelled = onCancelled
        self.onOpenSettings = onOpenSettings
        _model = StateObject(
            wrappedValue: ScanningViewModel(
                rootPathLabel: rootPathLabel,
                scanRootURL: scanRootURL,
                dormantYears: dormantYears,
                inactiveMonths: inactiveMonths,
                exclusionEntries: exclusionEntries,
                enabledEcosystemTags: enabledEcosystemTags,
                enabledSystemScanKeys: enabledSystemScanKeys,
                onCompleted: onCompleted,
                onCancelled: onCancelled
            )
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                headerBlock
                    .padding(.bottom, 32)

                progressSection
                    .padding(.bottom, 32)

                findingsTicker
                    .padding(.bottom, 24)

                cancelControl
            }
            .frame(width: 560)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            .padding(.bottom, 40)
        }
        .background(Color.roomyBackground)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                Text("Roomy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape", action: onOpenSettings)
                    .help("Settings unavailable during scan")
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.roomyTextTertiary.opacity(0.45))
                    .disabled(true)
            }
        })
        .onAppear {
            model.start()
        }
    }

    private var headerBlock: some View {
        VStack(spacing: 6) {
            Text(model.phaseLabel)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
                .multilineTextAlignment(.center)
            Text(model.livePath)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.roomyTextSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressSection: some View {
        VStack(spacing: 0) {
            Group {
                if model.isIndeterminate {
                    ScanningIndeterminateBar()
                } else {
                    ScanningDeterminateBar(progress: model.progress, pulse: model.completionPulse)
                }
            }
            .frame(width: 360)

            if !model.isIndeterminate {
                Text("\(Int(model.progress * 100))%")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                    .frame(width: 360, alignment: .trailing)
                    .padding(.top, 6)
            }

            statsGrid
                .padding(.top, model.isIndeterminate ? 28 : 22)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsGrid: some View {
        let fmt = ScanningView.numberFormatter
        return VStack(spacing: 12) {
            HStack(spacing: 16) {
                statCell(
                    value: fmt.string(from: NSNumber(value: model.foldersScanned)) ?? "0",
                    label: "Folders scanned",
                    hero: false
                )
                statCell(
                    value: fmt.string(from: NSNumber(value: model.projectsFound)) ?? "0",
                    label: "Projects found",
                    hero: false
                )
            }
            HStack(spacing: 16) {
                statCell(
                    value: fmt.string(from: NSNumber(value: model.artifactsFound)) ?? "0",
                    label: "Artifacts found",
                    hero: false
                )
                statCell(
                    value: formatRecoverable(model.recoverableBytes),
                    label: "Recoverable so far",
                    hero: true
                )
            }
        }
        .frame(width: 360)
    }

    private func statCell(value: String, label: String, hero: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(hero ? Color.roomyAccent : Color.roomyTextPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
        }
        .padding(12)
        .frame(width: 172, height: 56, alignment: .leading)
        .background(hero ? Color.roomyAccentSubtle : Color.roomyElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.roomyBorderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var findingsTicker: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(spacing: 0) {
                    ForEach(Array(model.tickerRows.prefix(5).enumerated()), id: \.element.id) { index, row in
                        tickerRowView(row, emphasis: index)
                            .frame(height: 22)
                    }
                    if model.tickerRows.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            Color.clear.frame(height: 22)
                        }
                    } else if model.tickerRows.count < 5 {
                        ForEach(0..<(5 - model.tickerRows.count), id: \.self) { _ in
                            Color.clear.frame(height: 22)
                        }
                    }
                }

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.roomyBackground, Color.roomyBackground.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                    Spacer(minLength: 0)
                    LinearGradient(
                        colors: [Color.roomyBackground.opacity(0), Color.roomyBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                }
                .allowsHitTesting(false)
            }
            .frame(width: 480, height: 110)
            .clipped()
        }
        .frame(maxWidth: .infinity)
    }

    private func tickerRowView(_ row: ScanningTickerRow, emphasis: Int) -> some View {
        let primary = Color.roomyTextPrimary
        let tertiary = Color.roomyTextTertiary
        let nameColor = emphasis == 0 ? primary : primary.opacity(1 - Double(emphasis) * 0.18)
        let pathColor = emphasis == 0 ? tertiary.opacity(0.95) : tertiary

        return HStack(spacing: 8) {
            Text("[\(row.ecosystemTag)]")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(tertiary)
                .frame(width: 44, alignment: .leading)

            Text(row.artifact)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(nameColor)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            Text(row.path)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(pathColor)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            Text(row.size)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.roomyAccent)
                .frame(width: 64, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 4)
        .transition(.opacity.combined(with: .offset(y: 4)))
    }

    private var cancelControl: some View {
        Button("Cancel scan") {
            model.cancel()
        }
        .buttonStyle(.plain)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(Color.roomyTextTertiary)
        .frame(maxWidth: .infinity)
    }

    private func formatRecoverable(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb < 0.05 { return "0 GB" }
        return String(format: "%.1f GB", gb)
    }

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()
}

// MARK: - Progress bars

private struct ScanningIndeterminateBar: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 1.25) / 1.25
            GeometryReader { geo in
                let w = geo.size.width
                let band = w * 0.34
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Color.roomyAccent.opacity(0.12))
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Color.roomyAccent)
                        .frame(width: band)
                        .offset(x: t * (w + band) - band)
                }
            }
            .frame(height: 2)
            .frame(maxWidth: 360)
        }
        .frame(width: 360, height: 2)
    }
}

private struct ScanningDeterminateBar: View {
    var progress: Double
    var pulse: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.roomyAccent.opacity(0.12))
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.roomyAccent.opacity(pulse ? 1 : 0.92))
                    .frame(width: max(0, w * progress))
                    .animation(.easeInOut(duration: 0.15), value: pulse)
            }
        }
        .frame(height: 4)
        .frame(maxWidth: 360)
    }
}

#Preview {
    ScanningView(
        rootPathLabel: "~/",
        scanRootURL: FileManager.default.homeDirectoryForCurrentUser,
        enabledEcosystemTags: Set(RoomySettingsEcosystems.all.map(\.key)),
        onCompleted: { _, _ in },
        onCancelled: { _, _ in },
        onOpenSettings: {}
    )
    .frame(width: 900, height: 600)
}
