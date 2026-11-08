/// A marketing version (`CFBundleShortVersionString`) read as numbers, so `1.10.0` sorts after
/// `1.9.0` and `1.6` equals `1.6.0`.
///
/// Internal on purpose: the public API takes versions as strings, so an app keeps whatever version
/// type it already has. One to three dot-separated non-negative integers, the same reading as
/// `swift-review`'s `AppVersion`.
struct VersionNumber: Hashable, Comparable, Sendable {

    let major: Int
    let minor: Int
    let patch: Int
    /// How many parts the text had (1 to 3).
    let partCount: Int

    init?(_ text: String) {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }), let number = Int(part) else {
                return nil
            }
            numbers.append(number)
        }
        partCount = numbers.count
        while numbers.count < 3 { numbers.append(0) }
        major = numbers[0]
        minor = numbers[1]
        patch = numbers[2]
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) == (rhs.major, rhs.minor, rhs.patch)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
