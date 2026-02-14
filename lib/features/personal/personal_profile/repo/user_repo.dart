import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

import '../../../../core/api/apiService/base_service.dart';

class UserRepo extends BaseService {
  Future<ResponseModel> getUserById({required String userId}) async {
    final response = await ApiBaseHelper().getHTTP(
      '$getUserProfileOverviewById$userId',
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getCountRatingUserById({required String userId}) async {
    final response = await ApiBaseHelper().getHTTP(
      '$getCountRating$userId',
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getRattingSummaryById({required String userId}) async {
    final response = await ApiBaseHelper().getHTTP(
      getRattingSummary(userId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getRattingDetailsById({required String userId}) async {
    final response = await ApiBaseHelper().getHTTP(
      userGetRattingDetails(userId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> postEmail({Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(
      addSupport,
      params: bodyRequest,
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getQueries(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getSupportQuery,
      showProgress: true,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getQuerySearch(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getQueryById,
      showProgress: true,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FOLLOW USER
  Future<ResponseModel> followUser({required String? followUserId}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${follow}/${followUserId}",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UN FOLLOW USER
  Future<ResponseModel> unfollowUser({required String? followUserId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "${unfollow}/${followUserId}",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///FOLLOW USER
  Future<ResponseModel> channelFollowUser(
      {required String? followUserId}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${channelServiceFollower}/$followUserId/follow",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UN FOLLOW USER
  Future<ResponseModel> channelUnfollowUser(
      {required String? followUserId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "${channelServiceFollower}/$followUserId/unfollow",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///addTestimonial
  Future<ResponseModel> addTestimonialRepo(
      {required Map<String, dynamic>? reqPar}) async {
    final response = await ApiBaseHelper().postHTTP(
      "${addTestimonial}",
      onError: (error) {},
      params: reqPar,
      onSuccess: (data) {},
    );
    return response;
  }

  ///getTestimonial
  Future<ResponseModel> getTestimonialRepo({required String? userId}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${getTestimonialById}$userId",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get All users...
  Future<ResponseModel> getAllUsers(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      allUsers,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Card Categories
  Future<ResponseModel> getAllCardCategories() async {
    final response = await ApiBaseHelper().getHTTP(
      cardCategories,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Card Categories
  Future<ResponseModel> getAllCards(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      allCardCategories,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Card Categories By Date
  Future<ResponseModel> cardCategoriesSortedByDate(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      cardCategoriesSortByDate,
      params: queryParams,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  //faq
  Future<ResponseModel> getFaqsForHelp() async {
    final response = await ApiBaseHelper().getHTTP(
      getFaqs,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  //quries
  Future<ResponseModel> addFQueriesHelp(
      {required Map<String, dynamic>? reqPar}) async {
    final response = await ApiBaseHelper().postHTTP(
      createQueries,
      onError: (error) {},
      showProgress: false,
      params: reqPar,
      onSuccess: (data) {},
    );
    return response;
  }


  Future<ResponseModel> getQueriesHelp() async {
    final response = await ApiBaseHelper().getHTTP(
      createQueries,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getQueriesByIdForHelp(String Qid) async {
    final response = await ApiBaseHelper().getHTTP(
      getQueriesById(Qid),
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> uploadUserImageDocument(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        mediaUploadUrlEarn,
        params: params,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getMyReferralCodeApi() async {
    final response = await ApiBaseHelper().getHTTP(
        getMyReferralCode,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getMyReferralHistoryApi() async {
    final response = await ApiBaseHelper().getHTTP(
        getMyReferralHistory,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> joinAsBdmApi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        joinAsBdm,
        params: params,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getBdmDetails() async {
    final response = await ApiBaseHelper().getHTTP(
        getBdm,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel?> uploadVideoToS3({required Function(double progress) onProgress, required File file, required String fileType, required String preSignedUrl}) async {
    final response = await ApiBaseHelper().uploadVideoToS3(
      preSignedUrl,
      file: file,
      fileType: fileType,
      showProgress: false,
      onProgress: onProgress,
    );
    return response;
  }

}
