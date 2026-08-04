import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models/persona.dart';
import '../theme/tokens.dart';
import '../widgets/responsive.dart';

/// Two columns divided by a 1px rule: languages on the left, architecture on
/// the right. Both change with the persona; nothing else in the row does.
class SkillsTable extends StatelessWidget {
  const SkillsTable({super.key, required this.persona});

  final ValueNotifier<Persona> persona;

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final brightness = layout.brightness;

    return ValueListenableBuilder<Persona>(
      valueListenable: persona,
      builder: (context, value, _) {
        final (languages, architecture) = Content.skills[value]!;
        // Cells hug the rail on the outside and clear the divider on the
        // inside, so the first character of the left column lines up with
        // every other section's first character.
        final left = _Cell(
          text: languages,
          padding: layout.isCompact
              ? EdgeInsets.zero
              : const EdgeInsets.only(right: Tokens.space2),
        );
        final right = _Cell(
          text: architecture,
          padding: layout.isCompact
              ? EdgeInsets.zero
              : const EdgeInsets.only(left: Tokens.space2),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                width: Tokens.ruleWidth,
                color: Tokens.foregroundOn(brightness),
              ),
            ),
          ),
          child: Padding(
            padding: layout.contentPadding,
            child: ContentRail(
              child: layout.isCompact
                  // Under 600 the two columns stack and the divider turns
                  // horizontal — a 1px vertical rule with 24 characters either
                  // side of it does not survive a 320px viewport.
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        left,
                        const Rule(),
                        right,
                      ],
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: left),
                          Container(
                            width: Tokens.ruleWidth,
                            color: Tokens.foregroundOn(brightness),
                          ),
                          Expanded(flex: 2, child: right),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, required this.padding});

  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Layout.of(context).brightness;
    return Padding(
      padding: padding.copyWith(top: Tokens.space3, bottom: Tokens.space3),
      child: Text(text, style: Tokens.body(brightness)),
    );
  }
}
