import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration using FlexColorScheme.
/// WHY: Aligns UI colors with LiveIt "Grounded Growth" brand palette from docs.
class AppTheme {
  // --- Brand palette constants (Light) ---
  static const Color _lightPrimary = Color(0xFF2F5D62); // Deep Teal
  static const Color _lightPrimaryContainer = Color(0xFF68B0AB); // Lighter Teal
  static const Color _lightSecondary = Color(0xFFC3B49A); // Warm Sand
  static const Color _lightSecondaryContainer = Color(
    0xFFE9E0D2,
  ); // Soft Gold/Sand
  static const Color _lightTertiary = Color(0xFFFF7B54); // Coral
  static const Color _lightTertiaryContainer = Color(0xFFFFD2C6); // Soft Coral
  static const Color _lightBackground = Color(0xFFF8F8F8); // Off-White
  static const Color _lightSurface = Color(0xFFFFFFFF); // White
  static const Color _lightOutline = Color(0xFFE0E0E0); // Divider/Outline
  static const Color _lightOnBackground = Color(0xFF333333); // Text Primary
  static const Color _lightOnSurface = Color(0xFF333333); // Text Primary

  // --- Brand palette constants (Dark) ---
  static const Color _darkPrimary = Color(0xFF68B0AB); // Mint/Lighter Teal
  static const Color _darkPrimaryContainer = Color(0xFF2F5D62); // Deep Teal
  static const Color _darkSecondary = Color(0xFFA98B74); // Muted Brown
  static const Color _darkSecondaryContainer = Color(
    0xFF6E5A49,
  ); // Deeper Brown
  static const Color _darkTertiary = Color(0xFFFF9A8B); // Lighter Coral
  static const Color _darkTertiaryContainer = Color(0xFF8C4F48); // Deep Coral
  static const Color _darkBackground = Color(0xFF1A1A1A); // Near Black
  static const Color _darkSurface = Color(0xFF2C2C2C); // Dark Grey
  static const Color _darkOutline = Color(0xFF424242); // Divider/Outline
  static const Color _darkOnBackground = Color(0xFFE0E0E0); // Text Primary
  static const Color _darkOnSurface = Color(0xFFE0E0E0); // Text Primary

  // --- Semantic colors (Soft tones consistent with brand) ---
  static const Color _successLight = Color(0xFF66BB6A);
  static const Color _warningLight = Color(0xFFF4A261);
  static const Color _infoLight = Color(0xFF4A90A4);
  static const Color _successDark = Color(0xFF81C784);
  static const Color _warningDark = Color(0xFFF4A261);
  static const Color _infoDark = Color(0xFF7FB3C2);

  /// Light theme using the Grounded Growth palette.
  static ThemeData light() {
    final scheme = FlexSchemeColor(
      primary: _lightPrimary,
      primaryContainer: _lightPrimaryContainer,
      secondary: _lightSecondary,
      secondaryContainer: _lightSecondaryContainer,
      tertiary: _lightTertiary,
      tertiaryContainer: _lightTertiaryContainer,
      error: Color(0xFFE57373), // Soft Red
    );

    // Base text theme using Plus Jakarta Sans for body/UI
    final TextTheme baseTextLight = ThemeData.light().textTheme;
    final TextTheme plusJakartaLight = GoogleFonts.plusJakartaSansTextTheme(
      baseTextLight,
    );

    // Override display/headline with New Amsterdam for headings/display
    final TextTheme lightTextTheme = plusJakartaLight
        .copyWith(
          displayLarge: plusJakartaLight.displayLarge?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          displayMedium: plusJakartaLight.displayMedium?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          displaySmall: plusJakartaLight.displaySmall?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: plusJakartaLight.headlineLarge?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: plusJakartaLight.headlineMedium?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: plusJakartaLight.headlineSmall?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w600,
          ),
          // Titles remain Plus Jakarta Sans with strengthened weights
          titleLarge: plusJakartaLight.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleMedium: plusJakartaLight.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          titleSmall: plusJakartaLight.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(bodyColor: _lightOnSurface, displayColor: _lightOnSurface);

    return FlexThemeData.light(
      colors: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      scaffoldBackground: _lightBackground,
      useMaterial3: true,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 12,
        inputDecoratorRadius: 12,
        filledButtonRadius: 12,
        elevatedButtonRadius: 12,
        outlinedButtonRadius: 12,
        cardRadius: 16,
        bottomSheetRadius: 16,
        dialogRadius: 16,
        popupMenuRadius: 12,
      ),
      visualDensity: VisualDensity.standard,
    ).copyWith(
      colorScheme: FlexColorScheme.light(colors: scheme).toScheme.copyWith(
        surface: _lightSurface,
        outline: _lightOutline,
        onSurface: _lightOnSurface,
      ),
      textTheme: lightTextTheme,
      extensions: <ThemeExtension<dynamic>>[
        const AppSemanticColors(
          success: _successLight,
          warning: _warningLight,
          info: _infoLight,
        ),
      ],
    );
  }

  /// Dark theme using the Grounded Growth palette (dark variants).
  static ThemeData dark() {
    final scheme = FlexSchemeColor(
      primary: _darkPrimary,
      primaryContainer: _darkPrimaryContainer,
      secondary: _darkSecondary,
      secondaryContainer: _darkSecondaryContainer,
      tertiary: _darkTertiary,
      tertiaryContainer: _darkTertiaryContainer,
      error: Color(0xFFEF9A9A), // Soft Red (dark)
    );

    // Base text theme using Plus Jakarta Sans for body/UI
    final TextTheme baseTextDark = ThemeData.dark().textTheme;
    final TextTheme plusJakartaDark = GoogleFonts.plusJakartaSansTextTheme(
      baseTextDark,
    );

    // Override display/headline with New Amsterdam for headings/display
    final TextTheme darkTextTheme = plusJakartaDark
        .copyWith(
          displayLarge: plusJakartaDark.displayLarge?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          displayMedium: plusJakartaDark.displayMedium?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          displaySmall: plusJakartaDark.displaySmall?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: plusJakartaDark.headlineLarge?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: plusJakartaDark.headlineMedium?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: plusJakartaDark.headlineSmall?.copyWith(
            fontFamily: 'NewAmsterdam',
            fontWeight: FontWeight.w600,
          ),
          // Titles remain Plus Jakarta Sans with strengthened weights
          titleLarge: plusJakartaDark.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleMedium: plusJakartaDark.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          titleSmall: plusJakartaDark.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(bodyColor: _darkOnSurface, displayColor: _darkOnSurface);

    return FlexThemeData.dark(
      colors: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 10,
      scaffoldBackground: _darkBackground,
      useMaterial3: true,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 12,
        inputDecoratorRadius: 12,
        filledButtonRadius: 12,
        elevatedButtonRadius: 12,
        outlinedButtonRadius: 12,
        cardRadius: 16,
        bottomSheetRadius: 16,
        dialogRadius: 16,
        popupMenuRadius: 12,
      ),
      visualDensity: VisualDensity.standard,
    ).copyWith(
      colorScheme: FlexColorScheme.dark(colors: scheme).toScheme.copyWith(
        surface: _darkSurface,
        outline: _darkOutline,
        onSurface: _darkOnSurface,
      ),
      textTheme: darkTextTheme,
      extensions: <ThemeExtension<dynamic>>[
        const AppSemanticColors(
          success: _successDark,
          warning: _warningDark,
          info: _infoDark,
        ),
      ],
    );
  }
}

/// ThemeExtension for semantic colors not covered by Material's ColorScheme.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color info;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  @override
  AppSemanticColors copyWith({Color? success, Color? warning, Color? info}) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
