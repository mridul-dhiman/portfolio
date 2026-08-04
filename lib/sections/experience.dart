import 'package:flutter/material.dart';

import '../data/content.dart';
import '../theme/tokens.dart';
import '../widgets/responsive.dart';

/// Dates in a fixed-width left column, role and employer in the right. The
/// column width is measured from the longest date string rather than guessed,
/// so the two columns stay aligned whatever the copy becomes.
class ExperienceList extends StatelessWidget {
  const ExperienceList({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final brightness = layout.brightness;
    final style = Tokens.body(brightness);
    final dateColumn = _dateColumnWidth(style, MediaQuery.textScalerOf(context));

    return Padding(
      padding: layout.contentPadding.copyWith(bottom: layout.sectionPadding),
      child: ContentRail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (date, role) in Content.experience)
              Padding(
                padding: const EdgeInsets.only(top: Tokens.space2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: dateColumn,
                      child: Text(
                        date,
                        style: style.copyWith(color: Tokens.dimOn(brightness)),
                      ),
                    ),
                    Expanded(child: Text(role, style: style)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _dateColumnWidth(TextStyle style, TextScaler scaler) {
    var widest = 0.0;
    for (final (date, _) in Content.experience) {
      final painter = TextPainter(
        text: TextSpan(text: date, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = widest > painter.width ? widest : painter.width;
      painter.dispose();
    }
    return widest + Tokens.space3;
  }
}
