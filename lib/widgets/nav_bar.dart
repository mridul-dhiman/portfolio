import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models/persona.dart';
import '../theme/tokens.dart';
import 'accent.dart';
import 'interactive.dart';
import 'responsive.dart';

/// The pinned bar: wordmark, section anchors, and the build-variant toggle.
class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.persona,
    required this.onNavigate,
  });

  final ValueNotifier<Persona> persona;

  /// Jumps the page to a section. Instant, not animated — a smooth scroll
  /// would be a fourth animation, and the motion budget is three.
  final void Function(SectionKey section) onNavigate;

  /// Height of the bar for the given layout, so the pinned header delegate and
  /// the anchor-jump offset agree on one number.
  ///
  /// The line box is measured rather than assumed, because the reader's text
  /// scale factor is theirs to set. Every line in the bar is `maxLines: 1`, so
  /// the count is fixed and only the box height varies.
  static double heightFor(Layout layout) {
    final line = _lineHeight(layout);
    final toggleBlock = line * Persona.values.length;

    if (layout.isWide) {
      // One row; the two-line toggle sets the height.
      return Tokens.space2 * 2 + toggleBlock + Tokens.ruleWidth;
    }
    final verticalPadding = layout.isCompact ? Tokens.space1 : Tokens.space2;
    return verticalPadding * 2 +
        line +
        Tokens.space1 +
        toggleBlock +
        Tokens.ruleWidth;
  }

  static double _lineHeight(Layout layout) {
    final painter = TextPainter(
      text: TextSpan(
        text: Content.wordmark,
        style: Tokens.meta(layout.brightness),
      ),
      textDirection: TextDirection.ltr,
      textScaler: layout.textScaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final brightness = layout.brightness;
    final verticalPadding = layout.isCompact ? Tokens.space1 : Tokens.space2;

    // Every line in the bar is single-line: the extent is computed from a
    // fixed line count, so a wrap here would silently overflow the header.
    final wordmark = Text(
      Content.wordmark,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      style: Tokens.meta(brightness).copyWith(fontWeight: Tokens.medium),
    );
    final links = _NavLinks(persona: persona, onNavigate: onNavigate);
    final toggle = BuildVariantToggle(persona: persona);

    // Below 600 the wordmark, the anchors and the 27-character build command
    // cannot share a row at 320px, so the anchors drop: the page is five
    // sections long and scrolling is the natural gesture there anyway.
    final Widget content = layout.isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              wordmark,
              const Spacer(),
              links,
              const SizedBox(width: Tokens.space6),
              toggle,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  wordmark,
                  if (!layout.isCompact) ...[const Spacer(), links],
                ],
              ),
              const SizedBox(height: Tokens.space1),
              toggle,
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.backgroundOn(brightness),
        border: Border(
          bottom: BorderSide(
            width: Tokens.ruleWidth,
            color: Tokens.foregroundOn(brightness),
          ),
        ),
      ),
      child: Padding(
        padding: layout.contentPadding.copyWith(
          top: verticalPadding,
          bottom: verticalPadding,
        ),
        child: ContentRail(child: content),
      ),
    );
  }
}

class _NavLinks extends StatelessWidget {
  const _NavLinks({required this.persona, required this.onNavigate});

  final ValueNotifier<Persona> persona;
  final void Function(SectionKey section) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, section) in Content.navLinks)
          Padding(
            padding: const EdgeInsets.only(left: Tokens.space2),
            child: _NavLink(
              persona: persona,
              label: label,
              onPressed: () => onNavigate(section),
            ),
          ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.persona,
    required this.label,
    required this.onPressed,
  });

  final ValueNotifier<Persona> persona;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Layout.of(context).brightness;

    return AccentBuilder(
      persona: persona,
      builder: (context, accent) => Interactive(
        onActivate: onPressed,
        builder: (context, hovered, focused) => FocusRing(
          focused: focused,
          accent: accent,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: Tokens.meta(brightness).copyWith(
              color: hovered ? accent : Tokens.foregroundOn(brightness),
            ),
          ),
        ),
      ),
    );
  }
}

/// The signature element. Not styled as a switch — styled as the build command
/// the reader appears to be running. The active persona's command carries the
/// `$` prompt; clicking the other line runs that build instead.
class BuildVariantToggle extends StatelessWidget {
  const BuildVariantToggle({super.key, required this.persona});

  /// Prefix on the active line. The inactive line is indented to match so the
  /// two commands stay column-aligned.
  static const String prompt = r'$ ';
  static const String inactivePrompt = '  ';

  final ValueNotifier<Persona> persona;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Persona>(
      valueListenable: persona,
      builder: (context, active, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in Persona.values)
            _BuildCommandLine(
              persona: persona,
              value: value,
              active: value == active,
            ),
        ],
      ),
    );
  }
}

class _BuildCommandLine extends StatelessWidget {
  const _BuildCommandLine({
    required this.persona,
    required this.value,
    required this.active,
  });

  final ValueNotifier<Persona> persona;
  final Persona value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final brightness = Layout.of(context).brightness;
    final style = Tokens.meta(brightness);

    return AccentBuilder(
      persona: persona,
      builder: (context, accent) {
        // `armed` is the inactive line under the pointer: it comes up out of
        // `dim` to full contrast, the way a shell command does when it is the
        // one about to run. Instant, no transition.
        Widget lineFor({required bool armed}) => Text.rich(
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          TextSpan(
            style: style,
            children: [
              TextSpan(
                text: active
                    ? BuildVariantToggle.prompt
                    : BuildVariantToggle.inactivePrompt,
                style: TextStyle(color: accent),
              ),
              TextSpan(
                text: Content.buildCommand[value],
                style: TextStyle(
                  color: active || armed
                      ? Tokens.foregroundOn(brightness)
                      : Tokens.dimOn(brightness),
                ),
              ),
            ],
          ),
        );

        // The active line is a statement of current state, not a control:
        // only the line that would change something is focusable or clickable.
        if (active) return lineFor(armed: false);

        return Interactive(
          onActivate: () => persona.value = value,
          semanticLabel: Content.buildCommandSemantics[value],
          builder: (context, hovered, focused) => FocusRing(
            focused: focused,
            accent: accent,
            child: lineFor(armed: hovered),
          ),
        );
      },
    );
  }
}
