[English](./README.md) | 日本語

# swift-app-launch

更新した人に、何が新しくなったかを絵のある数枚で伝え、起動したときに何をどの順番で出すか（オンボーディング → 新しくなったこと → 評価のお願い → その他）を1か所で決める。

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

リリースノートはほとんど読まれません。更新した後の画面は、新しいことを見せられる唯一の場所ですが、
よくある形で外れます。箇条書きの壁、ビューに直書きした版、アプリを閉じられて出せなかった画面、1回の起動で3枚重なるシート。

## 特徴

- **版ごとの宣言。** 伝えることのある版に `Release(version:pages:)` を1つ。いくつも飛ばした人には一番新しい1件だけ。出せなかった分は次の起動に持ち越します
- **起動で出す物の順番を1か所で。** `LaunchQueue` に出すかもしれない物を渡すと、いま何を出すかを返します。1つずつ・オンボーディングが先・オンボーディングの後はお知らせを捨てる・ペイウォールの後は次に回す・後に続く物は1回の起動で1つまで
- **決まりを守る土台。** 上の半分〜6割に絵、見出し1つと短い1行、どの枚にも ×、「動きを減らす」で動きを止める、許可を聞くのはその機能の枚だけ
- **計測はクロージャで。** `whats_new_shown{release}` と `whats_new_closed{release, page, pages, via}`。`via` は `close_button`・`finished`・`swipe_down`
- **依存なし・版は文字列で。** 判定は純粋な関数で、macOS の `swift test` で全部確かめられます

## 使い方

```swift
import AppLaunchCore
import WhatsNewUI

enum NewsPage: Hashable, Sendable { case yearCards, yearNotes }

let tracker = WhatsNewTracker<NewsPage>(catalog: [
    Release(version: "1.6.1", pages: [.yearCards, .yearNotes]),
])

// 起動ごとに1回。
let start = tracker.begin(bundle: .main)

// ほかに何も出ていないときに、枚を出す。
if let release = start.release {
    WhatsNewPager(
        release,
        onEvent: { analytics.send($0.name, $0.parameters) },
        onClose: { _ in tracker.settle() },
        text: { page in WhatsNewPageText(title: Text(page.title), message: Text(page.line)) },
        art: { page, context in NewsArt(page, animates: context.animates) }
    )
}
```

## ドキュメント

API の説明は DocC（[AppLaunchCore](Sources/AppLaunchCore/Documentation.docc)・[WhatsNewUI](Sources/WhatsNewUI/Documentation.docc)）にあります。
[DESIGN.md](./DESIGN.md) に、画面と起動の順番の決まり・その理由・アプリへの組み込み方があります。

## 導入

```swift
.package(url: "https://github.com/no-problem-dev/swift-app-launch.git", .upToNextMinor(from: "0.1.0"))
```

| プロダクト | 中身 | 依存 |
|---|---|---|
| `AppLaunchCore` | 版の変化・宣言と出す版の判定・端末の記録・起動の順番・計測のイベント | Foundation |
| `WhatsNewUI` | `WhatsNewPager` | SwiftUI |

[swift-review](https://github.com/no-problem-dev/swift-review) を使うアプリは、このパッケージが版を受け取る所に
`appVersion.description` を渡し、`onClose` で「お知らせの後」の評価の場面に進めます。

## 動作環境

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## ライセンス

MIT — [LICENSE](LICENSE) を見てください。
