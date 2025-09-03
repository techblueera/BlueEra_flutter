import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class DialogCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const DialogCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.primaryColor,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: LocalAssets(imagePath: icon),
              ),
              const SizedBox(height: 6),
              CustomText(label,textAlign: TextAlign.center,fontSize: SizeConfig.small,fontWeight: FontWeight.w700,)
            ],
          ),
        )
      ),
    );
  }
}
