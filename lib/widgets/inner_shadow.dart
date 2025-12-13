import 'package:flutter/material.dart';

class InnerShadow extends StatelessWidget {
  final Widget child;
  final List<BoxShadow> shadows;

  const InnerShadow({required this.child, this.shadows = const [], super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InnerShadowPainter(shadows),
      child: child,
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final List<BoxShadow> shadows;

  _InnerShadowPainter(this.shadows);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // fill the whole area (optional background)
    final paint = Paint()..color = Colors.transparent;
    canvas.drawRect(rect, paint);

    // draw every shadow **inward**
    for (final shadow in shadows) {
      final shadowPaint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);
      canvas.drawRect(rect.deflate(shadow.spreadRadius), shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}