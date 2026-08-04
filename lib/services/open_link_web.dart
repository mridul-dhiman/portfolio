import 'dart:js_interop';

@JS('window')
external _Window get _window;

@JS()
@staticInterop
class _Window {}

extension on _Window {
  external void open(String url, String target, String features);
}

/// `noopener,noreferrer` because these are outbound links to sites this page
/// does not control.
void openLink(String href) => _window.open(href, '_blank', 'noopener,noreferrer');
