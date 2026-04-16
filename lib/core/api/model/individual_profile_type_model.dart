import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';

class IndividualProfileTypeModel{
  final String type;
  final String title;
  final String subTitle;
  final String icon;

  IndividualProfileTypeModel({
    required this.type,
    required this.title,
    required this.subTitle,
    required this.icon,
  });

  /// Static helper to find the correct model from the global list
  static IndividualProfileTypeModel fromString(String typeId) {
    return profileTypeList.firstWhere(
          (element) => element.type == typeId,
      orElse: () => profileTypeList[0],
    );
  }

  /// Returns the specific hint text for this profile type
  String get hintText {
    switch (type) {
      case SOCIAL_PROFILE:
        return "Select Profession";
      case SELF_EMPLOYED:
        return "Select Profession";
      case GIG_WORKER:
        return "Select Profession";
      case PROFESSIONAL:
        return "Select Profession";
      default:
        return "Select Profession";
    }
  }
}

final List<IndividualProfileTypeModel> profileTypeList = [
  IndividualProfileTypeModel(
    type: SOCIAL_PROFILE,
    title: "Social Profile",
    subTitle: "Eg. Politician, Student, Artist...",
    icon: AppIconAssets.socialProfile,
  ),
  IndividualProfileTypeModel(
    type: SELF_EMPLOYED,
    title: "Skilled Services",
    subTitle: "Eg. Electrician, Plumber, Carpenter...",
    icon: AppIconAssets.skillService,
  ),
  IndividualProfileTypeModel(
    type: GIG_WORKER,
    title: "Self-Employed (Delivery / Taxi)",
    subTitle: "Eg. Driver, Delivery Rider...",
    icon: AppIconAssets.carTaxiGigWorker,
  ),
  IndividualProfileTypeModel(
    type: PROFESSIONAL,
    title: "Professional Consultant",
    subTitle: "Eg. Doctor, Lawyer, Consultant...",
    icon: AppIconAssets.professional,
  ),
];