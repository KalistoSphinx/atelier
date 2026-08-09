
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_app/core/services/shared_prefs_service.dart';

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPrefsServiceProvider).isDarkMode;
  }

  void toggleTheme(bool isDark) {
    state = isDark;
    ref.read(sharedPrefsServiceProvider).setDarkMode(isDark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});

ThemeData lightMode = ThemeData(
  fontFamily: "Manrope",
  sliderTheme: SliderThemeData(
    activeTrackColor: Colors.black,
    inactiveTrackColor: Colors.grey.shade300,
    thumbColor: Colors.black
  ),
  colorScheme: ColorScheme.light(
    surface: CupertinoColors.white,
    onSurface: Colors.black,
    inverseSurface: Colors.black,
    onSurfaceVariant: Colors.grey.shade600,
    surfaceContainerHighest: Colors.grey.shade200,
    surfaceContainerLowest: Colors.white.withValues(alpha: 0.8),
    secondaryContainer: CupertinoColors.systemGrey4,
    tertiaryContainer: Colors.white.withValues(alpha: 0.9),
    surfaceContainer: Colors.white,

    error: Colors.red.shade700
  )
);

ThemeData darkMode = ThemeData(
  brightness: .dark,
  fontFamily: "Manrope",
  sliderTheme: SliderThemeData(
    activeTrackColor: Colors.white,
    inactiveTrackColor: Colors.grey.shade800,
    thumbColor: Colors.white
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.grey.shade900,
  ),
  colorScheme: ColorScheme.dark(
    // onSurface: const Color(0xFFE6E1E5),
    inverseSurface: Colors.white,
    onSurfaceVariant: Colors.grey.shade500,
    surfaceContainer: const Color(0xFF2A2A2E),
    surfaceContainerHighest: Colors.grey.shade900,
    surfaceContainerLowest: Colors.grey.shade900.withValues(alpha: 0.8),
    secondaryContainer: const Color(0xFF383838),
    tertiaryContainer: Colors.grey.shade900.withValues(alpha: 0.9),
    error: Colors.red.shade300
  )
);