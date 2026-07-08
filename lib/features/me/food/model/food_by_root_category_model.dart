import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';

/// Response of `GET food-service/api/foodProduct/by-root-category`.
///
/// The API returns `data` as a MAP keyed by root-category key
/// (e.g. `"BAKERY_NAMKEENS"`) → `{ category, productCount, products }`.
/// We flatten it into an ordered list of [FoodRootCategorySection] (Dart
/// preserves Map insertion order) so the UI can render one horizontal
/// "Quick Upload" rail per root category.
class FoodByRootCategoryModel {
  final List<FoodRootCategorySection> sections;

  FoodByRootCategoryModel({required this.sections});

  factory FoodByRootCategoryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final List<FoodRootCategorySection> sections = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          sections.add(FoodRootCategorySection.fromJson(
              Map<String, dynamic>.from(value)));
        }
      });
    }
    return FoodByRootCategoryModel(sections: sections);
  }
}

/// One root-category rail: its category (title + icon), the total product count
/// and the (capped) product list to show in the rail.
class FoodRootCategorySection {
  final GroceryNestedCategoryModel? category;
  final int productCount;
  final List<CategoryFoodProductData> products;

  FoodRootCategorySection({
    this.category,
    this.productCount = 0,
    this.products = const [],
  });

  String get name => category?.name ?? '';
  String get key => category?.key ?? '';
  String get image => category?.image ?? '';

  factory FoodRootCategorySection.fromJson(Map<String, dynamic> json) {
    return FoodRootCategorySection(
      category: json['category'] is Map
          ? GroceryNestedCategoryModel.fromJson(
              Map<String, dynamic>.from(json['category']))
          : null,
      productCount: json['productCount'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) => CategoryFoodProductData.fromJson(e))
              .toList() ??
          <CategoryFoodProductData>[],
    );
  }
}
