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
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UN FOLLOW USER
  Future<ResponseModel> unfollowUser({required String? followUserId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "${unfollow}/${followUserId}",
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
  Future<ResponseModel> getTestimonialRepo(
      {required String? userId}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${getTestimonialById}$userId",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// getDailyContentOrGreeting
  Future<ResponseModel> getDailyContentOrGreeting() async {
    final response = await ApiBaseHelper().getHTTP(
      "${getTestimonialById}",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get All users...
  Future<ResponseModel> getAllUsers({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      allUsers,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}
