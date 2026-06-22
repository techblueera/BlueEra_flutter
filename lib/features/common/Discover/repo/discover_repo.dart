import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

class DiscoverRepo extends BaseService {

  /// GET EARN SERVICES
  Future<ResponseModel> fetchSelfWorkServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      servicesByLatLng,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// POST: Raise a service enquiry from the Discover self-profession card.
  /// The backend creates the enquiry, the in-chat `service_enquiry` card and
  /// emits `newServiceEnquiryReceived` to the provider.
  ///
  /// No photos → plain JSON body. With photos → `multipart/form-data` where the
  /// whole [params] body is sent as a JSON string under `payload` and the
  /// images are sent under `photos`. See docs/backend/service-enquiry-api.md.
  Future<ResponseModel> sendServiceEnquiry({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        serviceEnquiries,
        params: params,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {},
      );
    }

    final files = <MultipartFile>[];
    for (final path in photoPaths) {
      files.add(await MultipartFile.fromFile(path));
    }
    final multipartParams = <String, dynamic>{
      'payload': jsonEncode(params),
      'photos': files,
    };
    return ApiBaseHelper().postHTTP(
      serviceEnquiries,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// PUT: Provider accepts / declines a service enquiry. Emits
  /// `serviceEnquiryStatusUpdated` to both parties.
  Future<ResponseModel> updateServiceEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      serviceEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET the predefined option catalog for a profession [professionCategory]
  /// (e.g. ELECTRICIAN), filtered by the `segment` query param (serviceTypes /
  /// typesOfWork / workCategories / servicesOffered …). Backs the dynamic,
  /// profession-based options in the enquiry sheet. Endpoint inherited from
  /// `EarnServiceApi` via [BaseService].
  Future<ResponseModel> fetchPredefinedCategory({
    required String professionCategory,
    required Map<String, dynamic> queryParams,
  }) async {
    return ApiBaseHelper().getHTTP(
      predefinedServiceCategory(professionCategory),
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// GET the predefined "services offered" catalog for a professional
  /// consultant's profession [professionSlug] (e.g. ADVOCATE). Backs the
  /// dynamic options in the consultant enquiry sheet. Endpoint inherited from
  /// `EarnServiceApi` via [BaseService].
  Future<ResponseModel> fetchPredefinedProfession({
    required String professionSlug,
  }) async {
    return ApiBaseHelper().getHTTP(
      predefinedProfessionServices(professionSlug),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// GET RENTAL SERVICES
  Future<ResponseModel> getRentalService({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      rentalService,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getBookingRidersApi({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getBookingRiders,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }  Future<ResponseModel> makeTransportBookOrderApi({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      makeTransportBookOrder,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Sort shops furthest→nearest + find riders near the furthest shop for a
  /// multi-stop order. POST `/fare/multi-shop/riders`.
  Future<ResponseModel> getMultiShopRidersApi(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      multiShopRiders,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Create the multi-stop order (book a rider). POST `/fare/multi-shop/orders`.
  Future<ResponseModel> makeMultiShopOrderApi(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      multiShopOrders,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET EARN SERVICES
  Future<ResponseModel> fetchProfessionalConsServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      professionalSearch,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET a single self-employed earn-service by its owner [userId].
  /// Backs the visit flow where we only have the author id (no list item).
  Future<ResponseModel> fetchEarnServiceByUserId(String userId) async {
    return ApiBaseHelper().getHTTP(
      earnServiceByUserID(userId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// GET a single professional/consultant by [userId] (the search endpoint
  /// filtered to one user — we take the first result).
  Future<ResponseModel> fetchProfessionalByUserId(String userId) async {
    return ApiBaseHelper().getHTTP(
      professionalSearch,
      params: {'userId': userId},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// GET: Get Hotel Stay
  Future<ResponseModel> fetchHotelSearchRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      hotelSearch,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET: Filter businesses by category. Used by the education / school
  /// listing screens to fetch college-, university-, school-type providers
  /// (e.g. `category=COLLEGE_UNIVERSITY`). Backed by:
  /// `GET user-service/business/filter?category=...&page=...&limit=...`
  Future<ResponseModel> fetchBusinessFilterRepo({
    required Map<String, dynamic> queryParams,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      'user-service/business/filter',
      // 'user-service/business/filter?typeOfBusiness=Siksha&category=SPORTS_HOBBY',
      // 'user-service/business/filter?typeOfBusiness=Siksha',

      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}

