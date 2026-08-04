import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class BusinessProfileRepo extends BaseService {
  Future<ResponseModel> viewParticularBusinessProfile() async {
    final response = await ApiBaseHelper().getHTTP(viewBusinessProfile,
        showProgress: false, onError: (error) {}, onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> updateBusinessProfileDetails(
      Map<String, dynamic> params, {
    bool showProgress = true,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
        params: params,
        showProgress: showProgress,
        isMultipart: true,
        updateBusinessProfile,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> uploadVerifyBusinessDocs(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        isMultipart: true,
        params: params,
        postVerifyBusinessDocs,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> uploadVerificationOwnerDocs(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        isMultipart: true,
        params: params,
        postVerificationOwnerDocs,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getBusinessVerificationStatus() async {
    final response = await ApiBaseHelper().getHTTP(verifyBusinessStatus,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Ready-written descriptions for a category / subcategory. [params] takes
  /// `category`, `sub_category`, `business_name`, `limit` — Dio encodes them,
  /// which matters because category names carry spaces and `&`.
  /// See docs/FLUTTER_BUSINESS_DESCRIPTION_SUGGESTIONS_GUIDE.md
  Future<ResponseModel> getBusinessDescriptionSuggestions(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
      businessDescriptionSuggestions,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }

  Future<ResponseModel> uploadBusinessDescription(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        params: params,
        updateBusinessDescription,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> deleteLiveStoreImage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().deleteHTTP(
        params: params,
        showProgress: false,
        removeBusinessLivePhotos,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> uploadLiveStoreImages(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        isMultipart: true,
        params: params,
        businessLivePhotos,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> viewBusinessProfileById(String userId) async {
    final response = await ApiBaseHelper().getHTTP(
      // "$bussinessProfileById/6a27b32d37875c6a8eb7b3da",
      "$bussinessProfileById/$userId",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> viewBusinessIdForLocation(String userId,String userType) async {

    final response = await ApiBaseHelper().getHTTP(
      "${(userType=="INDIVIDUAL")?getUserByIdUrlForAddress:businessIdViewForLocation}/$userId",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getNearByRiders(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
      getNearByRiderApi,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> updateMsgOrderStatus(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
      "$updateMessageOrderStatus",
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> submitRatingToPersonal(
      String userId, Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
      userGetRattingSummary(userId),
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> submitRatingToBusinessAccount(
      String businessId, Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
      businessRattingSummary(businessId),
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // Business Desc Via AI
  Future<ResponseModel> aiGenerateDescriptionRepo(
      {required Map<String, dynamic> bodyParam}) async {
    final response = await ApiBaseHelper().postHTTP(
      "$aiGenerateBusinessDescription",
      params: bodyParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // Get service API call
  Future<ResponseModel> getServices({
    required String businessId,
    Map<String, dynamic>? queryParam
  }) async {

    final response = await ApiBaseHelper().getHTTP(
      businessServicesByUserId(businessId),
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getFoods({
    required String businessId,
    Map<String, dynamic>? queryParam
  }) async {

    final response = await ApiBaseHelper().getHTTP(
      businessServicesByUserId(businessId),
      params: queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getBusinessRatings(
      {required String businessId, required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      businessRattingSummary(businessId),
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // ── Availability hours & go-live ────────────────────────────────────
  // Replace the stored weekly schedule. Send the full 7-day array each save
  // (JSON, not multipart). Open days must carry shopOpenTime/shopCloseTime.
  Future<ResponseModel> setBusinessHours(Map<String, dynamic> params) async {
    return await ApiBaseHelper().putHTTP(
      businessAvailabilityHours,
      params: params,
      isMultipart: false,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  // Read the schedule + liveState (used to hydrate the availability editor).
  Future<ResponseModel> getBusinessHours() async {
    return await ApiBaseHelper().getHTTP(
      businessAvailabilityHours,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  // Override TODAY's hours only (beats the weekly schedule for today and
  // auto-reverts tomorrow). Body: {isOpen, shopOpenTime?, shopCloseTime?}.
  Future<ResponseModel> setTodayHours(Map<String, dynamic> params) async {
    return await ApiBaseHelper().putHTTP(
      businessAvailabilityToday,
      params: params,
      isMultipart: false,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  // Clear today's override immediately, reverting to the weekly hours.
  Future<ResponseModel> clearTodayHours() async {
    return await ApiBaseHelper().deleteHTTP(
      businessAvailabilityToday,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  // Mark the business live for today.
  Future<ResponseModel> goLive() async {
    return await ApiBaseHelper().postHTTP(
      businessGoLive,
      params: {},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  // Mark the business offline.
  Future<ResponseModel> endLive() async {
    return await ApiBaseHelper().postHTTP(
      businessEndLive,
      params: {},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }
}