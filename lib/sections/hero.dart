import 'dart:async';

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models/persona.dart';
import '../theme/tokens.dart';
import '../widgets/accent.dart';
import '../widgets/responsive.dart';

/// Eyebrow, the two numbers, and where the reader is. No "about me" paragraph
/// — it folds into these three lines.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.persona});

  final ValueNotifier<Persona> persona;

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final brightness = layout.brightness;
    final heroStyle = Tokens.hero(brightness, layout.width);
    final last = Content.heroLines.length - 1;

    return Padding(
      padding: layout.contentPadding.copyWith(
        top: layout.sectionPadding,
        bottom: layout.sectionPadding,
      ),
      child: ContentRail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow(persona: persona),
            const SizedBox(height: Tokens.space4),
            for (final (index, line) in Content.heroLines.indexed)
              // The lines wrap rather than being clipped or scaled: at 320px
              // `1,150,000+ downloads` does not fit on one line at 32px, and
              // breaking at the space is better than either alternative. The
              // cursor rides along as a WidgetSpan so it stays glued to the
              // last character wherever the wrap lands.
              Padding(
                // Once they wrap, two adjacent statements at line-height 1.15
                // read as one paragraph. A single 8px step tells them apart
                // without loosening the block at widths where they don't wrap.
                padding: EdgeInsets.only(
                  top: index > 0 && layout.isCompact ? Tokens.space1 : 0,
                ),
                child: Text.rich(
                  TextSpan(
                    text: line,
                    children: [
                      if (index == last)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _HeroCursor(persona: persona),
                        ),
                    ],
                  ),
                  style: heroStyle,
                ),
              ),
            const SizedBox(height: Tokens.space4),
            Text(
              Content.heroMeta,
              style: Tokens.meta(
                brightness,
              ).copyWith(color: Tokens.dimOn(brightness)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.persona});

  final ValueNotifier<Persona> persona;

  @override
  Widget build(BuildContext context) {
    final brightness = Layout.of(context).brightness;

    return AccentBuilder(
      persona: persona,
      builder: (context, accent) => ValueListenableBuilder<Persona>(
        valueListenable: persona,
        builder: (context, value, _) => Text.rich(
          TextSpan(
            style: Tokens.meta(brightness),
            children: [
              TextSpan(
                text: SectionHeader.marker,
                style: TextStyle(color: accent),
              ),
              TextSpan(text: Content.heroEyebrow[value]),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 1ch accent block after the last hero line, blinking at 530ms.
///
/// Motion #1 of 3. Under `prefers-reduced-motion` the timer never starts and
/// the block stays solid.
class _HeroCursor extends StatefulWidget {
  const _HeroCursor({required this.persona});

  final ValueNotifier<Persona> persona;

  /// JetBrains Mono advances 0.6em per character, so 1ch is 0.6 of the size.
  static const double advanceRatio = 0.6;

  @override
  State<_HeroCursor> createState() => _HeroCursorState();
}

class _HeroCursorState extends State<_HeroCursor> {
  Timer? _timer;
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer(Layout.of(context).reduceMotion);
  }

  void _syncTimer(bool reduceMotion) {
    if (reduceMotion) {
      _timer?.cancel();
      _timer = null;
      if (!_visible) setState(() => _visible = true);
      return;
    }
    _timer ??= Timer.periodic(
      Tokens.cursorBlink,
      (_) => setState(() => _visible = !_visible),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final size = Tokens.heroSize(layout.width);

    return AccentBuilder(
      persona: widget.persona,
      builder: (context, accent) => SizedBox(
        width: size * _HeroCursor.advanceRatio,
        height: size,
        child: ColoredBox(color: _visible ? accent : Colors.transparent),
      ),
    );
  }
}
