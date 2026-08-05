import '../models/persona.dart';

/// Every string the site renders. Widget files contain no string literals —
/// it makes the persona swap trivial and the copy editable without touching
/// layout.
///
/// Copy rules, applied throughout: lowercase except proper nouns and metric
/// figures, no adjectives, no "passionate about". Each work row gets one line
/// describing what the thing does, not how it felt to build.
class Content {
  const Content._();

  // -------------------------------------------------------------------
  // Nav
  // -------------------------------------------------------------------

  static const String wordmark = 'mridul_dhiman';

  /// Label → the section key it scrolls to. Order is the visual order, which
  /// is also the tab order.
  static const List<(String, SectionKey)> navLinks = [
    ('work', SectionKey.work),
    ('experience', SectionKey.experience),
    ('contact', SectionKey.contact),
  ];

  /// The build command each persona is rendered as in the nav toggle. The
  /// active one is prefixed with `$`.
  static const Map<Persona, String> buildCommand = {
    Persona.android: './gradlew assembleRelease',
    Persona.flutter: 'flutter build web',
  };

  /// Screen-reader label for the toggle, since `$ ./gradlew assembleRelease`
  /// does not announce as a control.
  static const Map<Persona, String> buildCommandSemantics = {
    Persona.android: 'show the android build of this page',
    Persona.flutter: 'show the flutter build of this page',
  };

  // -------------------------------------------------------------------
  // Hero
  // -------------------------------------------------------------------

  static const Map<Persona, String> heroEyebrow = {
    Persona.android: 'android engineer',
    Persona.flutter: 'flutter engineer',
  };

  /// Two lines. The numbers carry the persuasion, so they lead and the prose
  /// stays out of the way.
  static const List<String> heroLines = [
    '1,150,000+ downloads',
    '0.12% crash rate',
  ];

  static const String heroMeta = 'gurugram, in · leading 7 engineers @ hranker';

  // -------------------------------------------------------------------
  // Skills — two columns, languages on the left, architecture on the right
  // -------------------------------------------------------------------

  /// Kept short enough that neither persona's row wraps where the other's
  /// does: the toggle is supposed to change the framing, not the layout, and
  /// `widget_test.dart` asserts the page does not move when it is used.
  static const Map<Persona, (String, String)> skills = {
    Persona.android: (
      'kotlin java dart swift',
      'mvvm · clean-arch · hilt · jetpack · coroutines',
    ),
    Persona.flutter: (
      'dart kotlin swift java',
      'mvvm · clean-arch · bloc · hive · channels',
    ),
  };

  // -------------------------------------------------------------------
  // Work — same three projects in both personas, only the tags change
  // -------------------------------------------------------------------

  static const List<WorkItem> work = [
    WorkItem(
      title: 'e-learning platform',
      line:
          'live classes, offline lessons and a timed test engine, '
          '#2 in its play store category',
      tags: {
        Persona.android: 'exoplayer, coroutines, cache',
        Persona.flutter: 'exoplayer, bloc, cache',
      },
    ),
    WorkItem(
      title: 'workforce management',
      line: 'field staff location and site geofences, tracked while closed',
      tags: {
        Persona.android: 'geofencing, workmanager, fcm',
        Persona.flutter: 'geolocator, platform channels, fcm',
      },
    ),
    WorkItem(
      title: 'sports data client',
      line: 'high-frequency match feeds rendered without blocking the ui',
      tags: {
        Persona.android: 'retrofit, coroutines, ktx',
        Persona.flutter: 'dio, isolates, streams',
      },
    ),
  ];

  // -------------------------------------------------------------------
  // Experience
  // -------------------------------------------------------------------

  static const List<(String, String)> experience = [
    ('2024—', 'software engineer lead, hranker'),
    ('2021—23', 'software engineer, oriental'),
    ('2021', 'app developer intern, kohli media'),
  ];

  // -------------------------------------------------------------------
  // Contact
  // -------------------------------------------------------------------

  static const String email = 'mridul98dhiman@gmail.com';
  static const String emailHref = 'mailto:$email';

  static const List<(String, String)> contactLinks = [
    ('github', 'https://github.com/mridul-dhiman'),
    ('linkedin', 'https://linkedin.com/in/mridul-d'),
    ('resume', 'resume.html'),
  ];

  // -------------------------------------------------------------------
  // Section headers — rendered as `// slug`, slashes in accent
  // -------------------------------------------------------------------

  static const Map<SectionKey, String> sectionLabel = {
    SectionKey.work: 'selected_work',
    SectionKey.experience: 'experience',
    SectionKey.contact: 'contact',
  };
}

/// One row in the work list.
class WorkItem {
  const WorkItem({required this.title, required this.line, required this.tags});

  final String title;
  final String line;

  /// The tech tag, which is the only part of the row the persona changes.
  final Map<Persona, String> tags;
}

/// The anchorable sections, in page order.
enum SectionKey { work, experience, contact }
