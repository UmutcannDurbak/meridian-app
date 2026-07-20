import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';

/// The signature element of the product.
///
/// Every other reminder app draws a progress bar filling toward a due date.
/// That is the wrong model here, because a deadline in this product is not a
/// point — it is a WINDOW that opens and then closes. Before it opens there is
/// nothing to do. Once it closes the decision is gone.
///
/// So the bar draws the window as a segment on a longer track, with a marker
/// for now. A user reads three things in one glance without a number:
///   is the window open, how much of it is left, and where does it end.
///
/// This is also the only place in the entire app where colour appears.
class ActionWindowBar extends StatelessWidget {
  const ActionWindowBar({
    super.key,
    required this.pressure,
    required this.windowStartFraction,
    this.height = 3,
  });

  /// 0..1 — how much of the decision window has been consumed.
  final double pressure;

  /// 0..1 — where on the track the window opens.
  final double windowStartFraction;

  final double height;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final colour = Pressure.at(pressure);
    final open = pressure > 0;

    return Semantics(
      label: open
          ? 'Action window open, ${(pressure * 100).round()} percent elapsed'
          : 'Action window not yet open',
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final start = (windowStartFraction.clamp(0.0, 1.0)) * w;
            final head = start + (w - start) * pressure.clamp(0.0, 1.0);

            return Stack(
              children: [
                // Full track: the dormant period before the window opens.
                Container(
                  width: w,
                  height: height,
                  decoration: BoxDecoration(
                    color: tone.hairline,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
                // The window itself, drawn only once it has opened.
                if (open)
                  AnimatedPositioned(
                    duration: Motion.base,
                    curve: Motion.easing,
                    left: start,
                    child: Container(
                      width: (head - start).clamp(2.0, w),
                      height: height,
                      decoration: BoxDecoration(
                        color: colour,
                        borderRadius: BorderRadius.circular(height),
                      ),
                    ),
                  ),
                // Terminal mark: where the window closes. Always visible, so
                // the end of the decision period is legible even when far off.
                Positioned(
                  left: w - 1.5,
                  child: Container(
                    width: 1.5,
                    height: height,
                    color: open ? colour : tone.inkFaint,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
