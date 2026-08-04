import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/models/persona.dart';
import 'package:portfolio/theme/tokens.dart';

/// The brief says to check contrast rather than assume it. This is that check,
/// wired into CI so it cannot silently regress when a token moves.
///
/// WCAG 2.1 relative luminance and contrast ratio, per
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance.
void main() {
  group('WCAG AA', () {
    test('dim clears 4.5:1 on both grounds', () {
      for (final surface in Brightness.values) {
        final ratio = _contrast(
          _flatten(Tokens.dimOn(surface), Tokens.backgroundOn(surface)),
          Tokens.backgroundOn(surface),
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'dim on ${surface.name} ground is ${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('foreground clears 4.5:1 on both grounds', () {
      for (final surface in Brightness.values) {
        expect(
          _contrast(
            Tokens.foregroundOn(surface),
            Tokens.backgroundOn(surface),
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('every accent clears 4.5:1 on the ground it is painted on', () {
      for (final surface in Brightness.values) {
        for (final persona in Persona.values) {
          final ratio = _contrast(
            Tokens.accentOn(surface, persona),
            Tokens.backgroundOn(surface),
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '${persona.name} accent on ${surface.name} ground is '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });

    test('the accents are declared for both grounds', () {
      expect(Tokens.accents, hasLength(Brightness.values.length * 2));
    });
  });

  test('dim is the only opacity in the system', () {
    final opaque = [
      Tokens.ink,
      Tokens.paper,
      for (final (_, accent) in Tokens.accents) accent,
    ];
    for (final colour in opaque) {
      expect(colour.a, 1.0, reason: '$colour carries an alpha value');
    }
  });
}

/// Composites a translucent [foreground] over an opaque [background].
Color _flatten(Color foreground, Color background) {
  double mix(double f, double b) => foreground.a * f + (1 - foreground.a) * b;
  return Color.from(
    alpha: 1,
    red: mix(foreground.r, background.r),
    green: mix(foreground.g, background.g),
    blue: mix(foreground.b, background.b),
  );
}

double _contrast(Color a, Color b) {
  final (lighter, darker) = (_luminance(a), _luminance(b));
  final hi = math.max(lighter, darker);
  final lo = math.min(lighter, darker);
  return (hi + 0.05) / (lo + 0.05);
}

double _luminance(Color colour) =>
    0.2126 * _linear(colour.r) +
    0.7152 * _linear(colour.g) +
    0.0722 * _linear(colour.b);

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
