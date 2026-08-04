import 'package:flutter/material.dart';

/// Everything clickable on the page, in one place: pointer, keyboard and
/// screen-reader affordances wired the same way for the nav anchors, the build
/// toggle, the work rows and the contact links.
///
/// Hover comes from a plain [MouseRegion] rather than
/// [FocusableActionDetector.onShowHoverHighlight], which is gated on the focus
/// highlight mode and stays silent while that mode is `touch`. Hover styling
/// is about the pointer being there, not about how the reader is navigating.
class Interactive extends StatefulWidget {
  const Interactive({
    super.key,
    required this.onActivate,
    required this.builder,
    this.semanticLabel,
    this.isLink = false,
  });

  final VoidCallback onActivate;

  /// Announced instead of the visible glyphs, for the elements whose label is
  /// a shell command or a bare arrow.
  final String? semanticLabel;

  /// Links navigate; the nav anchors and the build toggle do not.
  final bool isLink;

  final Widget Function(BuildContext context, bool hovered, bool focused)
  builder;

  @override
  State<Interactive> createState() => _InteractiveState();
}

class _InteractiveState extends State<Interactive> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !widget.isLink,
      link: widget.isLink,
      label: widget.semanticLabel,
      // Where a label is supplied it replaces the glyphs rather than being
      // merged in front of them: `$ ./gradlew assembleRelease` announced after
      // "show the flutter build of this page" is noise.
      excludeSemantics: widget.semanticLabel != null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onActivate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            // The work rows are a coloured band, and RenderColoredBox does not
            // hit-test itself — without this a row would only be clickable
            // where its glyphs are.
            behavior: HitTestBehavior.opaque,
            onTap: widget.onActivate,
            child: widget.builder(context, _hovered, _focused),
          ),
        ),
      ),
    );
  }
}
