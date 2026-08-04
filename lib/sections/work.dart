import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models/persona.dart';
import '../services/open_link.dart';
import '../theme/tokens.dart';
import '../widgets/accent.dart';
import '../widgets/interactive.dart';
import '../widgets/responsive.dart';

/// One full-bleed project row.
///
/// Hover (or keyboard focus) inverts the whole row: background becomes the
/// foreground colour, text becomes the background colour, and the trailing
/// arrow takes the accent for a dark surface. Instant — motion #2 of 3 is the
/// inversion itself, and it has no transition.
class WorkRow extends StatelessWidget {
  const WorkRow({super.key, required this.persona, required this.item});

  final ValueNotifier<Persona> persona;
  final WorkItem item;

  /// The trailing glyph. Each row opens the matching section of the static
  /// resume, which is where the detail lives.
  static const String arrow = '→';

  /// `e-learning platform` → `resume.html#e-learning-platform`.
  static String hrefFor(WorkItem item) =>
      'resume.html#${item.title.replaceAll(' ', '-')}';

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final page = layout.brightness;

    return Interactive(
      isLink: true,
      semanticLabel: '${item.title}. ${item.line}',
      onActivate: () => openLink(hrefFor(item)),
      builder: (context, hovered, focused) {
        // Inverting the row flips which surface the text — and the accent —
        // is painted on, in both themes.
        final surface = hovered || focused ? _flip(page) : page;

        return AccentBuilder(
          persona: persona,
          surface: surface,
          builder: (context, accent) {
            final title = Text(
              item.title,
              style: Tokens.body(surface).copyWith(fontWeight: Tokens.medium),
            );
            final tag = ValueListenableBuilder<Persona>(
              valueListenable: persona,
              builder: (context, value, _) => Text(
                item.tags[value]!,
                style: Tokens.meta(
                  surface,
                ).copyWith(color: Tokens.dimOn(surface)),
              ),
            );
            final trailing = Text(
              arrow,
              style: Tokens.body(surface).copyWith(color: accent),
            );
            final line = Text(
              item.line,
              style: Tokens.meta(
                surface,
              ).copyWith(color: Tokens.dimOn(surface)),
            );

            return Container(
              // Full bleed: the inverted ground runs to both viewport edges,
              // while the text stays inside the rail.
              color: Tokens.backgroundOn(surface),
              padding: layout.contentPadding.copyWith(
                top: Tokens.space3,
                bottom: Tokens.space3,
              ),
              child: ContentRail(
                child: FocusRing(
                  focused: focused,
                  accent: accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 3:2 rather than "title takes the slack": the tags
                          // start on the same x in every row, which is what
                          // makes the list read as a table.
                          Expanded(flex: 3, child: title),
                          const SizedBox(width: Tokens.space2),
                          // Below 1024 the tag moves under the description.
                          // The rail stops growing at 880, so the three-column
                          // row only has room to align once it is that wide.
                          if (layout.isWide) ...[
                            Expanded(flex: 2, child: tag),
                            const SizedBox(width: Tokens.space2),
                          ],
                          trailing,
                        ],
                      ),
                      const SizedBox(height: Tokens.space1),
                      line,
                      if (!layout.isWide) ...[
                        const SizedBox(height: Tokens.space1),
                        tag,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Brightness _flip(Brightness brightness) =>
      brightness == Brightness.light ? Brightness.dark : Brightness.light;
}
