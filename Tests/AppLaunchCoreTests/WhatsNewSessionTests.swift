import Testing
import AppLaunchCore

@Suite("枚の送りと計測")
struct WhatsNewSessionTests {
    @Test("出したのは1回だけ送る")
    func shownOnce() {
        var session = WhatsNewSession(Fixture.v161)
        #expect(session.appear() == .shown(release: "1.6.1"))
        #expect(session.appear() == nil)
    }

    @Test("最後の枚のボタンで閉じる（finished）")
    func finishes() {
        var session = WhatsNewSession(Fixture.v161)
        #expect(session.advance() == nil)
        #expect(session.pageNumber == 2)
        #expect(session.isLast)
        #expect(session.advance() == .closed(release: "1.6.1", page: 2, pages: 2, via: .finished))
        #expect(session.advance() == nil)
        #expect(session.pageNumber == 2)
    }

    @Test("× で閉じたら、そのときの枚を送り、2回目は送らない")
    func closesOnce() {
        var session = WhatsNewSession(Fixture.v160)
        _ = session.advance()
        #expect(session.close(via: .closeButton) == .closed(release: "1.6.0", page: 2, pages: 3, via: .closeButton))
        #expect(session.close(via: .swipeDown) == nil)
        #expect(session.closedVia == .closeButton)
    }

    @Test("1枚の版は最初のボタンで閉じる")
    func singlePage() {
        var session = WhatsNewSession(Fixture.v180)
        #expect(session.advance() == .closed(release: "1.8.0", page: 1, pages: 1, via: .finished))
    }

    @Test("計測の名前と中身は共通のカタログのとおり")
    func catalogNames() {
        #expect(WhatsNewEvent.shown(release: "1.6.1").name == "whats_new_shown")
        #expect(WhatsNewEvent.shown(release: "1.6.1").parameters == ["release": .text("1.6.1")])
        let closed = WhatsNewEvent.closed(release: "1.6.1", page: 1, pages: 2, via: .swipeDown)
        #expect(closed.name == "whats_new_closed")
        #expect(closed.parameters == ["release": .text("1.6.1"), "page": .count(1), "pages": .count(2), "via": .text("swipe_down")])
        #expect(WhatsNewCloseVia.allCases.map(\.rawValue) == ["close_button", "finished", "swipe_down"])
    }
}
