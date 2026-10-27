//
//  RoomyTheme.swift
//  Roomy
//
//  Semantic colors from roomy_01_visual_identity — dynamic light / dark.
//

import AppKit
import RoomyCore
import SwiftUI

extension Color {
    static let roomyBackground = Color(nsColor: .roomyBackground)
    static let roomyElevated = Color(nsColor: .roomyElevated)
    static let roomyInset = Color(nsColor: .roomyInset)
    static let roomyHover = Color(nsColor: .roomyHover)

    static let roomyTextPrimary = Color(nsColor: .roomyTextPrimary)
    static let roomyTextSecondary = Color(nsColor: .roomyTextSecondary)
    static let roomyTextTertiary = Color(nsColor: .roomyTextTertiary)

    static let roomyAccent = Color(nsColor: .roomyAccent)
    static let roomyAccentHover = Color(nsColor: .roomyAccentHover)
    static let roomyAccentSubtle = Color(nsColor: .roomyAccentSubtle)
    static let roomyOnAccent = Color(nsColor: .roomyOnAccent)

    static let roomyBorderSubtle = Color(nsColor: .roomyBorderSubtle)
    static let roomyBorderDefault = Color(nsColor: .roomyBorderDefault)
    static let roomyBorderStrong = Color(nsColor: .roomyBorderStrong)

    static let roomyStatusActive = Color(nsColor: .roomyStatusActive)
    static let roomyStatusActiveText = Color(nsColor: .roomyStatusActiveText)
    static let roomyStatusRecent = Color(nsColor: .roomyStatusRecent)
    static let roomyStatusRecentText = Color(nsColor: .roomyStatusRecentText)
    static let roomyStatusInactive = Color(nsColor: .roomyStatusInactive)
    static let roomyStatusInactiveText = Color(nsColor: .roomyStatusInactiveText)
    static let roomyStatusDormant = Color(nsColor: .roomyStatusDormant)
    static let roomyStatusDormantText = Color(nsColor: .roomyStatusDormantText)

    static let roomyDanger = Color(nsColor: .roomyDanger)
    static let roomyDangerHover = Color(nsColor: .roomyDangerHover)
}

// MARK: - NSColor (dynamic appearance)

private extension NSColor {
    static func roomyDynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
    }

    static let roomyBackground = roomyDynamic(
        light: NSColor(srgbRed: 0.969, green: 0.969, blue: 0.961, alpha: 1),
        dark: NSColor(srgbRed: 0.071, green: 0.075, blue: 0.094, alpha: 1)
    )

    static let roomyElevated = roomyDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1),
        dark: NSColor(srgbRed: 0.102, green: 0.106, blue: 0.133, alpha: 1)
    )

    static let roomyInset = roomyDynamic(
        light: NSColor(srgbRed: 0.922, green: 0.918, blue: 0.902, alpha: 1),
        dark: NSColor(srgbRed: 0.047, green: 0.051, blue: 0.067, alpha: 1)
    )

    static let roomyHover = roomyDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.04),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.04)
    )

    static let roomyTextPrimary = roomyDynamic(
        light: NSColor(srgbRed: 0.094, green: 0.094, blue: 0.102, alpha: 1),
        dark: NSColor(srgbRed: 0.925, green: 0.925, blue: 0.945, alpha: 1)
    )

    static let roomyTextSecondary = roomyDynamic(
        light: NSColor(srgbRed: 0.322, green: 0.322, blue: 0.357, alpha: 1),
        dark: NSColor(srgbRed: 0.608, green: 0.608, blue: 0.659, alpha: 1)
    )

    static let roomyTextTertiary = roomyDynamic(
        light: NSColor(srgbRed: 0.631, green: 0.631, blue: 0.651, alpha: 1),
        dark: NSColor(srgbRed: 0.396, green: 0.396, blue: 0.420, alpha: 1)
    )

    static let roomyAccent = roomyDynamic(
        light: NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 1),
        dark: NSColor(srgbRed: 0.310, green: 0.561, blue: 0.969, alpha: 1)
    )

    static let roomyAccentHover = roomyDynamic(
        light: NSColor(srgbRed: 0.114, green: 0.306, blue: 0.722, alpha: 1),
        dark: NSColor(srgbRed: 0.420, green: 0.639, blue: 1, alpha: 1)
    )

    static let roomyAccentSubtle = roomyDynamic(
        light: NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 0.12),
        dark: NSColor(srgbRed: 0.310, green: 0.561, blue: 0.969, alpha: 0.14)
    )

    static let roomyOnAccent = NSColor(srgbRed: 0.973, green: 0.980, blue: 0.988, alpha: 1)

    static let roomyBorderSubtle = roomyDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.08),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.08)
    )

    static let roomyBorderDefault = roomyDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.12),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.14)
    )

    static let roomyBorderStrong = roomyDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.22),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.24)
    )

    static let roomyStatusActive = NSColor(srgbRed: 0.204, green: 0.827, blue: 0.600, alpha: 1)
    static let roomyStatusActiveText = roomyDynamic(
        light: NSColor(srgbRed: 0.059, green: 0.451, blue: 0.318, alpha: 1),
        dark: NSColor(srgbRed: 0.431, green: 0.906, blue: 0.718, alpha: 1)
    )

    static let roomyStatusRecent = NSColor(srgbRed: 0.220, green: 0.741, blue: 0.973, alpha: 1)
    static let roomyStatusRecentText = roomyDynamic(
        light: NSColor(srgbRed: 0.027, green: 0.439, blue: 0.627, alpha: 1),
        dark: NSColor(srgbRed: 0.490, green: 0.827, blue: 0.988, alpha: 1)
    )

    static let roomyStatusInactive = NSColor(srgbRed: 0.984, green: 0.749, blue: 0.141, alpha: 1)
    static let roomyStatusInactiveText = roomyDynamic(
        light: NSColor(srgbRed: 0.600, green: 0.345, blue: 0.043, alpha: 1),
        dark: NSColor(srgbRed: 0.992, green: 0.831, blue: 0.341, alpha: 1)
    )

    static let roomyStatusDormant = NSColor(srgbRed: 0.973, green: 0.443, blue: 0.443, alpha: 1)
    static let roomyStatusDormantText = roomyDynamic(
        light: NSColor(srgbRed: 0.702, green: 0.153, blue: 0.153, alpha: 1),
        dark: NSColor(srgbRed: 0.988, green: 0.647, blue: 0.647, alpha: 1)
    )

    static let roomyDanger = roomyDynamic(
        light: NSColor(srgbRed: 0.863, green: 0.149, blue: 0.149, alpha: 1),
        dark: NSColor(srgbRed: 0.937, green: 0.267, blue: 0.267, alpha: 1)
    )

    static let roomyDangerHover = roomyDynamic(
        light: NSColor(srgbRed: 0.725, green: 0.106, blue: 0.106, alpha: 1),
        dark: NSColor(srgbRed: 0.973, green: 0.443, blue: 0.443, alpha: 1)
    )
}

extension ProjectActivity {
    var dotColor: Color {
        switch self {
        case .active: .roomyStatusActive
        case .recent: .roomyStatusRecent
        case .inactive: .roomyStatusInactive
        case .dormant: .roomyStatusDormant
        }
    }

    var labelColor: Color {
        switch self {
        case .active: .roomyStatusActiveText
        case .recent: .roomyStatusRecentText
        case .inactive: .roomyStatusInactiveText
        case .dormant: .roomyStatusDormantText
        }
    }
}

extension ArtifactSafetyTier {
    var badgeColor: Color {
        switch self {
        case .safe: Color.roomyAccent
        case .caution: Color.roomyStatusInactiveText
        case .warning: Color.roomyStatusDormantText
        }
    }
}
