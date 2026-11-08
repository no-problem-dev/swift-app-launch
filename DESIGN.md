# swift-app-launch — design

Status: 0.1.0, unreleased. Written 2026-11-08 from two apps that had each solved this on their
own: one with the version hard-coded in the sheet, one with releases declared as values. The
package takes the second shape.

A summary in Japanese is at the end ([日本語の要約](#日本語の要約)). It holds the screen rules in
full, since they are written down nowhere else.

---

## 1. Purpose

Two jobs that meet at launch:

1. **Tell people who updated what is new, in a few illustrated pages.** The app declares, per
   version, which pages to show. The package decides which release is due at a launch, carries one
   that could not be shown to the next launch, and provides the pager that shows it.
2. **Decide in one place what appears at launch, and in what order.** Onboarding, what's new, a
   rating request, a follow-up question and other sheets each want the screen at launch. Left to
   each screen, they stack or cancel each other. `LaunchQueue` takes what could appear and answers
   what to show now.

## 2. Non-goals, and why

| Not provided | Why |
|---|---|
| The illustrations, headings and lines | They are the content. A shared drawing would make every app's update screen look the same |
| An onboarding flow | Onboarding differs completely between apps. What they share (a slot that comes first, what it drops) is in `LaunchQueue` |
| A rating decision | `swift-review` owns when to ask. The queue only gives a review ask its place in the order |
| A price, a plan or a purchase button on a page | See §3. An update screen is for what changed |
| A "Later" button | Pages advance with one button; the close button is the way out. A "Later" before a permission dialog is rejected in review (§3) |
| A public version type | `swift-review` is to own `AppVersion`. Taking strings keeps this package free of that dependency (§5) |
| An analytics dependency | Events leave through a closure (§7) |

## 3. Rules for the screen

These are what the pager enforces, or what the app is asked to keep.

| Rule | Who keeps it | Why |
|---|---|---|
| Each page: an illustration on the upper half to 60 percent, then one heading and one short line | Pager (`artFraction` is clamped to 0.5–0.6) | Text alone does not land. A screen of text after an update reads as release notes, and release notes are skipped |
| No bullet lists | App (`WhatsNewPageText` has one heading and one line) | Bullets turn a page into a list of features. One page, one change |
| One to three pages per release | `Release` (precondition) | Past three, people tap through without looking |
| The illustration moves, and stands still under Reduce Motion | App draws it, pager passes `WhatsNewArtContext.animates` and fades between pages instead of sliding | A moving picture shows the change happening. Reduce Motion is a request to stop that |
| No price, plan or purchase invitation | App | The screen is a thank-you for updating. A sales pitch on it teaches people to close it next time |
| A close button on every page | Pager | The person decides how long to look. The screen must never feel like a gate |
| A permission is asked only on the page of the feature that needs it | App, through `WhatsNewAction.permission` | Asking at launch, before the feature is seen, gets "no". On that page the close button is hidden and pulling down is disabled, because an explanation before a permission dialog must lead to the dialog; declining happens in the dialog (App Review Guideline 5.1.1(iv); a "Later" there was rejected) |
| Shown at most once per release, and not after onboarding | `WhatsNewTracker`, `LaunchQueue` | Someone who just onboarded has nothing to catch up on |

## 4. Which release is due

Each version with something to tell gets one `Release(version:pages:)` in a `ReleaseCatalog`.

- **Fresh install or same version:** nothing.
- **After an update:** the newest release newer than the previous version and not newer than the
  current one. Someone who skipped from 1.4 to 1.8 sees one release, the newest, not three.
- **Carried over:** the release decided on is stored until `settle()` is called. If the app is
  closed before the release is, or the launch was taken by a paywall, the next launch shows it. If
  a newer release becomes due meanwhile, only the newer one is shown. A carried release newer than
  the running version (after a downgrade) is not shown.
- **Dropped:** a launch that showed onboarding drops what's new; the app calls `settle()`.

## 5. Versions

The public API takes versions as `String` and reads them internally as one to three dot-separated
numbers, the same reading as `swift-review`'s `AppVersion` (`1.10.0` > `1.9.0`, `1.6` == `1.6.0`).
A `Release` version must have two or three parts, matching the analytics pattern for `release`.

A version that cannot be read (such as `1.6.0-beta`) shows nothing and records nothing: an
unreadable version never puts a screen in front of anyone.

**Starting to record late.** An app that ships this package after it has users has no recorded
version on existing devices. Pass `untrackedEarlierUse:` with the oldest version that earlier use
could have been, when the app can tell from its own data that the device was used before; otherwise
the device counts as a fresh install. The argument is read only when nothing is recorded.

**Stored form.** Two plain strings in `UserDefaults` (`launch.lastVersion`, `whatsNew.pending` by
default). Plain strings, so an app that already keeps these values passes its own keys and keeps
what devices have.

## 6. The launch order

`LaunchQueue` is a value. The app adds what could appear (its own `LaunchItem` type, each with a
`LaunchSlot`), reads `next`, and reports `presented`, `dismissed` and `paywallShown`.

1. One thing at a time. While an item is on screen, `next` is `.busy`.
2. Highest slot first: `onboarding`, `whatsNew`, `reviewAsk`, `followUp`, `sheet`. Within a slot,
   in the order added.
3. A launch that showed onboarding shows no announcements: what's new is dropped, a review ask and
   follow-ups are held.
4. A launch that showed a paywall holds what's new, the review ask and follow-ups.
5. At most one of a review ask or a follow-up per launch. What's new may come before it; that pair
   is the most a launch shows.
6. Sheets are never held.

"Held" items stay in `held`; the app stores the ones that should come back. Items that should follow
another (a review ask decided when what's new closes) go in `dismissed(_:then:)`, so nothing slips in
between.

Initialisation (sign-in, migration, first data load) is the app's: it does not read `next` until the
first screen can be shown.

## 7. Analytics

The pager reports through `onEvent`:

| Event | Parameters | When |
|---|---|---|
| `whats_new_shown` | `release` | The pager appeared (once) |
| `whats_new_closed` | `release`, `page` (from 1), `pages`, `via` | It closed (once): `close_button`, `finished` (the last page's button), `swipe_down` (pulled down, or removed by the app) |

The names follow the shared analytics catalog. A bridge to an analytics package is a few lines:

```swift
onEvent: { event in
    analytics.send(event.name, event.parameters.mapValues { value in
        switch value {
        case let .text(text): .text(text)
        case let .count(count): .count(count)
        }
    })
}
```

## 8. Integrating

1. Declare the catalog and create a `WhatsNewTracker` once (it is a value; keep it where the app
   keeps its other launch state).
2. At launch, call `begin(bundle: .main)` as early as possible.
3. When the first screen can be shown, build a `LaunchQueue` from what could appear:
   onboarding if not completed, `start.release` if any, held follow-ups from an earlier launch,
   other sheets.
4. Present `next`. Report `presented` and `dismissed`; when onboarding is presented and drops what's
   new, call `tracker.settle()`.
5. In the pager's `onClose`, call `tracker.settle()`, decide the review ask (with `swift-review`, at
   the moment after what's new), and pass it to `dismissed(_:then:)`.

## 日本語の要約

更新した人に新しくなったことを数枚で伝え、起動のときに何をどの順番で出すかを1か所で決める。

### お知らせの画面の決まり

- 枚ごとに、上の半分〜6割に動くイラスト。その下に大きな見出し1つと短い1行だけ。**文字だけのお知らせは伝わらない**
- 箇条書きにしない。1枚に1つの変化
- 1つの版で1〜3枚
- 値段・プラン・購入の誘いを置かない。更新してくれた人へのお知らせで、売り込みを載せると次から閉じられる
- × でいつでも閉じられる（どの枚にも置く）
- 許可を聞くのはその機能の枚だけ。起動の瞬間には聞かない。その枚では × を隠し、下に引いて閉じられないようにする。許可の前の説明は必ず OS のダイアログへ進め、断るのはダイアログで選ぶ（審査 5.1.1(iv)。説明に「あとで」を置いてリジェクトされた）
- 「動きを減らす」がオンなら、イラストは終わりの形で止め、枚の切り替えはスライドでなくフェードにする
- 同じ版のお知らせは1回だけ。オンボーディングを見せた起動では出さない

### どの版を出すか

- 新しく入れた起動・同じ版の起動では出さない
- 前の版より新しく、いまの版以下の宣言のうち、一番新しい1件だけ（いくつも飛ばした人にも1件）
- 出せなかった分（閉じる前にアプリが終わった・ペイウォールに起動を譲った）は次の起動に持ち越す。その間に新しい版が来たら新しい方だけ
- 版は文字列で受け、中で1〜3つの数字として比べる。読めない版では何も出さず、何も書かない
- 途中から記録を始めたアプリは、前から使っていた跡があるときだけ `untrackedEarlierUse:` に想定の版を渡す

### 起動の順番

- 1つずつ。出している間はほかを出さない
- オンボーディング → お知らせ → 評価のお願い → 後に続く質問 → その他のシート
- オンボーディングを見せた起動では、お知らせを捨て、評価と質問は次に回す
- ペイウォールを出した起動では、お知らせ・評価・質問を次に回す（捨てない）
- 評価のお願いと質問は1回の起動で1つまで。お知らせの後に1つ続くのが最大
- シートは止めない

### 計測

`whats_new_shown{release}` と `whats_new_closed{release, page, pages, via}`。`via` は `close_button`・`finished`・`swipe_down`。名前は共通のカタログに合わせた。
