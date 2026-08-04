import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cli_portfolio/main.dart';
import 'package:cli_portfolio/services/command_processor.dart';

/// Types [command] into the terminal input and presses Enter.
Future<void> runCommand(WidgetTester tester, String command) async {
  await tester.enterText(find.byType(TextField), command);
  await tester.testTextInput.receiveAction(TextInputAction.go);
  await tester.pumpAndSettle();
}

Future<void> pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// Current contents of the input line.
String inputText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('shows the welcome banner on load', (tester) async {
    await tester.pumpWidget(const PortfolioApp());

    expect(
      find.textContaining('Welcome to mridul-portfolio'),
      findsOneWidget,
    );
  });

  testWidgets('input field is focused on load', (tester) async {
    await tester.pumpWidget(const PortfolioApp());

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode?.hasFocus, isTrue);
  });

  testWidgets('a known command echoes the prompt and prints output',
      (tester) async {
    await tester.pumpWidget(const PortfolioApp());

    await runCommand(tester, 'about');

    expect(find.textContaining('Mridul Dhiman'), findsOneWidget);
    // Prompt appears in the echoed history entry *and* the live input row.
    expect(
      find.textContaining(CommandProcessor.promptPrefix),
      findsNWidgets(2),
    );
  });

  testWidgets('an unknown command reports command not found', (tester) async {
    await tester.pumpWidget(const PortfolioApp());

    await runCommand(tester, 'sudo rm -rf /');

    expect(
      find.textContaining('Command not found: sudo rm -rf /'),
      findsOneWidget,
    );
  });

  testWidgets('clear empties the history', (tester) async {
    await tester.pumpWidget(const PortfolioApp());

    await runCommand(tester, 'about');
    expect(find.textContaining('Mridul Dhiman'), findsOneWidget);

    await runCommand(tester, 'clear');

    expect(find.textContaining('Mridul Dhiman'), findsNothing);
    expect(find.textContaining('Welcome to mridul-portfolio'), findsNothing);
  });

  testWidgets('the input clears after submitting', (tester) async {
    await tester.pumpWidget(const PortfolioApp());

    await runCommand(tester, 'skills');

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });

  group('arrow-key command history', () {
    testWidgets('up arrow recalls the previous command', (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await runCommand(tester, 'about');
      await pressKey(tester, LogicalKeyboardKey.arrowUp);

      expect(inputText(tester), 'about');
    });

    testWidgets('repeated up arrows walk backwards, then stop at the oldest',
        (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await runCommand(tester, 'about');
      await runCommand(tester, 'skills');

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'skills');

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');

      // Already at the oldest entry — should hold, not wrap around.
      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');
    });

    testWidgets('down arrow walks forward and returns to an empty line',
        (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await runCommand(tester, 'about');
      await runCommand(tester, 'skills');

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');

      await pressKey(tester, LogicalKeyboardKey.arrowDown);
      expect(inputText(tester), 'skills');

      await pressKey(tester, LogicalKeyboardKey.arrowDown);
      expect(inputText(tester), isEmpty);
    });

    testWidgets('a half-typed draft is restored on the way back down',
        (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await runCommand(tester, 'about');
      await tester.enterText(find.byType(TextField), 'ski');
      await tester.pumpAndSettle();

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');

      await pressKey(tester, LogicalKeyboardKey.arrowDown);
      expect(inputText(tester), 'ski');
    });

    testWidgets('consecutive duplicates are only recorded once',
        (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await runCommand(tester, 'about');
      await runCommand(tester, 'about');

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');

      // One entry only, so stepping down lands straight back on the blank line.
      await pressKey(tester, LogicalKeyboardKey.arrowDown);
      expect(inputText(tester), isEmpty);
    });

    testWidgets('blank submissions are not recorded', (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await runCommand(tester, 'about');
      await runCommand(tester, '   ');

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');
    });

    testWidgets('clear wipes the screen but keeps the recall buffer',
        (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await runCommand(tester, 'about');
      await runCommand(tester, 'clear');

      expect(find.textContaining('Mridul Dhiman'), findsNothing);

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'clear');

      await pressKey(tester, LogicalKeyboardKey.arrowUp);
      expect(inputText(tester), 'about');
    });

    testWidgets('up arrow does nothing before any command is run',
        (tester) async {
      await tester.pumpWidget(const PortfolioApp());

      await tester.enterText(find.byType(TextField), 'abo');
      await pressKey(tester, LogicalKeyboardKey.arrowUp);

      expect(inputText(tester), 'abo');
    });
  });

  group('CommandProcessor', () {
    late CommandProcessor processor;

    setUp(() => processor = CommandProcessor());

    test('clear returns null to signal a history wipe', () {
      expect(processor.run('clear'), isNull);
    });

    test('commands are case and whitespace insensitive', () {
      expect(processor.run('  HELP  '), processor.run('help'));
    });

    test('an empty command produces no output', () {
      expect(processor.run('   '), isEmpty);
    });

    test('help lists every available command', () {
      final help = processor.run('help')!;
      for (final command in [
        'about',
        'focus',
        'education',
        'experience',
        'projects',
        'skills',
        'contact',
        'clear',
      ]) {
        expect(help, contains(command));
      }
    });

    test('every command listed in help actually resolves', () {
      // Guards against help drifting ahead of the switch in run().
      final listed = RegExp(r'^  (\w+)\s', multiLine: true)
          .allMatches(processor.run('help')!)
          .map((m) => m.group(1)!);

      expect(listed, isNotEmpty);
      for (final command in listed) {
        if (command == 'clear') continue; // returns null by design
        expect(
          processor.run(command),
          isNot(startsWith('Command not found')),
          reason: '$command is in help but not handled by run()',
        );
      }
    });

    test('no output line is too wide for a terminal, in either focus', () {
      for (final focus in PortfolioFocus.values) {
        processor.run('focus ${focus.name}');
        for (final command in [
          'help',
          'about',
          'focus',
          'education',
          'experience',
          'projects',
          'skills',
          'contact',
        ]) {
          for (final line in processor.run(command)!.split('\n')) {
            expect(
              line.length,
              lessThanOrEqualTo(100),
              reason:
                  'a line of $command output in ${focus.name} focus '
                  'is ${line.length} chars',
            );
          }
        }
      }
    });
  });

  group('focus switching', () {
    late CommandProcessor processor;

    setUp(() => processor = CommandProcessor());

    test('defaults to the flutter framing', () {
      expect(processor.focus, PortfolioFocus.flutter);
      expect(processor.run('skills'), contains('flutter focus'));
    });

    test('focus with no argument reports the current focus and usage', () {
      final output = processor.run('focus')!;

      expect(output, contains('Current focus: flutter'));
      expect(output, contains('Usage: focus <flutter|android>'));
      expect(processor.focus, PortfolioFocus.flutter, reason: 'must not switch');
    });

    test('focus android retargets the four focus-aware commands', () {
      processor.run('focus android');

      expect(processor.focus, PortfolioFocus.android);
      for (final command in ['about', 'skills', 'experience', 'projects']) {
        expect(
          processor.run(command)!.toLowerCase(),
          contains('android'),
          reason: '$command should render the android framing',
        );
      }
    });

    test('the framings actually differ', () {
      final flutterSkills = processor.run('skills')!;
      processor.run('focus android');
      final androidSkills = processor.run('skills')!;

      expect(androidSkills, isNot(flutterSkills));
      expect(flutterSkills, contains('Riverpod'));
      expect(androidSkills, contains('WorkManager'));
    });

    test('focus-independent commands are identical across framings', () {
      final before = [processor.run('education'), processor.run('contact')];
      processor.run('focus android');
      final after = [processor.run('education'), processor.run('contact')];

      expect(after, before);
    });

    test('an unknown focus is rejected without changing state', () {
      final output = processor.run('focus ios')!;

      expect(output, contains('Unknown focus: ios'));
      expect(output, contains('Usage: focus <flutter|android>'));
      expect(processor.focus, PortfolioFocus.flutter);
    });

    test('switching back and forth is stable', () {
      final original = processor.run('about');
      processor.run('focus android');
      processor.run('focus flutter');

      expect(processor.run('about'), original);
    });

    test('each about points the visitor at the other framing', () {
      expect(processor.run('about'), contains("focus android"));
      processor.run('focus android');
      expect(processor.run('about'), contains("focus flutter"));
    });
  });
}
