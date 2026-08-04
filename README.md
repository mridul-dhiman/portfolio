# mridul-portfolio

An interactive, CLI-style personal portfolio built with Flutter. The whole page
behaves like a terminal window: type a command, get output, scroll back through
history.

## Running

```bash
flutter run -d chrome      # web
flutter run -d macos       # desktop
flutter test               # 18 tests
```

## Layout

```
lib/
  main.dart                       PortfolioApp, TerminalScreen, entry + input widgets
  models/terminal_item.dart       TerminalItem(command, output)
  services/command_processor.dart command -> output, and the prompt string
assets/fonts/                     Roboto Mono (Regular + Bold), Apache 2.0
web/index.html                    custom Flutter bootstrap (see below)
test/widget_test.dart
```

To change the portfolio content, edit `lib/services/command_processor.dart` —
all the copy lives there, none of it is in the UI code.

## Commands

`help`, `about`, `focus`, `education`, `experience`, `projects`, `skills`,
`contact`, `clear`. Anything else prints a "command not found" hint.

### Focus modes

Mridul maintains two role-targeted resumes — Flutter/cross-platform and native
Android. `focus <flutter|android>` is the terminal equivalent of choosing which
one to send: it retargets `about`, `skills`, `experience` and `projects`.
`education` and `contact` are the same in both. Flutter is the default, and
each `about` points the visitor at the other framing.

Content for both lives in `_flutterContent` and `_androidContent` in
`lib/services/command_processor.dart`, as two `_FocusContent` records — add a
third framing by adding an enum value and one more record.

The `contact` command deliberately omits the phone number that appears on both
resumes — a public page is a much wider audience than a resume sent
selectively.

Up/down arrows walk the command history, shell-style. A half-typed line is
preserved: arrow up to browse, arrow back down and your draft returns. Blank
input and immediate duplicates aren't recorded. `clear` wipes the screen but
keeps the recall buffer, matching a real terminal.

## Self-hosted assets

The app avoids third-party CDNs at runtime:

- **Roboto Mono** is bundled in `assets/fonts/` and declared in `pubspec.yaml`,
  rather than fetched at runtime via the `google_fonts` package. No
  fallback-font flash on first paint.
- **CanvasKit** is loaded from the copy `flutter build web` already writes to
  `build/web/canvaskit/`, via the `canvasKitBaseUrl` config in the custom
  bootstrap script in `web/index.html`. Without that config the Flutter loader
  pulls a ~1.5 MB `canvaskit.wasm` from `gstatic.com` on every cold load.

One external request remains that the app cannot control: the Flutter web
engine unconditionally fetches its own default Roboto fallback (~11 KB) from
`fonts.gstatic.com` at startup. It does not affect rendering here, since every
string in the UI is styled with the bundled Roboto Mono.

If you change `web/index.html`, note that the generated service worker caches
the old copy aggressively — hard-reload, or test on a different port, or you
will be looking at a stale page.
