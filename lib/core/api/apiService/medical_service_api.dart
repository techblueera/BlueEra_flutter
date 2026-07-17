/// All `medical-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: rider-side medical order endpoints (`rider-service/medical/...`)
/// live in `RiderServiceApi`, not here.
mixin MedicalServiceApi {
  final String getMedicalCategoryApi = "medical-service/categories";
  String getMedicalAdminProduct(String orderId) => "medical-service/products";
  String postMedicalAddProduct = "medical-service/products";

  String getProductVarient(String productId) =>
      "medical-service/product-variants/product/$productId";
  String addProductVarient = "medical-service/product-variants";
  String putProductVarient(String varientId) =>
      "medical-service/product-variants/$varientId";

  final String searchMedicalCategory = 'medical-service/products/search';
  final String userSearchMedicalCategory =
      'medical-service/products/user/search';
  String createNewMedicalProductVariant(String productId) =>
      'medical-service/products/$productId/variants';
  final String myMedicalProducts = 'medical-service/inventory/my-products';
  final String addMedicalProductVariant = 'medical-service/inventory';
  final String medicalCategoryWithVariant =
      'medical-service/categories/with-inventory';
  final String medicalOrder = "medical-service/orders";
  String updateMedicalOrder(String orderId) =>
      "medical-service/orders/$orderId";

  /// Merchant marks a self-pickup order ready for collection, from the chat
  /// order card. Mirrors `grocery-service/api/orders/{id}/ready`.
  String medicalOrderReady(String orderId) =>
      "medical-service/orders/$orderId/ready";
  String medicalServiceOrder(String orderId) =>
      'medical-service/orders/$orderId/alternatives';
  final String medicalNestedCategory = 'medical-service/categories/nested';
  // String medicalProfileFd(String businessId) => 'medical-service/profile/home/69ce088dde2705587c143d6c';
  String medicalProfileFd(String businessId) =>
      'medical-service/profile/home/$businessId';

  /// Medical - Inventory CRUD
  String updateMedicalInventory(String inventoryId) =>
      'medical-service/inventory/$inventoryId';
  String deleteMedicalInventory(String inventoryId) =>
      'medical-service/inventory/$inventoryId';

  /// Medical - Variant Update/Delete
  String updateMedicalVariant(String variantId) =>
      'medical-service/products/variants/$variantId';
  String deleteMedicalVariant(String variantId) =>
      'medical-service/products/variants/$variantId';

  /// Medical - Change Requests
  final String medicalChangeRequests =
      'medical-service/products/variants/change-requests';
  String approveMedicalChangeRequest(String requestId) =>
      'medical-service/products/variants/change-requests/$requestId/approve';
  String rejectMedicalChangeRequest(String requestId) =>
      'medical-service/products/variants/change-requests/$requestId/reject';

  /// Medical - Missing Product Requests
  final String medicalMissingProductRequests =
      'medical-service/missing-product-requests';
  final String medicalMissingProductRequestsBulk =
      'medical-service/missing-product-requests/bulk';
  final String medicalMissingProductRequestsMy =
      'medical-service/missing-product-requests/my';

  /// Medical - Smart Cart
  final String medicalSnapSearch = 'medical-service/smart-cart/snap-search';

  /// Medical - Profile
  final String medicalProfileAboutUs = 'medical-service/profile/about-us';
  final String medicalProfileContact = 'medical-service/profile/contact';
  final String medicalProfileTestimonials =
      'medical-service/profile/testimonials';
  String medicalProfileTestimonialById(String id) =>
      'medical-service/profile/testimonials/$id';
  String medicalProfileTestimonialToggle(String id) =>
      'medical-service/profile/testimonials/$id/toggle-status';
  final String medicalProfileGallery = 'medical-service/profile/gallery';
  String medicalProfileGalleryById(String id) =>
      'medical-service/profile/gallery/$id';
  String medicalProfileGalleryDeleteImage(String id) =>
      'medical-service/profile/gallery/$id/images';
  final String medicalProfileNearest = 'medical-service/profile/nearest';

  /// Medical - Upload
  final String medicalUploadInit = 'medical-service/upload/init';

  /// Medical - Orders (Business)
  final String medicalOrdersStatusMe = 'medical-service/orders/status/me';
  final String medicalOrdersMe = 'medical-service/orders/me';
}
