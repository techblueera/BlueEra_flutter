// grocery_nested_category_model also declares a `Product`; hide it so the
// catalog `Product` (the rail's product type) stays unambiguous.
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart'
    hide Product;
import 'package:BlueEra/features/me/product/model/product_catalog_response.dart';

/// Response of `GET product-service/api/products/by-root-category`.
///
/// The API returns `data` as a MAP keyed by root-category key
/// (e.g. `"ARTS_CRAFTS_SEWING"`) → `{ category, productCount, products }`.
/// We flatten it into an ordered list of [ProductRootCategorySection] (Dart
/// preserves Map insertion order) so the UI can render one horizontal
/// "Quick Upload" rail per root category.
class ProductByRootCategoryModel {
  final List<ProductRootCategorySection> sections;

  ProductByRootCategoryModel({required this.sections});

  factory ProductByRootCategoryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final List<ProductRootCategorySection> sections = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          sections.add(ProductRootCategorySection.fromJson(
              Map<String, dynamic>.from(value)));
        }
      });
    }
    return ProductByRootCategoryModel(sections: sections);
  }
}

/// One root-category rail: its category (title + icon), the total product count
/// and the (capped) product list to show in the rail.
class ProductRootCategorySection {
  final GroceryNestedCategoryModel? category;
  final int productCount;
  final List<Product> products;

  ProductRootCategorySection({
    this.category,
    this.productCount = 0,
    this.products = const [],
  });

  String get name => category?.name ?? '';
  String get key => category?.key ?? '';
  String get image => category?.image ?? '';

  factory ProductRootCategorySection.fromJson(Map<String, dynamic> json) {
    return ProductRootCategorySection(
      category: json['category'] is Map
          ? GroceryNestedCategoryModel.fromJson(
              Map<String, dynamic>.from(json['category']))
          : null,
      productCount: json['productCount'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          <Product>[],
    );
  }
}
