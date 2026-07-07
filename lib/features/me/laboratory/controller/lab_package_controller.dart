import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_package_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_package_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

/// CRUD over the "Create Your Own Packages" bundle screens plus S3 image
/// upload for the package cover. See lib/docs/LABORATORY_INTEGRATION.md §1.
class LabPackageController extends GetxController {
  final LabPackageRepo _repo = LabPackageRepo();

  // ── Reactive state ──────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingImage = false.obs;

  /// Owner's own packages — token-scoped list.
  final RxList<LabPackage> myPackages = <LabPackage>[].obs;

  /// Public list keyed by lab id (populated by the profile carousel).
  final RxList<LabPackage> byLabPackages = <LabPackage>[].obs;

  /// Currently-open detail (populated tests). Null when no detail loaded.
  final Rxn<LabPackage> current = Rxn<LabPackage>();

  // ── Preset names (matches assets/img_1.png + doc §1 chip list) ──────
  // "Others (Add Manually)" is a UI-only marker for a blank-name form —
  // it isn't sent to the backend.
  static const List<String> presetNames = [
    'Basic Health Checkup',
    'Full Body Checkup',
    'Executive Health Package',
    'Diabetes Package',
    'Thyroid Package',
    'Heart Check-up Package',
    'Senior Citizen Package',
    'Men Health Package',
  ];

  static const List<String> genderOptions = ['All', 'Male', 'Female'];

  // ── Reads ───────────────────────────────────────────────────────────

  Future<void> fetchMyPackages() async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getMyPackages();
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        myPackages.value = data
            .whereType<Map<String, dynamic>>()
            .map(LabPackage.fromJson)
            .toList();
      }
    } catch (e) {
      logs('LabPackageController.fetchMyPackages ERROR $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchByLab(String labId) async {
    if (labId.trim().isEmpty) return;
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getPackagesByLab(labId.trim());
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        byLabPackages.value = data
            .whereType<Map<String, dynamic>>()
            .map(LabPackage.fromJson)
            .toList();
      }
    } catch (e) {
      logs('LabPackageController.fetchByLab ERROR $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchById(String id) async {
    if (id.trim().isEmpty) return;
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getPackageById(id.trim());
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data is Map<String, dynamic>) {
          current.value = LabPackage.fromJson(data);
        }
      }
    } catch (e) {
      logs('LabPackageController.fetchById ERROR $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Writes ──────────────────────────────────────────────────────────

  /// Uploads [file] to S3 and returns the resulting public URL, or null on
  /// failure (a snackbar is shown so the caller doesn't need to).
  Future<String?> uploadPackageImage(File file) async {
    try {
      isUploadingImage.value = true;
      final result = await S3UploadService.uploadFile(file);
      if (result.isSuccess) return result.url;
      commonSnackBar(message: result.message);
      return null;
    } catch (e) {
      logs('LabPackageController.uploadPackageImage ERROR $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<bool> createPackage(LabPackage pkg) async {
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.createPackage(pkg.toCreateJson());
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? 'Package created');
        await fetchMyPackages();
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ??
            AppStrings.labFailedToAddTest.tr,
      );
      return false;
    } catch (e) {
      logs('LabPackageController.createPackage ERROR $e');
      commonSnackBar(message: '${AppStrings.hotelErrorPrefix.tr} $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updatePackage(String id, Map<String, dynamic> patch) async {
    if (id.trim().isEmpty) return false;
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.updatePackage(id.trim(), patch);
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? 'Package updated');
        await fetchMyPackages();
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ??
            AppStrings.labFailedToAddTest.tr,
      );
      return false;
    } catch (e) {
      logs('LabPackageController.updatePackage ERROR $e');
      commonSnackBar(message: '${AppStrings.hotelErrorPrefix.tr} $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deletePackage(String id) async {
    if (id.trim().isEmpty) return false;
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.deletePackage(id.trim());
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? 'Package deleted');
        myPackages.removeWhere((p) => p.id == id.trim());
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ?? AppStrings.somethingWentWrong,
      );
      return false;
    } catch (e) {
      logs('LabPackageController.deletePackage ERROR $e');
      commonSnackBar(message: '${AppStrings.hotelErrorPrefix.tr} $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
