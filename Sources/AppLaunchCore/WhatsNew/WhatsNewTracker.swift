/// What a launch starts with: how the version changed, and the release to show.
public struct LaunchStart<Page: Hashable & Sendable>: Hashable, Sendable {
    /// How this launch relates to the previous one.
    public let change: VersionChange
    /// The release to show at this launch, or `nil`.
    public let release: Release<Page>?

    public init(change: VersionChange, release: Release<Page>?) {
        self.change = change
        self.release = release
    }
}

import Foundation

/// Records each launch's version and keeps the release that is due until it is closed.
///
/// Call ``begin(currentVersion:untrackedEarlierUse:)`` once per launch, as early as possible, and
/// ``settle()`` when the release was closed or the launch decided not to show it at all (such as
/// after onboarding). A release that was due but never closed comes back at the next launch.
public struct WhatsNewTracker<Page: Hashable & Sendable>: Sendable {

    /// The releases this app declares.
    public let catalog: ReleaseCatalog<Page>
    private let store: any LaunchRecordStore

    /// - Parameters:
    ///   - catalog: The releases this app declares.
    ///   - store: Where the record is kept.
    public init(catalog: ReleaseCatalog<Page>, store: any LaunchRecordStore = UserDefaultsLaunchRecordStore()) {
        self.catalog = catalog
        self.store = store
    }

    /// Records this launch's version and returns the release to show, if any.
    ///
    /// Calling it again in the same launch returns the same release. When `currentVersion` cannot
    /// be read, nothing is recorded and nothing is shown.
    /// - Parameters:
    ///   - currentVersion: The version running now (`CFBundleShortVersionString`).
    ///   - untrackedEarlierUse: For a device with no recorded version, the version to assume when
    ///     the app can tell it was used before recording started; `nil` means a fresh install.
    @discardableResult
    public func begin(currentVersion: String, untrackedEarlierUse: String? = nil) -> LaunchStart<Page> {
        guard VersionNumber(currentVersion) != nil else { return LaunchStart(change: .same, release: nil) }
        var record = store.load()
        let previous: PreviousLaunch = if let last = record.lastLaunchedVersion {
            .recorded(last)
        } else if let untrackedEarlierUse {
            .untracked(assumedVersion: untrackedEarlierUse)
        } else {
            .neverLaunched
        }
        let change = VersionChange.resolve(current: currentVersion, previous: previous)
        let release = catalog.pending(
            carried: record.pendingRelease,
            found: catalog.due(for: change, current: currentVersion),
            current: currentVersion
        )
        record.lastLaunchedVersion = currentVersion
        record.pendingRelease = release?.version
        store.save(record)
        return LaunchStart(change: change, release: release)
    }

    /// Records this launch's version, read from a bundle's `CFBundleShortVersionString`.
    ///
    /// A bundle without a readable version records nothing and shows nothing.
    /// - Parameters:
    ///   - bundle: The app's bundle, usually `.main`.
    ///   - untrackedEarlierUse: See ``begin(currentVersion:untrackedEarlierUse:)``.
    @discardableResult
    public func begin(bundle: Bundle, untrackedEarlierUse: String? = nil) -> LaunchStart<Page> {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return begin(currentVersion: version ?? "", untrackedEarlierUse: untrackedEarlierUse)
    }

    /// The release still waiting, as stored.
    public var pending: Release<Page>? {
        store.load().pendingRelease.flatMap(catalog.release(version:))
    }

    /// Forgets the waiting release: it was closed, or this launch dropped it.
    public func settle() {
        var record = store.load()
        record.pendingRelease = nil
        store.save(record)
    }
}
