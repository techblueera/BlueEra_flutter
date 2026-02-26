import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class WelcomeSubscriptionOfferText extends StatelessWidget {
  const WelcomeSubscriptionOfferText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        CustomText(
          'Welcome Offer!',
          fontSize: SizeConfig.large,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w600,
          textAlign: TextAlign.center,
        ),

        SizedBox(height: SizeConfig.size4),

        // Offer Highlight
        CustomText(
          'get 75% OFF today.',
          fontSize: SizeConfig.extraLarge,
          color: AppColors.greenShade,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}