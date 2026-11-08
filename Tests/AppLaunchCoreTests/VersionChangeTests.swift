import Testing
@testable import AppLaunchCore

@Suite("版を数字で比べる")
struct VersionNumberTests {
    @Test("数字の並びで比べ、末尾の 0 は同じ版")
    func numeric() throws {
        let v = { (text: String) in try #require(VersionNumber(text)) }
        #expect(try v("1.10.0") > v("1.9.0"))
        #expect(try v("2.0") > v("1.99.99"))
        #expect(try v("1.6") == v("1.6.0"))
        #expect(try Set([v("1.6"), v("1.6.0")]).count == 1)
    }

    @Test("数字でない版・4つ以上の区切りは読まない")
    func rejects() {
        for text in ["", "1.6.0-beta", "1..0", "v1.6", "1.2.3.4", "1.٣"] {
            #expect(VersionNumber(text) == nil, "\(text)")
        }
    }
}

@Suite("前の起動から、この起動を見分ける")
struct VersionChangeTests {
    @Test("入れて最初の起動")
    func fresh() {
        #expect(VersionChange.resolve(current: "1.6.0", previous: .neverLaunched) == .fresh)
    }

    @Test("記録した版より新しければ更新")
    func upgraded() {
        #expect(VersionChange.resolve(current: "1.7.0", previous: .recorded("1.6.0")) == .upgraded(from: "1.6.0"))
    }

    @Test("同じ版・古い版に戻したときは更新でない")
    func sameOrDowngrade() {
        #expect(VersionChange.resolve(current: "1.6.0", previous: .recorded("1.6")) == .same)
        #expect(VersionChange.resolve(current: "1.6.0", previous: .recorded("1.7.0")) == .same)
    }

    @Test("記録の無い前の利用は、決めた版からの更新とみなす")
    func untracked() {
        #expect(VersionChange.resolve(current: "1.6.0", previous: .untracked(assumedVersion: "1.5")) == .upgraded(from: "1.5"))
    }

    @Test("読めない版では何も出さない")
    func unreadable() {
        #expect(VersionChange.resolve(current: "1.6.0-beta", previous: .recorded("1.5.0")) == .same)
        #expect(VersionChange.resolve(current: "1.6.0", previous: .recorded("garbage")) == .same)
    }
}
