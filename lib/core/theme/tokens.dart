import 'package:flutter/widgets.dart';

/// Design tokens for Meridian.
///
/// Rule that governs this entire palette: the interface is monochrome
/// ink-on-slate. The ONLY chromatic elements in the app are the pressure
/// ramp colours below, which encode proximity to an action deadline.
///
/// If colour appears anywhere else, it is a bug. This is what lets a user
/// with 200 obligations scan a screen and know instantly where to look.
abstract final class Tone {
  // Light — "slate paper"
  static const ink = Color(0xFF1B2430); // primary text, near-navy not black
  static const inkMuted = Color(0xFF6B7787); // secondary text
  static const inkFaint = Color(0xFF9AA4B0); // tertiary, placeholders
  static const paper = Color(0xFFEDEFF2); // app background
  static const surface = Color(0xFFF7F8FA); // cards, rows
  static const hairline = Color(0xFFDDE1E6); // 1px rules and dividers

  // Dark
  static const inkDark = Color(0xFFE8EBEF);
  static const inkMutedDark = Color(0xFF8B96A3);
  static const inkFaintDark = Color(0xFF5C6672);
  static const paperDark = Color(0xFF0E1319);
  static const surfaceDark = Color(0xFF171E26);
  static const hairlineDark = Color(0xFF262F3A);
}

/// The pressure ramp. The only colour in the product.
///
/// Deliberately NOT a green→yellow→red traffic light: green reads as
/// "complete" and this product never has a resting complete state, and a
/// full traffic light spends colour on the calm case where none is needed.
/// Calm is a desaturated slate that barely registers as colour at all.
abstract final class Pressure {
  static const dormant = Color(0xFF5B7C99); // window not yet open
  static const open = Color(0xFFC8862A); // inside the action window
  static const closing = Color(0xFFB4471F); // < 20% of window remains
  static const lapsed = Color(0xFF8B1E1E); // deadline passed

  /// Interpolates the ramp for a window that is [fraction] consumed (0..1).
  static Color at(double fraction) {
    if (fraction <= 0) return dormant;
    if (fraction >= 1) return lapsed;
    if (fraction < 0.8) {
      return Color.lerp(open, closing, fraction / 0.8)!;
    }
    return Color.lerp(closing, lapsed, (fraction - 0.8) / 0.2)!;
  }
}

/// 8pt grid. No arbitrary padding anywhere in the app.
abstract final class Space {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const huge = 64.0;
}

abstract final class Radii {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 16.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 380);
  static const easing = Curves.easeOutCubic;
}
