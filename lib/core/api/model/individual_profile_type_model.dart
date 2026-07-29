import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:get/get.dart';

class IndividualProfileTypeModel{
  final String type;

  /// Translation keys — [title] / [subTitle] resolve them at read time so the
  /// labels follow the active language instead of freezing at the value this
  /// list was built with (`profileTypeList` is a top-level final).
  final String titleKey;
  final String subTitleKey;
  final String icon;

  String get title => titleKey.tr;

  String get subTitle => subTitleKey.tr;

  IndividualProfileTypeModel({
    required this.type,
    required this.titleKey,
    required this.subTitleKey,
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
        return AppStrings.selectProfession.tr;
      case SELF_EMPLOYED:
        return AppStrings.selectProfession.tr;
      case GIG_WORKER:
        return AppStrings.selectProfession.tr;
      case PROFESSIONAL:
        return AppStrings.selectProfession.tr;
      default:
        return AppStrings.selectProfession.tr;
    }
  }
}

final List<IndividualProfileTypeModel> profileTypeList = [
  IndividualProfileTypeModel(
    type: SOCIAL_PROFILE,
    titleKey: AppStrings.socialProfile,
    subTitleKey: AppStrings.socialProfileSubTitle,
    icon: AppIconAssets.socialProfile,
  ),
  IndividualProfileTypeModel(
    type: SELF_EMPLOYED,
    titleKey: AppStrings.skilledServicesTitle,
    subTitleKey: AppStrings.skilledServicesSubTitle,
    icon: AppIconAssets.skillService,
  ),
  IndividualProfileTypeModel(
    type: GIG_WORKER,
    titleKey: AppStrings.selfEmployedGigTitle,
    subTitleKey: AppStrings.selfEmployedGigSubTitle,
    icon: AppIconAssets.carTaxiGigWorker,
  ),
  IndividualProfileTypeModel(
    type: PROFESSIONAL,
    titleKey: AppStrings.professionalConsultantTitle,
    subTitleKey: AppStrings.professionalConsultantSubTitle,
    icon: AppIconAssets.professional,
  ),
];