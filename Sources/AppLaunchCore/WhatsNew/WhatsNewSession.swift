/// Where someone is in a release's pages, and the analytics each step reports.
///
/// The pager in `WhatsNewUI` keeps one of these; it is here so the rules (shown once, closed once,
/// the last page's button finishes) are checked without a screen.
public struct WhatsNewSession: Hashable, Sendable {

    /// The release's version.
    public let release: String
    /// How many pages the release has.
    public let pageCount: Int
    /// The page on screen, from 0.
    public private(set) var index = 0
    /// How the screen was closed, once it has been.
    public private(set) var closedVia: WhatsNewCloseVia?
    private var hasAppeared = false

    /// - Parameter release: The release on screen.
    public init<Page>(_ release: Release<Page>) {
        self.release = release.version
        self.pageCount = release.pages.count
    }

    /// Whether the page on screen is the last one.
    public var isLast: Bool { index == pageCount - 1 }

    /// The page on screen, from 1, as analytics carry it.
    public var pageNumber: Int { index + 1 }

    /// The screen appeared. Returns the shown event the first time only.
    public mutating func appear() -> WhatsNewEvent? {
        guard !hasAppeared else { return nil }
        hasAppeared = true
        return .shown(release: release)
    }

    /// The page's main button was pressed: moves to the next page, or closes on the last one.
    ///
    /// Returns the closed event when this closed the screen, otherwise `nil`.
    public mutating func advance() -> WhatsNewEvent? {
        guard closedVia == nil else { return nil }
        if isLast { return close(via: .finished) }
        index += 1
        return nil
    }

    /// Closes the screen. Returns the closed event the first time only.
    /// - Parameter via: How it was closed.
    public mutating func close(via: WhatsNewCloseVia) -> WhatsNewEvent? {
        guard closedVia == nil else { return nil }
        closedVia = via
        return .closed(release: release, page: pageNumber, pages: pageCount, via: via)
    }
}
