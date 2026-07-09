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
  // Delete a single kitchen-inventory entry (a product variant) by its id.
  String kitchenInventoryById(String inventoryId) => 'food-service/api/kitchen-inventory/$inventoryId';
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
