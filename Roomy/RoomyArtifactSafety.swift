//
//  RoomyArtifactSafety.swift
//  Roomy
//

import SwiftUI

enum ArtifactSource: String, Codable, Sendable, Equatable {
    case projectWalk
    case systemProbe
    case dockerCLI
    case condaCLI
    case pipCLI
}

enum ArtifactSafetyTier: String, Codable, Sendable, Equatable {
    case safe
    case caution
    case warning

    var displayLabel: String {
        switch self {
        case .safe: "Safe"
        case .caution: "Review"
        case .warning: "Irreversible"
        }
    }

    var badgeColor: Color {
        switch self {
        case .safe: Color.roomyAccent
        case .caution: Color.roomyStatusInactiveText
        case .warning: Color.roomyStatusDormantText
        }
    }
}

enum RoomyArtifactSafety {
    /// Bulk dormant selection skips warning-tier artifacts.
    static func isEligibleForBulkDormantSelection(tier: ArtifactSafetyTier) -> Bool {
        tier != .warning
    }
}
