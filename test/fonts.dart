import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/theme/tokens.dart';

/// Registers the real JetBrains Mono subsets with the test binding.
///
/// Without this, `flutter test` falls back to a stand-in font that advances a
/// full em per character — roughly 1.7x wider than JetBrains Mono's 0.6em. Any
/// assertion about fitting inside 320px would then be measuring the wrong
/// font, and would fail on copy that fits fine in the browser.
Future<void> loadTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final loader = FontLoader(Tokens.fontFamily);
  for (final weight in ['Regular', 'Medium']) {
    final bytes = File('assets/fonts/JetBrainsMono-$weight.ttf')
        .readAsBytesSync();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  await loader.load();
}
