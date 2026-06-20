import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

class PropertyRepo extends BaseService {
  Future<ResponseModel> createProperty(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      properties,
      params: body,
      showProgress: false,
      isMultipart: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getProperties() async {
    return await ApiBaseHelper().getHTTP(
      properties,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getPropertyById(String id) async {
    return await ApiBaseHelper().getHTTP(
      propertyById(id),
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getPropertyStats() async {
    return await ApiBaseHelper().getHTTP(
      propertyStats,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> updateProperty(
      String id, Map<String, dynamic> body,
      {bool isMultipart = false}) async {
    return await ApiBaseHelper().putHTTP(
      propertyById(id),
      params: body,
      showProgress: false,
      isMultipart: isMultipart,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getFilteredProperties(
      String listingType, String propertyType) async {
    return await ApiBaseHelper().getHTTP(
      propertiesByFilter(listingType, propertyType),
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> deleteProperty(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      propertyById(id),
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> discoverProperties(
      Map<String, dynamic> queryParams) async {
    return await ApiBaseHelper().getHTTP(
      properties,
      params: queryParams,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// Submits a rating (+ optional comment) for a property. Body shape
  /// mirrors the user/business rating endpoints: `{rating, comment}`.
  Future<ResponseModel> rateProperty(
      String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      propertyRatings(id),
      params: body,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// POST: Raise a property enquiry from the rental Discover listing card.
  /// The backend creates the enquiry, the in-chat `property_enquiry` card and
  /// emits `newPropertyEnquiryReceived` to the owner.
  ///
  /// No photos → plain JSON body. With photos → `multipart/form-data` where the
  /// whole [params] body is sent as a JSON string under `payload` and the
  /// images are sent under `photos`. Mirrors [DiscoverRepo.sendServiceEnquiry].
  /// See docs/backend/property-enquiry-flutter-integration.md.
  Future<ResponseModel> sendPropertyEnquiry({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        propertyEnquiries,
        params: params,
        showProgress: false,
        onSuccess: (res) {},
        onError: (error) {},
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
      propertyEnquiries,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// PUT: Owner accepts / declines a property enquiry. Emits
  /// `propertyEnquiryStatusUpdated` to both parties.
  Future<ResponseModel> updatePropertyEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    return await ApiBaseHelper().putHTTP(
      propertyEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }
}
