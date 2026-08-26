/// All `food-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin FoodServiceApi {
  final String categoryTree = 'food-service/api/categories/tree';
  /// Children of a category by its key, e.g.
  /// `GET food-service/api/categories/key/RESTAURANT_SPECIAL/children`.
  String foodCategoryChildrenByKey(String key) =>
      'food-service/api/categories/key/$key/children';
  final String foodSnapSearch = 'food-service/api/smart-cart/snap-search';
  final String foodCategory = 'food-service/api/categories';
  final String foodProduct = 'food-service/api/foodProduct';
  final String foodServiceProduct = 'food-service/api/foodProduct';

  /// Cross-category food product showcase shown at the bottom of the food
  /// category menu screen. `GET food-service/api/foodProduct/category-showcase`.
  final String foodCategoryShowcase =
      'food-service/api/foodProduct/category-showcase';

  /// Food products grouped by root category — one section per root category,
  /// each with a capped product list — powering the "Quick Upload" rails on the
  /// food category menu screen.
  /// `GET food-service/api/foodProduct/by-root-category`.
  final String foodProductsByRootCategory =
      'food-service/api/foodProduct/by-root-category';
  final String kitchenInventory = 'food-service/api/kitchen-inventory';

  /// Batched product / root-category counts per owner, for the FOOD catalogue.
  /// `POST { businesses: [{ businessId?, userId? }] }`, max 100 entries.
  /// See docs/backend/BUSINESS_PRODUCT_STATS_FLUTTER_GUIDE.md.
  ///
  /// Note the path differs from the other two services (`kitchen-inventory`,
  /// not `inventory`) — food keeps its inventory under its own collection.
  final String foodBusinessProductStats =
      'food-service/api/kitchen-inventory/business-product-stats';

  // Delete a single kitchen-inventory entry (a product variant) by its id.
  String kitchenInventoryById(String inventoryId) => 'food-service/api/kitchen-inventory/$inventoryId';

  /// Invert the manual `isOutOfStock` flag on one or more kitchen-inventory
  /// records — independent of batch quantity.
  /// `PATCH food-service/api/kitchen-inventory/stock/flip-out-of-stock` with
  /// `{ "inventoryIds": [...] }` (or `{ "inventoryId": "..." }`).
  ///
  /// A FLIP, not a set: no value is sent, each id moves to the opposite of
  /// whatever it currently is. The pill that drives this only ever asks for the
  /// inverse of what it is showing (`onToggle(!currentFlag)`), so the two agree
  /// — but a caller that wants to force a specific value cannot use this.
  ///
  /// Note the `kitchen-inventory` segment: the stock-management doc writes the
  /// path as `/api/inventory/stock/...`, but food keeps its inventory under its
  /// own collection (same divergence as [foodBusinessProductStats]).
  ///
  /// The sibling services expose the IDENTICAL sub-path under their own prefix;
  /// pointing one at another marks the wrong catalogue sold out with no error
  /// at all (the request succeeds and the ids land in `notFound`).
  /// See docs/backend/STOCK_MANAGEMENT_FRONTEND_INTEGRATION.md.
  final String foodFlipOutOfStock =
      'food-service/api/kitchen-inventory/stock/flip-out-of-stock';

  /// The productVariant ids this restaurant ALREADY has in its kitchen
  /// inventory.
  /// `GET food-service/api/kitchen-inventory/product-variant-ids?businessId=`
  ///
  /// These are ids of the CATALOGUE variant (`productVariant`), not of the
  /// inventory record — so they compare directly against `FoodVariants.id` on
  /// the pre-publish selection screens, which is the point: a variant already
  /// stocked must not be offered for adding a second time.
  final String foodInventoryProductVariantIds =
      'food-service/api/kitchen-inventory/product-variant-ids';
  final String foodCustomerSearch = 'food-service/api/kitchen-inventory/all/search';
  final String home = 'food-service/api/home/';
  String discountFoodProducts(String businessId) => 'food-service/api/home/$businessId/discountProducts';
  String nestedCategoryWithInventory(String userId) => 'food-service/api/home/$userId';
  final String homeFoodContactUs = 'food-service/api/contact';
  final String homeFoodGallery = 'food-service/api/gallery';

  // Food self-pickup orders
  final String placeBulkFoodOrder = 'food-service/api/orders';
  String foodOrderReady(String orderId) =>
      'food-service/api/orders/$orderId/ready';
}
