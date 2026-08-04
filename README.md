# mridul-portfolio

Personal portfolio for Mridul Dhiman — senior Android + Flutter engineer.
Flutter Web, deployed static.

Live at **https://mridul-dhiman.github.io/portfolio/**

The page has one job: make a reader who will spend under 60 seconds on it
believe this person ships mobile apps that hold up at a million users. The
numbers lead, the prose stays flat, and the direction is terminal /
engineer-brutalist — monospace throughout, hard 1px rules, zero border-radius,
near-zero motion.

## Running

```bash
flutter run -d chrome
flutter test                              # 18 tests
flutter build web --release --base-href /portfolio/
```

Pages serves this repo from a subpath, so the build passes `--base-href`;
without it every asset request 404s. `canvasKitBaseUrl` in `web/index.html` is
deliberately relative for the same reason.

## Layout

```
lib/
  main.dart                  PortfolioApp, the sliver tree, anchor jumps
  theme/tokens.dart          every colour, size, space and duration
  theme/app_theme.dart       the Material defaults this direction has to undo
  models/persona.dart        android | flutter
  data/content.dart          all copy
  widgets/responsive.dart    the only MediaQuery read; ContentRail, Rule
  widgets/nav_bar.dart       wordmark, anchors, build-variant toggle
  widgets/accent.dart        accent crossfade, section header, focus ring
  widgets/interactive.dart   hover + focus + activate, shared by everything
  services/open_link.dart    window.open behind a conditional import
  sections/{hero,skills,work,experience,contact}.dart
web/
  index.html                 meta, JSON-LD, hand-written loading state
  resume.html                the same resume as plain semantic HTML
  fonts/                     JetBrains Mono woff2, for the two HTML pages
  og.png                     1200x630 social card
assets/fonts/                JetBrains Mono ttf, for the Flutter app
tool/make_og_image.py        regenerates og.png and the favicons
tool/subset_fonts.sh         regenerates both font subsets
```

No string literals live in widget files — all copy is in `data/content.dart`,
which is what makes the persona swap a data change rather than a layout one.
No colour or size is hardcoded either; everything comes from `theme/tokens.dart`.

## The build-variant toggle

The one memorable element. It is not styled as a UI switch — it is styled as
the build command the reader appears to be running:

```
$ ./gradlew assembleRelease     ← active
  flutter build web
```

Clicking the inactive line moves the `$`, moves the accent from Kotlin purple
to Flutter blue, and rewrites the hero eyebrow, the skills table and the tech
tag on each work row. Same projects, same numbers, same layout: the point is
that one person shipped both, not that there are two different people.

A test asserts the layout does not move when it is used — that is why the two
skills strings are kept to similar lengths.

State for all of it is one `ValueNotifier<Persona>` created in
`_PortfolioAppState` and passed down. One enum does not need Riverpod, Bloc or
Provider; a portfolio that over-engineers its own state management argues
against its author.

## Motion budget

Three animations, total:

1. Hero cursor blink, 530ms.
2. `WorkRow` hover: full inversion, instant, no transition.
3. Accent crossfade on persona switch, 120ms.

`prefers-reduced-motion` kills 1 and 3. Nav anchors `jumpTo` rather than
animating, which is why there is no fourth.

## Colour, and where it departs from the brief

The brief specifies five values and says to *check* contrast rather than
assume it. Checking it moved three numbers. `test/contrast_test.dart` computes
WCAG 2.1 ratios for every token pair on every ground and fails CI below 4.5:1,
so none of this can regress silently.

| token | value | on paper | on ink |
|---|---|---|---|
| ink / paper | `#0A0A0A` / `#FAFAF7` | 18.93 | 18.93 |
| dim | foreground @ 58% | 4.83 | 6.62 |
| accentK (Kotlin purple) | `#7A4CFA` / `#8759FF` | 4.73 | 4.62 |
| accentF (Flutter blue) | `#0778AB` / `#54C5F8` | 4.69 | 10.11 |

Three deviations, all forced by that 4.5:1 floor:

- **`dim` is 58%, not 55%.** At 55% it lands at 4.35:1 — under AA. 58% is the
  smallest step that clears it.
- **Each accent has two values, one per ground, rather than one per theme.**
  A `WorkRow` inverted under hover is a dark surface even while the page is
  light, so the accent is chosen by the surface it is painted on. The
  dark-ground values are the brief's brand colours, near enough.
- **`#54C5F8` is 1.87:1 on paper** — invisible. The light-ground Flutter blue
  is the same hue taken down in lightness until it clears AA.

Dark mode inverts `ink` and `paper` from `prefers-color-scheme`. There is no
manual theme toggle; the build variant is the only toggle on the page.

## Type

JetBrains Mono, weights 400 and 500, subset to latin plus the punctuation the
page actually uses (`→ · —`). Nothing is loaded from Google Fonts.

The subsets ship twice, because the two halves of the site read fonts
differently:

- `assets/fonts/*.ttf` (~19 KB each) is what the Flutter app bundles.
  CanvasKit cannot decode woff2, so this pair has to be TTF.
- `web/fonts/*.woff2` (~9 KB each) is what `index.html` and `resume.html` use
  through `@font-face` — the loading state renders before any Flutter code has
  run, and `resume.html` never runs any.

`tool/subset_fonts.sh` regenerates both formats and carries the unicode range.
Widen the range there before adding copy that needs a glyph outside it.

## SEO, and `resume.html`

Flutter Web paints to a canvas, so search engines and ATS-adjacent scrapers
see nothing. `web/resume.html` is the fix: the full resume as plain semantic
HTML, not rendered by Flutter, no JavaScript, linked from the footer and from
the `<noscript>` block. Each work row on the Flutter page opens its section of
it.

`web/index.html` also carries the full `<meta>` block, `og:*`, `twitter:card`
and a JSON-LD `Person` schema with `worksFor` and `sameAs`.

## Lighthouse

Measured against a local host that gzips, which is what Pages does. Recorded
rather than assumed — a Flutter Web page does not hit 90, and the actual
number is more useful than the assumption:

| | perf | a11y | best practices | SEO |
|---|---|---|---|---|
| `/` desktop | **72** | 100 | 77 | 100 |
| `/` mobile | **37** | 100 | 77 | 100 |
| `/resume.html` mobile | **100** | 100 | 100 | 100 |

2.77 MB over the wire, almost all of it `canvaskit.wasm` and `main.dart.js`.
That is the cost of the renderer, and it is why `resume.html` exists.

Best Practices is capped at 77 by three audits nothing here controls: dart2js
ships no source maps in release, the engine calls the deprecated
`Intl.v8BreakIterator`, and the engine unconditionally fetches its own Roboto
and Noto fallback fonts from `fonts.gstatic.com`. CanvasKit itself is
self-hosted — `canvasKitBaseUrl` points at the copy `flutter build web` writes
into `build/web/canvaskit/`, so the 6.9 MB `canvaskit.wasm` is served from
this origin.

Accessibility reaches 100 only because `index.html` puts the viewport meta
back after boot: the engine replaces it with one carrying `user-scalable=no`,
which fails WCAG 1.4.4. This page is a scrolling document, so pinch-zoom is
the reader's.

## Deploying

`.github/workflows/deploy.yml` analyzes, tests, builds and publishes to GitHub
Pages on every push to `main`. A failing test blocks the deploy. The workflow
drops `canvaskit/skwasm*` from the artifact — `index.html` pins the CanvasKit
renderer, so those files are never requested.

If you change `web/index.html`, note that the generated service worker caches
the old copy aggressively — hard-reload, or test on a different port, or you
will be looking at a stale page.

## Non-goals

No blog, no contact form, no analytics, no "about me" paragraph, no animation
library, no third-party UI package, no manual theme toggle. `flutter_web_plugins`
is the only dependency beyond `flutter` itself, and it ships with the SDK —
it is there for `usePathUrlStrategy()`.
