import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP COLORS — Single source of truth for the entire Borrow application
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Brand Blue ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF06B6D4); // Cyan highlight

  // ── Containers ───────────────────────────────────────────────────────────
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color secondaryContainer = Color(0xFFCFFAFE);
  static const Color accentContainer = Color(0xFFE0F7FA);

  // ── Semantic ─────────────────────────────────────────────────────────────
  /// Success / Available / Completed — intentionally kept green
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF16A34A);

  /// Warning / Reserved
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);

  /// Error / Rejected / Danger
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);

  /// Info
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color statusAvailable = Color(0xFF22C55E);   // green  ✓
  static const Color statusAvailableContainer = Color(0xFFDCFCE7);
  static const Color statusBorrowed = Color(0xFF2563EB);    // blue
  static const Color statusBorrowedContainer = Color(0xFFDBEAFE);
  static const Color statusReserved = Color(0xFFF59E0B);    // amber
  static const Color statusReservedContainer = Color(0xFFFEF3C7);
  static const Color statusUnavailable = Color(0xFF94A3B8); // slate
  static const Color statusUnavailableContainer = Color(0xFFF1F5F9);
  static const Color statusRejected = Color(0xFFEF4444);    // red
  static const Color statusRejectedContainer = Color(0xFFFEE2E2);
  static const Color statusCompleted = Color(0xFF22C55E);   // green ✓
  static const Color statusCompletedContainer = Color(0xFFDCFCE7);
  static const Color statusPending = Color(0xFFF59E0B);     // amber

  // ── Surface & Background ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSuccess = Color(0xFFFFFFFF);

  // ── Border & Divider ─────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFCBD5E1);

  // ── Field ────────────────────────────────────────────────────────────────
  static const Color fieldFill = Color(0xFFF8FAFC);
  static const Color fieldFillFocused = Color(0xFFEFF6FF);
  static const Color fieldBorder = Color(0xFFE2E8F0);

  // ── Card ─────────────────────────────────────────────────────────────────
  static const Color cardSurface = Color(0xFFFFFFFF);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBackground = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// APP RADIUS — Consistent border-radius tokens
// ─────────────────────────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;

  static BorderRadius get circular_xs => BorderRadius.circular(xs);
  static BorderRadius get circular_sm => BorderRadius.circular(sm);
  static BorderRadius get circular_md => BorderRadius.circular(md);
  static BorderRadius get circular_lg => BorderRadius.circular(lg);
  static BorderRadius get circular_xl => BorderRadius.circular(xl);
  static BorderRadius get circular_xxl => BorderRadius.circular(xxl);
  static BorderRadius get circular_full => BorderRadius.circular(full);
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SHADOWS — Subtle elevation helpers
// ─────────────────────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> bottomBar = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// APP TYPOGRAPHY — Material 3 text theme
// ─────────────────────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  static const TextTheme textTheme = TextTheme(
    // ── Display ─────────────────────────────────────────────────────────
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.25,
      color: AppColors.textPrimary,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w300,
      color: AppColors.textPrimary,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.22,
    ),
    // ── Headline ─────────────────────────────────────────────────────────
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.textPrimary,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.33,
    ),
    // ── Title ─────────────────────────────────────────────────────────────
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimary,
      height: 1.43,
    ),
    // ── Body ──────────────────────────────────────────────────────────────
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppColors.textPrimary,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
      height: 1.33,
    ),
    // ── Label ─────────────────────────────────────────────────────────────
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.textPrimary,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textSecondary,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textSecondary,
      height: 1.45,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME — Full Material 3 ThemeData factory
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    // Primary
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.textPrimary,
    // Secondary (Cyan accent)
    secondary: AppColors.accent,
    onSecondary: AppColors.textOnPrimary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.textPrimary,
    // Tertiary (Blue secondary)
    tertiary: AppColors.secondary,
    onTertiary: AppColors.textOnPrimary,
    tertiaryContainer: AppColors.primaryContainer,
    onTertiaryContainer: AppColors.textPrimary,
    // Error
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.textPrimary,
    // Surface
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    // Outline
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    // Other
    shadow: Color(0xFF0F172A),
    scrim: Color(0xFF0F172A),
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: Colors.white,
    inversePrimary: AppColors.primaryContainer,
    surfaceTint: AppColors.primary,
  );

  /// Build the complete light [ThemeData] for the Borrow application.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        actionsIconTheme:
            IconThemeData(color: AppColors.textSecondary, size: 22),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
          fontFamily: 'Roboto',
        ),
      ),

      // ── Navigation Bar (bottom) ─────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.border,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: 'Roboto',
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            fontFamily: 'Roboto',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(
              color: AppColors.textSecondary, size: 22);
        }),
      ),

      // ── Navigation Rail ─────────────────────────────────────────────────
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme:
            IconThemeData(color: AppColors.primary, size: 22),
        unselectedIconTheme:
            IconThemeData(color: AppColors.textSecondary, size: 22),
        selectedLabelTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primaryContainer,
        elevation: 0,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        shape: CircleBorder(),
        extendedTextStyle:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          minimumSize: const Size(0, 48),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          minimumSize: const Size(0, 48),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1),
        ),
      ),

      // ── Input Decoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle:
            const TextStyle(color: AppColors.textDisabled, fontSize: 14),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textSecondary,
        floatingLabelStyle:
            const TextStyle(color: AppColors.primary, fontSize: 14),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.border,
        deleteIconColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: true,
        checkmarkColor: AppColors.primary,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        contentTextStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxWidth: double.infinity),
      ),

      // ── SnackBar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14),
        actionTextColor: AppColors.primaryContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Switch ──────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryContainer;
          }
          return AppColors.border;
        }),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Checkbox ────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4)),
      ),

      // ── Radio ───────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
      ),

      // ── Progress Indicator ──────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryContainer,
        circularTrackColor: AppColors.primaryContainer,
        linearMinHeight: 6,
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Popup Menu ──────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: const TextStyle(
            fontSize: 14, color: AppColors.textPrimary),
      ),

      // ── Date Picker ─────────────────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textDisabled;
          }
          return AppColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        todayForegroundColor:
            WidgetStateProperty.all(AppColors.primary),
        todayBorder: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        dayOverlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return AppColors.primaryContainer;
          }
          return Colors.transparent;
        }),
      ),

      // ── Slider ──────────────────────────────────────────────────────────
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primaryContainer,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x1A2563EB),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),

      // ── Tab Bar ─────────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.divider,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // ── List Tile ───────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        tileColor: Colors.transparent,
        selectedColor: AppColors.primary,
        selectedTileColor: AppColors.primaryContainer,
        minLeadingWidth: 0,
        minVerticalPadding: 8,
      ),

      // ── Search Bar ──────────────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        backgroundColor:
            WidgetStateProperty.all(AppColors.fieldFill),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        surfaceTintColor:
            WidgetStateProperty.all(Colors.transparent),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md))),
        textStyle: WidgetStateProperty.all(
            const TextStyle(color: AppColors.textPrimary)),
        hintStyle: WidgetStateProperty.all(
            const TextStyle(color: AppColors.textDisabled)),
      ),

      // ── Icon ────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),

      // ── Text Selection ──────────────────────────────────────────────────
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryContainer,
        selectionHandleColor: AppColors.primary,
      ),

      // ── Tooltip ─────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle:
            const TextStyle(color: Colors.white, fontSize: 12),
      ),

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: AppTypography.textTheme,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SNACKBAR HELPERS — Semantic snack bars using AppColors
// ─────────────────────────────────────────────────────────────────────────────

class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
    ));
  }

  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
    ));
  }

  static void info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
    ));
  }

  static void warning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT BUTTON — Reusable primary gradient button widget
// ─────────────────────────────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width = double.infinity,
    this.height = 52,
    this.borderRadius = AppRadius.md,
    this.textStyle,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              gradient: onPressed != null
                  ? AppColors.gradientPrimary
                  : const LinearGradient(
                      colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)]),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: textStyle ??
                              const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.1,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
