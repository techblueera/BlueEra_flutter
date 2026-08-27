/// All `grocery-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin GroceryServiceApi {
  final String searchGroceryViaCategory = 'grocery-service/api/products/search';


  /// Products grouped by root category — one section per root category, each
  /// with a capped product list — powering the "Quick Upload" rails on the
  /// add-grocery super-category screen.
  /// `GET grocery-service/api/products/by-root-category`.
  final String groceryProductsByRootCategory =
      'grocery-service/api/products/by-root-category';
  String GroceryCategoryOfChildren(String key) =>
      'grocery-service/api/categories/key/$key/children';
  String GroceryCategoryOfChildrenWithInventory(String key) =>
      'grocery-service/api/categories/key/$key/children/with-inventory';
  final String userSearchGroceryCategory =
      'grocery-service/api/products/user/search';
  String createNewProductVariant(String productId) =>
      'grocery-service/api/products/$productId/variants';
  final String groceryProducts = 'grocery-service/api/inventory/my-products';

  /// Batched product / root-category counts per owner.
  /// `POST { businesses: [{ businessId?, userId? }] }`, max 100 entries.
  /// See docs/backend/BUSINESS_PRODUCT_STATS_FLUTTER_GUIDE.md.
  ///
  /// NOTE: product-service uses the IDENTICAL path on its own host
  /// ([ProductServiceApi.productBusinessProductStats]) — the two differ only by
  /// service prefix, and swapping them returns the wrong catalogue's numbers
  /// with no error.
  final String groceryBusinessProductStats =
      'grocery-service/api/inventory/business-product-stats';

  /// Public single-product fetch used by the grocery share deep-link landing
  /// (`https://beapp.in/app/grocery/{productId}`).
  /// `GET grocery-service/api/products/{productId}`.
  String groceryProductById(String productId) =>
      'grocery-service/api/products/$productId';
  final String globalGroceryProducts =
      'grocery-service/api/inventory/public/global-grocery-products';
  final String addGroceryProductVariant = 'grocery-service/api/inventory';

  /// The productVariant ids this store ALREADY has in its inventory.
  /// `GET grocery-service/api/inventory/product-variant-ids?businessId=`
  ///
  /// Grocery mirror of [FoodServiceApi.foodInventoryProductVariantIds] — same
  /// contract, same `data.productVariantIds` shape. These are ids of the
  /// CATALOGUE variant (`productVariant`), not of the inventory record, so they
  /// compare directly against `ProductVariants.sId` on the pre-publish
  /// selection screens. That is the point: a variant already stocked must not
  /// be offered for adding a second time.
  final String groceryInventoryProductVariantIds =
      'grocery-service/api/inventory/product-variant-ids';

  /// Update / delete a single inventory record (one variant) by its inventory
  /// id. `PUT|DELETE grocery-service/api/inventory/{id}` (grocery mirror of the
  /// product service's `updateProductInventory`).
  String updateGroceryInventory(String id) =>
      'grocery-service/api/inventory/$id';

  /// Bulk mark inventory records in / out of stock — the manual `isOutOfStock`
  /// flag, independent of batch quantity.
  /// `PATCH grocery-service/api/inventory/stock/toggle-out-of-stock` with
  /// `{ "inventoryIds": [...], "isOutOfStock": bool }`.
  /// See docs/backend/STOCK_MANAGEMENT_FRONTEND_INTEGRATION.md.
  final String groceryToggleOutOfStock =
      'grocery-service/api/inventory/stock/toggle-out-of-stock';
  final String groceryCategoryWithInventory =
      'grocery-service/api/categories/with-inventory';
  final String publicGroceryCategoryWithInventory =
      'grocery-service/api/categories/public/with-inventory';
  final String groceryBusinessProducts =
      'grocery-service/api/inventory/business-products';
  final String publicGroceryBusinessProducts =
      'grocery-service/api/inventory/public/business-products';

  /// Stores (grouped by business) that stock a given product/variant near a
  /// pincode/city — powers the search "Available at N stores near you" list.
  /// `POST grocery-service/api/inventory/public/search-by-product`.
  /// See docs/backend/SEARCH_ORDER_FLUTTER_GUIDE.md (step 2).
  final String searchInventoryByProduct =
      'grocery-service/api/inventory/public/search-by-product';
  final String grocerySnapSearch = 'grocery-service/api/smart-cart/snap-search';
  final String grocerySnapSearchWithInventory =
      'grocery-service/api/ai-inventory/snap-search';
  final String missingGroceryProductRequests =
      'grocery-service/api/missing-product-requests/bulk';
  final String groceryNestedCategory = 'grocery-service/api/categories/nested';
  final String groceryNestedCategoryWithInventory =
      'grocery-service/api/categories/nested/with-inventory';

  final String groceryOrder = "grocery-service/api/orders";
  String updateGroceryOrder(String orderId) =>
      "grocery-service/api/orders/$orderId";
  String selfPickupOrderReady(String orderId) =>
      "grocery-service/api/orders/$orderId/ready";
  String groceryServiceOrder(String orderId) =>
      'grocery-service/api/orders/$orderId/alternatives';
  String getGroceryAvailableShops(
          {required String orderId,
          required String latitude,
          required String longitude}) =>
      'grocery-service/api/orders/${orderId}/alternatives?filter=suggested&latitude=$latitude&longitude=$longitude';
  final String placeBulkGroceryOrder = 'grocery-service/api/orders';
}
