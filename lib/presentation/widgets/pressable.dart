import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Tap feedback for everything that isn't a themed button.
///
/// The app-wide theme sets `splashFactory: NoSplash` and transparent
/// highlight/hover colours — deliberately, because Android's ink ripple
/// reads as generic and tends to leak a tinted circle into a monochrome UI.
/// But turning it off with nothing in its place leaves every bare `InkWell`
/// (list rows, sheet options, nav items) dead on tap, which reads as
/// unresponsive rather than restrained. This is the replacement: a small
/// opacity + scale dip, the same gesture iOS uses for its own controls.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.borderRadius,
    this.scale = 0.97,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final BorderRadius? borderRadius;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: Motion.fast,
        curve: Motion.easing,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.72 : 1.0,
          duration: Motion.fast,
          curve: Motion.easing,
          child: widget.child,
        ),
      ),
    );
  }
}
