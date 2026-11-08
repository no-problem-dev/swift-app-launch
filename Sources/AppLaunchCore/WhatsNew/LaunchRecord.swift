import Foundation

/// What is kept on the device between launches.
public struct LaunchRecord: Hashable, Sendable {
    /// The version of the last launch.
    public var lastLaunchedVersion: String?
    /// A release decided on but not yet closed, to show at the next launch.
    public var pendingRelease: String?

    public init(lastLaunchedVersion: String? = nil, pendingRelease: String? = nil) {
        self.lastLaunchedVersion = lastLaunchedVersion
        self.pendingRelease = pendingRelease
    }
}

/// Where the launch record is kept between launches.
///
/// Keep it on the device: whether someone has seen a release is about this install.
public protocol LaunchRecordStore: Sendable {
    /// The stored record, empty when nothing is stored yet.
    func load() -> LaunchRecord
    /// Replaces the stored record.
    func save(_ record: LaunchRecord)
    /// Replaces only the waiting release, leaving the last launched version as stored.
    ///
    /// ``WhatsNewTracker/settle()`` uses it, so forgetting a release never writes back a version
    /// that was only read, such as one a test passed as a launch argument. The default loads the
    /// record, changes the release and saves it; a store that keeps the fields apart writes the one.
    func save(pendingRelease: String?)
}

extension LaunchRecordStore {
    public func save(pendingRelease: String?) {
        var record = load()
        record.pendingRelease = pendingRelease
        save(record)
    }
}

/// A store that keeps each field as a plain string under its own `UserDefaults` key.
///
/// Plain strings, not an encoded value, so an app that already stores these two values can pass
/// its existing keys and keep what devices already have.
///
/// Give it a suite's **name**, or a `UserDefaults` instance the app already holds (such as an App
/// Group suite, or one a test or scenario set up). With a name it opens the suite on each call.
///
/// ```swift
/// let store = UserDefaultsLaunchRecordStore()                                     // standard
/// let shared = UserDefaultsLaunchRecordStore(suiteName: "group.com.example.app")  // app group
/// let held = UserDefaultsLaunchRecordStore(defaults: appGroupDefaults)            // an instance
/// ```
public struct UserDefaultsLaunchRecordStore: LaunchRecordStore {

    private let source: Source
    private let lastLaunchedVersionKey: String
    private let pendingReleaseKey: String

    /// The store in a `UserDefaults` instance the app holds, `UserDefaults.standard` by default.
    ///
    /// The instance is kept and used from whichever thread calls the store. `UserDefaults` is
    /// documented as thread-safe, which is why the store stays `Sendable`.
    /// - Parameters:
    ///   - defaults: Where to store.
    ///   - lastLaunchedVersionKey: The key for ``LaunchRecord/lastLaunchedVersion``.
    ///   - pendingReleaseKey: The key for ``LaunchRecord/pendingRelease``.
    public init(
        defaults: UserDefaults = .standard,
        lastLaunchedVersionKey: String = "launch.lastVersion",
        pendingReleaseKey: String = "whatsNew.pending"
    ) {
        self.source = .instance(SharedDefaults(defaults))
        self.lastLaunchedVersionKey = lastLaunchedVersionKey
        self.pendingReleaseKey = pendingReleaseKey
    }

    /// The store in a named suite, or `nil` when `UserDefaults` refuses the name.
    /// - Parameters:
    ///   - suiteName: The suite, such as an app group.
    ///   - lastLaunchedVersionKey: The key for ``LaunchRecord/lastLaunchedVersion``.
    ///   - pendingReleaseKey: The key for ``LaunchRecord/pendingRelease``.
    public init?(
        suiteName: String,
        lastLaunchedVersionKey: String = "launch.lastVersion",
        pendingReleaseKey: String = "whatsNew.pending"
    ) {
        guard UserDefaults(suiteName: suiteName) != nil else { return nil }
        self.source = .suite(suiteName)
        self.lastLaunchedVersionKey = lastLaunchedVersionKey
        self.pendingReleaseKey = pendingReleaseKey
    }

    private var defaults: UserDefaults {
        switch source {
        case let .suite(name):
            // The name was accepted in init, and UserDefaults refuses a name only by what it is.
            UserDefaults(suiteName: name)!
        case let .instance(shared):
            shared.defaults
        }
    }

    public func load() -> LaunchRecord {
        LaunchRecord(
            lastLaunchedVersion: defaults.string(forKey: lastLaunchedVersionKey),
            pendingRelease: defaults.string(forKey: pendingReleaseKey)
        )
    }

    public func save(_ record: LaunchRecord) {
        set(record.lastLaunchedVersion, forKey: lastLaunchedVersionKey)
        set(record.pendingRelease, forKey: pendingReleaseKey)
    }

    public func save(pendingRelease: String?) {
        set(pendingRelease, forKey: pendingReleaseKey)
    }

    private func set(_ value: String?, forKey key: String) {
        if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
    }

    private enum Source: Sendable {
        case suite(String)
        case instance(SharedDefaults)
    }

    /// `UserDefaults` is thread-safe (Apple's documentation) but not marked `Sendable` in every SDK.
    private struct SharedDefaults: @unchecked Sendable {
        let defaults: UserDefaults
        init(_ defaults: UserDefaults) { self.defaults = defaults }
    }
}

/// A store in memory, for tests and previews.
public final class InMemoryLaunchRecordStore: LaunchRecordStore {

    private let storage: Locked<LaunchRecord>

    /// Starts from a record.
    /// - Parameter record: The record to start from.
    public init(_ record: LaunchRecord = LaunchRecord()) {
        storage = Locked(record)
    }

    /// The record as stored now.
    public var record: LaunchRecord { storage.value }

    public func load() -> LaunchRecord { storage.value }

    public func save(_ record: LaunchRecord) {
        storage.withValue { $0 = record }
    }
}
