import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

/// REST surface for the education-enquiry flow described in
/// `lib/docs/enquiry-flows-ui-integration.md` §3:
///   • `POST education-enquiries` — raises the enquiry; the backend
///     creates the in-chat `education_enquiry` card and emits
///     `newEducationEnquiryReceived`.
///   • `PUT  education-enquiries/:id/status` — owner accepts / declines,
///     emitting `educationEnquiryStatusUpdated` to both sides.
///
/// Photos can be sent as `multipart/form-data` (`payload` JSON part + up
/// to 5 `photos` files) or as already-uploaded URLs in the JSON body.
/// This repo uses multipart when local paths are present.
class EducationEnquiryRepo extends BaseService {
  Future<ResponseModel> sendEducationEnquiry({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        educationEnquiries,
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
      educationEnquiries,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  Future<ResponseModel> updateEducationEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      educationEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET one — used by the owner chat card to hydrate the enquiry's
  /// current server-side status.
  Future<ResponseModel> getEducationEnquiryById(String enquiryId) async {
    return ApiBaseHelper().getHTTP(
      educationEnquiryById(enquiryId),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }
}
