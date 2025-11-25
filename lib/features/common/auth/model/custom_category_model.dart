import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';

class CustomCategoryModel {
  final String name;
  final String icon;
  final CategoryData? categoryData;

  CustomCategoryModel({
    required this.name,
    required this.icon,
    this.categoryData,
  });

  CustomCategoryModel copyWith({
    String? slugId,
    String? name,
    String? icon,
    String? type,
    String? categoryId,
  }) {
    return CustomCategoryModel(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      categoryData: categoryData ?? this.categoryData,
    );
  }
}
