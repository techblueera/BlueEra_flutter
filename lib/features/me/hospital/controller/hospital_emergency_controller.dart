import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/me/hospital/model/emergency_care_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_emergency_repo.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:get/get.dart';

class HospitalEmergencyController extends GetxController {
  final hospitalServiceController = Get.find<HospitalServiceAiController>();

  final HospitalEmergencyRepo repo = HospitalEmergencyRepo();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isFormValid = false.obs;

  final RxBool emergencyCasualty = false.obs;
  final RxBool traumaCare = false.obs;
  final RxBool icu = false.obs;
  final RxBool ccu = false.obs;
  final RxBool nicu = false.obs;
  final RxBool picu = false.obs;

  String? hospitalIdArg;
  EmergencyCare? current;

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
          current = EmergencyCare.fromJson(data);
          emergencyCasualty.value = current?.emergencyCasualty ?? false;
          traumaCare.value = current?.traumaCare ?? false;
          icu.value = current?.icu ?? false;
          ccu.value = current?.ccu ?? false;
          nicu.value = current?.nicu ?? false;
          picu.value = current?.picu ?? false;
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

  void validate() {
    isFormValid.value = emergencyCasualty.value ||
        traumaCare.value ||
        icu.value ||
        ccu.value ||
        nicu.value ||
        picu.value;
  }

  bool get _isCreate => current == null || (current?.id.isEmpty ?? true);

  Future<void> save() async {
    isSaving.value = true;
    try {
      final body = {
        "emergencyCasualty": emergencyCasualty.value,
        "traumaCare": traumaCare.value,
        "icu": icu.value,
        "ccu": ccu.value,
        "nicu": nicu.value,
        "picu": picu.value,
        if (_isCreate) ApiKeys.hospitalId: hospitalIDGlobal,
      };
      final ResponseModel res =
          _isCreate ? await repo.create(body: body) : await repo.update(body: body);

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
}
