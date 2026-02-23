import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ServiceHomeTitleWidget extends StatelessWidget {
  final String title;
  const ServiceHomeTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return CustomText(
       title,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: AppColors.mainTextColor,
    );
  }
}
