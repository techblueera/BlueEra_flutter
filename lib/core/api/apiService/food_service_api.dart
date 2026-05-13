/// All `food-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin FoodServiceApi {
  final String categoryTree = 'food-service/api/categories/tree';
  final String foodSnapSearch = 'food-service/api/smart-cart/snap-search';
  final String foodCategory = 'food-service/api/categories';
  final String foodProduct = 'food-service/api/foodProduct';
  final String foodServiceProduct = 'food-service/api/foodProduct';
  final String kitchenInventory = 'food-service/api/kitchen-inventory';
  final String foodCustomerSearch =
      'food-service/api/kitchen-inventory/all/search';
  final String home = 'food-service/api/home/';
  String discountFoodProducts(String businessId) =>
      'food-service/api/home/$businessId/discountProducts';
  String nestedCategoryWithInventory(String userId) =>
      'food-service/api/home/$userId';
  final String homeFoodContactUs = 'food-service/api/contact';
  final String homeFoodGallery = 'food-service/api/gallery';

  // Food self-pickup orders
  final String placeBulkFoodOrder = 'food-service/api/orders';
  String foodOrderReady(String orderId) =>
      'food-service/api/orders/$orderId/ready';
}
