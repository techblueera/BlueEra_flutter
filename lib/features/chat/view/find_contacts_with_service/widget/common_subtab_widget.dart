import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
class CommonSubTabWidget extends StatelessWidget {
  final String title;
  final String selectedKey;
  final VoidCallback onTap;

  const CommonSubTabWidget({
    super.key,
    required this.title,
    required this.onTap,
    required this.selectedKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedKey == title;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 100,
        width: 110,
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
