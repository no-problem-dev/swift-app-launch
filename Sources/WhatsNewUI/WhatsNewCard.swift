import AppLaunchCore
import SwiftUI

/// The what's-new card: an illustration on the upper half to 60 percent, a heading and one line
/// below it, one button, and a close button.
///
/// It draws the values a `whats_new` campaign hands the app (``WhatsNewCardContent``) and nothing
/// else. Which version shows it, to whom and how often is the campaign's. The main button follows
/// the campaign's `on_tap` (the new feature's screen), so the card carries no price, plan or
/// purchase invitation of its own.
///
/// ```swift
/// RootView()
///     .campaignPlacement(WhatsNewPlacement.self, in: campaigns) { offer in
///         WhatsNewCard(offer.values, onPrimary: offer.tap, onClose: { offer.dismiss(.closeButton) })
///     }
/// ```
///
/// - The close button is always there, so the card can be closed at any time. Being pulled down
///   is reported by the sheet that presents it (`campaignPlacement` records `swipe_down`).
/// - Pass `art:` to draw the illustration yourself, such as one that moves. It is told to stand
///   still when Reduce Motion is on (``WhatsNewArtContext/animates``).
///
/// Style the main button with `.buttonStyle(_:)` on the card.
public struct WhatsNewCard<Art: View>: View {

    private let content: WhatsNewCardContent
    private let artFraction: CGFloat
    private let labels: WhatsNewLabels
    private let hasArt: Bool
    private let art: @MainActor (WhatsNewImage?, WhatsNewArtContext) -> Art
    private let onPrimary: @MainActor () -> Void
    private let onClose: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A card whose illustration the app draws.
    /// - Parameters:
    ///   - content: The campaign's values.
    ///   - artFraction: How much of the card's height the illustration takes, kept between 0.5 and 0.6.
    ///   - labels: The card's own labels.
    ///   - onPrimary: The main button. Pass the campaign offer's `tap`.
    ///   - onClose: The close button. Pass the campaign offer's `dismiss(.closeButton)`.
    ///   - art: The illustration, given the campaign's image (or `nil`) and whether to move.
    public init(
        _ content: WhatsNewCardContent,
        artFraction: CGFloat = 0.6,
        labels: WhatsNewLabels = .standard,
        onPrimary: @escaping @MainActor () -> Void,
        onClose: @escaping @MainActor () -> Void,
        @ViewBuilder art: @escaping @MainActor (WhatsNewImage?, WhatsNewArtContext) -> Art
    ) {
        self.init(content, artFraction: artFraction, labels: labels, hasArt: true,
                  onPrimary: onPrimary, onClose: onClose, art: art)
    }

    private init(
        _ content: WhatsNewCardContent,
        artFraction: CGFloat,
        labels: WhatsNewLabels,
        hasArt: Bool,
        onPrimary: @escaping @MainActor () -> Void,
        onClose: @escaping @MainActor () -> Void,
        art: @escaping @MainActor (WhatsNewImage?, WhatsNewArtContext) -> Art
    ) {
        self.content = content
        self.artFraction = min(max(artFraction, 0.5), 0.6)
        self.labels = labels
        self.hasArt = hasArt
        self.art = art
        self.onPrimary = onPrimary
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    if hasArt {
                        art(content.image, WhatsNewArtContext(animates: !reduceMotion))
                            .frame(maxWidth: .infinity)
                            .frame(height: proxy.size.height * artFraction)
                            .clipped()
                            .accessibilityHidden(true)
                    } else {
                        Spacer(minLength: 0)
                    }
                    words
                    Spacer(minLength: 0)
                }
            }
            Button(action: onPrimary) {
                primaryLabel
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("whatsNew.primary")
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var primaryLabel: Text {
        content.primaryLabel.map { Text($0) } ?? labels.primary
    }

    private var words: some View {
        VStack(spacing: 10) {
            Text(content.headline)
                .font(.title2.weight(.bold))
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            Text(content.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("whatsNew.card")
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(labels.close)
            .accessibilityIdentifier("whatsNew.close")
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
    }
}

extension WhatsNewCard where Art == WhatsNewImageView {

    /// A card that draws the campaign's image itself: an asset by name, or the fetched HTTPS image
    /// at its own aspect ratio. Without an image, the card is words only.
    /// - Parameters:
    ///   - content: The campaign's values.
    ///   - artFraction: How much of the card's height the illustration takes, kept between 0.5 and 0.6.
    ///   - labels: The card's own labels.
    ///   - onPrimary: The main button. Pass the campaign offer's `tap`.
    ///   - onClose: The close button. Pass the campaign offer's `dismiss(.closeButton)`.
    public init(
        _ content: WhatsNewCardContent,
        artFraction: CGFloat = 0.6,
        labels: WhatsNewLabels = .standard,
        onPrimary: @escaping @MainActor () -> Void,
        onClose: @escaping @MainActor () -> Void
    ) {
        self.init(content, artFraction: artFraction, labels: labels, hasArt: content.image != nil,
                  onPrimary: onPrimary, onClose: onClose) { image, _ in WhatsNewImageView(image) }
    }
}

/// Draws a ``WhatsNewImage``: an asset from the app's main bundle, or an HTTPS image at its own
/// aspect ratio. Draws nothing for `nil`.
public struct WhatsNewImageView: View {
    private let image: WhatsNewImage?

    /// - Parameter image: The image to draw, or `nil`.
    public init(_ image: WhatsNewImage?) {
        self.image = image
    }

    public var body: some View {
        switch image {
        case let .asset(name):
            Image(name, bundle: .main)
                .resizable()
                .scaledToFit()
        case let .url(url, width, height):
            AsyncImage(url: url) { phase in
                if let loaded = phase.image {
                    loaded.resizable().scaledToFit()
                } else {
                    Color.clear
                }
            }
            .aspectRatio(CGFloat(width) / CGFloat(max(height, 1)), contentMode: .fit)
        case nil:
            EmptyView()
        }
    }
}

/// What an illustration needs to know to draw itself.
public struct WhatsNewArtContext: Hashable, Sendable {
    /// Whether to move. `false` when Reduce Motion is on: draw the finished state and stay still.
    public let animates: Bool

    public init(animates: Bool) {
        self.animates = animates
    }
}

/// The labels the card uses for its own buttons.
public struct WhatsNewLabels {
    /// The main button when the campaign gives no `primary_label`.
    public var primary: Text
    /// The close button's accessibility label.
    public var close: Text

    /// - Parameters:
    ///   - primary: The main button when the campaign gives no `primary_label`.
    ///   - close: The close button's accessibility label.
    public init(primary: Text, close: Text) {
        self.primary = primary
        self.close = close
    }

    /// The package's own labels, in English and Japanese.
    public static var standard: WhatsNewLabels {
        WhatsNewLabels(
            primary: Text(WhatsNewStrings.primary),
            close: Text(WhatsNewStrings.close)
        )
    }
}

enum WhatsNewStrings {
    static var primary: String { String(localized: "whats_new.primary", bundle: .module) }
    static var close: String { String(localized: "whats_new.close", bundle: .module) }
}
