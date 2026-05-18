/// All `inventory-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin InventoryServiceApi {
  final String getAllProducts = 'inventory-service/product/getAllProducts';
  final String toplevelcategoriesApi =
      "/inventory-service/product/categories/top-level";
  final String cloneProductInventory =
      'inventory-service/products/cloneProductInventory';

  // Need to verify
  final String homePageProduct = 'inventory-service/products/homePageProduct';

  final String addProductToInventory =
      "inventory-service/products/addProductToInventory";
  String updateProductInventoryVariant(String inventoryId, String variantId) =>
      "inventory-service/products/inventory/$inventoryId/variants/$variantId";

  // Product self-pickup orders
  final String placeBulkProductOrder = 'inventory-service/orders';
  String productOrderReady(String orderId) =>
      'inventory-service/orders/$orderId/ready';
}
