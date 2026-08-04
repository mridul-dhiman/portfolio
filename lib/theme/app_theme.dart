import 'package:flutter/material.dart';

import 'tokens.dart';

/// The Material defaults that would otherwise leak into the direction:
/// rounded corners, splash ripples, tinted surfaces and a proportional font.
///
/// Everything here is a subtraction. Positive styling lives in the widgets and
/// comes from [Tokens].
class AppTheme {
  const AppTheme._();

  static ThemeData of(Brightness brightness) {
    final foreground = Tokens.foregroundOn(brightness);
    final background = Tokens.backgroundOn(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: Tokens.fontFamily,
      scaffoldBackgroundColor: background,
      canvasColor: background,

      // Radius zero globally. Every Material-provided shape is squared off
      // here so no widget has to remember to do it.
      cardTheme: const CardThemeData(shape: _square, margin: EdgeInsets.zero),
      dialogTheme: const DialogThemeData(shape: _square),
      popupMenuTheme: const PopupMenuThemeData(shape: _square),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(borderRadius: BorderRadius.zero),
      ),

      // No ripples, no hover tints, no focus haloes — hover and focus states
      // are drawn explicitly by the widgets that have them.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: foreground,
        onPrimary: background,
        secondary: foreground,
        onSecondary: background,
        error: foreground,
        onError: background,
        surface: background,
        onSurface: foreground,
      ),

      textTheme: Typography.blackMountainView
          .apply(
            fontFamily: Tokens.fontFamily,
            bodyColor: foreground,
            displayColor: foreground,
          )
          .merge(
            TextTheme(bodyMedium: Tokens.body(brightness)),
          ),
    );
  }

  static const RoundedRectangleBorder _square = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );
}
