/// Which build of the same career the page is currently rendering.
///
/// The two personas share every project, every number and every layout row.
/// Only the framing changes — the point of the toggle is that one person
/// shipped both, not that there are two different people.
enum Persona {
  /// Native Android. Accent is Kotlin purple.
  android,

  /// Flutter / cross-platform. Accent is Flutter blue.
  flutter;

  /// The other one. There are exactly two, so this is total.
  Persona get other => this == android ? flutter : android;
}
