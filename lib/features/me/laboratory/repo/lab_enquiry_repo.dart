import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

/// REST surface for the customer → laboratory enquiry flow described in
/// `lib/docs/LABORATORY_ENQUIRY_INTEGRATION_GUIDE.md`.
///
/// Kept in a dedicated file (not shared with [HealthcareEnquiryRepo]) so
/// the laboratory pipeline can be tuned per-category without ripple into
/// the hospital / business enquiry code path.
class LabEnquiryRepo extends BaseService {
  /// POST a laboratory enquiry. With photos → `multipart/form-data` where
  /// the whole [params] body is sent as a JSON string under `payload` and
  /// the images are sent under `photos` (≤5 files, ≤10 MB each — server
  /// enforces). Without photos → plain JSON. Mirrors [sendHospitalEnquiry].
  Future<ResponseModel> sendLaboratoryEnquiry({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        laboratoryEnquiries,
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
      laboratoryEnquiries,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// PUT: Lab owner accepts / declines an enquiry. Emits
  /// `healthcareEnquiryStatusUpdated` to both parties.
  Future<ResponseModel> updateLaboratoryEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      laboratoryEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET one — used by the owner chat card to hydrate the enquiry's
  /// current server-side status.
  Future<ResponseModel> getLaboratoryEnquiryById(String enquiryId) async {
    return ApiBaseHelper().getHTTP(
      laboratoryEnquiryById(enquiryId),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }
}
