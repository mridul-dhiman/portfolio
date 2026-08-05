import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models/persona.dart';
import '../theme/tokens.dart';
import 'accent.dart';
import 'interactive.dart';
import 'responsive.dart';

/// The pinned bar: wordmark, section anchors, and the build-variant toggle.
class NavBar extends StatelessWidget {
  const NavBar({super.key, required this.persona, required this.onNavigate});

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

    // Below 600 the wordmark, the anchors and the build command cannot share a
    // row at 320px, so the anchors drop: the page is five sections long and
    // scrolling is the natural gesture there anyway. The widest the toggle gets
    // is the bracketed gradle line at 29 characters, which still fits 320.
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

  /// Prompt on the active line: the build currently rendered.
  static const String prompt = r'$ ';

  /// The inactive line is drawn as a bracketed action — the TUI convention for
  /// the thing you can run — rather than as a dimmer copy of the active line.
  ///
  /// It used to be `dim` plus a two-space indent, lifting to full contrast only
  /// under the pointer. That put the entire affordance in hover, which does not
  /// exist on touch: on a phone the second build was inert grey text and the
  /// toggle was undiscoverable. The brackets carry it on every input instead.
  ///
  /// Both openers are two columns wide, so the commands stay aligned.
  static const String inactivePrompt = '[ ';
  static const String inactiveSuffix = ' ]';

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
    final page = Layout.of(context).brightness;

    // The active line is a statement of current state, not a control: only the
    // line that would change something is focusable or clickable.
    if (active) {
      return AccentBuilder(
        persona: persona,
        builder: (context, accent) => _line(surface: page, accent: accent),
      );
    }

    return Interactive(
      onActivate: () => persona.value = value,
      semanticLabel: Content.buildCommandSemantics[value],
      builder: (context, hovered, focused) {
        // `armed` is the bracketed line under the pointer or under focus. It
        // inverts the way a WorkRow does — the chip takes the opposite ground
        // and every glyph follows it — which keeps the pairing inside the
        // token set the contrast test already walks. Instant, no transition.
        final armed = hovered || focused;
        final surface = armed ? _flip(page) : page;

        // Two accents, because there are two grounds. The ring is painted
        // outside the chip, on the page, so it takes the page's accent; the
        // glyphs inside the chip take the inverted one. One builder for both
        // would put one of them on the wrong ground.
        return AccentBuilder(
          persona: persona,
          builder: (context, pageAccent) => FocusRing(
            focused: focused,
            accent: pageAccent,
            child: AccentBuilder(
              persona: persona,
              surface: surface,
              builder: (context, accent) => ColoredBox(
                // Unconditional: unarmed this repaints the ground already
                // there, so the only thing `armed` changes is which ground.
                color: Tokens.backgroundOn(surface),
                child: _line(surface: surface, accent: accent),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The command, at full contrast on whichever ground it is sitting on. Never
  /// `dim` — see [BuildVariantToggle.inactivePrompt] for why that mattered.
  Widget _line({required Brightness surface, required Color accent}) {
    return Text.rich(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      TextSpan(
        style: Tokens.meta(surface),
        children: [
          TextSpan(
            text: active
                ? BuildVariantToggle.prompt
                : BuildVariantToggle.inactivePrompt,
            style: TextStyle(color: accent),
          ),
          TextSpan(
            text: Content.buildCommand[value],
            style: TextStyle(color: Tokens.foregroundOn(surface)),
          ),
          if (!active)
            TextSpan(
              text: BuildVariantToggle.inactiveSuffix,
              style: TextStyle(color: accent),
            ),
        ],
      ),
    );
  }

  static Brightness _flip(Brightness brightness) =>
      brightness == Brightness.light ? Brightness.dark : Brightness.light;
}
