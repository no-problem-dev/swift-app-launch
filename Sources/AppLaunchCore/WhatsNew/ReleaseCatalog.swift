/// Every release that has something to tell, and which of them is due at a launch.
///
/// Add one ``Release`` when a version has something new. A version without a declaration shows
/// nothing.
///
/// ```swift
/// let catalog: ReleaseCatalog<NewsPage> = [
///     Release(version: "1.6.0", pages: [.unlimitedBooks, .memoOnShelf]),
///     Release(version: "1.6.1", pages: [.yearCards, .yearNotes]),
/// ]
/// ```
public struct ReleaseCatalog<Page: Hashable & Sendable>: Hashable, Sendable, ExpressibleByArrayLiteral {

    /// The releases, oldest first.
    public let releases: [Release<Page>]

    /// Collects releases. Two releases for the same version stop the app in development.
    /// - Parameter releases: The releases, in any order.
    public init(_ releases: [Release<Page>]) {
        let sorted = releases.sorted { $0.number < $1.number }
        for (earlier, later) in zip(sorted, sorted.dropFirst()) {
            precondition(earlier.number != later.number, "Two releases for version \(later.version)")
        }
        self.releases = sorted
    }

    public init(arrayLiteral releases: Release<Page>...) {
        self.init(releases)
    }

    /// The newest release.
    public var latest: Release<Page>? { releases.last }

    /// The release declared for `version`, comparing as numbers (`1.6` finds `1.6.0`).
    /// - Parameter version: The version to look up.
    public func release(version: String) -> Release<Page>? {
        guard let number = VersionNumber(version) else { return nil }
        return releases.first { $0.number == number }
    }

    /// The release to show for this launch, or `nil`.
    ///
    /// Nothing after a fresh install or on the same version. After an update, the newest release
    /// that is newer than the previous version and not newer than the current one: someone who
    /// skipped several versions sees one release, the latest.
    /// - Parameters:
    ///   - change: How this launch relates to the previous one.
    ///   - current: The version running now.
    public func due(for change: VersionChange, current: String) -> Release<Page>? {
        guard case let .upgraded(from) = change,
              let previous = VersionNumber(from),
              let now = VersionNumber(current) else { return nil }
        return releases.last { $0.number > previous && $0.number <= now }
    }

    /// The release still waiting to be shown: the one carried from an earlier launch or the one
    /// found now, whichever is newer.
    ///
    /// A release that could not be shown (the app was closed first, or the launch was taken by a
    /// paywall) is carried to the next launch. A carried release newer than the current version,
    /// after a downgrade, is not shown.
    /// - Parameters:
    ///   - carried: The version stored as still waiting.
    ///   - found: What ``due(for:current:)`` returned for this launch.
    ///   - current: The version running now.
    public func pending(carried: String?, found: Release<Page>?, current: String) -> Release<Page>? {
        guard let now = VersionNumber(current) else { return nil }
        let candidates = [carried.flatMap(release(version:)), found].compactMap { $0 }.filter { $0.number <= now }
        return candidates.max { $0.number < $1.number }
    }
}
