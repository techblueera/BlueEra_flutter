import 'package:flutter/material.dart';

class HalfScreenTabIndicator extends Decoration {
  final Color color;
  final double thickness;

  const HalfScreenTabIndicator({required this.color, this.thickness = 2});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _HalfScreenPainter(color: color, thickness: thickness);
  }
}

class _HalfScreenPainter extends BoxPainter {
  final Color color;
  final double thickness;

  _HalfScreenPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    final screenWidth = WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;
    final double indicatorWidth = screenWidth / 2;
    final double dx = offset.dx + (config.size!.width - indicatorWidth) / 2;
    final double dy = offset.dy + config.size!.height - thickness / 2;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(dx, dy), Offset(dx + indicatorWidth, dy), paint);
  }
}

