import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';

class BusinessProfileCategory {
  final String slugId;
  final String name;
  final String icon;
  final String type;
  final CategoryData? categoryData;

  BusinessProfileCategory({
    required this.slugId,
    required this.name,
    required this.icon,
    required this.type,
    this.categoryData,
  });

  BusinessProfileCategory copyWith({
    String? slugId,
    String? name,
    String? icon,
    String? type,
    CategoryData? categoryData,
  }) {
    return BusinessProfileCategory(
      slugId: slugId ?? this.slugId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      categoryData: categoryData ?? this.categoryData,
    );
  }
}
