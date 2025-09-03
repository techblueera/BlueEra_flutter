import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_delete_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class PortfolioSection extends StatelessWidget {
  final List<Map<String, String>> links;
  final VoidCallback onAddPressed;

  const PortfolioSection({required this.links, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText("Portfolio / Work Samples", color: AppColors.grey72, fontSize: SizeConfig.medium),
          SizedBox(height: SizeConfig.size15),
          Container(
            width: SizeConfig.screenWidth,
            padding: EdgeInsets.all(SizeConfig.size10),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey99, width: 0.5),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                ...links.asMap().entries.map((entry) {
                  final index = entry.key;
                  final link = entry.value;
                  final isLast = index == links.length - 1;

                  return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : SizeConfig.size15),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: SizeConfig.medium, color: AppColors.black28),
                          children: [
                            TextSpan(
                              text: link['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w400),
                            ),
                            TextSpan(
                              text: link['link'] ?? '',
                              style: TextStyle(color: AppColors.skyBlueDF),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    CommonDeleteWidget(),
                  ],
                ),
                 );
                }
              )
            ]
          ),
         ),
          SizedBox(height: SizeConfig.size15),
          InkWell(
            onTap: onAddPressed,
            child: Row(
              children: [
                LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                SizedBox(width: SizeConfig.size4),
                CustomText("Add Portfolio / Work Samples", color: AppColors.primaryColor, fontSize: SizeConfig.large),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
