[English](./README.md) | 日本語

# swift-app-launch

キャンペーンが渡すお知らせの枚を描き、起動のときに何をどの順に出すかを1か所で決める（オンボーディング → お知らせ → 後に続く質問 → その他）。

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

リリースノートはほとんど読まれません。更新の後の1枚が、新しくなったことを見せられる唯一の場所で、
箇条書きの壁・売り込み・1回の起動に3枚のシートが重なる、という形で崩れがちです。

**どの版で何を誰に出すかは決めません。** それは
[swift-app-campaign](https://github.com/no-problem-dev/swift-app-campaign) の型 `whats_new` の件が決めます
（きっかけは `app_updated`・1回だけ・holdout と比べる）。

## 特徴

- **決まりを守る枚。** 上の半分〜6割にイラスト・見出し1つと短い1行・ボタン1つ・×・「動きを減らす」に従う
- **件の値をそのまま。** `WhatsNewCardContent` は `whats_new` のプレースメントの値をそのまま読むので、プレースメントの `Values` にできます
- **起動のときの順番を1つに。** `LaunchQueue` が、いま何を出すかを答えます。1つずつ・オンボーディングが先・オンボーディングの後はお知らせを捨てる・ペイウォールの後は次に回す・質問は1回の起動で1つまで
- **外部の依存なし。** 順番は純粋で、macOS の `swift test` で確かめられます

## 使い方

```swift
import AppLaunchCore
import CampaignCore
import CampaignSwiftUI
import WhatsNewUI

struct WhatsNewPlacement: CampaignPlacement {
    static let name = CampaignTemplate.WhatsNew.name
    static let fields = CampaignTemplate.WhatsNew.fields
    typealias Values = WhatsNewCardContent
}

// CampaignEngine(…, placements: [WhatsNewPlacement.self], isBusy: { launch.presenting != nil }, …)

RootView()
    .campaignPlacement(WhatsNewPlacement.self, in: campaigns) { offer in
        WhatsNewCard(offer.values, onPrimary: offer.tap, onClose: { offer.dismiss(.closeButton) })
    }
```

件はアプリの `campaigns/` に置きます（app-growth の `whats_new` のテンプレート）。動くイラストを自分で描くときは `art:` を渡します。

## 起動の順番

```swift
enum LaunchScreen: LaunchItem {
    case onboarding, whatsNew, trialOffer

    var slot: LaunchSlot {
        switch self {
        case .onboarding: .onboarding
        case .whatsNew: .whatsNew
        case .trialOffer: .followUp
        }
    }
}

if case let .present(screen) = launch.next { show(screen); launch.presented(screen) }
// 件の枚が出たときと閉じたとき:
launch.presented(.whatsNew)
launch.dismissed(.whatsNew, then: canStartTrial ? [.trialOffer] : [])
```

この起動で出せなかった質問は `held` に残ります。次に出すなら保存してください。

## ドキュメント

API は DocC（[AppLaunchCore](Sources/AppLaunchCore/Documentation.docc)・[WhatsNewUI](Sources/WhatsNewUI/Documentation.docc)）。
[DESIGN.md](./DESIGN.md) に、何を誰が決めるか・枚と順番の決まり・0.3.0 で外へ出した物を書いています。

## 導入

```swift
.package(url: "https://github.com/no-problem-dev/swift-app-launch.git", .upToNextMinor(from: "0.3.0"))
```

| プロダクト | 中身 | 依存 |
|---|---|---|
| `AppLaunchCore` | 起動の順番・枚の値 | Foundation |
| `WhatsNewUI` | `WhatsNewCard`・`WhatsNewImageView` | SwiftUI |

## 要件

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
