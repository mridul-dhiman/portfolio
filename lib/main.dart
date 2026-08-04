import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'data/content.dart';
import 'models/persona.dart';
import 'sections/contact.dart';
import 'sections/experience.dart';
import 'sections/hero.dart';
import 'sections/skills.dart';
import 'sections/work.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/accent.dart';
import 'widgets/nav_bar.dart';
import 'widgets/responsive.dart';

void main() {
  // Drops the `#` from the URL so `/resume.html` and the page itself share a
  // sane path space.
  usePathUrlStrategy();
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatefulWidget {
  const PortfolioApp({super.key});

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp> {
  /// The whole of the site's state. One enum does not need Riverpod, Bloc or
  /// Provider — a portfolio that over-engineers its own state management
  /// argues against its author.
  final ValueNotifier<Persona> _persona = ValueNotifier(Persona.android);

  @override
  void dispose() {
    _persona.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: PortfolioPage.title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(Brightness.light),
      darkTheme: AppTheme.of(Brightness.dark),
      // No manual switch: the page follows `prefers-color-scheme`. The one
      // toggle on the page is the build variant.
      themeMode: ThemeMode.system,
      home: ResponsiveLayout(child: PortfolioPage(persona: _persona)),
    );
  }
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key, required this.persona});

  static const String title = 'mridul dhiman — android & flutter engineer';

  final ValueNotifier<Persona> persona;

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final ScrollController _controller = ScrollController();
  final Map<SectionKey, GlobalKey> _anchors = {
    for (final key in SectionKey.values) key: GlobalKey(),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Jumps — does not animate — to a section, landing its first line just
  /// below the pinned bar.
  void _navigate(SectionKey section) {
    final context = _anchors[section]?.currentContext;
    if (context == null || !_controller.hasClients) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final viewport = RenderAbstractViewport.of(box);
    final target =
        viewport.getOffsetToReveal(box, 0).offset -
        NavBar.heightFor(Layout.of(context));

    _controller.jumpTo(
      target.clamp(
        _controller.position.minScrollExtent,
        _controller.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);
    final persona = widget.persona;

    return Scaffold(
      body: PrimaryScrollController(
        controller: _controller,
        child: CustomScrollView(
          controller: _controller,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _NavBarDelegate(
                extent: NavBar.heightFor(layout),
                child: NavBar(persona: persona, onNavigate: _navigate),
              ),
            ),
            SliverToBoxAdapter(child: HeroSection(persona: persona)),
            SliverToBoxAdapter(child: SkillsTable(persona: persona)),
            SliverToBoxAdapter(
              child: _SectionTitle(
                key: _anchors[SectionKey.work],
                persona: persona,
                section: SectionKey.work,
              ),
            ),
            SliverList.builder(
              itemCount: Content.work.length,
              itemBuilder: (context, index) =>
                  WorkRow(persona: persona, item: Content.work[index]),
            ),
            SliverToBoxAdapter(
              child: _SectionTitle(
                key: _anchors[SectionKey.experience],
                persona: persona,
                section: SectionKey.experience,
              ),
            ),
            const SliverToBoxAdapter(child: ExperienceList()),
            const SliverToBoxAdapter(child: Rule()),
            SliverToBoxAdapter(
              // The key goes on the box, not the sliver: `_navigate` measures
              // a RenderBox against the viewport.
              child: ContactFooter(
                key: _anchors[SectionKey.contact],
                persona: persona,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `// section_name` with the rules above and below it that separate the
/// page's bands.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    super.key,
    required this.persona,
    required this.section,
  });

  final ValueNotifier<Persona> persona;
  final SectionKey section;

  @override
  Widget build(BuildContext context) {
    final layout = Layout.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Rule(),
        Padding(
          padding: layout.contentPadding.copyWith(
            top: layout.sectionPadding,
            bottom: Tokens.space3,
          ),
          child: ContentRail(
            child: SectionHeader(
              persona: persona,
              label: Content.sectionLabel[section]!,
            ),
          ),
        ),
        const Rule(),
      ],
    );
  }
}

class _NavBarDelegate extends SliverPersistentHeaderDelegate {
  const _NavBarDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(height: extent, child: child);

  @override
  bool shouldRebuild(_NavBarDelegate oldDelegate) =>
      extent != oldDelegate.extent || child != oldDelegate.child;
}
