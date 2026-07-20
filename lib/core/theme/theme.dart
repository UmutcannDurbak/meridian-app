import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Typography.
///
/// Two faces, each with one job:
///   Newsreader — a text serif, not a display serif. Carries the authority of
///     a register or ledger without tipping into editorial/broadsheet styling.
///     Used ONLY for large figures and screen titles.
///   Inter — everything else. Chosen specifically because its tabular figure
///     set is excellent, and this product is a column of dates and amounts
///     that must align vertically. Proportional figures would ruin it.
///
/// Both are bundled as local assets (assets/fonts/) rather than fetched at
/// runtime via google_fonts — this app's own typography shouldn't depend on
/// network access to render at all, let alone fail loudly when it can't.
///
/// Every numeric style below enables tabular figures. This is not optional.
abstract final class Type {
  static const _tabular = [FontFeature.tabularFigures()];
  static const _inter = 'Inter';
  static const _newsreader = 'Newsreader';

  static TextStyle display(Color c) => TextStyle(
        fontFamily: _newsreader,
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        color: c,
      );

  static TextStyle title(Color c) => TextStyle(
        fontFamily: _newsreader,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: c,
      );

  static TextStyle heading(Color c) => TextStyle(
        fontFamily: _inter,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: c,
      );

  static TextStyle body(Color c) => TextStyle(
        fontFamily: _inter,
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle label(Color c) => TextStyle(
        fontFamily: _inter,
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: c,
      );

  /// Section eyebrows: "OVERDUE", "THIS WEEK". Wide tracking, small size.
  static TextStyle eyebrow(Color c) => TextStyle(
        fontFamily: _inter,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: c,
      );

  /// Dates and counters in list rows.
  static TextStyle numeric(Color c) => TextStyle(
        fontFamily: _inter,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        fontFeatures: _tabular,
        color: c,
      );

  /// Monetary values. Serif, because money is the argument this product makes.
  static TextStyle amount(Color c) => TextStyle(
        fontFamily: _newsreader,
        fontSize: 17,
        height: 1.2,
        fontWeight: FontWeight.w500,
        fontFeatures: _tabular,
        color: c,
      );
}

/// Palette resolved for the current brightness, read via `context.tone`.
@immutable
class ToneScheme extends ThemeExtension<ToneScheme> {
  const ToneScheme({
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.paper,
    required this.surface,
    required this.hairline,
  });

  final Color ink, inkMuted, inkFaint, paper, surface, hairline;

  static const light = ToneScheme(
    ink: Tone.ink,
    inkMuted: Tone.inkMuted,
    inkFaint: Tone.inkFaint,
    paper: Tone.paper,
    surface: Tone.surface,
    hairline: Tone.hairline,
  );

  static const dark = ToneScheme(
    ink: Tone.inkDark,
    inkMuted: Tone.inkMutedDark,
    inkFaint: Tone.inkFaintDark,
    paper: Tone.paperDark,
    surface: Tone.surfaceDark,
    hairline: Tone.hairlineDark,
  );

  @override
  ToneScheme copyWith({
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? paper,
    Color? surface,
    Color? hairline,
  }) =>
      ToneScheme(
        ink: ink ?? this.ink,
        inkMuted: inkMuted ?? this.inkMuted,
        inkFaint: inkFaint ?? this.inkFaint,
        paper: paper ?? this.paper,
        surface: surface ?? this.surface,
        hairline: hairline ?? this.hairline,
      );

  @override
  ToneScheme lerp(ThemeExtension<ToneScheme>? other, double t) {
    if (other is! ToneScheme) return this;
    return ToneScheme(
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
    );
  }
}

extension ToneContext on BuildContext {
  ToneScheme get tone => Theme.of(this).extension<ToneScheme>()!;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, ToneScheme.light);
  static ThemeData dark() => _build(Brightness.dark, ToneScheme.dark);

  static ThemeData _build(Brightness b, ToneScheme t) {
    // Deliberately not ColorScheme.fromSeed. A seeded scheme derives a full
    // set of tinted colours from one seed and hands them to every Material
    // widget we haven't explicitly themed — which is how a monochrome app
    // ends up with a blue-ish switch thumb or focus ring. Every slot here
    // is set by hand to something from Tone or Pressure, so there is no
    // colour any component can fall back to that isn't one of the two.
    final scheme = b == Brightness.light
        ? ColorScheme(
            brightness: b,
            primary: t.ink,
            onPrimary: t.paper,
            secondary: t.inkMuted,
            onSecondary: t.paper,
            error: Pressure.closing,
            onError: t.paper,
            surface: t.surface,
            onSurface: t.ink,
            outline: t.hairline,
            outlineVariant: t.hairline,
            surfaceContainerHighest: t.surface,
          )
        : ColorScheme(
            brightness: b,
            primary: t.ink,
            onPrimary: t.paper,
            secondary: t.inkMuted,
            onSecondary: t.paper,
            error: Pressure.closing,
            onError: t.paper,
            surface: t.surface,
            onSurface: t.ink,
            outline: t.hairline,
            outlineVariant: t.hairline,
            surfaceContainerHighest: t.surface,
          );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: t.paper,
      colorScheme: scheme,
      extensions: [t],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,

      dividerTheme: DividerThemeData(
        color: t.hairline,
        thickness: 1,
        space: 1,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Flat and left-aligned, matching the inline "Horizon"/"Timeline"
      // headers on the tab screens — an AppBar here is for a pushed
      // screen's back action, not a second layer of chrome.
      appBarTheme: AppBarTheme(
        backgroundColor: t.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: t.ink, size: 22),
        titleTextStyle: Type.heading(t.ink),
      ),

      iconTheme: IconThemeData(color: t.inkMuted, size: 22),

      // Solid ink fill, flat — no drop shadow. This is the one button that
      // matters most in the app (Save/Confirm/Import), and it should read
      // as certain, not as a generic Material raised button.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.ink,
          foregroundColor: t.paper,
          disabledBackgroundColor: t.inkFaint,
          disabledForegroundColor: t.paper,
          elevation: 0,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          textStyle: Type.heading(t.paper),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          side: BorderSide(color: t.hairline),
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          textStyle: Type.heading(t.ink),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.inkMuted,
          textStyle: Type.label(t.inkMuted),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: t.inkMuted),
      ),

      // No filled bucket, no rounded pill, no blue focus border — a single
      // hairline that turns ink on focus. This is the one place a "premium"
      // reading of restraint is most easily lost to Material defaults.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: Space.sm,
        ),
        labelStyle: Type.label(t.inkMuted),
        floatingLabelStyle: Type.label(t.inkMuted),
        hintStyle: Type.body(t.inkFaint),
        errorStyle: Type.label(Pressure.closing),
        border: UnderlineInputBorder(borderSide: BorderSide(color: t.hairline)),
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: t.hairline)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.ink)),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Pressure.closing),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Pressure.closing),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? t.ink : t.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? t.inkMuted : t.hairline,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? t.ink : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? t.paper : t.ink,
          ),
          side: WidgetStateProperty.all(BorderSide(color: t.hairline)),
          textStyle: WidgetStateProperty.all(Type.label(t.ink)),
        ),
      ),

      // Flat ink square with soft corners, no drop shadow — a shadowed
      // circle is the single most "generic Flutter app" tell there is, and
      // this button (capture) is the app's highest-value action.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.ink,
        foregroundColor: t.paper,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      bottomAppBarTheme: BottomAppBarThemeData(
        color: t.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: t.inkMuted,
        textColor: t.ink,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.ink,
        contentTextStyle: Type.body(t.paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
    );
  }
}
