import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/visiting_card/helper/visiting_card_helper.dart';
import 'package:flutter/material.dart';

class VisitingCardShareButton extends StatelessWidget {
  final GlobalKey cardKey;
  final double? bottom;
  final double? right;

  const VisitingCardShareButton({
    super.key,
    required this.cardKey,
    this.bottom = 10,
    this.right = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: InkWell(
        onTap: () async {
          await VisitingCardHelper().shareVisitingCard(cardKey);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            boxShadow: [
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.3), // Added opacity for better shadow look
                blurRadius: 6,
                spreadRadius: 2,
              )
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.ios_share,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}