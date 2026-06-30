/// All `grocery-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin GroceryServiceApi {
  final String searchGroceryViaCategory = 'grocery-service/api/products/search';
  String GroceryCategoryOfChildren(String key) =>
      'grocery-service/api/categories/key/$key/children';
  String GroceryCategoryOfChildrenWithInventory(String key) =>
      'grocery-service/api/categories/key/$key/children/with-inventory';
  final String userSearchGroceryCategory =
      'grocery-service/api/products/user/search';
  String createNewProductVariant(String productId) =>
      'grocery-service/api/products/$productId/variants';
  final String groceryProducts = 'grocery-service/api/inventory/my-products';

  /// Public single-product fetch used by the grocery share deep-link landing
  /// (`https://beapp.in/app/grocery/{productId}`).
  /// `GET grocery-service/api/products/{productId}`.
  String groceryProductById(String productId) =>
      'grocery-service/api/products/$productId';
  final String globalGroceryProducts =
      'grocery-service/api/inventory/public/global-grocery-products';
  final String addGroceryProductVariant = 'grocery-service/api/inventory';

  /// Update / delete a single inventory record (one variant) by its inventory
  /// id. `PUT|DELETE grocery-service/api/inventory/{id}` (grocery mirror of the
  /// product service's `updateProductInventory`).
  String updateGroceryInventory(String id) =>
      'grocery-service/api/inventory/$id';
  final String groceryCategoryWithInventory =
      'grocery-service/api/categories/with-inventory';
  final String publicGroceryCategoryWithInventory =
      'grocery-service/api/categories/public/with-inventory';
  final String groceryBusinessProducts =
      'grocery-service/api/inventory/business-products';
  final String publicGroceryBusinessProducts =
      'grocery-service/api/inventory/public/business-products';
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
