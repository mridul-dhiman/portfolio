import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/data/content.dart';
import 'package:portfolio/main.dart';
import 'package:portfolio/models/persona.dart';
import 'package:portfolio/sections/work.dart';
import 'package:portfolio/services/open_link.dart';
import 'package:portfolio/theme/tokens.dart';
import 'package:portfolio/widgets/accent.dart';
import 'package:portfolio/widgets/nav_bar.dart';
import 'package:portfolio/widgets/responsive.dart';

import 'fonts.dart';

/// The three widths the layout has to hold up at: a real 320px phone, between
/// the 600 and 1024 breakpoints, and a desktop past 1024.
const Size narrow = Size(320, 640);
const Size medium = Size(760, 900);
const Size wide = Size(1440, 1000);

/// Wide, and tall enough that every sliver is built and laid out — the page is
/// lazy, so anything below the fold does not exist to `find` otherwise.
const Size whole = Size(1440, 3000);

void main() {
  late List<String> opened;

  setUpAll(loadTestFonts);

  setUp(() {
    opened = [];
    openLink = opened.add;
  });

  tearDown(resetLinkOpener);

  group('page', () {
    testWidgets('renders the hero numbers and every section', (tester) async {
      await _pumpPage(tester, whole);

      for (final line in Content.heroLines) {
        // `findRichText` because the last line carries the cursor as a
        // WidgetSpan, so it is a RichText rather than a plain Text.
        expect(find.textContaining(line, findRichText: true), findsOneWidget);
      }
      expect(find.text(Content.heroMeta), findsOneWidget);
      expect(find.text(Content.wordmark), findsOneWidget);
      // The eyebrow and the section headers are `// `-prefixed rich text.
      expect(
        find.textContaining(
          Content.heroEyebrow[Persona.android]!,
          findRichText: true,
        ),
        findsOneWidget,
      );
      for (final label in Content.sectionLabel.values) {
        expect(
          find.textContaining(
            '${SectionHeader.marker}$label',
            findRichText: true,
          ),
          findsOneWidget,
          reason: label,
        );
      }

      for (final item in Content.work) {
        expect(find.text(item.title), findsOneWidget);
        expect(find.text(item.line), findsOneWidget);
      }
      for (final (date, role) in Content.experience) {
        expect(find.text(date), findsOneWidget);
        expect(find.text(role), findsOneWidget);
      }
      expect(find.text(Content.email), findsOneWidget);
    });

    testWidgets('lays out without overflow at 320, 760 and 1440', (
      tester,
    ) async {
      for (final size in [narrow, medium, wide]) {
        await _pumpPage(tester, size);
        // Scroll the whole page so every sliver is laid out at this width.
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'at ${size.width}px');
      }
    });

    testWidgets('anchors jump to their section', (tester) async {
      await _pumpPage(tester, wide);
      final scrollable = find.byType(Scrollable).first;
      expect(tester.widget<Scrollable>(scrollable).controller!.offset, 0);

      await tester.tap(find.text('contact'));
      await tester.pump();

      expect(
        tester.widget<Scrollable>(scrollable).controller!.offset,
        greaterThan(0),
      );
    });
  });

  group('build-variant toggle', () {
    testWidgets('starts on android with the gradle command prompted', (
      tester,
    ) async {
      await _pumpPage(tester, wide);

      expect(
        _promptedCommand(tester),
        '\$ ${Content.buildCommand[Persona.android]}',
      );
      expect(_eyebrow(tester), Content.heroEyebrow[Persona.android]);
    });

    testWidgets('swapping rewrites eyebrow, skills and every work tag', (
      tester,
    ) async {
      await _pumpPage(tester, whole);

      final (androidLanguages, _) = Content.skills[Persona.android]!;
      expect(find.text(androidLanguages), findsOneWidget);
      for (final item in Content.work) {
        expect(find.text(item.tags[Persona.android]!), findsOneWidget);
      }

      await _swapPersona(tester, Persona.flutter);

      expect(
        _promptedCommand(tester),
        '\$ ${Content.buildCommand[Persona.flutter]}',
      );
      expect(_eyebrow(tester), Content.heroEyebrow[Persona.flutter]);

      final (flutterLanguages, _) = Content.skills[Persona.flutter]!;
      expect(find.text(flutterLanguages), findsOneWidget);
      expect(find.text(androidLanguages), findsNothing);

      for (final item in Content.work) {
        expect(find.text(item.tags[Persona.flutter]!), findsOneWidget);
        expect(find.text(item.tags[Persona.android]!), findsNothing);
      }
    });

    testWidgets('leaves the projects, the numbers and the layout alone', (
      tester,
    ) async {
      await _pumpPage(tester, whole);
      final before = tester.getRect(find.text(Content.work.first.title));

      await _swapPersona(tester, Persona.flutter);

      for (final line in Content.heroLines) {
        expect(find.textContaining(line, findRichText: true), findsOneWidget);
      }
      for (final item in Content.work) {
        expect(find.text(item.title), findsOneWidget);
      }
      expect(tester.getRect(find.text(Content.work.first.title)), before);
    });

    testWidgets('offers the inactive build at full contrast, unhovered', (
      tester,
    ) async {
      await _pumpPage(tester, narrow);

      // The whole affordance used to be hover: the inactive line sat at `dim`
      // and only rose to full contrast under the pointer. Touch has no pointer,
      // so on a phone the second build read as inert grey text. Assert the two
      // things that replaced it, with nothing hovered and at the narrowest
      // width — the case that was broken.
      final line = _inactiveLine(tester);
      expect(
        line.toPlainText(),
        '${BuildVariantToggle.inactivePrompt}'
        '${Content.buildCommand[Persona.flutter]}'
        '${BuildVariantToggle.inactiveSuffix}',
      );

      final command = _spans(line).firstWhere(
        (span) => span.text == Content.buildCommand[Persona.flutter],
      );
      expect(command.style!.color, Tokens.foregroundOn(Brightness.light));
      expect(command.style!.color, isNot(Tokens.dimOn(Brightness.light)));
    });

    testWidgets('inverts the bracketed line on hover, instantly', (
      tester,
    ) async {
      await _pumpPage(tester, wide);
      final chip = find.byType(BuildVariantToggle);

      expect(_chipBackground(tester), Tokens.paper);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await tester.pump();
      await mouse.moveTo(
        tester.getCenter(
          find.descendant(of: chip, matching: find.byType(ColoredBox)),
        ),
      );
      // One frame, no settle: the inversion has no transition. The accent
      // crossfade is keyed on the surface, so a flip skips it too.
      await tester.pump();

      expect(_chipBackground(tester), Tokens.ink);
    });
  });

  group('work rows', () {
    testWidgets('invert on hover, instantly', (tester) async {
      await _pumpPage(tester, wide);
      final row = find.byType(WorkRow).first;

      expect(_rowBackground(tester, row), Tokens.paper);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(row));
      // One frame, no settle: the inversion has no transition.
      await tester.pump();

      expect(_rowBackground(tester, row), Tokens.ink);
    });

    testWidgets('open their section of the static resume', (tester) async {
      await _pumpPage(tester, wide);

      await tester.tap(find.text(Content.work.first.title));
      await tester.pump();

      expect(opened, ['resume.html#e-learning-platform']);
    });
  });

  group('accessibility', () {
    testWidgets('every interactive element is reachable by Tab', (
      tester,
    ) async {
      await _pumpPage(tester, whole);

      // 3 anchors, the inactive build command, 3 work rows, the email and 3
      // contact links: 11 stops, and Tab has to reach all of them.
      const expected = 11;
      final reached = <Rect>{};
      for (var i = 0; i < expected * 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final node = FocusManager.instance.primaryFocus;
        if (node != null && node.rect != Rect.zero) reached.add(node.rect);
      }
      expect(reached, hasLength(expected));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion stops the cursor blinking', (tester) async {
      await _pumpPage(tester, wide, reduceMotion: true);

      // With the blink timer never started there is no pending periodic timer,
      // so the tree can settle. Without the guard this call times out.
      await tester.pumpAndSettle();
    });

    testWidgets('semantics label the toggle and the links', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPage(tester, whole);

      expect(
        find.bySemanticsLabel(Content.buildCommandSemantics[Persona.flutter]!),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(Content.email), findsOneWidget);
      handle.dispose();
    });
  });

  group('nav bar', () {
    testWidgets('drops the anchors below 600 but keeps the toggle', (
      tester,
    ) async {
      await _pumpPage(tester, narrow);

      for (final (label, _) in Content.navLinks) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.byType(BuildVariantToggle), findsOneWidget);
    });

    testWidgets('pinned extent matches what the layout actually needs', (
      tester,
    ) async {
      for (final size in [narrow, medium, wide]) {
        await _pumpPage(tester, size);
        final layout = Layout.of(tester.element(find.byType(NavBar)));
        expect(
          tester.getSize(find.byType(NavBar)).height,
          NavBar.heightFor(layout),
          reason: 'at ${size.width}px',
        );
      }
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  Size size, {
  bool reduceMotion = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: reduceMotion),
      child: const PortfolioApp(),
    ),
  );
  await tester.pump();
}

/// The build command currently carrying the `$` prompt.
/// The hero eyebrow, without its `// ` marker.
String _eyebrow(WidgetTester tester) {
  final text = tester
      .widgetList<RichText>(find.byType(RichText))
      .map((widget) => widget.text.toPlainText())
      .firstWhere((text) => text.startsWith(SectionHeader.marker));
  return text.substring(SectionHeader.marker.length);
}

/// Every [TextSpan] in [span], depth-first. `Text.rich` nests the span it is
/// handed inside a root carrying the resolved style, so the spans a widget
/// declares do not sit at a fixed depth.
Iterable<TextSpan> _spans(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _spans(child);
  }
}

/// The build command that is *not* prompted — the bracketed, tappable one.
InlineSpan _inactiveLine(WidgetTester tester) => tester
    .widgetList<RichText>(
      find.descendant(
        of: find.byType(BuildVariantToggle),
        matching: find.byType(RichText),
      ),
    )
    .map((widget) => widget.text)
    .firstWhere(
      (text) => !text.toPlainText().startsWith(BuildVariantToggle.prompt),
    );

String _promptedCommand(WidgetTester tester) {
  final lines = tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byType(BuildVariantToggle),
          matching: find.byType(RichText),
        ),
      )
      .map((widget) => widget.text.toPlainText())
      .where((text) => text.startsWith(BuildVariantToggle.prompt));
  return lines.single;
}

Future<void> _swapPersona(WidgetTester tester, Persona target) async {
  await tester.tap(
    find.descendant(
      of: find.byType(BuildVariantToggle),
      matching: find.text(
        '${BuildVariantToggle.inactivePrompt}'
        '${Content.buildCommand[target]}'
        '${BuildVariantToggle.inactiveSuffix}',
        findRichText: true,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The ground the bracketed (inactive) build line paints for itself. Only that
/// line has a [ColoredBox]; the prompted one is a bare span.
Color _chipBackground(WidgetTester tester) {
  final box = tester.widget<ColoredBox>(
    find
        .descendant(
          of: find.byType(BuildVariantToggle),
          matching: find.byType(ColoredBox),
        )
        .first,
  );
  return box.color;
}

Color _rowBackground(WidgetTester tester, Finder row) {
  final container = tester.widget<Container>(
    find.descendant(of: row, matching: find.byType(Container)).first,
  );
  return container.color!;
}
