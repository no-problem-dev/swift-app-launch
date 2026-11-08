/// Where someone is in a release's pages, and the analytics each step reports.
///
/// The pager in `WhatsNewUI` keeps one of these; it is here so the rules (shown once, closed once,
/// the last page's button finishes) are checked without a screen.
public struct WhatsNewSession: Hashable, Sendable {

    /// The release's version.
    public let release: String
    /// How many pages the release has now.
    public private(set) var pageCount: Int
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

    /// The release's pages changed while on screen, such as a page added once a feature flag is
    /// known.
    ///
    /// The page on screen stays on screen when it is still there; otherwise the same position is
    /// shown, or the new last page. Nothing changes once the screen is closed. Nothing is reported:
    /// `whats_new_closed` carries the page count at the time it closes.
    ///
    /// A release of another version is a different screen, not a change to this one, and stops the
    /// app like a mistaken declaration does.
    /// - Parameters:
    ///   - old: The release as it was.
    ///   - new: The release as it is now, with the same version.
    public mutating func update<Page>(from old: Release<Page>, to new: Release<Page>) {
        precondition(
            old.version == release && new.version == release,
            "A what's-new screen for \(release) cannot change to release \(new.version); show it in a new screen"
        )
        guard closedVia == nil else { return }
        let onScreen = old.pages.indices.contains(index) ? old.pages[index] : nil
        pageCount = new.pages.count
        if let onScreen, let kept = new.pages.firstIndex(of: onScreen) {
            index = kept
        } else {
            index = min(index, pageCount - 1)
        }
    }

    /// Closes the screen. Returns the closed event the first time only.
    /// - Parameter via: How it was closed.
    public mutating func close(via: WhatsNewCloseVia) -> WhatsNewEvent? {
        guard closedVia == nil else { return nil }
        closedVia = via
        return .closed(release: release, page: pageNumber, pages: pageCount, via: via)
    }
}
