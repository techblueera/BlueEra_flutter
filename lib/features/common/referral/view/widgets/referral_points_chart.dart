import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';


class ReferralPointsChart extends StatelessWidget {
  final int subscribe;
  final int unSubscribe;
  final int expired;

  const ReferralPointsChart({
    Key? key,
    required this.subscribe,
    required this.unSubscribe,
    required this.expired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int total = subscribe + unSubscribe + expired;

    final double subPercent = total == 0 ? 0 : subscribe / total;
    final double unSubPercent = total == 0 ? 0 : unSubscribe / total;
    final double expPercent = total == 0 ? 0 : expired / total;

    return Container(
      // margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          /// CIRCULAR SEGMENT GRAPH
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Subscribe (Green)
                CircularPercentIndicator(
                  radius: 100,
                  lineWidth: 14,
                  percent: subPercent.clamp(0, 1),
                  backgroundColor: Colors.transparent,
                  progressColor: const Color(0xFF43A047),
                  circularStrokeCap: CircularStrokeCap.round,
                ),

                /// Unsubscribe (Yellow)
                CircularPercentIndicator(
                  radius: 100,
                  lineWidth: 14,
                  percent: (subPercent + unSubPercent).clamp(0, 1),
                  backgroundColor: Colors.transparent,
                  progressColor: const Color(0xFFF4B400),
                  circularStrokeCap: CircularStrokeCap.round,
                ),

                /// Expired (Red)
                CircularPercentIndicator(
                  radius: 100,
                  lineWidth: 14,
                  percent: 1,
                  backgroundColor: Colors.transparent,
                  progressColor: Colors.green,
                  circularStrokeCap: CircularStrokeCap.round,
                ),

                /// CENTER TEXT
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      "Referral Count",
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      total.toString(),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.coloGreyText.withOpacity(0.3)),
          const SizedBox(height: 12),

          /// LEGEND
          _legendItem(
            color: const Color(0xFF43A047),
            title: "Subscribe",
            value: subscribe,
          ),
          const SizedBox(height: 12),
          _legendItem(
            color: const Color(0xFFF4B400),
            title: "Un-Subscribe",
            value: unSubscribe,
          ),
          const SizedBox(height: 12),
          _legendItem(
            color: const Color(0xFFD64A3A),
            title: "Expired",
            value: expired,
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String title,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            title,
            fontSize: 16,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        CustomText(
          value.toString(),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }
}