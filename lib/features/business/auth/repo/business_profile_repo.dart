
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class BusinessProfileRepo extends BaseService {
  Future<ResponseModel> viewParticularBusinessProfile() async {
    final response =
    await ApiBaseHelper().getHTTP(
        viewBusinessProfile,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> updateBusinessProfileDetails(
      Map<String, dynamic> params) async {
    final response =
    await ApiBaseHelper().putHTTP(
        params: params,
        isMultipart: true,
        updateBusinessProfile, onError: (error) {}, onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> getSubBusinessCat() async {
    final response =
    await ApiBaseHelper().getHTTP(
        subcategories, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> uploadVerifyBusinessDocs(
      Map<String, dynamic> params) async {
    final response =
    await ApiBaseHelper().postHTTP(
        isMultipart: true,
        params: params,
        postVerifyBusinessDocs, onError: (error) {}, onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> uploadVerificationOwnerDocs(
      Map<String, dynamic> params) async {
    final response =
    await ApiBaseHelper().postHTTP(
        isMultipart: true,
        params: params,
        postVerificationOwnerDocs, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getBusinessVerificationStatus() async {
    final response =
    await ApiBaseHelper().getHTTP(
        verifyBusinessStatus, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> uploadBusinessDescription(
      Map<String, dynamic> params) async {
    final response =
    await ApiBaseHelper().putHTTP(
        params: params,
        updateBusinessDescription, onError: (error) {}, onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> deleteLiveStoreImage(
      Map<String, dynamic> params) async {
    final response =
    await ApiBaseHelper().deleteHTTP(
        params: params,
        removeBusinessLivePhotos, onError: (error) {}, onSuccess: (data) {});

    return response;
  }

  Future<ResponseModel> uploadLiveStoreImages(
      Map<String, dynamic> params) async {
    final response =
    await ApiBaseHelper().postHTTP(
        isMultipart: true,
        params: params,
        businessLivePhotos, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> viewBusinessProfileById(String userId) async {
    return await ApiBaseHelper().getHTTP(
      "$bussinessProfileById/$userId",
    );
  }

  Future<ResponseModel> submitRatingToBusiness(String businessId, Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
      "$postBusinessRating/$businessId",
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getAllProductsApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
      "$getAllProducts",
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getParticularRatingApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
      "$getParticularRating",
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }




}
