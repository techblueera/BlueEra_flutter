import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/other_facilities_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_other_facilities_repo.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalOtherFacilitiesController extends GetxController {
  final hospitalServiceController = Get.find<HospitalServiceAiController>();

  final HospitalOtherFacilitiesRepo repo = HospitalOtherFacilitiesRepo();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isFormValid = false.obs;

  final RxBool ambulance = false.obs;
  final RxBool diagnosticStatus = false.obs;
  final RxBool medicalStoreStatus = false.obs;
  final RxBool pmSwasthyaBimaYojana = false.obs;
  final RxBool bloodBank = false.obs;
  final RxList<String> cashlessInsurance = <String>[].obs;

  final TextEditingController insuranceInput = TextEditingController();

  String? hospitalIdArg;
  OtherFacilities? current;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final ResponseModel res = await repo.getByHospital();
      if (res.isSuccess) {
        final data = res.response?.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          current = OtherFacilities.fromJson(data);
          ambulance.value = current?.ambulance ?? false;
          pmSwasthyaBimaYojana.value = current?.pmSwasthyaBimaYojana ?? false;
          bloodBank.value = current?.bloodBank ?? false;
          medicalStoreStatus.value = current?.medicalStore ?? false;
          diagnosticStatus.value = current?.diagnosticDepartments ?? false;
          cashlessInsurance.assignAll(current?.cashlessInsurance ?? []);
        }
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      validate();
      isLoading.value = false;
    }
  }

  void updateToggle() {
    validate();
  }

  void addInsurance() {
    final v = insuranceInput.text.trim();
    if (v.isEmpty) return;
    cashlessInsurance.add(v);
    insuranceInput.clear();
    validate();
  }

  void removeInsurance(String v) {
    cashlessInsurance.remove(v);
    validate();
  }

  void validate() {
    isFormValid.value = ambulance.value ||
        pmSwasthyaBimaYojana.value ||
        bloodBank.value ||
        cashlessInsurance.isNotEmpty;
  }

  /// Backend upserts on POST, so create/update share the same endpoint.
  Future<void> save() async {
    isSaving.value = true;
    try {
      final body = {
        "ambulance": ambulance.value,
        "pmSwasthyaBimaYojana": pmSwasthyaBimaYojana.value,
        "bloodBank": bloodBank.value,
        "cashlessInsurance": cashlessInsurance.toList(),
        ApiKeys.hospitalId: hospitalIDGlobal,
      };
      final ResponseModel res = await repo.create(body: body);
      if (res.isSuccess) {
        await load();
        Get.back();
        commonSnackBar(message: AppStrings.hospitalCtrlSaved.tr);
        hospitalServiceController.getHospitalFullDetailsController();
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  /// Single-toggle upsert used by the inline status switches
  /// (diagnostic departments / medical store).
  Future<void> updateStatus({required String keyParm}) async {
    isSaving.value = true;
    try {
      final body = <String, dynamic>{
        if (keyParm == "diagnosticDepartments")
          "diagnosticDepartments": diagnosticStatus.value,
        if (keyParm == "medicalStore") "medicalStore": medicalStoreStatus.value,
        ApiKeys.hospitalId: hospitalIDGlobal,
      };
      final ResponseModel res = await repo.create(body: body);
      if (res.isSuccess) {
        await load();
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
