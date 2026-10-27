//
//  RoomyMarketingLinks.swift
//  Roomy
//
//  Marketing site and support URLs for getroomy.dev.
//

import Foundation
import RoomyCore

enum RoomyMarketingLinks {
    private static let siteRoot = "https://getroomy.dev"

    static let productPage = siteRoot
    static let releases = "\(siteRoot)/release-notes"
    static let documentation = "\(siteRoot)/documentation"
    static let eula = "\(siteRoot)/eula"
    static let privacy = "\(siteRoot)/privacy"
    static let supportEmail = "teodor@azbouki.com"

    static var mailtoSupport: String {
        "mailto:\(supportEmail)"
    }
}
