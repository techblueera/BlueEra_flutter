import 'package:BlueEra/core/constants/app_enum.dart';

class CollapsibleGridModel {
  final String name;
  final String icon;
  final String slugId;
  final BusinessType? businessType;
  final IndividualType? individualType;

  const CollapsibleGridModel({
     required this.name,
     required this.icon,
     required this.slugId,
     this.businessType,
     this.individualType,
  });
}