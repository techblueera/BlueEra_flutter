import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

/// REST surface for the hotel-enquiry flow described in
/// `lib/docs/enquiry-flows-ui-integration.md` §2a. Wraps two endpoints:
///   • `POST hotel-enquiries` — raises the enquiry; the backend creates
///     the in-chat `hotel_enquiry` card and emits `newHotelEnquiryReceived`.
///   • `PUT  hotel-enquiries/:id/status` — owner accepts / declines,
///     emitting `hotelEnquiryStatusUpdated` to both sides.
///
/// Photos can be sent as `multipart/form-data` (`payload` JSON part + up
/// to 5 `photos` files) or as already-uploaded URLs in the JSON body.
/// This repo uses multipart when local paths are present, mirroring the
/// healthcare hospital flow.
class HotelEnquiryRepo extends BaseService {
  Future<ResponseModel> sendHotelEnquiry({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        hotelEnquiries,
        params: params,
        showProgress: false,
        onSuccess: (_) {},
        onError: (_) {},
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
      hotelEnquiries,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> updateHotelEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      hotelEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET one — used by the owner chat card to hydrate the enquiry's
  /// current server-side status ('pending' / 'accepted' / 'declined').
  Future<ResponseModel> getHotelEnquiryById(String enquiryId) async {
    return ApiBaseHelper().getHTTP(
      hotelEnquiryById(enquiryId),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }
}
