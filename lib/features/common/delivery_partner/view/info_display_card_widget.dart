import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class InfoDisplayCard extends StatelessWidget {
  final String title;
  final String value;
  final bool status;
  final VoidCallback onTap;

  const InfoDisplayCard({
    super.key,
    required this.title,
    required this.value,
    this.status = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
            vertical: SizeConfig.size10, horizontal: SizeConfig.size10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              title,
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Color(0xffFCFCFE),
                borderRadius: BorderRadius.circular(14),
                // border: Border.all(color: Colors.grey.shade300),
                border: Border.all(
                  width: 2,
                  color: Color(0xffE5E5E5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff000000).withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      value,
                      fontSize: SizeConfig.large,
                      color:
                      status ? AppColors.mainTextColor : Color(0xffB0B4BF),
                    ),
                  ),
                  if (status)
                    LocalAssets(imagePath: AppIconAssets.green_tick_icon),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
