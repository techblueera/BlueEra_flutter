import 'grocery_nested_category_model.dart';
import 'grocery_product_model.dart';

/// Response of `GET grocery-service/api/products/by-root-category`.
///
/// The API returns `data` as a MAP keyed by root-category key
/// (e.g. `"CLEANING_MAINTENANCE"`) → `{ category, productCount, products }`.
/// We flatten it into an ordered list of [GroceryRootCategorySection] (Dart
/// preserves Map insertion order) so the UI can render one horizontal
/// "Quick Upload" rail per root category.
class GroceryByRootCategoryModel {
  final List<GroceryRootCategorySection> sections;

  GroceryByRootCategoryModel({required this.sections});

  factory GroceryByRootCategoryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final List<GroceryRootCategorySection> sections = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          sections.add(GroceryRootCategorySection.fromJson(
              Map<String, dynamic>.from(value)));
        }
      });
    }
    return GroceryByRootCategoryModel(sections: sections);
  }
}

/// One root-category rail: its category (title + icon), the total product count
/// and the (capped) product list to show in the rail.
class GroceryRootCategorySection {
  final GroceryNestedCategoryModel? category;
  final int productCount;
  final List<GroceryProductData> products;

  GroceryRootCategorySection({
    this.category,
    this.productCount = 0,
    this.products = const [],
  });

  String get name => category?.name ?? '';
  String get key => category?.key ?? '';
  String get image => category?.image ?? '';

  factory GroceryRootCategorySection.fromJson(Map<String, dynamic> json) {
    return GroceryRootCategorySection(
      category: json['category'] is Map
          ? GroceryNestedCategoryModel.fromJson(
              Map<String, dynamic>.from(json['category']))
          : null,
      productCount: json['productCount'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) =>
                  GroceryProductData.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          <GroceryProductData>[],
    );
  }
}
