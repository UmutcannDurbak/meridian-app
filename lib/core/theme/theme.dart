import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
/// Every numeric style below enables tabular figures. This is not optional.
abstract final class Type {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle display(Color c) => GoogleFonts.newsreader(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        color: c,
      );

  static TextStyle title(Color c) => GoogleFonts.newsreader(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w500,
        color: c,
      );

  static TextStyle heading(Color c) => GoogleFonts.inter(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: c,
      );

  static TextStyle body(Color c) => GoogleFonts.inter(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle label(Color c) => GoogleFonts.inter(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: c,
      );

  /// Section eyebrows: "OVERDUE", "THIS WEEK". Wide tracking, small size.
  static TextStyle eyebrow(Color c) => GoogleFonts.inter(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: c,
      );

  /// Dates and counters in list rows.
  static TextStyle numeric(Color c) => GoogleFonts.inter(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w500,
        fontFeatures: _tabular,
        color: c,
      );

  /// Monetary values. Serif, because money is the argument this product makes.
  static TextStyle amount(Color c) => GoogleFonts.newsreader(
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
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: t.paper,
      // Seeded from the calm end of the pressure ramp so that any Material
      // widget we haven't explicitly themed degrades quietly rather than
      // injecting an unrelated colour into a monochrome interface.
      colorScheme: ColorScheme.fromSeed(
        seedColor: Pressure.dormant,
        brightness: b,
        surface: t.surface,
      ),
      extensions: [t],
      dividerTheme: DividerThemeData(
        color: t.hairline,
        thickness: 1,
        space: 1,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
