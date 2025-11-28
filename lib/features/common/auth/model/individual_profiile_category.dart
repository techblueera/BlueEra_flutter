import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';

class IndividualProfileCategory {
  final String slugId;
  final String name;
  final String icon;
  final String? professionTagId;
  final List<SubcategoriesFiledName>? professionSubCategory;
  final String? selfEmployment;
  final String? selfEmploymentTagId;

  IndividualProfileCategory({
    required this.slugId,
    required this.name,
    required this.icon,
    this.professionTagId,
    this.professionSubCategory,
    this.selfEmployment,
    this.selfEmploymentTagId,
  });

  IndividualProfileCategory copyWith({
    String? slugId,
    String? name,
    String? icon,
    String? professionTagId,
    List<SubcategoriesFiledName>? professionSubCategory,
    String? selfEmployment,
    String? selfEmploymentTagId
  }) {
    return IndividualProfileCategory(
      slugId: slugId ?? this.slugId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      professionTagId: professionTagId ?? this.professionTagId,
      professionSubCategory: professionSubCategory ?? this.professionSubCategory,
      selfEmployment: selfEmployment ?? this.selfEmployment,
      selfEmploymentTagId: selfEmploymentTagId ?? this.selfEmploymentTagId,
    );
  }
}
