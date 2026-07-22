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
  // Light — "slate paper". inkMuted and inkFaint are contrast-checked
  // against both paper and surface, not just picked by eye: inkMuted holds
  // ≥4.5:1 (WCAG AA for normal text — it carries real copy: subtitles,
  // labels, form hints). inkFaint holds ≥3.2:1, which clears the AA
  // threshold for large text and UI graphics (icons, the calendar's
  // weekday header) but not small body text — anything at inkFaint that
  // is the ONLY copy of information a user needs should be promoted to
  // inkMuted instead of leaned on at this tier. The original values here
  // (9AA4B0 / 6B7787) measured 2.2:1 and 3.95:1 — both failed AA outright.
  static const ink = Color(0xFF1B2430); // primary text, near-navy not black
  static const inkMuted = Color(0xFF666C75); // secondary text
  static const inkFaint = Color(0xFF80868D); // tertiary, placeholders
  static const paper = Color(0xFFEDEFF2); // app background
  static const surface = Color(0xFFF7F8FA); // cards, rows
  static const hairline = Color(0xFFDDE1E6); // 1px rules and dividers

  // Dark — already clears the same bars without adjustment (6.2:1 / 3.2:1
  // against paperDark) despite never having been checked when first
  // chosen; left as-is.
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
  // Each of these is a graphical indicator (ActionWindowBar's fill, the
  // calendar's day dot), never text — so the bar to clear is WCAG's 3:1
  // non-text contrast minimum against Tone.paper, not the 4.5:1 text
  // minimum. dormant/closing/lapsed already cleared it as originally
  // chosen; `open` (the amber "window is open" state — arguably the one
  // that most needs to actually be seen) measured 2.6:1 and was darkened
  // until it cleared 3.3:1, same hue.
  static const dormant = Color(0xFF5B7C99); // window not yet open
  static const open = Color(0xFFB17725); // inside the action window
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
