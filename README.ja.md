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

## 起動の後で分かる枚

起動の途中で分かること（サーバーから取ったフィーチャーフラグなど）で決まる枚は、枚を出している間に足せます。
同じ版の新しい `Release` を渡すと、いま出している枚はそのままで、点の数が変わります。

```swift
@State var release: Release<NewsPage>   // start.release から: [.yearCards]

WhatsNewPager(release, onClose: { _ in tracker.settle() }, text: text, art: art)
    .task {
        if await flags.isOn(.yearNotes) {
            release = Release(version: "1.6.1", pages: [.yearCards, .yearNotes])
        }
    }
```

出す前に分かっている枚なら `release.keeping { ... }` で絞る方が簡単です。

## 画面の見出しと、枚の中の次の段

何の画面かの一言（「新しくなりました」など）は `title:` に渡します。× の横に出ます。枚ごとの見出し1つと1行は変わりません。
アプリの文字の型が `Text` でなく View を返すときは、View で渡せます: `title: { Text("新しくなりました").typography(.titleSmall) }`。

枚のボタンで、アプリが描く次の段に替えられます。見せたリマインダーの時刻を選び、通知の許可を聞く、など。
段は枚の場所に出て、`finish()` で次の枚へ進みます。許可のダイアログへ進む段は `asksPermission: true` を渡します。
その段では × を隠し、断るのはダイアログで選ぶので、段に「あとで」は置きません。

```swift
WhatsNewPager(
    release,
    title: Text("新しくなりました"),
    onClose: { _ in tracker.settle() },
    text: text,
    action: { page in
        page == .reminder
            ? .step(Text("時間を決める"), asksPermission: true) { step in
                ReadingTimePicker(onChosen: { step.finish() })
            }
            : nil
    },
    art: art
)
```

## お知らせの後の誘い

枚には値段・プラン・購入の誘いを置きません（[DESIGN.md §3](./DESIGN.md#3-rules-for-the-screen)）。
無料体験を始める誘いなどは、お知らせを閉じた**後**に出す別の画面にして、`followUp` の枠に入れます。
`onClose` で決めて `dismissed(_:then:)` に渡すと、間にほかの画面が入りません。

```swift
enum LaunchScreen: LaunchItem {
    case onboarding, whatsNew(Release<NewsPage>), trialOffer

    var slot: LaunchSlot {
        switch self {
        case .onboarding: .onboarding
        case .whatsNew: .whatsNew
        case .trialOffer: .followUp
        }
    }
}

// お知らせの onClose で。
tracker.settle()
queue.dismissed(.whatsNew(release), then: canStartTrial ? [.trialOffer] : [])
```

誘いの決まりはキューが守ります。その起動でオンボーディングかペイウォールを出していたら出さない。評価のお願いと後に続く画面は1回の起動で1つまで。
出せなかった分は `held` に残るので、次の起動に回すなら保存します。

## バージョンを直書きしているアプリが移るとき

版を自前のコードで比べてお知らせを出しているアプリの場合です。

1. **端末にある値をそのまま使う。** いまの版を残しているキーを渡します。値は文字列のまま読むので、古い画面を見た端末に同じ物は出ません。
   App Group やテストの `UserDefaults` もそのまま渡せます。

   ```swift
   let store = UserDefaultsLaunchRecordStore(defaults: appGroupDefaults, lastLaunchedVersionKey: "lastSeenVersion")
   let tracker = WhatsNewTracker(catalog: catalog, store: store)
   ```

2. **何も残していなかったアプリでは、** 今の端末は新しく入れた扱いになり、何も出ません。前から使っていたことがアプリのデータで分かるなら、
   その使い方でありえる一番古い版を `untrackedEarlierUse:` に渡します。
3. **古い画面で出していた版を `Release` で宣言し、** 版の比較と古い画面は同じ変更で消します。両方が出ることがないように。
4. **ほかの起動の画面は1つずつ `LaunchQueue` に移します。** キューの外の画面は `isIdle` を待ちます。

## まだお知らせの無いアプリ

それでもトラッカーは始めておきます。今から起動ごとの版が残るので、あとで最初の `Release` を宣言したとき、その版に上げた人に届きます。
枚がまだ無いあいだは枚の型に `Never` を使い、`LaunchQueue` にもお知らせの項目を入れません（`start.release` はいつも `nil` です）。

```swift
let tracker = WhatsNewTracker<Never>(catalog: .empty)
tracker.begin(bundle: .main)
```

最初のお知らせを出すときに、`Never` を枚の型に、`.empty` をその版の `Release` に替えます。

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
