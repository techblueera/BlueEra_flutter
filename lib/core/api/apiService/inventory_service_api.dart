/// All `inventory-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin InventoryServiceApi {
  // Need to verify
  final String homePageProduct = 'inventory-service/products/homePageProduct';
  // Product self-pickup orders
  final String placeBulkProductOrder = 'inventory-service/orders';
  String productOrderReady(String orderId) => 'inventory-service/orders/$orderId/ready';
}
