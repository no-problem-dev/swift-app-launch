/// A value carried on an analytics event: text or a count.
///
/// The cases map one to one onto the text and count values of common analytics packages, so a
/// bridge copies them without deciding anything.
public enum LaunchMetricValue: Hashable, Sendable, CustomStringConvertible {
    case text(String)
    case count(Int)

    public var description: String {
        switch self {
        case let .text(value): value
        case let .count(value): String(value)
        }
    }
}

/// How a what's-new screen was closed.
public enum WhatsNewCloseVia: String, Hashable, Sendable, CaseIterable {
    /// The close button.
    case closeButton = "close_button"
    /// The last page's button.
    case finished
    /// Pulled down, or taken away by the app without either button.
    case swipeDown = "swipe_down"
}

/// What a what's-new screen reports for analytics.
///
/// Names and parameters follow the shared catalog: `whats_new_shown{release}` and
/// `whats_new_closed{release, page, pages, via}`.
public enum WhatsNewEvent: Hashable, Sendable {
    /// The screen appeared.
    case shown(release: String)
    /// The screen closed on page `page` (from 1) of `pages`.
    case closed(release: String, page: Int, pages: Int, via: WhatsNewCloseVia)

    /// The snake_case event name.
    public var name: String {
        switch self {
        case .shown: "whats_new_shown"
        case .closed: "whats_new_closed"
        }
    }

    /// The event's parameters.
    public var parameters: [String: LaunchMetricValue] {
        switch self {
        case let .shown(release):
            ["release": .text(release)]
        case let .closed(release, page, pages, via):
            ["release": .text(release), "page": .count(page), "pages": .count(pages), "via": .text(via.rawValue)]
        }
    }
}
