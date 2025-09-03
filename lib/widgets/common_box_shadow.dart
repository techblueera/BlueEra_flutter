import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';


class AppShadows {
  static const BoxShadow bottomShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.15), // 20% black
    offset: Offset(0, 4), // bottom
    blurRadius: 5,
  );

  static const BoxShadow topShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.15), // 10% black
    offset: Offset(0, -1.5), // top
    blurRadius: 5,
  );
  static  BoxShadow textFieldShadow =  BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    offset: const Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );
  static BoxShadow cardShadow =  BoxShadow(
    color: AppColors.shadowColor,
    offset: const Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );
  static BoxDecoration shadowDecoration=BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: AppColors.greyE5, width: 1),
  boxShadow: [AppShadows.textFieldShadow],
);

  static List<BoxShadow> get lightBottomShadow => [bottomShadow];

  static List<BoxShadow> get bottomAndTopShadow => [bottomShadow, topShadow];
}
