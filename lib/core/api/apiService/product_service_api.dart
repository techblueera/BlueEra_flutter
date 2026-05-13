/// All `product-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin ProductServiceApi {
  final String subchildORRootCategroy =
      "product-service/api/categories/getSubchildORRootCategroy";
  final String searchProductCategory =
      "product-service/api/categories/searchCategories";
  final String createProduct = "product-service/api/product/create-product";
  String updateProductFeature(String productId) =>
      'product-service/api/product/updateProductFeature/$productId';
  String updatePriceAndWarranty(String productId) =>
      'product-service/api/product/updatePriceAndWarranty/$productId';
  final String createProductViaAi =
      "product-service/api/product/createProductAI";
  final String getInventoryBasedSearchProduct =
      'product-service/api/product/getInventoryBasedSearchProduct';
  final String getListOfSearchProduct =
      'product-service/product/getListOfSearchProduct';
  String addUpdateProductVariant(String productId) =>
      'product-service/api/product/$productId';
  String getProductById(String productId) =>
      'product-service/api/product/get-product-by-id/$productId';
  final String productNestedCategory = 'product-service/api/categories/nested';
  String productInventoryByCategory(String businessId) =>
      'product-service/api/product/business/$businessId/inventoryByCategory';
  final String productSnapSearch = 'product-service/api/ai-search/snap-search';
  final String productSearchFilter = 'product-service/api/product/sort/filter';
  final String productCategoryTree = 'product-service/api/categories/all/tree';
  final String productBusinessProfile = "product-service/api/business-profile";
  final String productFilter = 'product-service/api/product/sort/filter';
}
