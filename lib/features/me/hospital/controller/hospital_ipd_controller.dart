import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/features/me/hospital/model/ipd_ward_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_ipd_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalIpdController extends GetxController {
  final HospitalIpdRepo _repo = HospitalIpdRepo();
  final RxList<IpdWard> wards = <IpdWard>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isFormValid = false.obs;
  final RxString error = ''.obs;

  final nameController = TextEditingController();
  final bedCountController = TextEditingController();
  final feesController = TextEditingController();
  final historyController = TextEditingController();

  final Rxn<File> selectedImage = Rxn<File>();
  String initialImageUrl = '';
  String? departmentIdArg;
  String? hospitalIdArg;

  IpdWard? editingWard;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    departmentIdArg = args?['departmentId'];
    hospitalIdArg = args?['hospitalId'];
    if (departmentIdArg != null) {
      loadByDepartment(departmentIdArg!);
    }
  }

  Future<void> loadByDepartment(String departmentId) async {
    isLoading.value = true;
    try {
      final ResponseModel res = await _repo.getByDepartment(departmentId: departmentId);
      if (res.isSuccess) {
        wards.assignAll(IpdWard.listFromJson(res.response?.data));
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

  void startCreate({String? departmentId, String? hospitalId}) {
    editingWard = null;
    nameController.clear();
    bedCountController.clear();
    feesController.clear();
    historyController.clear();
    selectedImage.value = null;
    initialImageUrl = '';
    departmentIdArg = departmentIdArg ?? departmentId;
    hospitalIdArg = hospitalIdArg ?? hospitalId;
    validate();
  }

  void startEdit(IpdWard ward) {
    editingWard = ward;
    nameController.text = ward.name;
    bedCountController.text = ward.bedCount.toString();
    historyController.text = ward.description;
    feesController.text = ward.fees.toString();
    initialImageUrl = ward.imageUrl;
    validate();
  }

  void validate() {
    final hasName = nameController.text.trim().isNotEmpty;
    final bedOk = int.tryParse(bedCountController.text.trim()) != null;
    final feesOk = int.tryParse(feesController.text.trim()) != null;
    final hasImage = (selectedImage.value != null) || initialImageUrl.isNotEmpty;
    final hasDept = (departmentIdArg?.isNotEmpty ?? false);
    isFormValid.value = hasName && bedOk && feesOk  && hasImage && hasDept;
  }

  Future<void> saveOrUpdate() async {
    if (!isFormValid.value) return;
    isSaving.value = true;
    try {
      final imageUrl = await _resolveImageUrl();
      if (imageUrl == null) return; // upload failed, snackbar already shown

      final body = {
        'name': nameController.text.trim(),
        'imageUrl': imageUrl,
        'bedCount': int.tryParse(bedCountController.text.trim()) ?? 0,
        'description': historyController.text.trim(),
        'fees': int.tryParse(feesController.text.trim()) ?? 0,
        'hospitalId': hospitalIdArg ?? (await getHospitalID()),
        'departmentId': departmentIdArg ?? '',
      };

      final isCreate = editingWard == null;
      final ResponseModel res = isCreate
          ? await _repo.create(body: body)
          : await _repo.update(id: editingWard!.id, body: body);

      if (res.isSuccess) {
        if (departmentIdArg != null) {
          await loadByDepartment(departmentIdArg!);
        }
        Get.back();
        commonSnackBar(
            message: isCreate
                ? AppStrings.hospitalCtrlIpdAddedSuccessfully.tr
                : AppStrings.hospitalCtrlIpdUpdatedSuccessfully.tr);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
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
    commonSnackBar(
        message: uploadResult.message.isNotEmpty
            ? uploadResult.message
            : AppStrings.hospitalCtrlImageUploadFailed.tr);
    isSaving.value = false;
    return null;
  }

  Future<void> deleteWard(IpdWard ward) async {
    try {
      final ResponseModel res = await _repo.delete(id: ward.id);
      if (res.isSuccess) {
        wards.removeWhere((w) => w.id == ward.id);
        commonSnackBar(message: AppStrings.hospitalCtrlDeleted.tr);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
