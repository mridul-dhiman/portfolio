import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models/persona.dart';
import '../services/open_link.dart';
import '../theme/tokens.dart';
import '../widgets/accent.dart';
import '../widgets/interactive.dart';
import '../widgets/responsive.dart';

/// The last row: the email, then github / linkedin / the static resume.
///
/// `resume.html` is deliberately in here rather than only in `index.html` —
/// it is the copy of this page that search engines and resume scrapers can
/// actually read.
class ContactFooter extends StatelessWidget {
  const ContactFooter({super.key, required this.persona});

  final ValueNotifier<Persona> persona;

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);

    final email = _ContactLink(
      persona: persona,
      label: Content.email,
      href: Content.emailHref,
    );
    final links = Wrap(
      spacing: Tokens.space3,
      runSpacing: Tokens.space1,
      children: [
        for (final (label, href) in Content.contactLinks)
          _ContactLink(persona: persona, label: label, href: href),
      ],
    );

    return Padding(
      padding: layout.contentPadding.copyWith(
        top: layout.sectionPadding,
        bottom: layout.sectionPadding,
      ),
      child: ContentRail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (layout.isCompact) ...[
              SectionHeader(
                persona: persona,
                label: Content.sectionLabel[SectionKey.contact]!,
              ),
              const SizedBox(height: Tokens.space3),
              email,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SectionHeader(
                    persona: persona,
                    label: Content.sectionLabel[SectionKey.contact]!,
                  ),
                  const SizedBox(width: Tokens.space6),
                  Expanded(child: email),
                ],
              ),
            const SizedBox(height: Tokens.space3),
            links,
          ],
        ),
      ),
    );
  }
}

class _ContactLink extends StatelessWidget {
  const _ContactLink({
    required this.persona,
    required this.label,
    required this.href,
  });

  final ValueNotifier<Persona> persona;
  final String label;
  final String href;

  @override
  Widget build(BuildContext context) {
    final brightness = Layout.of(context).brightness;

    return AccentBuilder(
      persona: persona,
      builder: (context, accent) => Interactive(
        isLink: true,
        semanticLabel: label,
        onActivate: () => openLink(href),
        builder: (context, hovered, focused) => FocusRing(
          focused: focused,
          accent: accent,
          child: Text(
            label,
            style: Tokens.body(brightness).copyWith(
              color: hovered ? accent : Tokens.foregroundOn(brightness),
              decoration: hovered ? TextDecoration.underline : null,
              decorationColor: accent,
            ),
          ),
        ),
      ),
    );
  }
}
