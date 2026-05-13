/// All `inventory-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin InventoryServiceApi {
  final String getAllProducts = 'inventory-service/product/getAllProducts';

  // categories
  final String toplevelcategoriesApi =
      "/inventory-service/product/categories/top-level";

  final String addProductToInventory =
      "inventory-service/products/addProductToInventory";
  String updateProductInventoryVariant(String inventoryId, String variantId) =>
      "inventory-service/products/inventory/$inventoryId/variants/$variantId";
  final String getOwnDraftedAndPublicProducts =
      'inventory-service/products/getOwnDraftedAndPublicProducts';
  final String cloneProductInventory =
      'inventory-service/products/cloneProductInventory';
  final String homePageProduct = 'inventory-service/products/homePageProduct';

  // Product self-pickup orders
  final String placeBulkProductOrder = 'inventory-service/orders';
  String productOrderReady(String orderId) =>
      'inventory-service/orders/$orderId/ready';
}
