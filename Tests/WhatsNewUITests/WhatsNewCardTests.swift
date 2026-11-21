import AppLaunchCore
import SwiftUI
import Testing
@testable import WhatsNewUI

@MainActor
@Suite("お知らせの枚の見た目")
struct WhatsNewCardTests {
    private let content = WhatsNewCardContent(headline: "Done without a tap", body: "Steps now count on their own.",
                                              image: .asset("missing"), primaryLabel: "Set up")

    @Test("自前のボタンの文言がパッケージの中から読める")
    func labelsResolve() {
        #expect(WhatsNewStrings.primary != "whats_new.primary")
        #expect(WhatsNewStrings.close != "whats_new.close")
    }

    @Test("件の値だけで描ける。画像も押す文言も無い枚も描ける")
    func rendersFromValues() {
        let card = WhatsNewCard(content, onPrimary: {}, onClose: {}).frame(width: 390, height: 700)
        #expect(ImageRenderer(content: card).cgImage != nil)

        let words = WhatsNewCard(WhatsNewCardContent(headline: "New", body: "Line"), onPrimary: {}, onClose: {})
            .frame(width: 390, height: 700)
        #expect(ImageRenderer(content: words).cgImage != nil)
    }

    @Test("アプリの絵で描ける。絵には件の画像と、動いてよいかが渡る")
    func rendersAppArt() {
        var seen: WhatsNewImage?
        let card = WhatsNewCard(content, onPrimary: {}, onClose: {}) { image, context in
            let _ = { seen = image }()
            Circle().opacity(context.animates ? 1 : 0.5)
        }
        .frame(width: 390, height: 700)
        #expect(ImageRenderer(content: card).cgImage != nil)
        #expect(seen == .asset("missing"))
    }
}
