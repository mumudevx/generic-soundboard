import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  // App Information
  static const String appName = 'Soundboard';
  static const String packageName = 'com.mumudevx.soundboard';
  static const String version = '1.0.0';

  // Theme Configuration
  static const Color primaryColor = Color(0xFF6200EE); // Material Design primary color
  static const Brightness brightness = Brightness.light;
  static const double buttonElevation = 4.0;
  static const double buttonOpacity = 0.9;
  static const double buttonIconSize = 32.0;
  static const double buttonFontSize = 16.0;
  static const double buttonPadding = 16.0;
  static const double buttonBorderRadius = 12.0;

  // Layout Configuration
  static const double gridSpacing = 12.0;
  static const int gridColumnsDesktop = 4;
  static const int gridColumnsMobile = 2;
  static const double gridBreakpoint = 600.0;

  // Audio Configuration
  static const Duration audioCrossFadeDuration = Duration(milliseconds: 200);
  static const Duration audioSeekDuration = Duration.zero;
  static const int audioMaxConcurrentPlays = 1;

  // Storage Configuration
  static const String soundsPath = 'lib/sounds';

  // Error Messages
  static const String errorPlayingSound = 'Error playing sound';
  static const String errorInitializingAudio = 'Error initializing audio';

  // Ad Configuration
  static const String bannerAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'  // Test banner ad unit ID
      : 'YOUR_PRODUCTION_BANNER_AD_UNIT_ID';

  static const String interstitialAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'  // Test interstitial ad unit ID
      : 'YOUR_PRODUCTION_INTERSTITIAL_AD_UNIT_ID';

  // Theme Data
  static ThemeData getThemeData(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      cardTheme: const CardTheme(
        elevation: buttonElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(buttonBorderRadius),
          ),
        ),
      ),
    );
  }

  // Button Colors
  static Color getButtonColor(String id) {
    // Use hashCode of ID to generate consistent color
    final colorSeed = id.hashCode;
    return Color((colorSeed * 0xFF3D88EF + 0xFF3D88EF) % 0xFFFFFFFF)
        .withAlpha((buttonOpacity * 255).round());
  }

  // Button Style
  static ButtonStyle getButtonStyle(Color color) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(color.withOpacity(buttonOpacity)),
      elevation: WidgetStateProperty.all(buttonElevation),
      padding: WidgetStateProperty.all(
        const EdgeInsets.all(buttonPadding),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
        ),
      ),
    );
  }

  // Text Styles
  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: buttonFontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    height: 1.4,
    leadingDistribution: TextLeadingDistribution.even,
    fontFamily: 'Poppins',
  );
}
