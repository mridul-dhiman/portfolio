/// Which of Mridul's two role framings the portfolio is currently presenting.
///
/// He maintains separate Flutter and Android resumes for different openings;
/// [PortfolioFocus] is the terminal equivalent of choosing which one to send.
enum PortfolioFocus {
  flutter('flutter', 'Flutter & cross-platform mobile engineering'),
  android('android', 'native Android engineering');

  const PortfolioFocus(this.name, this.description);

  final String name;
  final String description;

  static PortfolioFocus? byName(String value) {
    for (final focus in values) {
      if (focus.name == value) return focus;
    }
    return null;
  }
}

/// Executes terminal commands and returns the text to render as output.
///
/// A `null` return signals the caller to clear the history instead of
/// appending an entry (used by `clear`).
///
/// Stateful in one respect only: [focus] selects which framing `about`,
/// `skills`, `experience` and `projects` render. Everything else is constant.
///
/// All portfolio copy lives here so it can be updated without touching UI
/// code. The two-space indent and column alignment below are load-bearing for
/// the terminal look — keep every line under 100 characters (there's a test).
class CommandProcessor {
  static const String promptPrefix = 'visitor@mridul-portfolio:~\$ ';

  PortfolioFocus focus = PortfolioFocus.flutter;

  _FocusContent get _content =>
      focus == PortfolioFocus.flutter ? _flutterContent : _androidContent;

  String? run(String rawInput) {
    final command = rawInput.trim().toLowerCase();

    // Parsed ahead of the switch because it's the only command taking an
    // argument; everything else is an exact match.
    if (command == 'focus' || command.startsWith('focus ')) {
      return _setFocus(command.substring('focus'.length).trim());
    }

    switch (command) {
      case 'help':
        return _help;
      case 'about':
        return _content.about;
      case 'education':
        return _education;
      case 'experience':
        return _content.experience;
      case 'projects':
        return _content.projects;
      case 'skills':
        return _content.skills;
      case 'contact':
        return _contact;
      case 'clear':
        return null;
      case '':
        return '';
      default:
        return "Command not found: $rawInput. Type 'help' to see a list of available commands.";
    }
  }

  String _setFocus(String argument) {
    if (argument.isEmpty) return _focusUsage();

    final requested = PortfolioFocus.byName(argument);
    if (requested == null) {
      return 'Unknown focus: $argument\n\n${_focusUsage()}';
    }

    focus = requested;
    return 'Focus set to: ${requested.name} (${requested.description}).\n'
        "'about', 'skills', 'experience' and 'projects' now lead with this work.";
  }

  String _focusUsage() {
    final options = PortfolioFocus.values
        .map((f) => '  ${f.name.padRight(10)}${f.description}')
        .join('\n');
    return 'Current focus: ${focus.name} (${focus.description})\n\n'
        '$options\n\n'
        'Usage: focus <flutter|android>';
  }

  static const String _help = '''
Available commands:

  help         Show this list of available commands
  about        Learn a bit about me
  focus        Switch between Flutter and native Android framing
  education    My academic background
  experience   Where I've worked
  projects     What I've built
  skills       Languages, frameworks & tools I use
  contact      How to reach me
  clear        Clear the terminal screen''';

  static const String _education = '''
Education:

  B.Tech in Computer Science & Engineering       Aug 2018 - Jul 2021
  DAV Institute of Engineering and Technology    Jalandhar, India''';

  static const String _contact = '''
Contact:

  Email      mridul98dhiman@gmail.com
  GitHub     github.com/mridul-dhiman
  LinkedIn   linkedin.com/in/mridul-d''';

  // ---------------------------------------------------------------------
  // Flutter framing
  // ---------------------------------------------------------------------

  static const _FocusContent _flutterContent = _FocusContent(
    about: '''
Hi, I'm Mridul Dhiman. I'm a Flutter & Cross-Platform Mobile Engineer with 4+
years of experience building production mobile apps for Android and iOS.

I lead a team of 7 mobile engineers at Hranker, where I architected a multi-app
Flutter ecosystem that reached 1.15M+ downloads and a #2 Play Store domain rank.

Type 'focus android' to see the same career framed for native Android roles.''',
    skills: '''
Skills (flutter focus):

  Languages & Frameworks   Flutter SDK, Dart, Kotlin, Swift, Java
  State Management         Provider, BLoC, Riverpod, MVVM, Clean Architecture,
                           multi-modular app architecture
  Flutter Core             Custom widgets, MethodChannels (native interop),
                           animations, responsive UI, local storage (Hive, Sqflite)
  Backend & APIs           RESTful APIs, Dio / Retrofit, Firebase (FCM, Remote
                           Config, Analytics), live video streaming (ExoPlayer)
  Engineering Tools        Android Studio, VS Code, Xcode, Git, CI/CD pipelines,
                           unit & widget testing, Flutter profiling''',
    experience: '''
Experience (flutter focus):

  Hranker Educational Solution Pvt. Ltd.       Feb 2024 - present
  Software Engineer Lead                       Gurugram, India
    - Led cross-platform development in Flutter, implementing clean architecture
      and scalable state management.
    - Architected a multi-app Flutter ecosystem for educational platforms with
      live video streaming, offline downloads, and interactive test engines.
    - Cut overall crash rate to 0.12% through Flutter profiling, widget tree
      optimisation, and memory management.
    - Scaled the flagship app to 1.15M+ downloads (#2 domain rank on the Play
      Store), supporting a 346% DAU increase over 6 months.
    - Bridged native Android (Kotlin) and iOS (Swift) via MethodChannels for
      background services and FCM push notifications.
    - Directed code reviews, state management standards, and CI/CD pipelines for
      a team of 7 mobile engineers.

  Oriental Outsourcing Consultants (P) Ltd.    Aug 2021 - Sep 2023
  Software Engineer                            Kharar, India
    - Developed cross-platform Flutter applications alongside native Android and
      iOS modules for international client projects.
    - Built reusable Flutter widget libraries and responsive layouts for
      consistent rendering across mobile and tablet form factors.
    - Integrated REST backends and third-party plugins for real-time data sync,
      media handling, and payment processing.
    - Ran widget testing, state management refactoring, and performance
      profiling ahead of App Store and Play Store releases.

  Kohli Media LLP                              Jan 2021 - Jul 2021
  App Developer Intern                         Mohali, India
    - Developed cross-platform UI prototypes and app features using Flutter and
      the Android SDK.
    - Integrated REST APIs and managed asynchronous data flows for smooth UI
      updates.''',
    projects: '''
Projects (flutter focus):

  Cross-Platform E-Learning Suite
  Flutter, Dart, Firebase, REST APIs, ExoPlayer, Provider / BLoC
    - Architected 3 production Flutter applications supporting live video
      streaming, offline lesson caching, and interactive quiz/test flows.
    - Optimised rendering performance and widget rebuilds during continuous
      video playback and media caching.

  Workforce Management Application
  Flutter, Dart, Location API, WorkManager, MethodChannels, FCM
    - Built a cross-platform employee tracking interface with background
      geolocation and FCM notifications for real-time task updates.
    - Wrote custom native Android/iOS plugins via MethodChannels to run
      persistent background location tracking efficiently.''',
  );

  // ---------------------------------------------------------------------
  // Android framing
  // ---------------------------------------------------------------------

  static const _FocusContent _androidContent = _FocusContent(
    about: '''
Hi, I'm Mridul Dhiman. I'm an Android & Mobile Software Engineer with 4+ years
of experience building native Android applications in Kotlin and Java.

I lead a team of 7 mobile engineers at Hranker, where I cut the user-perceived
crash rate from 1.24% to 0.12% and helped drive a 346% DAU increase in 180 days.

Type 'focus flutter' to see the same career framed for cross-platform roles.''',
    skills: '''
Skills (android focus):

  Languages                Kotlin, Java, Dart, Swift, Core Java (8+)
  Android SDK & Core       Activities, Services, BroadcastReceivers, Coroutines,
                           WorkManager, Jetpack components, ExoPlayer, Location APIs
  Architecture             MVVM, Clean Architecture, multi-modular codebases,
                           dependency injection (Hilt / Dagger)
  Frameworks & Libraries   Flutter SDK, Retrofit, RxJava, Firebase (FCM, Remote
                           Config), Glide, JSON / RESTful APIs
  Tools & Practices        Android Studio, Xcode, Git, Gradle, unit testing,
                           performance & memory profiling''',
    experience: '''
Experience (android focus):

  Hranker Educational Solution Pvt. Ltd.       Feb 2024 - present
  Software Engineer Lead                       Gurugram, India
    - Led native Android and Flutter development, implementing MVVM architecture
      and Kotlin Coroutines.
    - Reduced user-perceived crash rate from 1.24% to 0.12% through targeted
      memory profiling and background process optimisation.
    - Built features that scaled the flagship educational app to 1.15M+
      downloads (#2 Play Store rank in domain), driving a 346% DAU increase
      over 180 days.
    - Integrated ExoPlayer for live video streaming and offline media caching,
      plus WorkManager with Location APIs for background synchronisation.
    - Set unit testing standards and code-review practices for a team of 7
      engineers to keep the codebase maintainable.

  Oriental Outsourcing Consultants (P) Ltd.    Aug 2021 - Sep 2023
  Software Engineer                            Kharar, India
    - Developed and maintained native Android apps in Kotlin and Java, alongside
      iOS features in Swift and cross-platform modules in Flutter.
    - Implemented MVVM, Dagger/Hilt for dependency injection, and Retrofit for
      REST networking to decouple business logic from UI.
    - Integrated Firebase Cloud Messaging for real-time notifications and tuned
      Glide image loading for smooth UI scrolling.
    - Ran module testing and code refactoring to improve stability ahead of
      production releases.

  Kohli Media LLP                              Jan 2021 - Jul 2021
  App Developer Intern                         Mohali, India
    - Built proof-of-concept features for native Android apps in Java and Kotlin
      from design specifications.
    - Managed asynchronous data loading and API integration using Handlers and
      Android background processing.
    - Worked with UI designers and backend developers to resolve critical bugs
      before deployment.''',
    projects: '''
Projects (android focus):

  E-Learning Mobile Platform
  Kotlin, MVVM, Coroutines, ExoPlayer, background services
    - Architected the native Android client with live video streaming, offline
      caching, and interactive test-taking modules.
    - Managed memory and battery performance during continuous media playback
      and background video downloads.

  Workforce Management Application
  Kotlin, MVVM, Location API, Firebase Cloud Messaging, WorkManager
    - Developed background geolocation tracking and geofencing to monitor site
      work zones without draining device battery.
    - Used WorkManager for persistent data sync while the app is closed, with
      FCM triggering real-time task updates.

  Sports Management System
  Java, Retrofit, Coroutines, Android SDK
    - Built the native Android client integrating high-frequency sports data
      APIs asynchronously via Retrofit.''',
  );
}

/// The four commands whose copy changes with the selected [PortfolioFocus].
class _FocusContent {
  const _FocusContent({
    required this.about,
    required this.skills,
    required this.experience,
    required this.projects,
  });

  final String about;
  final String skills;
  final String experience;
  final String projects;
}
