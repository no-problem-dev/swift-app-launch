English | [日本語](./README.ja.md)

# swift-app-launch

Draw the what's-new card a campaign hands your app, and decide in one place what appears at launch and in what order: onboarding, what's new, a follow-up, then everything else.

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

Most people never read release notes. A card after an update is the one place to show them what is
new, and it goes wrong in familiar ways: a wall of bullet points, a sales pitch, or three sheets
stacked on one launch.

**It does not decide which version shows what, or to whom.** The `whats_new` campaign type of
[swift-app-campaign](https://github.com/no-problem-dev/swift-app-campaign) does: triggered by
`app_updated`, shown once, compared with a holdout.

## Features

- **A card that keeps the rules.** An illustration on the upper half to 60 percent, a heading and
  one line, one button, a close button, Reduce Motion respected
- **Values straight from the campaign.** `WhatsNewCardContent` decodes the `whats_new` placement's
  values as they are, so it can be your placement's `Values`
- **One order for everything at launch.** `LaunchQueue` takes what could appear and answers what to
  show now: one at a time, onboarding first, what's new dropped after onboarding, held after a
  paywall, at most one follow-up per launch
- **No dependencies.** The order is pure and runs under `swift test` on macOS

## Usage

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

The campaign lives in the app's `campaigns/` (see the `whats_new` template in app-growth). Pass
`art:` to draw a moving illustration of your own.

## The launch order

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
// When the campaign's card appears and closes:
launch.presented(.whatsNew)
launch.dismissed(.whatsNew, then: canStartTrial ? [.trialOffer] : [])
```

A follow-up that cannot be shown at this launch stays in `held`; store it if it should come back.

## Documentation

The API reference is on DocC ([AppLaunchCore](Sources/AppLaunchCore/Documentation.docc),
[WhatsNewUI](Sources/WhatsNewUI/Documentation.docc)). [DESIGN.md](./DESIGN.md) covers who decides
what, the rules for the card and the launch order, and what moved out in 0.3.0.

## Installation

```swift
.package(url: "https://github.com/no-problem-dev/swift-app-launch.git", .upToNextMinor(from: "0.3.0"))
```

| Product | Contents | Depends on |
|---|---|---|
| `AppLaunchCore` | Launch order, the card's values | Foundation |
| `WhatsNewUI` | `WhatsNewCard`, `WhatsNewImageView` | SwiftUI |

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## License

MIT — see [LICENSE](LICENSE).
