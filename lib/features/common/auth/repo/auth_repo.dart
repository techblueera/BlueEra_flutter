import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class AuthRepo extends BaseService {
  ///Mobile OTP Send REPO...
  Future<ResponseModel> authMobileOtpSendRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(
      sentOtp,
      params: bodyRequest,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Mobile OTP Verify  REPO...
  Future<ResponseModel> authMobileOtpVerifyRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(
      verifyOtp,
      params: bodyRequest,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///User register  REPO...
  Future<ResponseModel> authUserRegisterRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(addUser,
        params: bodyRequest,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {},
        isMultipart: true);
    return response;
  }

  ///User register  REPO...
  Future<ResponseModel> updateIndividualAccountUserRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${updateIndividualAccountUser}$userId",
        params: bodyRequest,
        onError: (error) {},
        onSuccess: (data) {},
        isMultipart: true);
    return response;
  }

  ///User register  REPO...
  Future<ResponseModel> updateBusinessAccountUserRepo(
      { Map<String, dynamic>? bodyRequest,
        bool? showProgress
      }) async {
    final response = await ApiBaseHelper().putHTTP(
        "${updateBusinessAccount}$userId",
        params: bodyRequest,
        showProgress: showProgress ?? true,
        onError: (error) {},
        onSuccess: (data) {},
        isMultipart: true);
    return response;
  }

  /// Get All Categories REPO...
  Future<ResponseModel> getBusinessCategoriesRepo() async {
    final response = await ApiBaseHelper().getHTTP(getAllcategories,
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Get Verify GST REPO...
  Future<ResponseModel> getUserVerifyGstRepo(
      {required String? gstNumber}) async {
    final response = await ApiBaseHelper().getHTTP(
        "${userVerifyGst}?${ApiKeys.gst_no}=$gstNumber",
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///User Business register  REPO...
  Future<ResponseModel> authBusinessUserRegisterRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().putHTTP(updateGSTBusinessDetails,
        params: bodyRequest,
        onError: (error) {},
        onSuccess: (data) {},
        isMultipart: true);
    return response;
  }

  /// Get Username REPO...
  Future<ResponseModel> getCheckUsernameRepo(
      {required String? userName}) async {
    final response = await ApiBaseHelper().postHTTP("${checkUsername}",
        params: {"inputUsername": userName},
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///BLOCK USER...
  Future<ResponseModel> blockUser(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      blocked,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get All Categories REPO...
  Future<ResponseModel> getAllProfessionsRepo() async {
    final response = await ApiBaseHelper().getHTTP(individualProfessions,
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  //createGuestAccount...
  Future<ResponseModel> createGuestAccountRepo(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      createGuestAccount,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///REPORT...
  Future<ResponseModel> report({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      userFeedReport,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///App Maintenance...
  Future<ResponseModel> getAppMaintenanceRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      appMaintenance,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // Get products API call
  Future<ResponseModel> aiGenerateBioRepo(
      {required Map<String, dynamic> bodyParam,}) async {
    final response = await ApiBaseHelper().postHTTP(
      "$aiGenerateBio",
      params: bodyParam,
      // showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // GET PROVIDER STATUS Patch All(product, service and booking )
  Future<ResponseModel> getServiceExistenceStatusRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      serviceExistenceStatus,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///requestMobileUpdateOtpRepo...
  Future<ResponseModel> requestMobileUpdateOtpRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(
      requestMobileUpdateOtp,
      params: bodyRequest,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///verifyMobileUpdateOtp...
  Future<ResponseModel> verifyMobileUpdateOtpRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(
      verifyMobileUpdateOtp,
      params: bodyRequest,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get Business Sub Categories REPO...
  Future<ResponseModel> getBusinessSubCategoriesRepo({required String tagId}) async {
    final response = await ApiBaseHelper().getHTTP(getBusinessSubCategory(tagId),
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Get Business Sub Categories REPO...
  Future<ResponseModel> getIndividualFieldsRepo({required String tagId}) async {
    final response = await ApiBaseHelper().getHTTP(getIndividualFields(tagId),
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// Get Business Sub Categories REPO...
  Future<ResponseModel> fetchBusinessCategoriesByTypeRepo({required String businessType}) async {
    final response = await ApiBaseHelper().getHTTP(getBusinessCategoryByType(businessType),
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }


}
