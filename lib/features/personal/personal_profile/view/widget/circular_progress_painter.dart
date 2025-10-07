import 'dart:math';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final bool isMyProfile;

  CircleProgressPainter(this.progress, {this.isMyProfile = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 3.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - strokeWidth / 2;

    // background circle
    final Paint bgPaint = Paint()
      ..color = isMyProfile ? AppColors.white.withValues(alpha: 0.1) : AppColors.primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // progress arc
    final Paint progressPaint = Paint()
      ..color = isMyProfile ? AppColors.white : AppColors.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // draw base
    canvas.drawCircle(center, radius, bgPaint);

    // draw arc progress
    double startAngle = -pi / 2;
    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isMyProfile != isMyProfile;
  }
}