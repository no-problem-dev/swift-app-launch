# ``AppLaunchCore``

Put everything that appears at launch in one order, and read the values of a what's-new campaign.

@Metadata {
    @PageColor(blue)
}

## Overview

What appears at launch goes through ``LaunchQueue``: the app adds its own ``LaunchItem`` values,
each in a ``LaunchSlot``, and reads ``LaunchQueue/next``. The queue shows one thing at a time, puts
onboarding first, drops what's new after onboarding, holds announcements after a paywall, and lets
at most one follow-up through per launch.

Which version announces what is not decided here: a `whats_new` campaign does. Its values decode
into ``WhatsNewCardContent`` as they are, and `WhatsNewCard` in `WhatsNewUI` draws them.

```swift
var queue = LaunchQueue<LaunchScreen>()
if !onboardingCompleted { queue.add(.onboarding) }
for question in heldQuestions { queue.add(question) }

// The campaign engine waits while a launch screen is up.
// CampaignEngine(…, isBusy: { queue.presenting != nil })

if case let .present(screen) = queue.next {
    show(screen)
    queue.presented(screen)
}
```

Everything here is Foundation only and pure, so it is checked with `swift test` on macOS.

## Topics

### The launch order

- ``LaunchQueue``
- ``LaunchItem``
- ``LaunchSlot``
- ``LaunchStep``

### The what's-new card's values

- ``WhatsNewCardContent``
- ``WhatsNewImage``
