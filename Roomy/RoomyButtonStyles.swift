//
//  RoomyButtonStyles.swift
//  Roomy
//
//  Button styles aligned with roomy_03_component_library (primary, secondary, ghost).
//

import SwiftUI
import RoomyCore

struct RoomyPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor(isPressed: configuration.isPressed))
            )
            .foregroundStyle(Color.roomyOnAccent)
            .contentShape(Rectangle())
    }

    private func fillColor(isPressed: Bool) -> Color {
        guard isEnabled else { return Color.roomyAccent.opacity(0.35) }
        if isPressed { return Color.roomyAccent.opacity(0.88) }
        return Color.roomyAccent
    }
}

struct RoomySecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.roomyBorderDefault, lineWidth: 1)
            )
            .foregroundStyle(Color.roomyTextPrimary.opacity(isEnabled ? 1 : 0.45))
            .contentShape(Rectangle())
    }

    private func backgroundFill(isPressed: Bool) -> Color {
        guard isEnabled else { return Color.clear }
        return isPressed ? Color.roomyHover : Color.clear
    }
}

struct RoomyPrimaryLargeButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .frame(width: 200, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor(isPressed: configuration.isPressed))
            )
            .foregroundStyle(Color.roomyOnAccent)
            .contentShape(Rectangle())
    }

    private func fillColor(isPressed: Bool) -> Color {
        guard isEnabled else { return Color.roomyAccent.opacity(0.35) }
        if isPressed { return Color.roomyAccent.opacity(0.88) }
        return Color.roomyAccent
    }
}

struct RoomyDestructiveLargeButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor(isPressed: configuration.isPressed))
            )
            .foregroundStyle(Color.white)
            .contentShape(Rectangle())
    }

    private func fillColor(isPressed: Bool) -> Color {
        guard isEnabled else { return Color.roomyDanger.opacity(0.35) }
        if isPressed { return Color.roomyDanger.opacity(0.88) }
        return Color.roomyDanger
    }
}

struct RoomyGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .regular))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? Color.roomyAccentSubtle : Color.clear)
            )
            .foregroundStyle(Color.roomyAccent.opacity(isEnabled ? 1 : 0.45))
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == RoomyPrimaryButtonStyle {
    static var roomyPrimary: RoomyPrimaryButtonStyle { RoomyPrimaryButtonStyle() }
}

extension ButtonStyle where Self == RoomySecondaryButtonStyle {
    static var roomySecondary: RoomySecondaryButtonStyle { RoomySecondaryButtonStyle() }
}

extension ButtonStyle where Self == RoomyGhostButtonStyle {
    static var roomyGhost: RoomyGhostButtonStyle { RoomyGhostButtonStyle() }
}

extension ButtonStyle where Self == RoomyPrimaryLargeButtonStyle {
    static var roomyPrimaryLarge: RoomyPrimaryLargeButtonStyle { RoomyPrimaryLargeButtonStyle() }
}

extension ButtonStyle where Self == RoomyDestructiveLargeButtonStyle {
    static var roomyDestructiveLarge: RoomyDestructiveLargeButtonStyle { RoomyDestructiveLargeButtonStyle() }
}
