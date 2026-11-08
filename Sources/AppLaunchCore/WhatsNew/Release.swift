/// What one version tells people who updated: one to three pages, in order.
///
/// `Page` is the app's own type, usually an enum with a case per page. The package never looks
/// inside it; the app turns a page into an illustration, a heading and one line.
///
/// ```swift
/// enum NewsPage: Hashable, Sendable { case yearCards, yearNotes }
///
/// let release = Release(version: "1.6.1", pages: [NewsPage.yearCards, .yearNotes])
/// ```
public struct Release<Page: Hashable & Sendable>: Hashable, Sendable, Identifiable {

    /// The most pages one release may have. Past three, people stop reading and tap through.
    public static var maxPages: Int { 3 }

    /// The version as declared, such as `1.6.1`. This is what analytics carry as `release`.
    public let version: String
    /// The pages, in the order they are shown.
    public let pages: [Page]

    let number: VersionNumber

    public var id: String { version }

    /// Declares a release.
    ///
    /// A declaration is code, so a mistake in it stops the app in development rather than hiding at
    /// launch: the version must be two or three dot-separated numbers, and the pages must be one to
    /// ``maxPages`` distinct values.
    /// - Parameters:
    ///   - version: The version that introduces these pages, such as `1.6.1`.
    ///   - pages: The pages, in the order they are shown.
    public init(version: String, pages: [Page]) {
        guard let number = VersionNumber(version), number.partCount >= 2 else {
            preconditionFailure("Not a version of two or three numbers: \(version)")
        }
        precondition((1...Self.maxPages).contains(pages.count), "A release has 1 to \(Self.maxPages) pages")
        precondition(Set(pages).count == pages.count, "A page appears twice in release \(version)")
        self.version = version
        self.pages = pages
        self.number = number
    }

    /// The same release with only the pages that pass `isIncluded`, or `nil` when none do.
    ///
    /// For pages that depend on something known only at launch, such as a feature flag.
    /// - Parameter isIncluded: Whether to keep a page.
    public func keeping(_ isIncluded: (Page) throws -> Bool) rethrows -> Release? {
        let kept = try pages.filter(isIncluded)
        return kept.isEmpty ? nil : Release(version: version, pages: kept)
    }
}
