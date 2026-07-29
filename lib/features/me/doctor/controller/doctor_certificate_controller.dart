import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_profile_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_certificate_model.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_certificate_repo.dart';
import 'package:get/get.dart';

/// Certificate & Awards list + add/edit/delete.
///
/// Certificates are NOT paginated — `GET /doctor-certificates/me` returns
/// everything, newest first.
class DoctorCertificateController extends GetxController {
  final DoctorCertificateRepo _repo = DoctorCertificateRepo();

  final RxList<DoctorCertificate> certificates = <DoctorCertificate>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString loadError = ''.obs;

  /// Set when the API says the doctor profile must exist first, so the screen
  /// can route the user to the profile form instead of showing a dead error.
  final RxBool needsProfileFirst = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Seed from the profile controller when it already has them — the
    // dashboard's `GET /doctors/me` returns certificates inline, so opening
    // the list usually needs no request at all.
    final seeded = getOrPut(() => DoctorProfileController()).certificates;
    if (seeded.isNotEmpty) certificates.assignAll(seeded);
    fetchCertificates();
  }

  void _syncToProfile() {
    if (Get.isRegistered<DoctorProfileController>()) {
      Get.find<DoctorProfileController>().setCertificates(certificates.toList());
    }
  }

  Future<void> fetchCertificates() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final response = await _repo.getMyCertificates();
      if (!response.isSuccess) {
        loadError.value = response.message?.toString() ??
            AppStrings.somethingWentWrong.tr;
        return;
      }
      certificates.assignAll(DoctorCertificate.listFrom(response.data));
      _syncToProfile();
    } on Exception catch (e) {
      loadError.value = '${AppStrings.errorFetchingData.tr}: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Adds a certificate. Sends multipart when [imageFile] is provided so the
  /// record and its image are one request.
  Future<bool> addCertificate({
    required String title,
    String? description,
    String? issuedBy,
    DateTime? issuedDate,
    File? imageFile,
  }) async {
    isSaving.value = true;
    needsProfileFirst.value = false;
    try {
      final response = await _repo.createCertificate(
        fields: _fields(
          title: title,
          description: description,
          issuedBy: issuedBy,
          issuedDate: issuedDate,
        ),
        imageFile: imageFile,
      );
      if (!response.isSuccess) {
        // 404 here means "create your doctor profile before adding
        // certificates" — a routing signal, not a failure to report as-is.
        if (response.response?.statusCode == 404) {
          needsProfileFirst.value = true;
        }
        commonSnackBar(
          message: response.message?.toString() ??
              AppStrings.somethingWentWrong.tr,
        );
        return false;
      }
      final data = response.data;
      if (data is Map) {
        // The API returns newest-first, so prepend to match.
        certificates.insert(
          0,
          DoctorCertificate.fromJson(Map<String, dynamic>.from(data)),
        );
        _syncToProfile();
      }
      commonSnackBar(message: AppStrings.genericSavedSuccess.tr);
      return true;
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateCertificate({
    required String id,
    required String title,
    String? description,
    String? issuedBy,
    DateTime? issuedDate,
    File? imageFile,
  }) async {
    isSaving.value = true;
    try {
      final response = await _repo.updateCertificate(
        id: id,
        fields: _fields(
          title: title,
          description: description,
          issuedBy: issuedBy,
          issuedDate: issuedDate,
        ),
        imageFile: imageFile,
      );
      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message?.toString() ??
              AppStrings.somethingWentWrong.tr,
        );
        return false;
      }
      final data = response.data;
      if (data is Map) {
        final updated =
            DoctorCertificate.fromJson(Map<String, dynamic>.from(data));
        final index = certificates.indexWhere((c) => c.id == id);
        if (index >= 0) {
          certificates[index] = updated;
        } else {
          certificates.insert(0, updated);
        }
        _syncToProfile();
      }
      commonSnackBar(message: AppStrings.genericSavedSuccess.tr);
      return true;
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteCertificate({required String id}) async {
    try {
      final response = await _repo.deleteCertificate(id: id);
      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message?.toString() ??
              AppStrings.somethingWentWrong.tr,
        );
        return false;
      }
      certificates.removeWhere((c) => c.id == id);
      _syncToProfile();
      commonSnackBar(
        message: response.message?.toString() ?? AppStrings.successful.tr,
      );
      return true;
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    }
  }

  /// Only non-empty values are sent — an omitted key leaves the stored value
  /// alone on update, whereas an empty string would overwrite it.
  Map<String, dynamic> _fields({
    required String title,
    String? description,
    String? issuedBy,
    DateTime? issuedDate,
  }) {
    return <String, dynamic>{
      'title': title.trim(),
      if ((description ?? '').trim().isNotEmpty)
        'description': description!.trim(),
      if ((issuedBy ?? '').trim().isNotEmpty) 'issuedBy': issuedBy!.trim(),
      if (issuedDate != null)
        'issuedDate': issuedDate.toIso8601String().split('T').first,
    };
  }
}
