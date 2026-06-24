import 'package:flutter/material.dart';

/// Paints a WhatsApp-style chat bubble background with an optional triangular
/// "tail" nub on the top corner of the message.
///
/// - Received messages: tail sits on the top-left, pointing outward to the left.
/// - Sent messages: tail sits on the top-right, pointing outward to the right.
///
/// The tail is only drawn for the FIRST message of a consecutive group (set
/// [showTail] = false for the subsequent messages so they read as a tight run,
/// exactly like WhatsApp).
class ChatBubblePainter extends CustomPainter {
  final Color color;
  final bool isReceive;
  final bool showTail;
  final double radius;
  final double tailWidth;

  const ChatBubblePainter({
    required this.color,
    required this.isReceive,
    required this.showTail,
    this.radius = 12,
    this.tailWidth = 7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final double r = radius;
    // Space the tail occupies on its side; 0 when no tail so the body fills.
    final double tw = showTail ? tailWidth : 0;

    // Body rectangle — inset by the tail width on the tail side.
    final double bodyLeft = isReceive ? tw : 0;
    final double bodyRight = isReceive ? size.width : size.width - tw;
    final Rect body = Rect.fromLTRB(bodyLeft, 0, bodyRight, size.height);

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          body,
          // Square the top corner where the tail attaches.
          topLeft: Radius.circular((isReceive && showTail) ? 0 : r),
          topRight: Radius.circular((!isReceive && showTail) ? 0 : r),
          bottomLeft: Radius.circular(r),
          bottomRight: Radius.circular(r),
        ),
      );

    if (showTail) {
      final Path tail = Path();
      if (isReceive) {
        // Top-left tail pointing left.
        tail.moveTo(tw, 0);
        tail.lineTo(0, 0);
        tail.quadraticBezierTo(tw * 0.45, r * 0.55, tw, r);
        tail.close();
      } else {
        // Top-right tail pointing right.
        tail.moveTo(size.width - tw, 0);
        tail.lineTo(size.width, 0);
        tail.quadraticBezierTo(
            size.width - tw * 0.45, r * 0.55, size.width - tw, r);
        tail.close();
      }
      path.addPath(tail, Offset.zero);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChatBubblePainter old) =>
      old.color != color ||
      old.isReceive != isReceive ||
      old.showTail != showTail ||
      old.radius != radius ||
      old.tailWidth != tailWidth;
}
