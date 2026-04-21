import 'dart:ui';

import 'package:flutter/material.dart';

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color borderColor;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const DashedBorderContainer({
    Key? key,
    required this.child,
    this.borderRadius = 12,
    this.borderColor = const Color(0xFFB0B4BF), // light grey
    this.strokeWidth = 1.2,
    this.dashLength = 6,
    this.gapLength = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        borderRadius: borderRadius,
        color: borderColor,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    _drawDashedRRect(canvas, rRect, paint);
  }

  void _drawDashedRRect(Canvas canvas, RRect rRect, Paint paint) {
    final Path path = Path()..addRRect(rRect);
    final PathMetrics metrics = path.computeMetrics();
    for (final PathMetric metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A single horizontal dashed line. Unlike [DashedBorderContainer], which
/// always paints a full rectangular border (and so stacks two near-identical
/// strokes when its child is only a 1px strip), this draws exactly one run
/// of dashes across the full width at the line's vertical midpoint.
class DashedHorizontalLine extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const DashedHorizontalLine({
    super.key,
    this.color = const Color(0xFFB0B4BF),
    this.strokeWidth = 1,
    this.dashLength = 8,
    this.gapLength = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: strokeWidth,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedHorizontalLinePainter(
          color: color,
          strokeWidth: strokeWidth,
          dashLength: dashLength,
          gapLength: gapLength,
        ),
      ),
    );
  }
}

class _DashedHorizontalLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedHorizontalLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final endX = (x + dashLength).clamp(0, size.width).toDouble();
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x = endX + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedHorizontalLinePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}