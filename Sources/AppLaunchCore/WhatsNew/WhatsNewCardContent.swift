import Foundation

/// What the what's-new card shows: the values of a `whats_new` campaign.
///
/// The fields are the `whats_new` placement's (`headline` up to 20 characters, `body` up to 60,
/// an optional `image` and an optional `primary_label`), already in the device's language. It
/// decodes from the campaign's values as they are, so an app can use it as its placement's
/// `Values` without this package depending on the campaign SDK:
///
/// ```swift
/// struct WhatsNewPlacement: CampaignPlacement {
///     static let name = CampaignTemplate.WhatsNew.name
///     static let fields = CampaignTemplate.WhatsNew.fields
///     typealias Values = WhatsNewCardContent
/// }
/// ```
///
/// Which version shows what, and to whom, is the campaign's: its trigger is `app_updated` with the
/// version, and it is shown at most once.
public struct WhatsNewCardContent: Hashable, Sendable, Decodable {
    /// The heading, large and short.
    public let headline: String
    /// One short line under the heading. Never a list.
    public let body: String
    /// The illustration, or `nil` for a card of words only.
    public let image: WhatsNewImage?
    /// The main button's label, or `nil` for the package's own ("Take a look").
    public let primaryLabel: String?

    /// - Parameters:
    ///   - headline: The heading.
    ///   - body: One short line under the heading.
    ///   - image: The illustration, or `nil`.
    ///   - primaryLabel: The main button's label, or `nil` for the package's own.
    public init(headline: String, body: String, image: WhatsNewImage? = nil, primaryLabel: String? = nil) {
        self.headline = headline
        self.body = body
        self.image = image
        self.primaryLabel = primaryLabel
    }
}

/// An illustration on the card: one bundled in the app, or an HTTPS image the campaign engine
/// fetched ahead of time. The same JSON as a campaign's image value.
public enum WhatsNewImage: Hashable, Sendable, Decodable {
    /// An image in the app's asset catalog, by name.
    case asset(String)
    /// An HTTPS image and its size in pixels, so the card keeps its shape while it loads.
    case url(URL, width: Int, height: Int)

    enum CodingKeys: String, CodingKey { case asset, url, width, height }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let name = try container.decodeIfPresent(String.self, forKey: .asset) {
            self = .asset(name)
        } else {
            self = .url(try container.decode(URL.self, forKey: .url),
                        width: try container.decode(Int.self, forKey: .width),
                        height: try container.decode(Int.self, forKey: .height))
        }
    }

    /// Width over height, or `nil` for an asset (its own size is used).
    public var aspectRatio: Double? {
        guard case let .url(_, width, height) = self, width > 0, height > 0 else { return nil }
        return Double(width) / Double(height)
    }
}
