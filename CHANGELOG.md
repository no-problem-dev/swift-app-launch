# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
