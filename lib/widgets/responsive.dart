import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The one place in the app that touches [MediaQuery].
///
/// Leaf widgets read [Layout.of] instead, so a breakpoint change is a single
/// edit here rather than a hunt through the tree for scattered width checks.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.child});

  /// Below this the page is a single column at mobile padding.
  static const double compactBreakpoint = 600;

  /// At or above this the page gets its full 880px rail.
  static const double wideBreakpoint = 1024;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Layout(
      width: media.size.width,
      brightness: media.platformBrightness,
      reduceMotion: media.disableAnimations,
      textScaler: media.textScaler,
      child: child,
    );
  }
}

/// Resolved layout facts, handed down once from [ResponsiveLayout].
class Layout extends InheritedWidget {
  const Layout({
    super.key,
    required this.width,
    required this.brightness,
    required this.reduceMotion,
    required this.textScaler,
    required super.child,
  });

  /// Viewport width in logical pixels. Feeds the hero's `6vw` term.
  final double width;

  /// Page brightness, from `prefers-color-scheme`. There is no manual toggle.
  final Brightness brightness;

  /// `prefers-reduced-motion: reduce`. Kills the cursor blink and the accent
  /// crossfade — the site's only two animations.
  final bool reduceMotion;

  /// The reader's text-size preference. The pinned nav measures its own extent
  /// with this rather than assuming 1.0, so scaled-up text does not get
  /// clipped vertically.
  final TextScaler textScaler;

  bool get isCompact => width < ResponsiveLayout.compactBreakpoint;

  bool get isWide => width >= ResponsiveLayout.wideBreakpoint;

  /// 32px on mobile, 64px from 600px up.
  double get sectionPadding => Tokens.sectionPadding(isCompact);

  /// Horizontal insets for a section's content: the rail is left-aligned and
  /// capped, so the surplus goes to the right margin rather than being split.
  EdgeInsets get contentPadding =>
      EdgeInsets.symmetric(horizontal: sectionPadding);

  static Layout of(BuildContext context) {
    final layout = context.dependOnInheritedWidgetOfExactType<Layout>();
    assert(layout != null, 'No ResponsiveLayout above this widget');
    return layout!;
  }

  @override
  bool updateShouldNotify(Layout oldWidget) =>
      width != oldWidget.width ||
      brightness != oldWidget.brightness ||
      reduceMotion != oldWidget.reduceMotion ||
      textScaler != oldWidget.textScaler;
}

/// The 880px left rail every section's content sits in.
class ContentRail extends StatelessWidget {
  const ContentRail({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Tokens.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// A full-bleed 1px rule in the foreground colour.
class Rule extends StatelessWidget {
  const Rule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Tokens.ruleWidth,
      color: Tokens.foregroundOn(Layout.of(context).brightness),
    );
  }
}
