import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/terminal_item.dart';
import 'services/command_processor.dart';

void main() {
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  static const Color background = Color(0xFF0C0C0C);
  static const Color terminalGreen = Color(0xFF00FF00);

  /// Bundled in assets/fonts and declared in pubspec.yaml, so the terminal
  /// text is served from our own origin with no fallback-font flash on first
  /// paint. (The Flutter web engine separately fetches CanvasKit and its
  /// default Roboto fallback from gstatic.com; see README for self-hosting.)
  static const String monoFont = 'RobotoMono';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mridul Dhiman — Terminal Portfolio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: monoFont,
        scaffoldBackgroundColor: background,
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: monoFont,
          bodyColor: terminalGreen,
          displayColor: terminalGreen,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: terminalGreen,
          brightness: Brightness.dark,
        ),
      ),
      home: const TerminalScreen(),
    );
  }
}

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);

  /// Holds the selected [PortfolioFocus] across commands.
  final CommandProcessor _processor = CommandProcessor();

  final List<TerminalItem> _history = [
    const TerminalItem(
      output:
          'Welcome to mridul-portfolio [Version 1.0.0]\n'
          "Type 'help' to see a list of available commands.\n"
          'Use the up/down arrow keys to browse previous commands.',
    ),
  ];

  /// Commands the visitor actually ran, oldest first — the shell-style
  /// recall buffer. Deliberately survives `clear`, which wipes the screen
  /// rather than the history, matching a real terminal.
  final List<String> _commandHistory = [];

  /// Position within [_commandHistory]. Equal to its length when the user is
  /// on the live input line rather than recalling a past command.
  int _historyCursor = 0;

  /// Whatever was half-typed before stepping back into history, so pressing
  /// down-arrow all the way returns it instead of an empty line.
  String _draft = '';

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Maps up/down arrows onto history recall. Everything else falls through
  /// to the TextField so normal typing and caret movement are untouched.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _recallHistory(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _recallHistory(1);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  /// Steps [delta] entries through [_commandHistory] and loads the result
  /// into the input, caret parked at the end.
  void _recallHistory(int delta) {
    if (_commandHistory.isEmpty) return;

    // Stash the live line the first time we step off it.
    if (_historyCursor == _commandHistory.length) {
      _draft = _inputController.text;
    }

    final next = (_historyCursor + delta).clamp(0, _commandHistory.length);
    if (next == _historyCursor) return;
    _historyCursor = next;

    final text = next == _commandHistory.length
        ? _draft
        : _commandHistory[next];
    _inputController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _scrollToBottom() {
    // Deferred a frame so the newly appended entry is laid out and
    // maxScrollExtent reflects it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _submitCommand(String rawInput) {
    final output = _processor.run(rawInput);

    setState(() {
      if (output == null) {
        _history.clear();
      } else {
        _history.add(TerminalItem(command: rawInput, output: output));
      }
    });

    _recordInHistory(rawInput);
    _inputController.clear();
    _scrollToBottom();
    // Enter can drop focus on web/desktop; take it straight back.
    _focusNode.requestFocus();
  }

  /// Appends to the recall buffer and returns the cursor to the live line.
  /// Blank input and an immediate repeat of the previous command are skipped,
  /// so arrowing back doesn't wade through duplicates.
  void _recordInHistory(String rawInput) {
    final command = rawInput.trim();
    if (command.isNotEmpty &&
        (_commandHistory.isEmpty || _commandHistory.last != command)) {
      _commandHistory.add(command);
    }
    _historyCursor = _commandHistory.length;
    _draft = '';
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 14, height: 1.5);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: Scaffold(
        backgroundColor: PortfolioApp.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: _history.length,
                    itemBuilder: (context, index) => _TerminalEntry(
                      item: _history[index],
                      textStyle: textStyle,
                    ),
                  ),
                ),
                _TerminalInputRow(
                  controller: _inputController,
                  focusNode: _focusNode,
                  textStyle: textStyle,
                  onSubmitted: _submitCommand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders one history entry: the echoed prompt + command, then its output.
class _TerminalEntry extends StatelessWidget {
  const _TerminalEntry({required this.item, required this.textStyle});

  final TerminalItem item;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.command != null)
            SelectableText.rich(
              TextSpan(
                style: textStyle,
                children: [
                  TextSpan(
                    text: CommandProcessor.promptPrefix,
                    style: const TextStyle(
                      color: PortfolioApp.terminalGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: item.command,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          if (item.output.isNotEmpty)
            SelectableText(
              item.output,
              style: textStyle.copyWith(color: const Color(0xFFD8D8D8)),
            ),
        ],
      ),
    );
  }
}

/// The always-focused input line pinned below the history.
class _TerminalInputRow extends StatelessWidget {
  const _TerminalInputRow({
    required this.controller,
    required this.focusNode,
    required this.textStyle,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle textStyle;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          CommandProcessor.promptPrefix,
          style: textStyle.copyWith(
            color: PortfolioApp.terminalGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            cursorColor: PortfolioApp.terminalGreen,
            cursorWidth: 8,
            style: textStyle.copyWith(color: Colors.white),
            textInputAction: TextInputAction.go,
            inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }
}
