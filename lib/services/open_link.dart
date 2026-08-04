import 'open_link_stub.dart'
    if (dart.library.js_interop) 'open_link_web.dart'
    as platform;

/// Opens [href] — an external URL, a `mailto:` or a sibling static page.
///
/// The site ships no `url_launcher` dependency for this: it is one call to
/// `window.open` behind a conditional import, so tests (and any non-web build)
/// get the stub instead of a compile error.
typedef LinkOpener = void Function(String href);

/// Swappable so widget tests can assert on what a row would have opened
/// without a real browser. Reset it in `tearDown`.
LinkOpener openLink = platform.openLink;

/// Restores the real implementation after a test has replaced [openLink].
void resetLinkOpener() => openLink = platform.openLink;
