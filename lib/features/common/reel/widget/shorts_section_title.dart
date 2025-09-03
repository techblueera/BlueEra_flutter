import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ShortsSectionTitle extends StatelessWidget {
  final String title;
  final double topPadding;
  final VoidCallback onViewAll;

  const ShortsSectionTitle({super.key, required this.title, required this.topPadding, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: SizeConfig.paddingXSL, right: SizeConfig.paddingXSL, bottom: SizeConfig.size15, top: topPadding),
      child:
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontWeight: FontWeight.w700,
            fontSize: SizeConfig.large,
          ),
          InkWell(
            onTap: onViewAll,
            child: CustomText(
              "View All",
              fontWeight: FontWeight.w500,
              fontSize: SizeConfig.medium,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      )
    );
  }
}
