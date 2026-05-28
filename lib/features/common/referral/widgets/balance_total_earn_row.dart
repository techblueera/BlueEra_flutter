import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../../../../core/constants/app_strings.dart';

class BalanceTotalEarnRow extends StatelessWidget {
  final num balance;
  final num totalEarn;
  final num? estimatedEarning;

  /// When false the row renders as a plain `Row` (no CustomFormCard
  /// wrapper) so callers that already supply their own card can embed
  /// it without double-padding. Defaults to true to keep existing call
  /// sites working unchanged.
  final bool wrapInCard;

  const BalanceTotalEarnRow({
    super.key,
    required this.balance,
    required this.totalEarn,
    this.estimatedEarning,
    this.wrapInCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      _cell(AppStrings.balance.tr, balance),
      _divider(),
      _cell(AppStrings.totalEarn.tr, totalEarn),
      if (estimatedEarning != null) ...[
        _divider(),
        _cell(AppStrings.estdEarning.tr, estimatedEarning!),
      ],
    ];

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: cells,
    );

    if (!wrapInCard) return row;

    return CustomFormCard(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size12,
      ),
      child: row,
    );
  }

  Widget _cell(String label, num value) {
    return Expanded(
      child: Column(
        children: [
          CustomText(
            label,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
          ),
          SizedBox(height: SizeConfig.paddingM / 2),
          CustomText(
            '₹ ${value.toStringAsFixed(0).padLeft(2, '0')}',
            fontSize: SizeConfig.extraLarge,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  // Dashed separator — sits between the cells. Height is intentionally
  // shorter than the row so the rule reads as a divider, not as a full
  // edge.
  Widget _divider() => const _DashedVerticalLine(
        height: 40,
        thickness: 1,
        color: Color(0xFFDDE2EE),
      );
}

class _DashedVerticalLine extends StatelessWidget {
  final double height;
  final double thickness;
  final Color color;

  const _DashedVerticalLine({
    required this.height,
    required this.color,
    this.thickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: thickness,
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color, strokeWidth: thickness),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  static const double _dashLength = 4;
  static const double _dashGap = 3;

  final Color color;
  final double strokeWidth;

  _DashedLinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final centerX = size.width / 2;
    double y = 0;
    while (y < size.height) {
      final end = (y + _dashLength).clamp(0, size.height).toDouble();
      canvas.drawLine(Offset(centerX, y), Offset(centerX, end), paint);
      y += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
