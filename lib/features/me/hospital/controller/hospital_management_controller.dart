import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/management_member_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_management_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';

class HospitalManagementController extends GetxController {
  final HospitalManagementRepo _repo = HospitalManagementRepo();
  final RxList<ManagementMember> members = <ManagementMember>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isFormValid = false.obs;
  final RxBool isChanged = false.obs;
  final RxString error = ''.obs;

  final nameController = TextEditingController();
  final positionController = TextEditingController();
  final educationController = TextEditingController();
  final descriptionController = TextEditingController();

  final Rxn<File> selectedImage = Rxn<File>();
  String initialImageUrl = '';

  ManagementMember? editingMember;
  String? hospitalIdArg;

  @override
  void onInit() {
    super.onInit();
    loadMembers();
  }

  Future<void> loadMembers() async {
    isLoading.value = true;
    try {
      final String hid = hospitalIdArg ?? await getHospitalID();
      final ResponseModel res = await _repo.getByHospital(hospitalId: hid);
      if (res.isSuccess) {
        members.assignAll(ManagementMember.listFromJson(res.response?.data));
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
    editingMember = null;
    nameController.clear();
    positionController.clear();
    educationController.clear();
    descriptionController.clear();
    selectedImage.value = null;
    initialImageUrl = '';
    isChanged.value = true;
    validate();
  }

  void startEdit(ManagementMember m) {
    editingMember = m;
    nameController.text = m.name;
    positionController.text = m.position;
    educationController.text = m.education;
    descriptionController.text = m.description;
    initialImageUrl = m.imageUrl;
    selectedImage.value = null;
    isChanged.value = false;
    validate();
  }

  void validate() {
    final nameErr = ValidationMethod.validateName(nameController.text);
    final posErr = ValidationMethod.validatePosition(positionController.text);
    final eduErr = ValidationMethod.validateEducation(educationController.text);
    final descErr =
        ValidationMethod.validateDescription(descriptionController.text);

    final ok = nameErr == null &&
        posErr == null &&
        eduErr == null &&
        descErr == null &&
        ((selectedImage.value != null) || initialImageUrl.isNotEmpty);
    isFormValid.value = ok;
    isChanged.value = isDataChanged;
  }

  bool get isDataChanged {
    if (editingMember == null) return true;

    final nameChanged = nameController.text.trim() != editingMember!.name;
    final posChanged =
        positionController.text.trim() != editingMember!.position;
    final eduChanged =
        educationController.text.trim() != editingMember!.education;
    final descChanged =
        descriptionController.text.trim() != editingMember!.description;

    final imageChanged = selectedImage.value != null ||
        initialImageUrl != editingMember!.imageUrl;

    return nameChanged ||
        posChanged ||
        eduChanged ||
        descChanged ||
        imageChanged;
  }

  Future<void> save() async {
    if (!isFormValid.value) return;
    isSaving.value = true;
    try {
      String imageUrl = initialImageUrl;
      if (selectedImage.value != null) {
        final uploadRes =
            await S3UploadService.uploadFile(selectedImage.value!);
        if (uploadRes.isSuccess) {
          imageUrl = uploadRes.url;
        } else {
          commonSnackBar(message: uploadRes.message);
          isSaving.value = false;
          return;
        }
      }

      final body = {
        ApiKeys.name: nameController.text.trim(),
        "imageUrl": imageUrl,
        "education": educationController.text.trim(),
        ApiKeys.description: descriptionController.text.trim(),
        "position": positionController.text.trim(),
        ApiKeys.hospitalId: hospitalIdArg ?? await getHospitalID(),
      };

      if (editingMember == null) {
        final ResponseModel res = await _repo.create(body: body);
        if (res.isSuccess) {
          final created = ManagementMember.fromJson(res.response?.data['data']);
          members.insert(0, created);
          commonSnackBar(message: AppStrings.hospitalCtrlMemberAdded.tr);
          Get.back();
        } else {
          commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        final ResponseModel res =
            await _repo.update(id: editingMember!.id, body: body);
        if (res.isSuccess) {
          final upd = ManagementMember.fromJson(res.response?.data['data']);
          final idx =
              members.indexWhere((element) => element.id == editingMember!.id);
          if (idx != -1) members[idx] = upd;
          commonSnackBar(message: AppStrings.hospitalCtrlMemberUpdated.tr);
          Get.back();
        } else {
          commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteMember(ManagementMember m) async {
    try {
      final ResponseModel res = await _repo.delete(id: m.id);
      if (res.isSuccess) {
        members.removeWhere((e) => e.id == m.id);
        commonSnackBar(message: AppStrings.hospitalCtrlMemberDeleted.tr);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
