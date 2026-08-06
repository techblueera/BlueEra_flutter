import 'package:flutter/material.dart';

/// The pill surface the Discover "Your Ongoing Ride/Booking" chip is made of:
/// a soft left-to-right gradient, a hairline border in the accent colour, a
/// 14pt radius and a low lift.
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14101828),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
