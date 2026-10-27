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
    /// Redirects (Firebase Hosting) to the current Stripe Payment Link, so the checkout can change without an app update.
    static let buy = "\(siteRoot)/buy"
    static let price = "$9.99"
    static let supportEmail = "hello@getroomy.dev"

    static var mailtoSupport: String {
        "mailto:\(supportEmail)"
    }
}
