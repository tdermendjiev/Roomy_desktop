//
//  ExclusionsManagerView.swift
//  Roomy
//
//  S10 — Exclusions manager (roomy_11_s09_s10).
//

import AppKit
import RoomyCore
import SwiftUI

struct ExclusionsManagerView: View {
    @ObservedObject var exclusionsStore: ExclusionsStore
    var parent: ExclusionsDismissParent
    var onDismiss: () -> Void

    @State private var patternMode = false
    @State private var patternText = ""
    @FocusState private var patternFocused: Bool

    private var backTitle: String {
        switch parent {
        case .settings: "← Settings"
        case .projectDetail: "← Project"
        }
    }

    private var countCaption: String {
        let n = exclusionsStore.count
        if n == 0 { return "No paths excluded" }
        return "\(n) paths excluded"
    }

    var body: some View {
        VStack(spacing: 0) {
            listHeader
            ScrollView(.vertical, showsIndicators: true) {
                if exclusionsStore.entries.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else {
                    VStack(spacing: 0) {
                        ForEach(exclusionsStore.entries) { entry in
                            exclusionRow(entry)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            addControlsBar
        }
        .background(Color.roomyBackground)
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                Button(backTitle, action: onDismiss)
            }
            ToolbarItem(placement: .principal) {
                Text("Exclusions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.roomyTextSecondary)
            }
        })
    }

    private var listHeader: some View {
        HStack {
            Text("Exclusions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.roomyTextPrimary)
            Spacer()
            Text(countCaption)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
        }
        .padding(.horizontal, 24)
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(Color.roomyElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.slash")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
            Text("No exclusions yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.roomyTextSecondary)
            Text("Projects you exclude will never appear in scan results")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.roomyTextTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }

    private func exclusionRow(_ entry: ExclusionEntry) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.pathDisplay)
                    .font(.system(size: 13, weight: .regular, design: entry.kind == .pattern ? .monospaced : .default))
                    .foregroundStyle(entry.kind == .pattern ? Color.roomyTextSecondary : Color.roomyTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    typeBadge(entry.kind)
                    Text("Added \(formattedAdded(entry.addedAt))")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.roomyTextTertiary)
                }
            }
            Spacer()
            RemoveExclusionButton {
                withAnimation(.easeOut(duration: 0.15)) {
                    exclusionsStore.remove(id: entry.id)
                }
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 52)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
        }
    }

    private func typeBadge(_ kind: ExclusionRowKind) -> some View {
        Text(kind.title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.roomyTextSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.roomyElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.roomyBorderDefault, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var addControlsBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.roomyBorderSubtle)
                .frame(height: 1)
            HStack {
                if patternMode {
                    patternInputRow
                } else {
                    Button(action: addPathTapped) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 14, weight: .regular))
                            Text("Add path")
                        }
                    }
                    .buttonStyle(.roomySecondary)
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            patternMode = true
                            patternText = ""
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                            patternFocused = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 14, weight: .regular))
                            Text("Add pattern")
                        }
                    }
                    .buttonStyle(.roomySecondary)
                    .padding(.leading, 8)
                }
                Spacer()
                Text("Changes take effect on next scan")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.roomyTextTertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 24)
            .frame(height: 52)
            .background(Color.roomyElevated)
        }
    }

    private var patternInputRow: some View {
        HStack(spacing: 8) {
            TextField("e.g. */vendor/* or ~/work/**", text: $patternText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .focused($patternFocused)
                .padding(.horizontal, 10)
                .frame(width: 360, height: 28)
                .background(Color.roomyInset)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(patternFocused ? Color.roomyBorderStrong : Color.roomyBorderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Button("Add") {
                exclusionsStore.addPattern(patternText)
                withAnimation(.easeOut(duration: 0.15)) {
                    patternMode = false
                    patternText = ""
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.roomyOnAccent)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.roomyAccent.opacity(
                        patternText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 ? 0.35 : 1
                    ))
            )
            .disabled(patternText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
            Button("Cancel") {
                withAnimation(.easeOut(duration: 0.15)) {
                    patternMode = false
                    patternText = ""
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Color.roomyAccent)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func addPathTapped() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let path = pathDisplayWithTilde(url: url)
            exclusionsStore.addPath(path, kind: .path)
        }
    }

    private func pathDisplayWithTilde(url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let p = url.path
        if p == home { return "~" }
        if p.hasPrefix(home + "/") {
            return "~/" + String(p.dropFirst(home.count + 1))
        }
        return p
    }

    private func formattedAdded(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

private struct RemoveExclusionButton: View {
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(hovering ? Color.roomyDanger : Color.roomyTextTertiary)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.08), value: hovering)
    }
}

#Preview("S10 — sample") {
    ExclusionsManagerView(
        exclusionsStore: {
            let ex = ExclusionsStore()
            ex.entries = ExclusionsStore.designSampleEntries()
            return ex
        }(),
        parent: .settings(.welcome),
        onDismiss: {}
    )
    .frame(width: 900, height: 600)
}

#Preview("S10 — empty") {
    ExclusionsManagerView(
        exclusionsStore: ExclusionsStore(),
        parent: .settings(.welcome),
        onDismiss: {}
    )
    .frame(width: 900, height: 600)
}
