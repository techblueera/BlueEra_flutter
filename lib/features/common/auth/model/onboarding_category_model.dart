import 'dart:ui';

import 'package:BlueEra/core/constants/app_enum.dart';

class OnboardingCategoryModel {
  final String name;
  // final String? flagIcon;
  final String slugId;
  final String accountType;
  final String? icon;
  final String? subtitle;
  final Color? colorCode;
  final BusinessType? businessType;
  final IndividualProfileType? individualType;


  const OnboardingCategoryModel({
    required this.name,
    // this.flagIcon,
    required this.slugId,
    required this.accountType,
    this.icon,
    this.businessType,
    this.subtitle,
    this.colorCode,
    this.individualType,
  });
}