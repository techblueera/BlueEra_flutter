import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// `hospital-service/doctor-certificates*` — Certificate & Awards.
///
/// Images go up as DIRECT MULTIPART (one request, server uploads to S3) under
/// the field name `image`, per the integration guide. That is one round trip
/// instead of the three the presign flow needs.
class DoctorCertificateRepo extends BaseService {
  /// `GET /doctor-certificates/me` — newest first, not paginated.
  Future<ResponseModel> getMyCertificates() async {
    return ApiBaseHelper().getHTTP(
      doctorCertificatesMe,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `POST /doctor-certificates`. Sends multipart when [imageFile] is set,
  /// plain JSON otherwise. Never auto-retry — you would create duplicates.
  ///
  /// A `404 "Create your doctor profile before adding certificates"` means the
  /// doctor profile does not exist yet; route the user to the profile form.
  Future<ResponseModel> createCertificate({
    required Map<String, dynamic> fields,
    File? imageFile,
    void Function(int, int)? onSendProgress,
  }) async {
    if (imageFile == null) {
      return ApiBaseHelper().postHTTP(
        doctorCertificatesBase,
        params: fields,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
    }
    final formData = FormData.fromMap({
      ...fields,
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: p.basename(imageFile.path),
      ),
    });
    return ApiBaseHelper().postMultiImage(
      doctorCertificatesBase,
      params: formData,
      showProgress: false,
      onSendProgress: onSendProgress,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `PUT /doctor-certificates/:id` — PARTIAL. Sending a new `image` replaces
  /// the stored URL.
  Future<ResponseModel> updateCertificate({
    required String id,
    required Map<String, dynamic> fields,
    File? imageFile,
    void Function(int, int)? onSendProgress,
  }) async {
    if (imageFile == null) {
      return ApiBaseHelper().putHTTP(
        doctorCertificateById(id),
        params: fields,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
    }
    return ApiBaseHelper().putHTTP(
      doctorCertificateById(id),
      isMultipart: true,
      params: {
        ...fields,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: p.basename(imageFile.path),
        ),
      },
      showProgress: false,
      onSendProgress: onSendProgress,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `DELETE /doctor-certificates/:id`. A 404 covers both "gone" and
  /// "not yours" — the server does not leak the difference.
  Future<ResponseModel> deleteCertificate({required String id}) async {
    return ApiBaseHelper().deleteHTTP(
      doctorCertificateById(id),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
