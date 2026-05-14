import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/facility_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/facility_repo.dart';
import 'package:get/get.dart';

/// Toggle list of laboratory facilities (wheelchair access, digital reports,
/// payment methods, …). All flags are pushed to the API as a single
/// `Facilities` snapshot via [saveFacilities].
class FacilityController extends GetxController {
  final FacilityRepo _repo = FacilityRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isValid = false.obs;

  // Standard facility flags.
  final RxBool wheelchairAssistance = false.obs;
  final RxBool doctorConsultationTieUp = false.obs;
  final RxBool insuranceCashlessSupport = false.obs;
  final RxBool homeSampleCollection = false.obs;
  final RxBool digitalReport = false.obs;

  // Payment & package flags.
  final RxBool upiPayment = false.obs;
  final RxBool cardPayment = false.obs;
  final RxBool healthPackage = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFacilities();
  }

  Future<void> fetchFacilities() async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getFacilitiesByUser();
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data != null) {
          final fac = Facilities.fromJson(data);
          wheelchairAssistance.value = fac.wheelchairAssistance;
          doctorConsultationTieUp.value = fac.doctorConsultationTieUp;
          insuranceCashlessSupport.value = fac.insuranceCashlessSupport;
          homeSampleCollection.value = fac.homeSampleCollection;
          digitalReport.value = fac.digitalReport;
        }
      }
    } catch (e) {
      logs("FacilityController.fetchFacilities ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
      validateForm();
    }
  }

  void validateForm() {
    isValid.value = wheelchairAssistance.value ||
        doctorConsultationTieUp.value ||
        insuranceCashlessSupport.value ||
        homeSampleCollection.value ||
        digitalReport.value;
  }

  Future<bool> saveFacilities() async {
    try {
      isSaving.value = true;
      final payload = Facilities(
        laboratoryId: labIDGlobal,
        wheelchairAssistance: wheelchairAssistance.value,
        doctorConsultationTieUp: doctorConsultationTieUp.value,
        insuranceCashlessSupport: insuranceCashlessSupport.value,
        homeSampleCollection: homeSampleCollection.value,
        digitalReport: digitalReport.value,
        credit_card_payment: cardPayment.value,
        health_checkup_pkg: healthPackage.value,
        upi_online: upiPayment.value,
      ).toJson();

      final ResponseModel res = await _repo.createOrUpdateFacilities(payload);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labFacilitiesSaved.tr);
        return true;
      }
      commonSnackBar(
        message: res.response?.data['message'] ?? AppStrings.labFailedToSave.tr,
      );
      return false;
    } catch (e) {
      logs("FacilityController.saveFacilities ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
