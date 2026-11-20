# E-ink mode module

Optional, self-contained module that makes OpenlibExtended usable on e-paper
screens (Onyx Boox, Bigme, Meebook, PocketBook Android, Mudita and other
Android e-readers).

E-ink panels need roughly 120–700 ms per redraw and leave ghost images behind
fast partial updates. Anything that moves — page transitions, ink ripples,
spinners, fling scrolling, overscroll effects, progress text that ticks many
times a second — turns into flicker, smearing and wasted battery. While
E-ink mode is on, this module keeps the screen still.

## What it does

| While E-ink mode is on | File |
| --- | --- |
| No route transitions; screens appear in one redraw | `eink_theme.dart` |
| No ink splash / ripple on taps | `eink_theme.dart` |
| Scrolling follows the finger and stops when it lifts (no fling, no bounce, no overscroll glow) | `eink_scroll.dart` |
| Indeterminate spinners and bars become a still hourglass / empty track | `busy_indicator.dart` |
| The app reports `MediaQuery.disableAnimations`, so widgets that honour the system "Remove animations" setting go still too | `eink_mode.dart` |
| Download progress repaints at most every 2 s (250 ms when off, instead of once per network chunk) | `progress_throttle.dart` |

`BusyIndicator` and `BusyBar` also go still when the user turns on Android's
own "Remove animations", even with E-ink mode off.

## Turning it on

Settings › Appearance › **E-ink mode**. It's stored as the `einkMode`
preference (`1` on, `0` off). If the user has never chosen, the app turns it
on for Android devices whose manufacturer or brand matches
`einkManufacturerHints` (e.g. `onyx`, `boox`, `bigme`, `pocketbook`). Once the
user saves a choice, it always wins.

No new dependencies: detection uses `device_info_plus`, which the app already
uses.

## Where the app calls the module

The module lives entirely in this folder. The rest of the app uses it in only
these places:

- `lib/main.dart`: `loadEinkMode()` at startup, the `einkModeProvider`
  override, `einkTheme()` on both themes, `applyEinkMediaQuery()` in the
  `MaterialApp` builder, and `EinkScrollPhysics` in the app scroll behaviour.
- `lib/ui/settings_page.dart`: the switch tile, which calls `setEinkMode()`.
- `lib/services/download_manager.dart`: `shouldEmitProgressUi()` in
  `_updateTaskProgress`.
- The screens that show a loading spinner use `BusyIndicator` / `BusyBar`
  in place of `CircularProgressIndicator` / indeterminate
  `LinearProgressIndicator`.
- `lib/l10n/app_*.arb`: `einkMode` and `einkModeHint` strings, in all five
  languages.
- Page turning (see below): `lib/ui/epub_viewer.dart` and
  `lib/ui/pdf_viewer.dart` (`PageTurnKeys`, `PageTapZones`),
  `lib/ui/results_page.dart` (**Load more**), the Reader section of
  `lib/ui/settings_page.dart`, `MainActivity.kt` (volume keys), the
  `volumeKeysTurnPages*`, `loadMoreResults` and `readerHelp*` strings, and
  `lib/ui/components/reader_help_overlay.dart`.

To take the module out, revert those calls and delete this folder.

## Using it in new code

```dart
import 'package:openlib/features/eink/eink.dart';

// Use instead of an indeterminate CircularProgressIndicator:
const BusyIndicator(size: 20, strokeWidth: 2);

// Read the setting:
final eink = ref.watch(einkModeProvider);
```

Rules of thumb for screens that should work on e-ink:

- Use `BusyIndicator` / `BusyBar` for indeterminate progress. A determinate
  indicator with a `value` is fine as it is.
- Before adding an animation, check `MediaQuery.disableAnimationsOf(context)`
  and skip it when that's true.
- Don't use colour as the only signal of a state. Pair it with an icon or a
  label.
- Throttle any value that updates more than about once a second.

## Tests

`test/eink_mode_test.dart` covers device detection, the throttle intervals,
both indicator states, the e-ink theme and scroll behaviour in `MyApp`, and
the no-fling physics. `test/download_manager_test.dart` sets
`EinkProgress.throttle = false` because those tests react to each network
chunk.

```bash
flutter test test/eink_mode_test.dart
```

## Contributing to this module

Follow the repository's [CONTRIBUTING.md](../../../CONTRIBUTING.md). For this
module that means:

- **No new dependencies.** APK size matters. Vendor refresh SDKs (for example
  Onyx `onyxsdk-device`) are deliberately left out. Any future integration
  should be optional and loaded behind a platform channel, not added as a
  pubspec dependency.
- **Don't edit the project README or other info files** for e-ink changes
  (typo fixes are the exception). Document them here instead.
- **Self-review before opening a PR:**
  - [ ] `flutter analyze` and `flutter test` pass, and nothing outside e-ink
        mode changes behaviour (apart from the 250 ms progress throttle).
  - [ ] With the switch off, the app looks and animates exactly as before.
  - [ ] With it on, there are no transitions, ripples, spinners or fling
        scrolling, on a real e-ink device if you have one.
  - [ ] New strings are in every `lib/l10n/app_*.arb` and regenerated with
        `flutter gen-l10n`.
  - [ ] The technical claims in this README are still accurate, and its
        spelling and grammar are checked.

## Page turning

Readers on e-paper turn pages instead of scrolling. These work in the
built-in EPUB and PDF readers whether E-ink mode is on or off; E-ink mode
only changes whether the turn animates.

| What | Where |
| --- | --- |
| Keys: PageDown / ArrowRight / ArrowDown / Space = next page; PageUp / ArrowLeft / ArrowUp / Shift+Space = previous page (e-reader page buttons send PAGE_UP / PAGE_DOWN; Bluetooth page turners send these too) | `page_keys.dart` (`PageTurnKeys`, `pageTurnForKey`) |
| Volume keys turn pages (volume down = next): optional, Android only | `page_keys.dart` (`VolumeKeyPaging`) + `MainActivity.kt` |
| EPUB edge tap zones: right 30 % of the width = next page, left 30 % = previous; the middle keeps its normal gestures (text selection, links) | `page_scroll.dart` (`PageTapZones`) |
| EPUB "page" = scroll by one screen minus 10 % overlap; jumps with no animation in E-ink mode or with "Remove animations" | `page_scroll.dart` (`scrollByPage`) |
| PDF: the same keys go to the next / previous PDF page (jump in E-ink mode) | `lib/ui/pdf_viewer.dart` |
| Search results: no auto-loading on scroll; a **Load more** button at the end of the list fetches the next 50 | `lib/ui/results_page.dart` |

**Volume keys.** Settings › Reader › **Volume keys turn pages** (shown on
Android only), stored as the `volumeKeyPaging` preference (`1` / `0`). If
the user has never chosen, it follows E-ink mode. While a reader screen is
open with the setting on, it calls `setVolumeKeyPaging(true)` on the
`openlib/page_keys` channel; `MainActivity.dispatchKeyEvent` then swallows
VOLUME_UP / VOLUME_DOWN and sends `pageKey` (`next` / `previous`) back. On
leaving the reader it sends `false`, so the volume keys change the volume
everywhere else.

**How EPUB paging finds the scroll position.** `epub_view` keeps its
`ScrollablePositionedList` controllers private and only exposes
index-based `jumpTo` / `scrollTo`, which can't move by a screen. The reader
puts a `GlobalKey` on the book's subtree and `findVerticalScrollPosition`
walks down to the first vertical `ScrollableState` — the list's active
(primary) view, which `ScrollablePositionedList` always builds first. The
page turn is then a clamped `jumpTo` / `animateTo` on that position, which
is the same thing `ScrollOffsetController.animateScroll` does inside the
package.

**Tap zones** use a raw `Listener`, not a gesture recognizer, so they never
win the gesture arena against text selection, links or scrolling. Only a
press shorter than 400 ms that moves less than the touch slop counts. A tap
on a link inside an edge zone both follows the link and turns the page.

`test/page_turn_test.dart` covers the key mapping, `PageTurnKeys`, the
volume-key channel, the tap zones and `scrollByPage`, the EPUB reader
wiring, and the results page's **Load more** button.

## High-contrast theme

On 16-grey e-paper the red accent, light-grey fills and half-transparent
text all turn into faint, similar greys. While E-ink mode is on,
`einkTheme()` makes the app pure black on white (light) or white on black
(dark):

| What | Where |
| --- | --- |
| Accents (`secondary`, `tertiary`), text, icons, outlines and dividers use the foreground; every surface and container (`tertiaryContainer`, chips, inputs, cards, dialogs, nav bar) uses the background | `eink_theme.dart` |
| Fills that marked an edge become 1.5 px borders (2.5 px for focus and selection); no shadows, elevation or surface tint | `eink_theme.dart` |
| Headline greys (`#595E60`, `#7F7F7F`) become full-strength; hints are `#333333` (`#CCCCCC` on dark) | `eink_theme.dart`, `EinkColors.muted` |
| `EinkColors` theme extension and the `EinkColorX` colour helpers | `eink_palette.dart` |

`primary` / `onPrimary` become a foreground / background pair too. The
normal light theme has a white `primary` on a white surface, which stock
widgets (Switch, Slider, spinners, dialog TextButtons, RefreshIndicator)
use by default. Screens that paint an app bar with `colorScheme.primary`
as a background expecting white should use `colorScheme.surface` instead
(identical in the normal light theme).

**Using it in widgets.** `EinkColors.of(context)` returns the extension, or
`EinkColors.standard` when E-ink mode is off. The `EinkColorX` helpers on
`Color` hand the colour back unchanged when E-ink mode is off, so the
normal look doesn't move:

```dart
// Half-transparent text or meaningful fill: opaque in E-ink mode.
scheme.tertiary.einkText(context, 170 / 255) // was .withAlpha(170)
// Decorative tint: transparent (or `mono:`) in E-ink mode.
scheme.secondary.einkTint(context, 0.1)
// Status / accent colour: the foreground in E-ink mode.
Colors.green.einkFg(context)
// Decorative fill, or white text on an accent: the background.
Colors.white.einkBg(context)
// Edge that replaces a fill: null / BorderSide.none when off.
BoxDecoration(border: EinkColors.of(context).border)
```

Every status that used colour alone also has an icon or a label: each
download state has its own icon and text, failures and "verification
required" have an icon and the message, the downloaded badge is a check
mark, and the update snackbars carry their message. Applied in the download
panel, snackbars, book cards, book details, settings tiles and the search
fields.

Not converted yet: the other half-transparent colours in `lib/ui` (mostly
secondary text on the home, library and instances screens) and the GNav
bottom bar, which draws white icons on `secondary` (so its active pill is
white on white in dark E-ink mode); `app_navigation_bar.dart` should use
`Colors.white.einkBg(context)` there.

`test/eink_theme_test.dart` checks both monochrome themes, that the normal
themes carry no `EinkColors`, the helpers in both modes, and `MyApp` with
the switch on and off.

## Not covered yet

These come from the e-ink gap analysis and are planned as later steps:

- Tap zones in the PDF reader (pdfrx keeps its own gestures; it has the
  page keys and the top-bar page buttons).
- Volume keys on iOS and desktop (only Android's activity can intercept
  them).
- Dialog fade-ins, and the animated Trending/Categories switch on the home
  screen.
- Greyscale / dithered covers.
- Optional Onyx full-refresh action.
