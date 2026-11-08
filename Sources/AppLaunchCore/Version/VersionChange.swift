/// What the app knows about the launch before this one.
public enum PreviousLaunch: Hashable, Sendable {
    /// Nothing: this is the first launch after installing.
    case neverLaunched
    /// The version recorded at the previous launch.
    case recorded(String)
    /// The app was used before it started recording versions, and this is the version to assume.
    ///
    /// Use it once, for the release that starts recording: pass the oldest version the earlier use
    /// could have been, so every release after it counts as new.
    case untracked(assumedVersion: String)
}

/// How this launch relates to the previous one: a fresh install, an update, or the same version.
public enum VersionChange: Hashable, Sendable {
    /// The first launch after installing.
    case fresh
    /// The first launch of a newer version. `from` is the previous (or assumed) version as text.
    case upgraded(from: String)
    /// The same version as before, or an older one after a downgrade.
    case same

    /// Compares the current version with the previous launch.
    ///
    /// A version that cannot be read as one to three numbers (such as `1.6.0-beta`) resolves to
    /// ``same``, so an unreadable version never shows anything at launch.
    /// - Parameters:
    ///   - current: The version running now (`CFBundleShortVersionString`).
    ///   - previous: What is known about the launch before this one.
    public static func resolve(current: String, previous: PreviousLaunch) -> VersionChange {
        guard let now = VersionNumber(current) else { return .same }
        let before: String
        switch previous {
        case .neverLaunched: return .fresh
        case let .recorded(version): before = version
        case let .untracked(assumedVersion): before = assumedVersion
        }
        guard let then = VersionNumber(before), now > then else { return .same }
        return .upgraded(from: before)
    }
}
