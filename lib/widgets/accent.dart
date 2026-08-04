import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/persona.dart';
import '../theme/tokens.dart';
import 'responsive.dart';

/// Rebuilds [builder] with the accent for the current persona, crossfading
/// between the two over [Tokens.accentCrossfade].
///
/// This is one of the site's three permitted animations. Under
/// `prefers-reduced-motion` the tween collapses to zero and the colour snaps.
class AccentBuilder extends StatelessWidget {
  const AccentBuilder({
    super.key,
    required this.persona,
    required this.builder,
    this.surface,
  });

  final ValueListenable<Persona> persona;

  /// The brightness of the surface the accent is painted on. Defaults to the
  /// page brightness; pass [Brightness.dark] explicitly for a widget drawn on
  /// inverted (ink) ground while the page is light.
  final Brightness? surface;

  final Widget Function(BuildContext context, Color accent) builder;

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final surface = this.surface ?? layout.brightness;

    return ValueListenableBuilder<Persona>(
      valueListenable: persona,
      builder: (context, value, _) {
        final target = Tokens.accentOn(surface, value);
        return TweenAnimationBuilder<Color?>(
          // Keyed on the surface so a surface flip — a WorkRow inverting under
          // hover — mounts a fresh builder and lands on the new colour with no
          // transition. Only a persona change crossfades; hover stays instant.
          key: ValueKey(surface),
          tween: ColorTween(end: target),
          duration: layout.reduceMotion ? Duration.zero : Tokens.accentCrossfade,
          builder: (context, colour, _) => builder(context, colour ?? target),
        );
      },
    );
  }
}

/// `// section_name` — slashes in accent, label in the foreground colour.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.persona, required this.label});

  final ValueListenable<Persona> persona;
  final String label;

  /// The comment marker every section header opens with.
  static const String marker = '// ';

  @override
  Widget build(BuildContext context) {
    final brightness = Layout.of(context).brightness;
    final style = Tokens.section(brightness);

    return AccentBuilder(
      persona: persona,
      builder: (context, accent) => Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: marker, style: TextStyle(color: accent)),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}

/// A 2px accent outline, offset 2px, drawn only while [focused].
///
/// Applied to every interactive element in the site — the Material default
/// focus highlight is switched off in [AppTheme], so this replaces it rather
/// than removing it.
///
/// Painted outside the child's bounds rather than as padding + border, so it
/// behaves like a CSS `outline`: showing and hiding it never reflows the row
/// it sits in. The nav's pinned extent is computed from line boxes, and a ring
/// that added 8px on focus would make that number wrong.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.focused,
    required this.accent,
    required this.child,
  });

  final bool focused;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: focused ? _RingPainter(accent) : null,
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Stroke centred on the rect, so half the width sits either side of it —
    // inflate by the offset plus half the stroke to land the inner edge of the
    // ring exactly `focusOutlineOffset` away from the child.
    final inset =
        Tokens.focusOutlineOffset + Tokens.focusOutlineWidth / 2;
    canvas.drawRect(
      (Offset.zero & size).inflate(inset),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Tokens.focusOutlineWidth
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.accent != accent;
}
