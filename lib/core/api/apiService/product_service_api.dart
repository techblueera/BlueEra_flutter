/// All `product-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin ProductServiceApi {
  final String searchProductCategory =
      "product-service/api/categories/searchCategories";

  /// Admin product create endpoint used by the AI flow's "Post Product".
  final String createProductAdmin = "product-service/api/products/admin";
  final String searchProductViaCategory = 'product-service/api/products/search';

  /// Cross-category product showcase shown at the bottom of the product
  /// super-category screen. `GET product-service/api/products/category-showcase`.
  final String productCategoryShowcase =
      'product-service/api/products/category-showcase';
  String addUpdateProductVariant(String productId) =>
      'product-service/api/products/$productId/variants';
  String getProductById(String productId) =>
      'product-service/api/products/$productId';
  final String productNestedCategory = 'product-service/api/categories/nested';

  /// Front-end AI keys (Google Custom Search key + cx) for product image search.
  /// `GET product-service/api/products/fe/ai-keys`.
  final String productAiKeys = 'product-service/api/products/fe/ai-key';

  /// Categories for a given group (e.g. `homeMadeProduct`) — backs the
  /// AI add-product category grid for the user/earn flow.
  String productCategoriesByGroup(String group) =>
      'product-service/api/categories/group/$group';
  final String productInventoryByCategory = 'product-service/api/categories/with-inventory';
  final String productPublicInventoryByCategory = 'product-service/api/categories/nested/with-inventory';
  final String productSnapSearch = 'product-service/api/ai-search/snap-search';
  final String productSearchFilter = 'product-service/api/product/sort/filter';
  final String productCategoryTree = 'product-service/api/categories/all/tree';
  final String productBusinessProfile = "product-service/api/business-profile";
  final String productFilter = 'product-service/api/product/sort/filter';
  final String allProducts = "product-service/api/inventory/all-business-products";
  final String addProductVariant = 'product-service/api/inventory';

  /// Add product to inventory. `POST product-service/api/inventory`.
  final String addProductToInventory = "product-service/api/inventory";

  /// Update a product inventory record by id.
  /// `PATCH product-service/api/inventory/{id}`.
  String updateProductInventory(String id) =>
      'product-service/api/inventory/$id';

  /// Place a product order. `POST product-service/api/orders`.
  final String placeProductOrder = 'product-service/api/orders';

  /// Mirrors grocery's `createNewProductVariant` — same `/products/<id>/variants`
  /// path, only the service prefix changes. Renamed here to avoid a mixin
  /// member clash with [GroceryServiceApi.createNewProductVariant].
  String createProductNewVariant(String productId) =>
      'product-service/api/products/$productId/variants';
}
