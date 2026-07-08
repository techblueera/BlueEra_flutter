import 'package:BlueEra/features/me/automotive_products/model/automotive_product_catalog_response.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';

/// Response of `GET automotive-service/api/products/by-root-category`.
///
/// A parallel copy of the product module's by-root-category model — kept
/// SEPARATE from product so the two services never share state. The API
/// returns `data` as a MAP keyed by root-category key → `{ category,
/// productCount, products }`, which we flatten into an ordered list of
/// [AutomotiveProductRootCategorySection] (Dart preserves Map insertion order)
/// so the UI can render one horizontal "Quick Upload" rail per root category.
class AutomotiveProductByRootCategoryModel {
  final List<AutomotiveProductRootCategorySection> sections;

  AutomotiveProductByRootCategoryModel({required this.sections});

  factory AutomotiveProductByRootCategoryModel.fromJson(
      Map<String, dynamic> json) {
    final data = json['data'];
    final List<AutomotiveProductRootCategorySection> sections = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          sections.add(AutomotiveProductRootCategorySection.fromJson(
              Map<String, dynamic>.from(value)));
        }
      });
    }
    return AutomotiveProductByRootCategoryModel(sections: sections);
  }
}

/// One root-category rail: its category (title + icon), the total product count
/// and the (capped) product list to show in the rail.
class AutomotiveProductRootCategorySection {
  final GroceryNestedCategoryModel? category;
  final int productCount;
  final List<AutomotiveProduct> products;

  AutomotiveProductRootCategorySection({
    this.category,
    this.productCount = 0,
    this.products = const [],
  });

  String get name => category?.name ?? '';
  String get key => category?.key ?? '';
  String get image => category?.image ?? '';

  factory AutomotiveProductRootCategorySection.fromJson(
      Map<String, dynamic> json) {
    return AutomotiveProductRootCategorySection(
      category: json['category'] is Map
          ? GroceryNestedCategoryModel.fromJson(
              Map<String, dynamic>.from(json['category']))
          : null,
      productCount: json['productCount'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) =>
                  AutomotiveProduct.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          <AutomotiveProduct>[],
    );
  }
}
