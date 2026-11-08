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
}

/// A store that keeps each field as a plain string under its own `UserDefaults` key.
///
/// Plain strings, not an encoded value, so an app that already stores these two values can pass
/// its existing keys and keep what devices already have.
public struct UserDefaultsLaunchRecordStore: LaunchRecordStore {

    private let suiteName: String?
    private let lastLaunchedVersionKey: String
    private let pendingReleaseKey: String

    /// The store in `UserDefaults.standard`.
    /// - Parameters:
    ///   - lastLaunchedVersionKey: The key for ``LaunchRecord/lastLaunchedVersion``.
    ///   - pendingReleaseKey: The key for ``LaunchRecord/pendingRelease``.
    public init(lastLaunchedVersionKey: String = "launch.lastVersion", pendingReleaseKey: String = "whatsNew.pending") {
        self.suiteName = nil
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
        self.suiteName = suiteName
        self.lastLaunchedVersionKey = lastLaunchedVersionKey
        self.pendingReleaseKey = pendingReleaseKey
    }

    private var defaults: UserDefaults {
        // The name was accepted in init, and UserDefaults refuses a name only by what it is.
        suiteName.map { UserDefaults(suiteName: $0)! } ?? .standard
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

    private func set(_ value: String?, forKey key: String) {
        if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
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
