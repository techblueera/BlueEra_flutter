import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class EarnProfileRepo extends BaseService {

  /// Create Earn Profile — sends JSON body with image content types.
  /// Returns pre-signed S3 URLs for uploading images.
  Future<ResponseModel> createEarnProfileRepo({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      earnProfiles,
      params: params,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch earn profiles filtered by `profileType` (+ lat/long) — backs the
  /// Discover home-made-food / product / service store lists.
  Future<ResponseModel> fetchEarnProfilesByType({
    required Map<String, dynamic> queryParams,
  }) async {
    return ApiBaseHelper().getHTTP(
      earnProfiles,
      params: queryParams,
      showProgress: false,
    );
  }

  /// Fetch all home made food items for a given earn profile — backs the
  /// consumer store details screen.
  Future<ResponseModel> fetchEarnProfileHomeFoods({
    required String id,
  }) async {
    return ApiBaseHelper().getHTTP(
      earnProfileHomeFoods(id),
      showProgress: false,
    );
  }

  /// Place a home made food order.
  Future<ResponseModel> placeHomeFoodOrder({
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().postHTTP(
      homeFoodOrders,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Fetch earn profile by userId.
  Future<ResponseModel> fetchEarnProfileByUserId({
    required String userId,
  }) async {
    return ApiBaseHelper().getHTTP(
      '$earnProfiles/user/$userId',
      showProgress: false,
    );
  }

  /// Patch earn profile by id.
  Future<ResponseModel> updateEarnProfile({
    required String id,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().patchHTTP(
      '$earnProfiles/$id',
      params: params,
      showProgress: true,
    );
  }
}
