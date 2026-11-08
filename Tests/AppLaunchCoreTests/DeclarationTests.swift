import Testing
import AppLaunchCore

@Suite("宣言の誤りは開発中に止める")
struct DeclarationTests {
    @Test("版は2つか3つの数字")
    func versionShape() async {
        await #expect(processExitsWith: .failure) { _ = Release(version: "2", pages: [NewsPage.yearCards]) }
        await #expect(processExitsWith: .failure) { _ = Release(version: "2.0-beta", pages: [NewsPage.yearCards]) }
    }

    @Test("枚は1〜3枚で、同じ枚を2度置かない")
    func pageCount() async {
        await #expect(processExitsWith: .failure) { _ = Release<NewsPage>(version: "2.0", pages: []) }
        await #expect(processExitsWith: .failure) {
            _ = Release(version: "2.0", pages: [NewsPage.yearCards, .yearNotes, .reminder, .memoOnShelf])
        }
        await #expect(processExitsWith: .failure) { _ = Release(version: "2.0", pages: [NewsPage.yearCards, .yearCards]) }
    }

    @Test("同じ版を2度宣言しない（1.6 と 1.6.0 も同じ版）")
    func duplicateVersion() async {
        await #expect(processExitsWith: .failure) {
            _ = ReleaseCatalog([Release(version: "1.6", pages: [NewsPage.yearCards]), Release(version: "1.6.0", pages: [NewsPage.yearNotes])])
        }
    }
}
