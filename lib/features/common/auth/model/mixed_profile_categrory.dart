import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';

class MixedProfileCategory {
  final String slugId;
  final String name;
  final String icon;

  MixedProfileCategory({
    required this.slugId,
    required this.name,
    required this.icon
  });

  MixedProfileCategory copyWith({
    String? slugId,
    String? name,
    String? icon,
    String? professionTagId,
    List<SubcategoriesFiledName>? professionSubCategory,
    String? selfEmployment,
    String? selfEmploymentTagId
  }) {
    return MixedProfileCategory(
      slugId: slugId ?? this.slugId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}
