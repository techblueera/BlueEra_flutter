import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
class CommonSubTabWidget extends StatelessWidget {
  final String title;
  final int index;
  final int selectedIndex;
  final String? icon;
  final VoidCallback onTap;

  const CommonSubTabWidget({
    super.key,
    required this.title,
    required this.onTap,
    this.icon, required this.index, required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: SizeConfig.size120,
        width: SizeConfig.size114,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.primaryColor)
              : null,
        ),
        child: Stack(
          children: [
            if(icon!=null)
            Center(child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: LocalAssets(
                boxFix: BoxFit.cover,
              height: 50,
                width: 50, imagePath:icon??'',
              ),
            )),
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient:isSelected? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryColor.withOpacity(0.0),
                      AppColors.primaryColor.withOpacity(0.2),
                    ],
                  ):null,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomText(title,textAlign: TextAlign.center,fontSize: 12,fontWeight: FontWeight.w600,),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
