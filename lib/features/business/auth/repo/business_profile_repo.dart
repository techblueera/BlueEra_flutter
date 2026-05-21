import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';

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

  Future<ResponseModel> getBusinessRatingsSummary(String userId) async {
    return await ApiBaseHelper().getHTTP(
      "$bussinessProfileById/$userId/rating-summary",
    );
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

}