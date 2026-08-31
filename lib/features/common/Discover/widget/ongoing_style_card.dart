import 'dart:ui' as ui;

import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:flutter/material.dart';

/// The pill surface the Discover "Your Ongoing Ride/Booking" chip is made of.
///
/// Two looks, one object:
///
///   * Under a [DiscoverSurfaceTheme] — which is every in-flight card on the
///     Discover landing page — it paints that page's section surface, so the
///     ride, the pending order and the recent orders are the same material as
///     the panels around them.
///   * With no scope, its own look: a soft left-to-right gradient, a hairline
///     border in [accent], a 14pt radius and a low lift.
///
/// Extracted so the recent-order cards can be the same object rather than a
/// copy of its decoration — the two sit directly above and below each other on
/// Discover, so any drift between them is immediately visible.
///
/// The card carries only the surface. What goes inside is the caller's — a ride
/// needs a blinking OTP pill and a live distance, an order needs a message
/// preview and an unread badge, and pushing both through one parameter list
/// would make the shared piece harder to read than the duplication it saves.
class OngoingStyleCard extends StatelessWidget {
  const OngoingStyleCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.accent,
    required this.gradient,
  });

  final Widget child;
  final VoidCallback onTap;

  /// Border tint. Also the colour the content is expected to key its icons and
  /// action buttons to, so the card reads as one object.
  final Color accent;

  /// Two-stop fill, painted left to right.
  final List<Color> gradient;

  /// Live ride — warm peach into mint.
  static const List<Color> liveGradient = [
    Color(0xFFFFF0E4),
    Color(0xFFE7F7EC),
  ];

  /// Finished ride — mint into a cool blue.
  static const List<Color> doneGradient = [
    Color(0xFFE7F7EC),
    Color(0xFFEAF3FF),
  ];

  /// Recent order / inquiry thread — a cool blue wash. Deliberately NOT the
  /// live-ride peach: the two stack on the same screen, and a ride happening
  /// right now has to stay the loudest thing on it.
  static const List<Color> orderGradient = [
    Color(0xFFEAF3FF),
    Color(0xFFF3F0FF),
  ];

  static const Color liveAccent = Color(0xFFFF8A3D);
  static const Color doneAccent = Color(0xFF1FA463);
  static const Color orderAccent = Color(0xFF2F6BFF);

  @override
  Widget build(BuildContext context) {
    // Under a [DiscoverSurfaceTheme] the card wears that page's section
    // surface instead of its own gradient, so the in-flight stack (ride,
    // pending order, recent orders) reads as the same material as the panels
    // it sits among rather than as a strip of coloured pills laid over them.
    //
    // [accent] is unchanged either way: it was always the key for the CONTENT
    // — the icons, the OTP pill, the action buttons — and that is what still
    // tells a live ride apart from a finished one once the fill is shared.
    final surface = DiscoverSurfaceTheme.maybeOf(context);
    final radius = BorderRadius.circular(surface == null ? 14 : surface.radius);

    final decoration = surface == null
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradient,
            ),
            borderRadius: radius,
            border: Border.all(color: accent.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14101828),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          )
        : BoxDecoration(
            color: surface.fill,
            borderRadius: radius,
            border: Border.all(
              color: surface.border,
              width: surface.strokeWidth ?? 1,
            ),
          );

    Widget card = Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: decoration,
      child: child,
    );

    // The scoped surface is translucent and specified with a blur, so it needs
    // the same clip + BackdropFilter the other panels use. Skipped entirely in
    // the gradient case, which is opaque and must not pay for a saveLayer.
    if (surface != null) {
      card = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: surface.blur,
            sigmaY: surface.blur,
          ),
          child: card,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        // Shadow OUTSIDE the clip — a ClipRRect crops its child, so a shadow
        // declared inside it is cropped away with the rest.
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: surface == null ? const [] : surface.shadow ?? const [],
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}
