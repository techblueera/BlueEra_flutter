import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/opd_doctor_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_opd_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';

class HospitalOpdController extends GetxController {
  final HospitalOpdRepo _repo = HospitalOpdRepo();
  final RxList<OpdDoctor> doctors = <OpdDoctor>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isFormValid = false.obs;
  final RxString error = ''.obs;

  final nameController = TextEditingController();
  final educationController = TextEditingController();
  final descriptionController = TextEditingController();
  final positionController = TextEditingController();
  final feesController = TextEditingController();
  final timingController = TextEditingController();

  final Rxn<File> selectedImage = Rxn<File>();
  String initialImageUrl = '';

  OpdDoctor? editing;
  String? hospitalIdArg;
  String? departmentIdArg;

  Future<void> loadByDepartment(String departmentId) async {
    departmentIdArg = departmentId;
    isLoading.value = true;
    try {
      final res = await _repo.getByDepartment(departmentId: departmentId);
      if (res.isSuccess) {
        doctors.assignAll(OpdDoctor.listFromJson(res.response?.data));
      } else {
        error.value = res.message ?? AppStrings.somethingWentWrong;
        commonSnackBar(message: error.value);
      }
    } catch (e) {
      error.value = e.toString();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  void startCreate() {
    editing = null;
    nameController.clear();
    educationController.clear();
    descriptionController.clear();
    positionController.clear();
    feesController.clear();
    timingController.clear();
    selectedImage.value = null;
    initialImageUrl = '';
    validate();
  }

  void startEdit(OpdDoctor m) {
    editing = m;
    nameController.text = m.name;
    educationController.text = m.education ?? '';
    descriptionController.text = m.description;
    positionController.text = m.position ?? '';
    feesController.text = m.fees?.toString() ?? '';
    timingController.text = m.timing;
    initialImageUrl = m.imageUrl;
    selectedImage.value = null;
    departmentIdArg = m.departmentId;
    hospitalIdArg = m.hospitalId;
    validate();
  }

  void validate() {
    final ok = nameController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        timingController.text.trim().isNotEmpty &&
        (departmentIdArg?.isNotEmpty ?? false) &&
        (hospitalIdArg?.isNotEmpty ?? true) &&
        ((selectedImage.value != null) || initialImageUrl.isNotEmpty);
    isFormValid.value = ok;
  }

  Future<void> save() async {
    if (!isFormValid.value) return;
    isSaving.value = true;
    try {
      final imageUrl = await _resolveImageUrl();
      if (imageUrl == null) return; // upload failed, snackbar already shown

      final feesText = feesController.text.trim();
      final body = {
        ApiKeys.name: nameController.text.trim(),
        "education": educationController.text.trim(),
        ApiKeys.description: descriptionController.text.trim(),
        "departmentId": departmentIdArg ?? "",
        "position": positionController.text.trim(),
        "fees": feesText.isEmpty ? 0 : (int.tryParse(feesText) ?? 0),
        "imageUrl": imageUrl,
        "timing": timingController.text.trim(),
        ApiKeys.hospitalId: hospitalIdArg ?? (await getHospitalID()),
      };

      final isCreate = editing == null;
      final ResponseModel res = isCreate
          ? await _repo.create(body: body)
          : await _repo.update(id: editing!.id, body: body);

      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return;
      }

      final saved = OpdDoctor.fromJson(res.response?.data['data']);
      if (isCreate) {
        doctors.insert(0, saved);
        commonSnackBar(message: AppStrings.hospitalCtrlOpdDoctorAdded.tr);
      } else {
        final idx = doctors.indexWhere((e) => e.id == editing!.id);
        if (idx != -1) doctors[idx] = saved;
        commonSnackBar(message: AppStrings.hospitalCtrlOpdDoctorUpdated.tr);
      }
      Get.back();
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  /// Uploads [selectedImage] if the user picked a new one; otherwise returns
  /// the existing URL. Returns `null` (and shows a snackbar) on upload failure
  /// so the caller can abort save.
  Future<String?> _resolveImageUrl() async {
    if (selectedImage.value == null) return initialImageUrl;
    final uploadResult = await S3UploadService.uploadFile(selectedImage.value!);
    if (uploadResult.isSuccess) return uploadResult.url;
    commonSnackBar(message: uploadResult.message);
    isSaving.value = false;
    return null;
  }

  Future<void> deleteOpd(OpdDoctor d) async {
    try {
      final ResponseModel res = await _repo.delete(id: d.id);
      if (res.isSuccess) {
        doctors.removeWhere((e) => e.id == d.id);
        commonSnackBar(message: AppStrings.hospitalCtrlDeleted.tr);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
