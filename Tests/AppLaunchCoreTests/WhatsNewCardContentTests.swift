import Foundation
import Testing
import AppLaunchCore

@Suite("お知らせの枚の値")
struct WhatsNewCardContentTests {

    private func decode(_ json: String) throws -> WhatsNewCardContent {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase   // as the campaign engine decodes values
        return try decoder.decode(WhatsNewCardContent.self, from: Data(json.utf8))
    }

    @Test("件の値（snake_case）をそのまま読む。画像はアプリの中の名前")
    func decodesCampaignValues() throws {
        let content = try decode(#"""
        {"headline": "押さなくても、達成に", "body": "歩数・運動・睡眠の習慣は、やった日に自動で達成になります。",
         "image": {"asset": "auto_check"}, "primary_label": "設定する"}
        """#)
        #expect(content == WhatsNewCardContent(
            headline: "押さなくても、達成に",
            body: "歩数・運動・睡眠の習慣は、やった日に自動で達成になります。",
            image: .asset("auto_check"),
            primaryLabel: "設定する"
        ))
        #expect(content.image?.aspectRatio == nil)
    }

    @Test("画像と押す文言は無くてもよい。URL の画像は縦横の比を持つ")
    func optionalFields() throws {
        let words = try decode(#"{"headline": "New", "body": "Line"}"#)
        #expect(words.image == nil)
        #expect(words.primaryLabel == nil)

        let remote = try decode(#"""
        {"headline": "New", "body": "Line", "image": {"url": "https://example.com/a.png", "width": 1200, "height": 800}}
        """#)
        #expect(remote.image == .url(URL(string: "https://example.com/a.png")!, width: 1200, height: 800))
        #expect(remote.image?.aspectRatio == 1.5)
    }

    @Test("見出しか本文が無ければ読まない")
    func requiresWords() {
        #expect(throws: DecodingError.self) { try decode(#"{"headline": "New"}"#) }
    }
}
