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

  /// Place a tiffin order. Separate endpoint from home-made-food orders;
  /// the request sends `{ items: [{ tiffin, quantity }], ... }`.
  Future<ResponseModel> placeTiffinOrder({
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().postHTTP(
      tiffinOrders,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Mark a home made food self-pickup order as ready (cook/seller side).
  /// `PUT earn-service/homeFoodOrders/{orderId}/ready`.
  Future<ResponseModel> markHomeFoodOrderReadyRepo({
    required String orderId,
  }) async {
    return ApiBaseHelper().putHTTP(
      homeFoodOrderReady(orderId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Mark a tiffin self-pickup order as ready (cook/seller side).
  /// `PUT earn-service/tiffinOrders/{orderId}/ready`.
  Future<ResponseModel> markTiffinOrderReadyRepo({
    required String orderId,
  }) async {
    return ApiBaseHelper().putHTTP(
      tiffinOrderReady(orderId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Customer's tiffin order history. `GET earn-service/tiffinOrders/me`.
  /// [queryParams] supports page/limit/orderStatus/startDate/endDate/sortBy/sortOrder.
  Future<ResponseModel> getMyTiffinOrders({
    Map<String, dynamic>? queryParams,
  }) async {
    return ApiBaseHelper().getHTTP(
      tiffinOrdersMe,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Whether the customer has an ongoing tiffin order.
  /// `GET earn-service/tiffinOrders/status/me`.
  Future<ResponseModel> getOngoingTiffinOrder() async {
    return ApiBaseHelper().getHTTP(
      tiffinOrdersStatusMe,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Cook's incoming tiffin orders. `GET earn-service/tiffinOrders/seller/me`.
  Future<ResponseModel> getSellerTiffinOrders({
    Map<String, dynamic>? queryParams,
  }) async {
    return ApiBaseHelper().getHTTP(
      tiffinOrdersSellerMe,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Update or cancel a tiffin order (e.g. `{ "orderStatus": "cancelled" }`,
  /// customer-only while `placed`). `PUT earn-service/tiffinOrders/{id}`.
  Future<ResponseModel> updateTiffinOrder({
    required String orderId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      tiffinOrderById(orderId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Convenience: cancel a tiffin order (customer, while `placed`).
  Future<ResponseModel> cancelTiffinOrder({required String orderId}) {
    return updateTiffinOrder(
      orderId: orderId,
      params: {'orderStatus': 'cancelled'},
    );
  }

  /// Alternative cooks for a tiffin order's meal slot(s).
  /// `GET earn-service/tiffinOrders/{orderId}/alternatives`.
  /// [queryParams]: `filter` (suggested|cheapest|nearest), `latitude`, `longitude`.
  Future<ResponseModel> getTiffinOrderAlternatives({
    required String orderId,
    Map<String, dynamic>? queryParams,
  }) async {
    return ApiBaseHelper().getHTTP(
      tiffinOrderAlternatives(orderId),
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Place a home made product order.
  Future<ResponseModel> placeHomeProductOrder({
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().postHTTP(
      homeProductOrders,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// Fetch earn profile(s) by userId, optionally filtered via [queryParams]
  /// (e.g. `{'profileType': 'homeMadeFood'}`).
  Future<ResponseModel> fetchEarnProfileByUserId({
    required String userId,
    Map<String, dynamic>? queryParams,
  }) async {
    return ApiBaseHelper().getHTTP(
      '$earnProfiles/user/$userId',
      params: queryParams,
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
