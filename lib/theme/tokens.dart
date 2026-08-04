import 'package:flutter/widgets.dart';

import '../models/persona.dart';

/// Every colour, size and spacing value in the site. Nothing in the widget
/// tree hardcodes one — if a widget needs a number it comes from here.
class Tokens {
  const Tokens._();

  // -------------------------------------------------------------------
  // Palette
  // -------------------------------------------------------------------

  /// Text, borders and inverted-state backgrounds in light mode.
  static const Color ink = Color(0xFF0A0A0A);

  /// Page background in light mode.
  static const Color paper = Color(0xFFFAFAF7);

  /// Opacity of [dimOn] — the only opacity in the system.
  ///
  /// The brief specifies 55%, but it also requires `dim` on `paper` to clear
  /// WCAG AA 4.5:1, and 55% lands at 4.35:1. 58% is the smallest step that
  /// clears with margin (4.82:1). `test/contrast_test.dart` enforces it, so
  /// this number can't silently regress.
  static const double dimOpacity = 0.58;

  /// Secondary text only. Never a border, never a background.
  static Color dimOn(Brightness surface) =>
      foregroundOn(surface).withValues(alpha: dimOpacity);

  /// Kotlin purple — the accent when the persona is [Persona.android].
  ///
  /// Two values, not one. The brief's `#7F52FF` reads correctly on a dark
  /// surface but only reaches 4.41:1 on `paper`, so the accent is defined per
  /// surface rather than per theme: a [WorkRow] inverted under hover is a dark
  /// surface even in light mode, and gets the dark-surface value.
  static const Color _accentKOnPaper = Color(0xFF7A4CFA); // 4.74:1 on paper
  static const Color _accentKOnInk = Color(0xFF8759FF); //   4.62:1 on ink

  /// Flutter blue — the accent when the persona is [Persona.flutter].
  ///
  /// `#54C5F8` is 10.1:1 on ink and 1.87:1 on paper, i.e. unreadable in light
  /// mode. The paper value is the same hue taken down in lightness until it
  /// clears AA.
  static const Color _accentFOnPaper = Color(0xFF0778AB); // 4.69:1 on paper
  static const Color _accentFOnInk = Color(0xFF54C5F8); //  10.13:1 on ink

  /// Page background for [surface].
  static Color backgroundOn(Brightness surface) =>
      surface == Brightness.light ? paper : ink;

  /// Text and rule colour for [surface].
  static Color foregroundOn(Brightness surface) =>
      surface == Brightness.light ? ink : paper;

  /// The accent for [persona], picked for the surface it is painted on rather
  /// than for the page theme. Pass the brightness of the *surface behind the
  /// glyph*: [Brightness.light] for paper, [Brightness.dark] for ink.
  static Color accentOn(Brightness surface, Persona persona) {
    return switch ((surface, persona)) {
      (Brightness.light, Persona.android) => _accentKOnPaper,
      (Brightness.dark, Persona.android) => _accentKOnInk,
      (Brightness.light, Persona.flutter) => _accentFOnPaper,
      (Brightness.dark, Persona.flutter) => _accentFOnInk,
    };
  }

  /// Every accent value, for the contrast test to walk.
  static const List<(Brightness, Color)> accents = [
    (Brightness.light, _accentKOnPaper),
    (Brightness.light, _accentFOnPaper),
    (Brightness.dark, _accentKOnInk),
    (Brightness.dark, _accentFOnInk),
  ];

  // -------------------------------------------------------------------
  // Type
  // -------------------------------------------------------------------

  static const String fontFamily = 'JetBrainsMono';
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;

  /// `clamp(32px, 6vw, 56px)` — Flutter has no `clamp()`, so the viewport
  /// term is resolved at build time from the width [ResponsiveLayout] hands
  /// down.
  static double heroSize(double viewportWidth) =>
      (viewportWidth * 0.06).clamp(32, 56);

  static TextStyle hero(Brightness surface, double viewportWidth) => TextStyle(
    fontSize: heroSize(viewportWidth),
    fontWeight: medium,
    height: 1.15,
    letterSpacing: -0.02 * heroSize(viewportWidth),
    color: foregroundOn(surface),
  );

  static TextStyle section(Brightness surface) => TextStyle(
    fontSize: 20,
    fontWeight: medium,
    letterSpacing: 0.04 * 20,
    color: foregroundOn(surface),
  );

  static TextStyle body(Brightness surface) => TextStyle(
    fontSize: 15,
    fontWeight: regular,
    height: 1.7,
    color: foregroundOn(surface),
  );

  /// The explicit `height` is load-bearing: the pinned nav's extent is
  /// computed from the meta line box, so it has to be a known number rather
  /// than whatever the font's own metrics produce.
  static const double metaLineHeight = 18;

  static TextStyle meta(Brightness surface) => TextStyle(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.06 * 12,
    height: metaLineHeight / 12,
    color: foregroundOn(surface),
  );

  // -------------------------------------------------------------------
  // Space — 8px grid, hard. Every gap in the site is one of these.
  // -------------------------------------------------------------------

  static const double space1 = 8;
  static const double space2 = 16;
  static const double space3 = 24;
  static const double space4 = 32;
  static const double space6 = 48;
  static const double space8 = 64;

  /// Section padding: 64px desktop, 32px mobile.
  static double sectionPadding(bool isCompact) => isCompact ? space4 : space8;

  /// Left-aligned rail, not a centred column.
  static const double maxContentWidth = 880;

  static const double ruleWidth = 1;

  /// 2px accent outline, offset 2px, on every focusable element.
  static const double focusOutlineWidth = 2;
  static const double focusOutlineOffset = 2;

  // -------------------------------------------------------------------
  // Motion — the entire budget for the site is these two durations.
  // -------------------------------------------------------------------

  /// Accent crossfade on persona switch.
  static const Duration accentCrossfade = Duration(milliseconds: 120);

  /// Hero cursor blink half-period.
  static const Duration cursorBlink = Duration(milliseconds: 530);
}
