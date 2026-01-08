import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ServiceCategoryItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ServiceCategoryItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: selected ? 11 : 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.skyBlueE4,
                AppColors.skyBlueE4.withValues(alpha: 0.3),
              ],
            ),
            border: selected
                ? const Border(
              left: BorderSide(
                color: AppColors.primaryColor,
                width: 3,
                style: BorderStyle.solid,
              ),
            )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? null : AppColors.skyBlueE4,
                ),
                padding: EdgeInsets.all(selected ? 0 : 6),
                child: LocalAssets(
                  imagePath: icon,
                  height: 40,
                  width: 40,
                  // boxFix: BoxFit.cover, // Uncomment if needed
                ),
              ),
              const SizedBox(height: 6),
              CustomText(
                label,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.black : AppColors.grayText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}