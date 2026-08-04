/// A single entry in the terminal's scroll-back history.
///
/// [command] is null for entries that aren't a response to user input
/// (e.g. the initial welcome banner) — in that case only [output] renders.
class TerminalItem {
  final String? command;
  final String output;

  const TerminalItem({this.command, required this.output});
}
