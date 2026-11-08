# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.2] - 2026-11-08

### Added

- `WhatsNewPager(_:title:…)` with a `@ViewBuilder` title, for an app whose type styles return
  `some View` (`title: { Text("What's New").typography(.titleSmall) }`). It sits in the same place as
  the `Text` title: one line beside the close button, read as a header. The pager's font and color
  apply underneath, so the app's style wins. The `title: Text?` initializer stays as it was

## [0.2.1] - 2026-11-08

### Added

- `ReleaseCatalog.empty`, for an app that has nothing to tell yet:
  `WhatsNewTracker<Never>(catalog: .empty)`. The README shows how such an app starts recording
  versions so its first release later reaches the people who update to it

## [0.2.0] - 2026-11-08

### Fixed

- `WhatsNewTracker.settle()` wrote the last launched version back along with clearing the waiting
  release. A version that was only read (such as one a UI test passes as a launch argument, which
  `UserDefaults` reads but does not keep) was saved to the device and seen again at the next
  launch. `settle()` now writes only the waiting release, through the new
  `LaunchRecordStore.save(pendingRelease:)`. It has a default (load, change, save), so stores an app
  wrote keep compiling; `UserDefaultsLaunchRecordStore` writes the one key.

### Added

- `WhatsNewPager(_:title:...)`: a screen title (such as "What's New") beside the close button, read
  as a header. Each page keeps its one heading and one line.
- `WhatsNewAction.step(_:asksPermission:content:)`: a page's button moves the page to a next step the
  app draws, such as choosing a reminder time and then asking for notifications. The step takes the
  page's place without the dots and the main button, and moves on with
  `WhatsNewStepContext.finish()`. A step that leads to a permission dialog hides the close button and
  cannot be pulled down. Backed by `WhatsNewSession.enterStep()` and `isInStep`, cleared when the
  page changes. `WhatsNewAction.opensStep` tells the two kinds of button apart.
- Not added: a secondary button ("Later") in a step or on a page. Before a permission dialog it is
  rejected in review (5.1.1(iv)), and elsewhere the close button is the way out (DESIGN.md §3).

## [0.1.1] - 2026-11-08

### Added

- `WhatsNewPager` takes a changed release while on screen, such as a page added once a feature
  flag is known: pass the new release with the same version, and the page on screen stays. Backed
  by `WhatsNewSession.update(from:to:)`; `WhatsNewSession.pageCount` now follows the change.
- `UserDefaultsLaunchRecordStore(defaults:lastLaunchedVersionKey:pendingReleaseKey:)` takes a
  `UserDefaults` instance the app holds (an App Group suite, or one a test or scenario set up),
  `.standard` by default. The store stays `Sendable`. It replaces
  `init(lastLaunchedVersionKey:pendingReleaseKey:)`, so existing calls compile as before;
  `init?(suiteName:...)` is unchanged.
- README: pages known only after launch, an invitation (such as a free trial) after what's new in
  the `followUp` slot, and moving from a version hard-coded in the app.

## [0.1.0] - 2026-11-08

### Added

- `AppLaunchCore`, Foundation only:
  - `Release` (a version and one to three pages of the app's own type) and `ReleaseCatalog`, which
    picks the release due after an update: the newest one newer than the previous version and not
    newer than the current one.
  - `VersionChange` (`fresh`, `upgraded(from:)`, `same`) and `PreviousLaunch`, including a version
    to assume for devices used before recording started. Versions are taken as strings and compared
    as one to three numbers.
  - `WhatsNewTracker`, which records each launch's version and carries a release that was not
    closed to the next launch, over `LaunchRecordStore` (`UserDefaultsLaunchRecordStore` with
    configurable keys, `InMemoryLaunchRecordStore`).
  - `LaunchQueue`, `LaunchItem`, `LaunchSlot` and `LaunchStep`: one order for what appears at
    launch, one at a time, with what's new dropped after onboarding, announcements held after a
    paywall, and at most one follow-up per launch.
  - `WhatsNewSession` and `WhatsNewEvent` (`whats_new_shown`, `whats_new_closed` with
    `close_button`, `finished` or `swipe_down`).
- `WhatsNewUI`: `WhatsNewPager`, with `WhatsNewPageText`, `WhatsNewAction` (a permission asked only
  on its feature's page), `WhatsNewArtContext` (Reduce Motion) and `WhatsNewLabels` (English and
  Japanese).
