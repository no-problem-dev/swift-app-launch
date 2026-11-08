import AppLaunchCore
import SwiftUI
import Testing
@testable import WhatsNewUI

enum Page: Hashable, Sendable { case first, second }

@MainActor
@Suite("枚を送る土台")
struct WhatsNewPagerTests {
    @Test("自前のボタンの文言がパッケージの中から読める")
    func labelsResolve() {
        #expect(WhatsNewStrings.next != "whats_new.next")
        #expect(WhatsNewStrings.done != "whats_new.done")
        #expect(WhatsNewStrings.close != "whats_new.close")
    }

    @Test("アプリの絵と言葉で描ける")
    func renders() {
        let pager = WhatsNewPager(
            Release(version: "2.0", pages: [Page.first, .second]),
            onClose: { _ in },
            text: { page in WhatsNewPageText(title: Text("Title \(String(describing: page))"), message: Text("Line")) },
            action: { page in page == .second ? .permission(Text("Allow")) {} : nil },
            art: { _, context in Circle().opacity(context.animates ? 1 : 0.5) }
        )
        .frame(width: 390, height: 844)
        let renderer = ImageRenderer(content: pager)
        #expect(renderer.cgImage != nil)
    }
}
