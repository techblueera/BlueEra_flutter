import 'package:BlueEra/core/constants/app_enum.dart';

class OnBoardingCategoryModel {
  final String name;
  final String icon;
  final String slugId;
  final String accountType;
  final BusinessType? businessType;
  final IndividualType? individualType;

  const OnBoardingCategoryModel({
    required this.name,
    required this.icon,
    required this.slugId,
    required this.accountType,
    this.businessType,
    this.individualType,
  });
}