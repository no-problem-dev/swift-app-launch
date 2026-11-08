# ``WhatsNewUI``

Show a release's pages one at a time, with the app's own illustrations, a close button on every page, and Reduce Motion respected.

@Metadata {
    @PageColor(blue)
}

## Overview

``WhatsNewPager`` lays out each page as an illustration on the upper half to 60 percent, then one
heading and one short line (``WhatsNewPageText``). The app draws the illustration and is told
through ``WhatsNewArtContext`` whether to move. A page that needs a permission replaces "Next" with
``WhatsNewAction/permission(_:request:)``; that page hides the close button and cannot be pulled
down, so the explanation always leads to the system dialog.

```swift
.fullScreenCover(item: $release) { release in
    WhatsNewPager(
        release,
        onEvent: analytics.record,
        onClose: { via in
            tracker.settle()
            self.release = nil
        },
        text: { page in WhatsNewPageText(title: page.title, message: page.line) },
        action: { page in
            page == .reminders ? .permission(Text("Turn on reminders")) { await reminders.requestAccess() } : nil
        },
        art: { page, context in page.art(animates: context.animates) }
    )
    .buttonStyle(.borderedProminent)
}
```

## Topics

### Showing pages

- ``WhatsNewPager``
- ``WhatsNewPageText``
- ``WhatsNewAction``
- ``WhatsNewArtContext``
- ``WhatsNewLabels``
