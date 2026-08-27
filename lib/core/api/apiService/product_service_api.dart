/// All `product-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin ProductServiceApi {
  final String searchProductCategory =
      "product-service/api/categories/searchCategories";

  /// Admin product create endpoint used by the AI flow's "Post Product".
  final String createProductAdmin = "product-service/api/products/admin";
  final String searchProductViaCategory = 'product-service/api/products/search';


  /// Products grouped by root category — one section per root category, each
  /// with a capped product list — powering the "Quick Upload" rails on the
  /// product super-category screen.
  /// `GET product-service/api/products/by-root-category`.
  final String productsByRootCategory =
      'product-service/api/products/by-root-category';
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

  /// Public, category-filtered global product feed (home-made-product discover).
  /// `GET product-service/api/inventory/public/global-grocery-products`.
  final String globalProducts =
      "product-service/api/inventory/public/global-grocery-products";
  final String addProductVariant = 'product-service/api/inventory';

  /// Add product to inventory. `POST product-service/api/inventory`.
  final String addProductToInventory = "product-service/api/inventory";

  /// The productVariant ids this business ALREADY has in its inventory.
  /// `GET product-service/api/inventory/product-variant-ids?businessId=`
  ///
  /// Product mirror of [FoodServiceApi.foodInventoryProductVariantIds] — same
  /// contract, same `data.productVariantIds` shape. These are ids of the
  /// CATALOGUE variant, not of the inventory record, so they compare directly
  /// against `Variant.id` on the pre-publish selection screens: a variant
  /// already stocked must not be offered for adding a second time.
  final String productInventoryProductVariantIds =
      'product-service/api/inventory/product-variant-ids';

  /// Batched product / root-category counts per owner, for the PRODUCT
  /// catalogue. `POST { businesses: [{ businessId?, userId? }] }`, max 100.
  /// See docs/backend/BUSINESS_PRODUCT_STATS_FLUTTER_GUIDE.md.
  ///
  /// NOTE: grocery-service exposes the IDENTICAL sub-path
  /// ([GroceryServiceApi.groceryBusinessProductStats]) — the two differ only by
  /// service prefix, and swapping them returns the wrong catalogue's numbers
  /// with no error.
  final String productBusinessProductStats =
      'product-service/api/inventory/business-product-stats';

  /// Update a product inventory record by id.
  /// `PATCH product-service/api/inventory/{id}`.
  String updateProductInventory(String id) =>
      'product-service/api/inventory/$id';

  /// Bulk mark inventory records in / out of stock — the manual `isOutOfStock`
  /// flag, independent of batch quantity.
  /// `PATCH product-service/api/inventory/stock/toggle-out-of-stock` with
  /// `{ "inventoryIds": [...], "isOutOfStock": bool }`.
  /// See docs/backend/STOCK_MANAGEMENT_FRONTEND_INTEGRATION.md.
  final String productToggleOutOfStock =
      'product-service/api/inventory/stock/toggle-out-of-stock';

  /// Place a product order. `POST product-service/api/orders`.
  final String placeProductOrder = 'product-service/api/orders';

  /// Mirrors grocery's `createNewProductVariant` — same `/products/<id>/variants`
  /// path, only the service prefix changes. Renamed here to avoid a mixin
  /// member clash with [GroceryServiceApi.createNewProductVariant].
  String createProductNewVariant(String productId) =>
      'product-service/api/products/$productId/variants';
}
