English | [日本語](./README.ja.md)

# swift-app-launch

Tell people what changed after an update, in a few illustrated pages, and decide in one place what appears at launch and in what order: onboarding, what's new, a rating request, then everything else.

![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

Most people never read release notes. A screen after an update is the one place to show them what
is new, and it goes wrong in familiar ways: a wall of bullet points, a version hard-coded in a view,
a screen lost because the app was closed, or three sheets stacked on one launch.

## Features

- **Releases as declarations.** One `Release(version:pages:)` per version with something to tell.
  Someone who skipped versions sees one release, the newest; one that could not be shown comes back
  at the next launch
- **One order for everything at launch.** `LaunchQueue` takes what could appear and answers what to
  show now: one at a time, onboarding first, what's new dropped after onboarding, held after a
  paywall, at most one follow-up per launch
- **A pager that keeps the rules.** An illustration on the upper half to 60 percent, a heading and
  one line, a close button on every page, Reduce Motion respected, permissions asked only on the
  feature's own page
- **Analytics through a closure.** `whats_new_shown{release}` and
  `whats_new_closed{release, page, pages, via}`, with `via` one of `close_button`, `finished`,
  `swipe_down`
- **No dependencies, versions as strings.** The decisions are pure and run under `swift test` on macOS

## Quick Start

```swift
import AppLaunchCore
import WhatsNewUI

enum NewsPage: Hashable, Sendable { case yearCards, yearNotes }

let tracker = WhatsNewTracker<NewsPage>(catalog: [
    Release(version: "1.6.1", pages: [.yearCards, .yearNotes]),
])

// Once per launch.
let start = tracker.begin(bundle: .main)

// When nothing else is on screen, show the pages.
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

## Documentation

The API reference is on DocC ([AppLaunchCore](https://no-problem-dev.github.io/swift-app-launch/documentation/applaunchcore/),
[WhatsNewUI](https://no-problem-dev.github.io/swift-app-launch/documentation/whatsnewui/)).
[DESIGN.md](./DESIGN.md) covers the rules for the screen and the launch order, the reasons behind
them, and how an app integrates the package.

## Installation

```swift
.package(url: "https://github.com/no-problem-dev/swift-app-launch.git", .upToNextMinor(from: "0.1.0"))
```

| Product | Contents | Depends on |
|---|---|---|
| `AppLaunchCore` | Version change, releases and which is due, stored record, launch order, analytics events | Foundation |
| `WhatsNewUI` | `WhatsNewPager` | SwiftUI |

Apps that use [swift-review](https://github.com/no-problem-dev/swift-review) pass
`appVersion.description` wherever this package takes a version, and reach their after-what's-new
rating moment in `onClose`.

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.2+

## License

MIT — see [LICENSE](LICENSE).
