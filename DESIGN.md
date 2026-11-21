# swift-app-launch — design

Status: 0.3.0 (2026-11-21). Rewritten for appgrowstack (app-playbook
`docs/growth-platform-design-2026-11-21.md` §3.2 and §4.2): which version shows what, and to whom,
moved to the `whats_new` campaign type of swift-app-campaign. What is left here is the card's look
and the order of the app's own launch screens.

A summary in Japanese is at the end ([日本語の要約](#日本語の要約)).

---

## 1. Purpose

Two jobs that meet at launch:

1. **Draw the what's-new card from a campaign's values.** A `whats_new` campaign is triggered by
   `app_updated` (the first launch of a newer version, which the campaign engine records), shown
   at most once, and compared with a holdout. Its values are a heading, one line, an optional image
   and an optional button label. `WhatsNewCard` draws them.
2. **Decide in one place what appears at launch, and in what order.** Onboarding, what's new, a
   follow-up question and other sheets each want the screen at launch. Left to each screen, they
   stack or cancel each other. `LaunchQueue` takes what could appear and answers what to show now.

## 2. Who decides what

| Question | Where it is decided |
|---|---|
| Which version announces what | the campaign: trigger `app_updated` with `to_version`, `app_version` (`whats_new.trigger`) |
| Once only | the campaign's `limits.max_shown` 1 (`whats_new.max_shown`) |
| What the button opens | the campaign's `on_tap`: the new feature's screen (`whats_new.on_tap`) |
| No price or purchase invitation | the campaign check (`whats_new.no_purchase`) and the card, which has no place for one |
| Whether it worked | the holdout: the share who used the feature within the goal's window |
| Not on top of onboarding or another screen | the engine waits while `isBusy`; the app's `LaunchQueue` says what is on screen |
| The look | **this package** (`WhatsNewCard`) |

The checks are in app-growth `schema/inapp/templates/whats_new.json`.

## 3. Rules for the card

| Rule | Who keeps it | Why |
|---|---|---|
| An illustration on the upper half to 60 percent, then one heading and one short line | Card (`artFraction` is clamped to 0.5–0.6); the template's `headline` (20) and `body` (60) | Text alone does not land. A screen of text after an update reads as release notes (rating R28) |
| No bullet lists | The values: one heading, one line | One card, one change |
| One card per version | The campaign (`max_shown` 1) | Past one, people tap through |
| The illustration moves, and stands still under Reduce Motion | App draws it (`art:`), the card passes `WhatsNewArtContext.animates` | A moving picture shows the change happening |
| No price, plan or purchase invitation | The campaign check; the card has no place for one | The card is a thank-you for updating (R28) |
| A close button, always | Card | The person decides how long to look |
| A permission is asked on the feature's own screen, which the button opens | The app's screen | Asking before the feature is seen gets "no" (5.1.1(iv)) |

## 4. The launch order

`LaunchQueue` is a value. The app adds what could appear (its own `LaunchItem` type, each with a
`LaunchSlot`), reads `next`, and reports `presented`, `dismissed` and `paywallShown`.

1. One thing at a time. While an item is on screen, `next` is `.busy`.
2. Highest slot first: `onboarding`, `whatsNew`, `followUp`, `sheet`. Within a slot, in the order
   added.
3. A launch that showed onboarding shows no announcements: what's new is dropped, follow-ups are
   held.
4. A launch that showed a paywall holds what's new and follow-ups.
5. At most one follow-up per launch. What's new may come before it; that pair is the most a launch
   shows.
6. Sheets are never held.

With campaigns: give the engine `isBusy: { queue.presenting != nil || … }`, so a campaign waits
while a launch screen is up. When the engine hands the app the what's-new card, report it to the
queue (`presented(.whatsNew)`), and `dismissed(.whatsNew, then: …)` when it closes, so a follow-up
comes after it and not on top of it.

The rating prompt is not in the queue: it is a `system` placement with no screen (swift-review).

## 5. What was removed in 0.3.0, and where it went

| Removed | Now |
|---|---|
| `Release`, `ReleaseCatalog`, `WhatsNewTracker`, `LaunchStart` | the `whats_new` campaign (trigger `app_updated`, `max_shown` 1) |
| `VersionChange`, `VersionNumber`, `PreviousLaunch` | the engine records `app_updated { from_version, to_version }` |
| `LaunchRecord` and its stores | the engine's own record |
| `WhatsNewPager`, `WhatsNewSession`, `WhatsNewPageText`, `WhatsNewAction` | `WhatsNewCard` (one card) |
| `WhatsNewEvent`, `LaunchMetricValue` | the engine's `campaign_shown`, `campaign_tapped`, `campaign_dismissed` |
| `LaunchSlot.reviewAsk` | no own review screen (rating R2, R3); the rating prompt is a `system` placement |

## 日本語の要約

**何のためのパッケージか。** 型 `whats_new` のキャンペーンの値からお知らせの枚を描くことと、起動のときにアプリ自身の画面を何の順に出すかの純粋な関数。どの版で何を誰に出すかは持たない。それは swift-app-campaign の件（きっかけ `app_updated`・`max_shown` 1・holdout）が決める。

**お知らせの枚の決まり。** 上の半分〜6割にイラスト（アプリが描けば動かしてよい・「動きを減らす」で止める）。その下に見出し1つと短い1行（件の `headline` 20字・`body` 60字）。箇条書きにしない。値段・購入の誘いを置かない（件の check と、枚にその場所が無いこと）。× でいつでも閉じられる。ボタンは件の `on_tap`（新しい機能の画面）へ進み、許可はその画面で聞く。

**起動の順番。** 1つずつ。オンボーディング → お知らせ → 後に続く質問 → その他のシート。オンボーディングを見せた起動ではお知らせを捨て、質問は次に回す。ペイウォールを出した起動ではお知らせと質問を次に回す。質問は1回の起動で1つまで。キャンペーンの判定には `isBusy: { queue.presenting != nil }` を渡し、お知らせの枚が出たら `presented(.whatsNew)`、閉じたら `dismissed(.whatsNew, then:)` を伝える。評価の依頼は画面を持たないので順番に入れない。

**0.3.0 で消した物。** 版の宣言と、どの版を出すかの判定（`Release`・`ReleaseCatalog`・`WhatsNewTracker`）・前回の版との変化・記録の置き場所・数枚を送る `WhatsNewPager`・計測（`whats_new_shown`・`whats_new_closed`）・評価のお願いの段（`LaunchSlot.reviewAsk`）。
