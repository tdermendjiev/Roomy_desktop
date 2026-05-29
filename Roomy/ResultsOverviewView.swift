//
//  ResultsOverviewView.swift
//  Roomy
//
//  S03 — Results overview (roomy_06_s03_results_overview).
//

import SwiftUI

struct ResultsOverviewView: View {
    var model: ScanResultsSummary
    var showPartialBanner: Bool
    var onDeleteDormantOnly: () -> Void
    var onReviewAllFindings: () -> Void
    var onSelectDormantProjects: () -> Void
    var onRescan: () -> Void
    var onChangeScanSettings: () -> Void
    var onOpenSettings: () -> Void

    @State private var heroProgress: CGFloat = 0
    @State private var segmentReveal: [CGFloat] = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    heroBand
                    bandDivider
                    if model.isEmpty {
                        emptyFollowUp
                    } else {
                        breakdownBand
                        bandDivider
                        actionsBand
                    }
                }
            }
            .background(Color.roomyBackground)

            ScanSessionFooterBar(
                summary: model,
                onRescan: onRescan,
                onChangeScanSettings: onChangeScanSettings
            )
        }
        .background(Color.roomyBackground)
        .toolbar(content: {
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
            segmentReveal = Array(repeating: 0, count: model.ageSegments.count)
            startHeroAnimation()
            startBarAnimation()
        }
    }

    // MARK: - Hero

    private var heroBand: some View {
        VStack(spacing: 0) {
            if showPartialBanner {
                partialHeroBanner
                    .padding(.bottom, 16)
            }

            if model.isEmpty {
                emptyHero
            } else {
                filledHero
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color.roomyBackground)
    }

    private var partialHeroBanner: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyStatusInactive)
            Text("Partial scan — results may be incomplete. Re-scan for full results.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Re-scan →", action: onRescan)
                .buttonStyle(.roomyGhost)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.roomyStatusInactive.opacity(0.1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.roomyStatusInactive)
                .frame(width: 3)
        }
    }

    private var filledHero: some View {
        let eased = easeOutCubic(Double(heroProgress))
        let gb = model.totalRecoverableGB * eased

        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: String(format: "%.1f", gb))
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color.roomyTextPrimary)
                    .monospacedDigit()
                Text("GB")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
            .padding(.bottom, 8)

            Text("recoverable across \(model.projectCount) projects")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)

            Text("Safely deletable — all regenerable from source")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .padding(.top, 8)

            if model.systemCacheGB >= 0.05 {
                Text("Includes \(String(format: "%.1f GB", model.systemCacheGB)) of system caches")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                    .padding(.top, 4)
            }

            Text("System caches scanned separately from project path.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary.opacity(0.85))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyHero: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color.roomyStatusActive)
            Text("Nothing to clean up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
            Text("No regenerable artifacts found in \(model.scannedPathLabel)")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyFollowUp: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button("Re-scan", action: onRescan)
                    .buttonStyle(.roomySecondary)
                Button("Change scan settings", action: onChangeScanSettings)
                    .buttonStyle(.roomyGhost)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(Color.roomyBackground)
    }

    // MARK: - Breakdown

    private var breakdownBand: some View {
        GeometryReader { geo in
            let midGap: CGFloat = 24
            let lineWidth: CGFloat = 1
            let leftW = geo.size.width * 0.55 - midGap / 2 - lineWidth / 2
            let rightW = geo.size.width * 0.45 - midGap / 2 - lineWidth / 2
            HStack(alignment: .top, spacing: 0) {
                ecosystemColumn
                    .frame(width: leftW, alignment: .topLeading)
                HStack(spacing: 0) {
                    Spacer().frame(width: 12)
                    Rectangle()
                        .fill(Color.roomyBorderSubtle)
                        .frame(width: lineWidth)
                    Spacer().frame(width: 12)
                }
                ageColumn
                    .frame(width: rightW, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(height: 220)
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(Color.roomyBackground)
    }

    private var ecosystemColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionCaption("By ecosystem")
                .padding(.bottom, 12)

            ZStack(alignment: .trailing) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(model.ecosystems) { card in
                            ecosystemCard(card)
                        }
                    }
                }
                LinearGradient(
                    colors: [Color.roomyBackground.opacity(0), Color.roomyBackground],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
                .allowsHitTesting(false)
            }
            .frame(height: 88)
        }
    }

    private func ecosystemCard(_ card: EcosystemResultCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: card.iconSystemName)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
            Text(card.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.roomyTextPrimary)
                .lineLimit(1)
            Text(String(format: "%.1f GB", card.sizeGB))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
                .monospacedDigit()
            Text("\(card.projectCount) projects")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.roomyTextSecondary)
        }
        .padding(12)
        .frame(width: 140, height: 88, alignment: .topLeading)
        .background(card.isLargest ? Color.roomyAccentSubtle : Color.roomyElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.roomyBorderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var ageColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionCaption("By project age")
                .padding(.bottom, 12)

            ageStackedBar
                .padding(.bottom, 10)

            ageLegend
        }
    }

    @ViewBuilder
    private var ageStackedBar: some View {
        let total = model.ageSegments.reduce(0.0) { $0 + $1.gigabytes }
        if total <= 0 {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.roomyInset)
                .frame(height: 12)
        } else {
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 0) {
                    ForEach(Array(model.ageSegments.enumerated()), id: \.offset) { index, seg in
                        let frac = seg.gigabytes / total
                        let reveal = index < segmentReveal.count ? segmentReveal[index] : 1
                        seg.tier.swatchColor
                            .frame(width: max(0, w * frac * CGFloat(reveal)))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .frame(height: 12)
        }
    }

    private var ageLegend: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(model.ageSegments.enumerated()), id: \.offset) { _, seg in
                HStack(spacing: 8) {
                    Circle()
                        .fill(seg.tier.swatchColor)
                        .frame(width: 8, height: 8)
                    Text(seg.tier.legendTitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roomyTextSecondary)
                    Spacer(minLength: 8)
                    Text(String(format: "%.1f GB", seg.gigabytes))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.roomyTextPrimary)
                    Text("\(seg.projectCount) projects")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                        .frame(minWidth: 72, alignment: .trailing)
                }
                .frame(height: 24)
            }
        }
    }

    // MARK: - Actions

    private var actionsBand: some View {
        let dormant = model.dormantRecoverableGB
        return HStack(alignment: .center) {
            Button("Select dormant projects", action: onSelectDormantProjects)
                .buttonStyle(.roomyGhost)

            Spacer(minLength: 16)

            Button("Review all findings →", action: onReviewAllFindings)
                .buttonStyle(.roomySecondary)

            Spacer(minLength: 16)

            Button {
                onDeleteDormantOnly()
            } label: {
                Text("Delete dormant only (\(String(format: "%.1f", dormant)) GB)")
            }
            .buttonStyle(.roomyDestructiveLarge)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.roomyElevated)
    }

    private var bandDivider: some View {
        Rectangle()
            .fill(Color.roomyBorderSubtle)
            .frame(height: 1)
    }

    private func sectionCaption(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.roomyTextTertiary)
            .kerning(0.66)
    }

    private func startHeroAnimation() {
        guard !model.isEmpty else {
            heroProgress = 1
            return
        }
        heroProgress = 0
        withAnimation(.easeOut(duration: 0.8)) {
            heroProgress = 1
        }
    }

    private func startBarAnimation() {
        let n = segmentReveal.count
        guard n > 0 else { return }
        for i in 0..<n {
            let delay = 0.08 * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.6)) {
                    segmentReveal[i] = 1
                }
            }
        }
    }

    private func easeOutCubic(_ t: Double) -> Double {
        let x = min(1, max(0, t))
        return 1 - pow(1 - x, 3)
    }
}

#Preview("S03 — full") {
    ResultsOverviewView(
        model: .canonical,
        showPartialBanner: false,
        onDeleteDormantOnly: {},
        onReviewAllFindings: {},
        onSelectDormantProjects: {},
        onRescan: {},
        onChangeScanSettings: {},
        onOpenSettings: {}
    )
    .frame(width: 900, height: 600)
}

#Preview("S03 — partial") {
    ResultsOverviewView(
        model: .canonical,
        showPartialBanner: true,
        onDeleteDormantOnly: {},
        onReviewAllFindings: {},
        onSelectDormantProjects: {},
        onRescan: {},
        onChangeScanSettings: {},
        onOpenSettings: {}
    )
    .frame(width: 900, height: 600)
}
