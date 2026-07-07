import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_testimonial_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_testimonial_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

/// CRUD over the profile-section testimonials carousel + S3 upload for the
/// author photo. See lib/docs/LABORATORY_INTEGRATION.md §2.
class LabTestimonialController extends GetxController {
  final LabTestimonialRepo _repo = LabTestimonialRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingImage = false.obs;

  final RxList<LabTestimonial> myTestimonials = <LabTestimonial>[].obs;
  final RxList<LabTestimonial> byLabTestimonials = <LabTestimonial>[].obs;

  Future<void> fetchMyTestimonials() async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getMyTestimonials();
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        myTestimonials.value = data
            .whereType<Map<String, dynamic>>()
            .map(LabTestimonial.fromJson)
            .toList();
      }
    } catch (e) {
      logs('LabTestimonialController.fetchMyTestimonials ERROR $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchByLab(String labId) async {
    if (labId.trim().isEmpty) return;
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getTestimonialsByLab(labId.trim());
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        byLabTestimonials.value = data
            .whereType<Map<String, dynamic>>()
            .map(LabTestimonial.fromJson)
            .toList();
      }
    } catch (e) {
      logs('LabTestimonialController.fetchByLab ERROR $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadTestimonialPhoto(File file) async {
    try {
      isUploadingImage.value = true;
      final result = await S3UploadService.uploadFile(file);
      if (result.isSuccess) return result.url;
      commonSnackBar(message: result.message);
      return null;
    } catch (e) {
      logs('LabTestimonialController.uploadTestimonialPhoto ERROR $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<bool> createTestimonial(LabTestimonial t) async {
    try {
      isSaving.value = true;
      final ResponseModel res =
          await _repo.createTestimonial(t.toCreateJson());
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? 'Testimonial added');
        await fetchMyTestimonials();
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ?? AppStrings.somethingWentWrong,
      );
      return false;
    } catch (e) {
      logs('LabTestimonialController.createTestimonial ERROR $e');
      commonSnackBar(message: '${AppStrings.hotelErrorPrefix.tr} $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateTestimonial(String id, Map<String, dynamic> patch) async {
    if (id.trim().isEmpty) return false;
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.updateTestimonial(id.trim(), patch);
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? 'Testimonial updated');
        await fetchMyTestimonials();
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ?? AppStrings.somethingWentWrong,
      );
      return false;
    } catch (e) {
      logs('LabTestimonialController.updateTestimonial ERROR $e');
      commonSnackBar(message: '${AppStrings.hotelErrorPrefix.tr} $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteTestimonial(String id) async {
    if (id.trim().isEmpty) return false;
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.deleteTestimonial(id.trim());
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? 'Testimonial deleted');
        myTestimonials.removeWhere((t) => t.id == id.trim());
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ?? AppStrings.somethingWentWrong,
      );
      return false;
    } catch (e) {
      logs('LabTestimonialController.deleteTestimonial ERROR $e');
      commonSnackBar(message: '${AppStrings.hotelErrorPrefix.tr} $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
