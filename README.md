<div align="center">

<img src="assets/icons/appIcon.png" width="150">

# OpenlibExtended E-ink

**An open-source client for Anna's Archive and other shadow libraries, built for e-ink readers. <br/> Search, download and read books on Boox, Bigme, PocketBook and other Android e-paper devices.**

> A new project started from [OpenlibExtended](https://github.com/warreth/OpenlibExtended), itself a fork of [openlib](https://github.com/dstark5/Openlib), reworked for e-ink screens.

[![made-with-flutter](https://img.shields.io/badge/Made%20with-Flutter-4361ee.svg?style=for-the-badge)](https://flutter.dev/)
[![AGPLv3 License](https://img.shields.io/badge/License-AGPL%20v3-e63946.svg?style=for-the-badge)](https://opensource.org/licenses/)

**[📖 Frequently Asked Questions (FAQ)](./FAQ.md)**
</div>

## Why an e-ink edition? 📖

E-paper screens take about 0.1–0.7 s to redraw and leave ghost images behind
fast updates. Apps made for phones flicker, smear and drain the battery on
them: page transitions, ripples, spinning loaders, momentum scrolling and
progress counters that tick many times a second all turn into extra screen
refreshes. This edition keeps the screen still, makes everything readable in
black and white, and works with the page-turn buttons e-readers have.

## E-ink features ✨

- **E-ink mode**
  Turns on by itself on Onyx Boox, Bigme, Meebook, Boyue/Likebook, PocketBook,
  Mudita and HyRead devices, and can be switched on or off in
  Settings › Appearance. While it's on:
  - no page transitions, tap ripples or spinning loaders;
  - scrolling stops when your finger lifts: no momentum, bounce or glow;
  - download progress redraws at most every 2 seconds;
  - search results load with a **Load more** button instead of endless scrolling.

- **High-contrast black and white theme**
  Pure black on white (or white on black), with borders instead of grey
  fills and no shadows. Download states, badges and messages use an icon or
  label as well as colour, so they still read on a greyscale screen.

- **Page turning like an e-reader**
  - Tap the left or right edge of an EPUB to turn the page.
  - Page Up/Down, the arrow keys and Space turn pages in the EPUB and PDF
    readers.
  - Optional **Volume keys turn pages** on Android, which also covers the
    page buttons on many Boox cases. It applies only while a book is open.

- **Easy on the battery**
  - Mirror list and update checks run at most once a day, not on every launch.
  - The hidden site-verification browser stops after 40 seconds and checks
    less often in E-ink mode.
  - Book covers are decoded at the size they're shown, not full resolution.
  - Tabs you're not looking at don't animate or redraw.

- **Works with your device's reader**
  Open EPUB and PDF files in the built-in reader or hand them to another app
  such as NeoReader or KOReader, chosen per format.

- **Storage access only when needed**
  Books are saved in the app's own folder, or in Download/ or Documents/,
  without any permission. "All files access" is requested only if you pick
  another shared folder (for example one your e-reader's library scans), and
  only after a short explanation.

## Search and library 🔎

- **Resilient downloads**: automatically balances and fails over between mirrors.
- **Only files you can open, by default**: the File type filter starts on
  **Supported formats** (EPUB, PDF, CBR, CBZ). Pick **All** to see every
  format, or a single format.
- **Filters that work on every source**: language, format, year, type and
  sort are applied by the source when it can, and by the app otherwise. If a
  source can't apply one, the results page says so.
- **Private typing**: nothing is sent while you type; a search runs only when
  you press Search.
- **Clear result cards**: title, author, format, size and year at a glance.
- **Helpful empty and error states**: offline and "source didn't respond"
  messages with Retry, and next steps when nothing matches.
- **Library management**: track your collection and browse trending books
  and genres. Pull down on My Library to sync it with your book folder: books
  whose file was deleted are removed, new EPUB, PDF, CBR and CBZ files are
  added, and other formats you downloaded (MOBI, AZW3…) stay as long as the
  file is there.
- **Respects your text size**: the in-app text size builds on your device's
  font size instead of replacing it.

## Supported file formats 📚

| Format | Opens in | In the library |
|---|---|---|
| EPUB | Built-in reader (tap zones, page keys) or another app you choose | Yes |
| PDF | Built-in reader (page keys) or another app you choose | Yes |
| CBR, CBZ | Another app on the device (e.g. a comic reader) | Yes |
| MOBI, AZW3, FB2, DJVU and others | Another app on the device, if one is installed | Yes, once downloaded |

Choose the reader for EPUB and PDF in Settings › Reader. Native support for
CBR, CBZ and AZW3 is on the roadmap.

## Supported devices 📱

| Device | Status |
|---|---|
| Android e-ink readers and phones: Onyx Boox, Bigme, Meebook, PocketBook (Android models), Hisense, Mudita Kompakt | Supported: install the APK |
| Android phones and tablets | Works, with E-ink mode off |
| Kobo, Kindle, reMarkable, Linux-based PocketBook | Not supported: these devices can't install Android apps |

Most e-ink devices run Android 11–15. The app needs Android 7.0 or later.

## Installation 📦

Install the APK on your device (sideload). Pick the one for your device's
processor:

- `arm64-v8a`: almost every phone and e-reader from the last few years,
  including recent Boox models. Use this one if unsure.
- `armeabi-v7a`: older 32-bit e-readers.
- `universal`: both of the above in one larger file.

Builds are ARM only: there is no x86_64 (emulator) APK.

To build them yourself:

```bash
flutter build apk --split-per-abi --release --target-platform android-arm,android-arm64
```

Release builds need your signing key in `android/key.properties`. Without it
the APK is unsigned and Android won't install it.

**Note:** Publishing this app to the Play Store violates their terms.

## Roadmap 🎯

- [ ] **Enhanced Formats**: Native support for CBR, CBZ, and AZW3.

## Development 🛠️

```bash
git clone <this repository>
flutter pub get
flutter run
```

The e-ink code lives in its own module, [`lib/features/eink/`](lib/features/eink/README.md).
Its README explains what each part does, where the app calls into it, and
the rules for keeping new screens e-ink friendly. See
[CONTRIBUTING.md](CONTRIBUTING.md) for general guidelines.

## Command line (CLI) 🖥️

For scripts and AI agents, `bin/ai_cli.dart` exposes the same Anna's Archive flow as the app:

```bash
dart run bin/ai_cli.dart search "quantum computing" --ext epub --limit 5
dart run bin/ai_cli.dart info <md5|book-url>
dart run bin/ai_cli.dart download <md5|book-url> --output ~/books
dart run bin/ai_cli.dart mirrors
```

Results are one JSON document on stdout; progress is JSON lines on stderr. Exit codes are
`0` ok, `1` usage, `2` challenge-blocked, `3` not found and `4` network. `--base-url` pins one
mirror, `--timeout` changes the per-request timeout and `--quiet` suppresses progress. Mirror
URLs still come only from open-slum.org; the CLI shares the app's parsers through `lib/core/`.

## Credits 🙏

- [openlib](https://github.com/dstark5/Openlib) by dstark5: the original app.
- [OpenlibExtended](https://github.com/warreth/OpenlibExtended) by warreth:
  the fork this project started from, with desktop support, mirror failover
  and many other features.

## Donate 🎁

- [**Donate To Anna’s Archive**](https://annas-archive.org/donate?tier=1) (Support the library itself)
- [**Sponsor warreth on GitHub 💖**](https://github.com/sponsors/warreth) (Support OpenlibExtended, the upstream project)

## License 📜

Licensed under [AGPL v3.0](https://www.gnu.org/licenses/agpl-3.0.html).

## Disclaimer ⚠️

OpenlibExtended E-ink does not own or have any affiliation with the books available through the app. All books are the property of their respective owners and are protected by copyright law. OpenlibExtended E-ink is not responsible for any infringement of copyright or other intellectual property rights that may result from the use of the books available through the app. By using the app, you agree to use the books only for personal, non-commercial purposes and in compliance with all applicable laws and regulations.
