import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class MedicalRepo extends BaseService {

  // ─────────────────────────────────────────────
  // PRODUCT SEARCH
  // ─────────────────────────────────────────────

  Future<ResponseModel> searchGroceryCategoryRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      searchMedicalCategory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> userSearchGroceryCategoryRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      userSearchMedicalCategory,
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // PRODUCT VARIANTS
  // ─────────────────────────────────────────────

  /// Create New Product Variant
  Future<ResponseModel> createNewGroceryProductVariantRepo(
      {required String productId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      createNewMedicalProductVariant(productId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update Variant (business approval flow)
  Future<ResponseModel> updateMedicalVariantRepo(
      {required String variantId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().putHTTP(
      updateMedicalVariant(variantId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Delete Variant
  Future<ResponseModel> deleteMedicalVariantRepo(
      {required String variantId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      deleteMedicalVariant(variantId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // CHANGE REQUESTS
  // ─────────────────────────────────────────────

  /// Get pending change requests
  Future<ResponseModel> fetchMedicalChangeRequestsRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalChangeRequests,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Approve change request
  Future<ResponseModel> approveMedicalChangeRequestRepo(
      {required String requestId}) async {
    final response = await ApiBaseHelper().postHTTP(
      approveMedicalChangeRequest(requestId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Reject change request
  Future<ResponseModel> rejectMedicalChangeRequestRepo(
      {required String requestId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      rejectMedicalChangeRequest(requestId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // INVENTORY
  // ─────────────────────────────────────────────

  /// Add Product Variants to Inventory
  Future<ResponseModel> addGroceryProductVariantRepo(
      {List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addMedicalProductVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch My Products (grouped by category)
  Future<ResponseModel> fetchMyGroceryProductsRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      myMedicalProducts,
      showProgress: false,
      params: queryParam,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch My Categories with Variants
  Future<ResponseModel> fetchGroceryCategoryWithVariantRepo(
      {List<Map<String, dynamic>>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalCategoryWithVariant,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update Inventory
  Future<ResponseModel> updateMedicalInventoryRepo(
      {required String inventoryId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().putHTTP(
      updateMedicalInventory(inventoryId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Delete Inventory
  Future<ResponseModel> deleteMedicalInventoryRepo(
      {required String inventoryId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      deleteMedicalInventory(inventoryId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────

  Future<ResponseModel> fetchGroceryNestedCategoryRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalNestedCategory,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // ORDERS (Customer)
  // ─────────────────────────────────────────────

  /// Create Order
  Future<ResponseModel> groceryOrderRepo({Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Merchant marks a self-pickup order ready, from the chat order card.
  /// Backend then pushes `medicalPickupOrderReady` to the customer.
  Future<ResponseModel> markMedicalOrderReadyRepo(
      {required String orderId}) async {
    final response = await ApiBaseHelper().putHTTP(
      medicalOrderReady(orderId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update Order (assign rider etc.)
  Future<ResponseModel> updateGroceryOrderRepo(
      {Map<String, dynamic>? params, required String orderId}) async {
    final response = await ApiBaseHelper().putHTTP(
      updateMedicalOrder(orderId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch Near By Riders
  Future<ResponseModel> fetchNearByRidersRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getNearByRiderApi,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Send Order Request To Rider
  Future<ResponseModel> orderReqToRiderRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      sendOrderReqToRider,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get Order Service Details
  Future<ResponseModel> groceryOrderServiceRepo(
      {required String? orderID,
        required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalServiceOrder(orderID ?? " "),
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Accept Order Service
  Future<ResponseModel> createGroceryAcceptOrderServiceRepo(
      {required String? rideOrderId,
        required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalServiceOrder(rideOrderId ?? " "),
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Submit Accept Order Service
  Future<ResponseModel> submitGroceryAcceptOrderServiceRepo(
      {required String? rideOrderId, required String? itemId,
        required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().patchHTTP(
      "${ridersMedicalOrders}${rideOrderId}/businesses/$businessId/items/$itemId/pickup",
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // ORDERS (Business)
  // ─────────────────────────────────────────────

  /// Fetch My Orders (business seller side)
  Future<ResponseModel> fetchGroceryOrdersRepo(
      {required Map<String, dynamic> queryParm}) async {
    final response = await ApiBaseHelper().getHTTP(
      myMedicalOrders,
      showProgress: false,
      params: queryParm,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Item Availability (POST)
  Future<ResponseModel> groceryOrderItemAvailabilityRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalOrderAvailableItem,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get Available Items (GET)
  Future<ResponseModel> groceryOrderAvailableItemRepo(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalOrderAvailableItem,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Submit Order To Rider with Payment
  Future<ResponseModel> submitGroceryOrderToRiderRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalOrderUpdatePaymentStatus,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Check for ongoing order (business)
  Future<ResponseModel> fetchMedicalOrderStatusMeRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      medicalOrdersStatusMe,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get all orders with filters (business)
  Future<ResponseModel> fetchMedicalOrdersMeRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalOrdersMe,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // MISSING PRODUCT REQUESTS
  // ─────────────────────────────────────────────

  /// Create Single Missing Product Request
  Future<ResponseModel> createMissingProductRequestRepo(
      {Map<String, dynamic>? params, bool isMultipart = false}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalMissingProductRequests,
      params: params,
      isMultipart: isMultipart,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create Bulk Missing Product Requests
  Future<ResponseModel> createBulkMissingProductRequestsRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalMissingProductRequestsBulk,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get My Missing Product Requests
  Future<ResponseModel> fetchMyMissingProductRequestsRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalMissingProductRequestsMy,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // SMART CART (AI Vision)
  // ─────────────────────────────────────────────

  /// Snap & Search - AI Image Recognition
  Future<ResponseModel> snapSearchRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalSnapSearch,
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────

  /// Get Profile Home (aggregated)
  Future<ResponseModel> fetchMedicalProfileFd({required String businessId}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalProfileFd(businessId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get About Us
  Future<ResponseModel> fetchMedicalAboutUsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      medicalProfileAboutUs,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create/Update About Us
  Future<ResponseModel> updateMedicalAboutUsRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().putHTTP(
      medicalProfileAboutUs,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get Contact
  Future<ResponseModel> fetchMedicalContactRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      medicalProfileContact,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create Contact
  Future<ResponseModel> createMedicalContactRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalProfileContact,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update Contact
  Future<ResponseModel> updateMedicalContactRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().putHTTP(
      medicalProfileContact,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Delete Contact
  Future<ResponseModel> deleteMedicalContactRepo() async {
    final response = await ApiBaseHelper().deleteHTTP(
      medicalProfileContact,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get All Testimonials
  Future<ResponseModel> fetchMedicalTestimonialsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      medicalProfileTestimonials,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create Testimonial
  Future<ResponseModel> createMedicalTestimonialRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalProfileTestimonials,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update Testimonial
  Future<ResponseModel> updateMedicalTestimonialRepo(
      {required String testimonialId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().putHTTP(
      medicalProfileTestimonialById(testimonialId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Delete Testimonial
  Future<ResponseModel> deleteMedicalTestimonialRepo(
      {required String testimonialId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      medicalProfileTestimonialById(testimonialId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Toggle Testimonial Status
  Future<ResponseModel> toggleMedicalTestimonialRepo(
      {required String testimonialId}) async {
    final response = await ApiBaseHelper().patchHTTP(
      medicalProfileTestimonialToggle(testimonialId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get All Gallery Entries
  Future<ResponseModel> fetchMedicalGalleryRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      medicalProfileGallery,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create Gallery Entry
  Future<ResponseModel> createMedicalGalleryRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalProfileGallery,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Update Gallery Entry
  Future<ResponseModel> updateMedicalGalleryRepo(
      {required String galleryId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().putHTTP(
      medicalProfileGalleryById(galleryId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Delete Gallery Entry
  Future<ResponseModel> deleteMedicalGalleryRepo(
      {required String galleryId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      medicalProfileGalleryById(galleryId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Delete Single Image from Gallery Entry
  Future<ResponseModel> deleteMedicalGalleryImageRepo(
      {required String galleryId, Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      medicalProfileGalleryDeleteImage(galleryId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Find Nearest Pharmacies
  Future<ResponseModel> fetchNearestPharmaciesRepo(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().postHTTP(
      medicalProfileNearest,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ─────────────────────────────────────────────
  // UPLOAD
  // ─────────────────────────────────────────────

  /// Generate Pre-signed S3 Upload URL
  Future<ResponseModel> fetchUploadInitRepo(
      {Map<String, dynamic>? queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      medicalUploadInit,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> fetchFilteredBusinessRepo({
    required String category,
    String? subCategory,
    int page = 1,
    int limit = 10,
  }) async {
    String url = 'user-service/business/filter?category=$category&page=$page&limit=$limit';
    if (subCategory != null && subCategory.isNotEmpty) {
      url += '&subCategory=$subCategory';
    }
    final response = await ApiBaseHelper().getHTTP(
      url,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}