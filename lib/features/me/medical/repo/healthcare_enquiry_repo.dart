import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/image_upload_response_model.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// REST surface for the unified healthcare-enquiry flow described in
/// `lib/docs/healthcare-enquiry-ui-integration.md`. Two producers, identical
/// contract for the in-chat card / realtime / push:
///   • Hospitals → `hospital-service/hospital-enquiries` (multipart or JSON)
///   • Non-hospitals (Doctors, Labs, Pharmacy, Surgical, …) →
///     `user-service/business-enquiries` (JSON; photos must be pre-uploaded
///     S3 URLs via the `userUploadInit` presign flow).
///
/// The controller picks the right method per category — callers above the
/// repo see one [submitHealthcareEnquiry] signature.
class HealthcareEnquiryRepo extends BaseService {
  // ── Hospital endpoint ───────────────────────────────────────────────

  /// POST a hospital enquiry. With photos → `multipart/form-data` where the
  /// whole [params] body is sent as a JSON string under `payload` and the
  /// images are sent under `photos` (≤5 files, ≤10 MB each — server-enforced).
  /// Without photos → plain JSON. Mirrors [DiscoverRepo.sendServiceEnquiry] /
  /// [PropertyRepo.sendPropertyEnquiry].
  Future<ResponseModel> sendHospitalEnquiry({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        hospitalEnquiries,
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
      hospitalEnquiries,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// PUT: Hospital owner accepts / declines an enquiry. Emits
  /// `healthcareEnquiryStatusUpdated` to both parties.
  Future<ResponseModel> updateHospitalEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      hospitalEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // ── Non-hospital (business) endpoint ────────────────────────────────

  /// POST a non-hospital healthcare enquiry. JSON only — any photos must
  /// already be uploaded to S3 (see [uploadPhotosViaPresign]) so [params]
  /// can include `photos: [url, …]`.
  Future<ResponseModel> sendBusinessEnquiry({
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().postHTTP(
      businessEnquiries,
      params: params,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// PUT: Business owner accepts / declines an enquiry. Emits
  /// `healthcareEnquiryStatusUpdated` to both parties.
  Future<ResponseModel> updateBusinessEnquiryStatus({
    required String enquiryId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      businessEnquiryStatus(enquiryId),
      params: params,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // ── S3 presign helper (for the business endpoint) ───────────────────

  /// Upload each local photo via the standard two-step presign flow
  /// (`GET userUploadInit?fileName=&fileType=` → returns `{uploadURL, fileUrl}`
  /// → `PUT` the file to `uploadURL`) and return the public `fileUrl`s in
  /// the same order. Photos that fail to upload are silently skipped — the
  /// caller can decide how to surface partial failure (typically: still
  /// submit the enquiry with the photos that did upload).
  Future<List<String>> uploadPhotosViaPresign(List<String> photoPaths) async {
    if (photoPaths.isEmpty) return const [];
    final urls = <String>[];
    for (final path in photoPaths) {
      final url = await _uploadOne(path);
      if (url != null && url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  Future<String?> _uploadOne(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final fileName = p.basename(path);
      final fileType =
          lookupMimeType(path) ?? 'application/octet-stream';

      final initRes = await ApiBaseHelper().getHTTP(
        userUploadInit,
        params: {ApiKeys.fileName: fileName, ApiKeys.fileType: fileType},
        showProgress: false,
        onSuccess: (_) {},
        onError: (_) {},
      );
      if (!initRes.isSuccess) return null;
      final init = ImageUploadResponseModel.fromJson(
          Map<String, dynamic>.from(initRes.response?.data ?? {}));
      final uploadUrl = init.uploadUrl;
      final fileUrl = init.fileUrl;
      if (uploadUrl == null || fileUrl == null) return null;

      final putRes = await ApiBaseHelper().uploadVideoToS3(
        uploadUrl,
        file: file,
        fileType: fileType,
        showProgress: false,
      );
      if (putRes == null || !(putRes.isSuccess)) return null;
      return fileUrl;
    } catch (_) {
      return null;
    }
  }
}
