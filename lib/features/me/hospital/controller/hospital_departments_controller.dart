import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/department_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_departments_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';

class HospitalDepartmentsController extends GetxController {
  final HospitalDepartmentsRepo repo = HospitalDepartmentsRepo();
  final RxList<Department> departments = <Department>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isFormValid = false.obs;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxString selectedType = "OPD".obs;

  Department? editingDepartment;

  @override
  void onInit() {
    super.onInit();
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    isLoading.value = true;
    try {
      final ResponseModel res = await repo.getDepartmentsByHospital();
      if (res.isSuccess) {
        departments.assignAll(Department.listFromJson(res.response?.data));
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  void startCreate() {
    editingDepartment = null;
    nameController.clear();
    descriptionController.clear();
    selectedType.value = "OPD";
    validate();
  }

  void startEdit(Department d) {
    editingDepartment = d;
    nameController.text = d.name;
    descriptionController.text = d.description;
    selectedType.value = d.type;
    validate();
  }

  void validate() {
    final ok = nameController.text.trim().isNotEmpty &&
        selectedType.value.trim().isNotEmpty;
    isFormValid.value = ok;
  }

  Future<void> saveDepartment() async {
    if (!isFormValid.value) return;
    isSaving.value = true;
    try {
      final body = {
        ApiKeys.name: nameController.text.trim(),
        ApiKeys.type: selectedType.value.trim(),
        ApiKeys.description: descriptionController.text.trim(),
        ApiKeys.hospitalId:hospitalIDGlobal,
      };
      ResponseModel res;
      if (editingDepartment == null) {
        res = await repo.createDepartment(body: body);
      } else {
        res = await repo.updateDepartment(id: editingDepartment!.id, body: body);
      }
      if (res.isSuccess) {
        await loadDepartments();
        Get.back();
        commonSnackBar(message: editingDepartment == null ? "Department created" : "Department updated");
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteDepartment(Department d) async {
    try {
      final res = await repo.deleteDepartment(id: d.id);
      if (res.isSuccess) {
        departments.removeWhere((e) => e.id == d.id);
        commonSnackBar(message: "Department deleted");
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
