# ``WhatsNewUI``

Draw the what's-new card from a campaign's values: an illustration, a heading and one line, one button, and a close button.

@Metadata {
    @PageColor(blue)
}

## Overview

``WhatsNewCard`` lays out an illustration on the upper half to 60 percent, then one heading and
one short line from ``AppLaunchCore/WhatsNewCardContent``. Without `art:`, it draws the campaign's
image itself (``WhatsNewImageView``); with it, the app draws the illustration and is told through
``WhatsNewArtContext`` whether to move.

```swift
struct WhatsNewPlacement: CampaignPlacement {
    static let name = CampaignTemplate.WhatsNew.name
    static let fields = CampaignTemplate.WhatsNew.fields
    typealias Values = WhatsNewCardContent
}

RootView()
    .campaignPlacement(WhatsNewPlacement.self, in: campaigns) { offer in
        WhatsNewCard(offer.values, onPrimary: offer.tap, onClose: { offer.dismiss(.closeButton) }) { image, context in
            AutoCheckArt(animates: context.animates)
        }
        .buttonStyle(.borderedProminent)
    }
```

## Topics

### The card

- ``WhatsNewCard``
- ``WhatsNewImageView``
- ``WhatsNewArtContext``
- ``WhatsNewLabels``
