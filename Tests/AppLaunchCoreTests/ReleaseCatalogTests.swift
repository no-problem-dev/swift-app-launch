import Testing
@testable import AppLaunchCore

@Suite("どのお知らせを出すか")
struct ReleaseCatalogTests {
    let catalog = Fixture.catalog

    @Test("古い順に並べる")
    func sorted() {
        #expect(catalog.releases.map(\.version) == ["1.6.0", "1.6.1", "1.8.0"])
        #expect(catalog.latest == Fixture.v180)
    }

    @Test("新しく入れた人・同じ版の起動には出さない")
    func notForFreshOrSame() {
        #expect(catalog.due(for: .fresh, current: "1.6.0") == nil)
        #expect(catalog.due(for: .same, current: "1.6.0") == nil)
    }

    @Test("前の版より新しく、いまの版以下の、一番新しい1件")
    func latestInRange() {
        #expect(catalog.due(for: .upgraded(from: "1.5"), current: "1.6.0") == Fixture.v160)
        #expect(catalog.due(for: .upgraded(from: "1.5"), current: "1.6.1") == Fixture.v161)
        #expect(catalog.due(for: .upgraded(from: "1.4"), current: "1.8.2") == Fixture.v180)
        #expect(catalog.due(for: .upgraded(from: "1.6.0"), current: "1.7.0") == Fixture.v161)
    }

    @Test("宣言の無い版に上げても出さない")
    func nothingWithoutDeclaration() {
        #expect(catalog.due(for: .upgraded(from: "1.6.1"), current: "1.7.0") == nil)
        #expect(catalog.due(for: .upgraded(from: "1.8.0"), current: "1.8.1") == nil)
    }

    @Test("版は数字で探す")
    func lookup() {
        #expect(catalog.release(version: "1.8") == Fixture.v180)
        #expect(catalog.release(version: "9.9.9") == nil)
        #expect(catalog.release(version: "x") == nil)
    }

    @Test("持ち越した分と見つけた分の新しい方。いまの版より新しい持ち越しは出さない")
    func pending() {
        #expect(catalog.pending(carried: nil, found: nil, current: "1.8.0") == nil)
        #expect(catalog.pending(carried: "1.6.0", found: nil, current: "1.6.0") == Fixture.v160)
        #expect(catalog.pending(carried: "1.6.0", found: Fixture.v180, current: "1.8.0") == Fixture.v180)
        #expect(catalog.pending(carried: "1.8.0", found: Fixture.v161, current: "1.8.0") == Fixture.v180)
        #expect(catalog.pending(carried: "1.8.0", found: nil, current: "1.6.1") == nil)
        #expect(catalog.pending(carried: "9.9.9", found: nil, current: "1.8.0") == nil)
    }

    @Test("条件で枚を減らす。全部消えたら出さない")
    func keeping() {
        #expect(Fixture.v160.keeping { $0 != .reminder }?.pages == [.unlimitedBooks, .memoOnShelf])
        #expect(Fixture.v180.keeping { _ in false } == nil)
    }
}
