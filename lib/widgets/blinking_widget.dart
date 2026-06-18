import 'package:flutter/material.dart';

/// Wraps [child] in a repeating attention "blink" — a pulsing **coloured glow**
/// (halo) plus a slight scale. The child stays fully opaque (no fading to a
/// pale/light state); instead a saturated [glowColor] halo grows and brightens
/// to draw the eye. Used for the floating "Add …" CTAs on the Discover screens.
class BlinkingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  /// Colour of the pulsing glow. Defaults to the app primary blue.
  final Color glowColor;

  /// Should match the child's rounded shape so the glow hugs it (the Discover
  /// FAB pills use a 30 radius).
  final BorderRadius borderRadius;

  const BlinkingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 750),
    this.glowColor = const Color(0xFF0086FF),
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
  });

  @override
  State<BlinkingWidget> createState() => _BlinkingWidgetState();
}

class _BlinkingWidgetState extends State<BlinkingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat(reverse: true);

  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = _t.value; // 0 → 1
        return Transform.scale(
          scale: 1.0 + 0.06 * v,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.30 + 0.55 * v),
                  blurRadius: 12 + 16 * v,
                  spreadRadius: 1 + 5 * v,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
