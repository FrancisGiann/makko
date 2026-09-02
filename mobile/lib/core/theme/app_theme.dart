import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Makko's brand and semantic colors. Screens should consume [ColorScheme] and
/// [MakkoSemanticColors] rather than hard-coding appearance-specific colors.
class MakkoColors {
  static const primary = Color(0xFF22D3EE);
  static const lightPrimary = Color(0xFF0891B2);
  static const deepHarbor = Color(0xFF070D18);
  static const harborSurface = Color(0xFF0C1527);
  static const harborElevated = Color(0xFF101C33);
  static const harborInset = Color(0xFF080F1D);
  static const lightCanvas = Color(0xFFF4F7FB);
  static const paper = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF0F172A);
  static const lightOnSurfaceVariant = Color(0xFF475569);
  static const darkOnSurface = Color(0xFFDDE2F3);
  static const darkOnSurfaceVariant = Color(0xFFBBC9CD);
  static const lightOutline = Color(0xFFCBD5E1);
  static const darkOutline = Color(0xFF52636C);
  static const success = Color(0xFF10B981);
  static const successBright = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFF43F5E);
  static const dangerBright = Color(0xFFFB7185);
  static const slate = Color(0xFF94A3B8);
}

class MakkoSemanticColors extends ThemeExtension<MakkoSemanticColors> {
  final Color todo;
  final Color inProgress;
  final Color done;
  final Color high;
  final Color medium;
  final Color low;
  final Color bug;
  final Color task;

  const MakkoSemanticColors({
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.high,
    required this.medium,
    required this.low,
    required this.bug,
    required this.task,
  });

  @override
  MakkoSemanticColors copyWith({
    Color? todo,
    Color? inProgress,
    Color? done,
    Color? high,
    Color? medium,
    Color? low,
    Color? bug,
    Color? task,
  }) => MakkoSemanticColors(
    todo: todo ?? this.todo,
    inProgress: inProgress ?? this.inProgress,
    done: done ?? this.done,
    high: high ?? this.high,
    medium: medium ?? this.medium,
    low: low ?? this.low,
    bug: bug ?? this.bug,
    task: task ?? this.task,
  );

  @override
  MakkoSemanticColors lerp(
    ThemeExtension<MakkoSemanticColors>? other,
    double t,
  ) {
    if (other is! MakkoSemanticColors) return this;
    return MakkoSemanticColors(
      todo: Color.lerp(todo, other.todo, t)!,
      inProgress: Color.lerp(inProgress, other.inProgress, t)!,
      done: Color.lerp(done, other.done, t)!,
      high: Color.lerp(high, other.high, t)!,
      medium: Color.lerp(medium, other.medium, t)!,
      low: Color.lerp(low, other.low, t)!,
      bug: Color.lerp(bug, other.bug, t)!,
      task: Color.lerp(task, other.task, t)!,
    );
  }
}

extension MakkoThemeContext on BuildContext {
  MakkoSemanticColors get makkoSemantics =>
      Theme.of(this).extension<MakkoSemanticColors>()!;
}

class MakkoShapes {
  static const radiusSm = 4.0;
  static const radius = 12.0;
  static const radiusMd = 14.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
  static const radiusFull = 9999.0;
  static const screenPadding = 16.0;
  static const gutter = 12.0;
  static const stackGap = 8.0;
  static const touchTarget = 48.0;
}

class MakkoText {
  static TextTheme get textTheme {
    final base = GoogleFonts.hankenGroteskTextTheme();
    return base.copyWith(
      displaySmall: GoogleFonts.hankenGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.hankenGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.hankenGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.33,
      ),
      titleMedium: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      labelSmall: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: MakkoColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCFFAFE),
      onPrimaryContainer: Color(0xFF083344),
      secondary: Color(0xFF0E7490),
      onSecondary: Colors.white,
      surface: MakkoColors.paper,
      onSurface: MakkoColors.lightOnSurface,
      surfaceContainerLowest: MakkoColors.lightCanvas,
      surfaceContainerLow: Color(0xFFF8FAFC),
      surfaceContainer: Color(0xFFF1F5F9),
      surfaceContainerHigh: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFFCBD5E1),
      onSurfaceVariant: MakkoColors.lightOnSurfaceVariant,
      outline: MakkoColors.lightOutline,
      outlineVariant: Color(0xFFE2E8F0),
      error: Color(0xFFBE123C),
      onError: Colors.white,
      errorContainer: Color(0xFFFFE4E6),
      onErrorContainer: Color(0xFF881337),
    ),
    semantics: const MakkoSemanticColors(
      todo: Color(0xFF64748B),
      inProgress: MakkoColors.lightPrimary,
      done: Color(0xFF059669),
      high: Color(0xFFE11D48),
      medium: Color(0xFFD97706),
      low: Color(0xFF64748B),
      bug: Color(0xFFE11D48),
      task: MakkoColors.lightPrimary,
    ),
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: MakkoColors.primary,
      onPrimary: Color(0xFF00363E),
      primaryContainer: Color(0xFF164E63),
      onPrimaryContainer: Color(0xFFA5F3FC),
      secondary: Color(0xFF67E8F9),
      onSecondary: Color(0xFF00363E),
      surface: MakkoColors.harborSurface,
      onSurface: MakkoColors.darkOnSurface,
      surfaceContainerLowest: MakkoColors.deepHarbor,
      surfaceContainerLow: MakkoColors.harborSurface,
      surfaceContainer: MakkoColors.harborElevated,
      surfaceContainerHigh: Color(0xFF182742),
      surfaceContainerHighest: Color(0xFF243653),
      onSurfaceVariant: MakkoColors.darkOnSurfaceVariant,
      outline: MakkoColors.darkOutline,
      outlineVariant: Color(0xFF293A4D),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
    ),
    semantics: const MakkoSemanticColors(
      todo: MakkoColors.slate,
      inProgress: MakkoColors.primary,
      done: MakkoColors.successBright,
      high: MakkoColors.dangerBright,
      medium: MakkoColors.warning,
      low: MakkoColors.slate,
      bug: MakkoColors.dangerBright,
      task: MakkoColors.primary,
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
    required MakkoSemanticColors semantics,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      textTheme: MakkoText.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      extensions: [semantics],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radius),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radius),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(MakkoShapes.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MakkoShapes.radius),
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(MakkoShapes.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MakkoShapes.radius),
          ),
          side: BorderSide(color: scheme.outline),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(
            fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radiusFull),
        ),
        labelStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
