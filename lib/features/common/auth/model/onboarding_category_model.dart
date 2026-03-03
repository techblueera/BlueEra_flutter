import 'package:BlueEra/core/constants/app_enum.dart';

class OnboardingCategoryModel {
  final String name;
  // final String? flagIcon;
  final String slugId;
  final String accountType;
  final String? icon;
  final BusinessType? businessType;
  final IndividualProfileType? individualType;


  const OnboardingCategoryModel({
    required this.name,
    // this.flagIcon,
    required this.slugId,
    required this.accountType,
    this.icon,
    this.businessType,
    this.individualType,
  });
}