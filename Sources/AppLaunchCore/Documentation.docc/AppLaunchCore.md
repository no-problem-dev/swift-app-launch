# ``AppLaunchCore``

Decide which release's pages are due after an update, keep one that could not be shown, and put everything that appears at launch in one order.

@Metadata {
    @PageColor(blue)
}

## Overview

An app declares, per version, the pages that tell people what changed (``Release``), and collects
them in a ``ReleaseCatalog``. At each launch, ``WhatsNewTracker`` compares the running version with
the one recorded last time (``VersionChange``), picks the newest release in between, and stores it
until the app calls ``WhatsNewTracker/settle()``, so a release that was never closed comes back.

What appears at launch goes through ``LaunchQueue``: the app adds its own ``LaunchItem`` values, each
in a ``LaunchSlot``, and reads ``LaunchQueue/next``. The queue shows one thing at a time, puts
onboarding first, drops what's new after onboarding, holds announcements after a paywall, and lets
at most one follow-up through per launch.

```swift
let start = tracker.begin(bundle: .main)

var queue = LaunchQueue<LaunchScreen>()
if !onboardingCompleted { queue.add(.onboarding) }
if let release = start.release { queue.add(.whatsNew(release)) }
for question in heldQuestions { queue.add(question) }

if case let .present(screen) = queue.next {
    show(screen)
    if !queue.presented(screen).isEmpty { tracker.settle() }
}
```

Everything here is Foundation only and pure, so it is checked with `swift test` on macOS.

## Topics

### Declaring releases

- ``Release``
- ``ReleaseCatalog``

### Each launch

- ``WhatsNewTracker``
- ``LaunchStart``
- ``VersionChange``
- ``PreviousLaunch``

### Storing

- ``LaunchRecord``
- ``LaunchRecordStore``
- ``UserDefaultsLaunchRecordStore``
- ``InMemoryLaunchRecordStore``

### The launch order

- ``LaunchQueue``
- ``LaunchItem``
- ``LaunchSlot``
- ``LaunchStep``

### Pages and analytics

- ``WhatsNewSession``
- ``WhatsNewEvent``
- ``WhatsNewCloseVia``
- ``LaunchMetricValue``
