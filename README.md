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

## Pages known only after launch

A page that depends on something known later in the launch, such as a feature flag fetched from the
server, can join the release while the pager is on screen. Pass the new release with the same
version; the pager keeps the page on screen and redraws the dots.

```swift
@State var release: Release<NewsPage>   // from start.release: [.yearCards]

WhatsNewPager(release, onClose: { _ in tracker.settle() }, text: text, art: art)
    .task {
        if await flags.isOn(.yearNotes) {
            release = Release(version: "1.6.1", pages: [.yearCards, .yearNotes])
        }
    }
```

Pages known before the pager appears are simpler with `release.keeping { ... }`.

## A screen title, and a next step on a page

A title naming the screen (such as "What's New") goes in `title:`; it sits beside the close button.
Each page still has one heading and one line.

A page can move to a next step the app draws, such as choosing a time for the reminder it just
showed and then asking for notifications. The step takes the page's place and moves on with
`finish()`. A step that leads to a permission dialog passes `asksPermission: true`: the close
button is hidden there and declining happens in the dialog, so the step has no "Later".

```swift
WhatsNewPager(
    release,
    title: Text("What's New"),
    onClose: { _ in tracker.settle() },
    text: text,
    action: { page in
        page == .reminder
            ? .step(Text("Choose a time"), asksPermission: true) { step in
                ReadingTimePicker(onChosen: { step.finish() })
            }
            : nil
    },
    art: art
)
```

## An invitation after what's new

The pages carry no price, plan or purchase invitation ([DESIGN.md §3](./DESIGN.md#3-rules-for-the-screen)).
An invitation, such as starting a free trial, is a screen of its own that comes **after** the pager
closes, in the `followUp` slot. Decide it in `onClose` and pass it to `dismissed(_:then:)`, so
nothing slips in between.

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

// In the pager's onClose:
tracker.settle()
queue.dismissed(.whatsNew(release), then: canStartTrial ? [.trialOffer] : [])
```

The queue keeps the invitation's rules: not after onboarding or a paywall at this launch, and at most
one of a review ask or a follow-up per launch. One that cannot be shown stays in `held`; store it if
it should come back.

## Moving from a version hard-coded in the app

An app that already shows what's new by comparing versions in its own code:

1. **Keep what devices already have.** Pass the key the app already stores the last version under.
   The value is read as a plain string, so a device that saw the old screen does not see it again.
   An App Group or a test's `UserDefaults` is passed as is.

   ```swift
   let store = UserDefaultsLaunchRecordStore(defaults: appGroupDefaults, lastLaunchedVersionKey: "lastSeenVersion")
   let tracker = WhatsNewTracker(catalog: catalog, store: store)
   ```

2. **When the app stored nothing,** existing devices count as fresh installs and see nothing. If the
   app can tell from its own data that the device was used before, pass the oldest version that use
   could have been as `untrackedEarlierUse:`.
3. **Declare the release the old screen showed** as a `Release`, and remove the version check and
   the old screen in the same change, so the two never both appear.
4. **Move other launch screens into `LaunchQueue`** one at a time. Screens outside the queue wait for
   `isIdle`.

## Documentation

The API reference is on DocC ([AppLaunchCore](Sources/AppLaunchCore/Documentation.docc),
[WhatsNewUI](Sources/WhatsNewUI/Documentation.docc)).
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
