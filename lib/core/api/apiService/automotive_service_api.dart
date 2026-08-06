/// All `automotive-service/*` endpoint constants used by the automotive_products
/// module (a parallel copy of the product module).
///
/// Mixed into [BaseService] alongside [ProductServiceApi]. Because both
/// mixins are composed onto the same class, every member here is
/// `automotive_products`-prefixed so the names never collide with the
/// product-service equivalents.
mixin AutomotiveServiceApi {
  final String automotiveSearchProductCategory =
      "automotive-service/api/categories/searchCategories";

  /// `POST /api/inventory/business-product-stats` — category + product counts
  /// for a batch of businesses, for the stat box on each store row.
  ///
  /// Same request and same response as the grocery / food / product-catalogue
  /// endpoints; only the SERVICE differs, because each answers for its own
  /// inventory. Asking product-service about an automotive shop returns a
  /// clean, wrong `0` — see [StoreController.countsCatalogueOverride] and
  /// docs/backend/BUSINESS_PRODUCT_STATS_FLUTTER_GUIDE.md.
  final String automotiveBusinessProductStats =
      'automotive-service/api/inventory/business-product-stats';

  /// Admin product create endpoint used by the AI flow's "Post Product".
  final String automotiveCreateProductAdmin =
      "automotive-service/api/products/admin";
  final String automotiveSearchProductViaCategory =
      'automotive-service/api/products/search';
  String automotiveAddUpdateProductVariant(String productId) =>
      'automotive-service/api/products/$productId/variants';
  String automotiveGetProductById(String productId) =>
      'automotive-service/api/products/$productId';
  final String automotiveProductNestedCategory =
      'automotive-service/api/categories/nested';

  /// Products grouped by root category — one section per root category, each
  /// with a capped product list — powering the "Quick Upload" rails on the
  /// automotive product super-category screen.
  /// `GET automotive-service/api/products/by-root-category`.
  final String automotiveProductsByRootCategory =
      'automotive-service/api/products/by-root-category';

  /// Front-end AI keys (Google Custom Search key + cx) for product image search.
  /// `GET automotive-service/api/products/fe/ai-keys`.
  final String automotiveProductAiKeys =
      'automotive-service/api/products/fe/ai-key';

  /// Categories for a given group (e.g. `homeMadeProduct`) — backs the
  /// AI add-product category grid for the user/earn flow.
  String automotiveProductCategoriesByGroup(String group) =>
      'automotive-service/api/categories/group/$group';
  final String automotiveProductInventoryByCategory =
      'automotive-service/api/categories/with-inventory';
  final String automotiveProductPublicInventoryByCategory =
      'automotive-service/api/categories/nested/with-inventory';
  final String automotiveProductSnapSearch =
      'automotive-service/api/ai-search/snap-search';
  final String automotiveProductSearchFilter =
      'automotive-service/api/product/sort/filter';
  final String automotiveProductCategoryTree =
      'automotive-service/api/categories/all/tree';
  final String automotiveProductBusinessProfile =
      "automotive-service/api/business-profile";
  final String automotiveProductFilter =
      'automotive-service/api/product/sort/filter';
  /// Own business products. `GET automotive-service/api/inventory/my-products?businessId=<id>`.
  final String automotiveAllProducts =
      "automotive-service/api/inventory/my-products";

  /// Public, cross-business product listing used by the consumer
  /// category-discover screen.
  /// `GET automotive-service/api/inventory/public/global-products`.
  final String automotiveGlobalProducts =
      "automotive-service/api/inventory/public/global-products";
  final String automotiveAddProductVariant = 'automotive-service/api/inventory';

  /// Add product to inventory. `POST automotive-service/api/inventory`.
  final String automotiveAddProductToInventory =
      "automotive-service/api/inventory";

  /// Update a product inventory record by id.
  /// `PATCH automotive-service/api/inventory/{id}`.
  String automotiveUpdateProductInventory(String id) =>
      'automotive-service/api/inventory/$id';

  /// Place a product order. `POST automotive-service/api/orders`.
  final String automotivePlaceProductOrder = 'automotive-service/api/orders';

  /// Mirrors product's `createProductNewVariant` — same
  /// `/products/<id>/variants` path, only the service prefix changes.
  String automotiveCreateProductNewVariant(String productId) =>
      'automotive-service/api/products/$productId/variants';
}
