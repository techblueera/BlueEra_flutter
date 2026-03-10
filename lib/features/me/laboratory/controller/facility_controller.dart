import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/facility_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/facility_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FacilityController extends GetxController {
  final FacilityRepo _repo = FacilityRepo();

  var isLoading = false.obs;
  var isValid = false.obs;

  RxBool wheelchairAssistance = false.obs;
  RxBool doctorConsultationTieUp = false.obs;
  RxBool insuranceCashlessSupport = false.obs;
  RxBool homeSampleCollection = false.obs;
  RxBool digitalReport = false.obs;
  RxBool upiPayment = false.obs;
  RxBool cardPayment = false.obs;
  RxBool healthPackage = false.obs;

  RxBool otherEnabled = false.obs;
  var others = <FacilityOther>[].obs;

  // RxString laboratoryId = "698b225f2c44cc586fa1d5c2".obs;
  // RxString userId = "696f13baead58417505a8851".obs;

  final List<TextEditingController> otherLabelCtrls = [];
  final List<TextEditingController> otherDetailsCtrls = [];

  @override
  void onInit() {
    super.onInit();
    fetchFacilities();
  }

  void fetchFacilities() async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.getFacilitiesByUser();
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data != null) {
          final fac = Facilities.fromJson(data);
          wheelchairAssistance.value = fac.wheelchairAssistance;
          doctorConsultationTieUp.value = fac.doctorConsultationTieUp;
          insuranceCashlessSupport.value = fac.insuranceCashlessSupport;
          homeSampleCollection.value = fac.homeSampleCollection;
          digitalReport.value = fac.digitalReport;
          // laboratoryId.value = fac.laboratoryId ?? laboratoryId.value;
          // userId.value = fac.userId ?? userId.value;

          others.value = fac.other;
          otherEnabled.value = others.isNotEmpty;
          _syncOtherControllers();
        }
      }
    } catch (e) {
      commonSnackBar(message: "Error fetching facilities: $e");
    } finally {
      isLoading.value = false;
      validateForm();
    }
  }

  void _syncOtherControllers() {
    otherLabelCtrls.clear();
    otherDetailsCtrls.clear();
    for (final o in others) {
      otherLabelCtrls.add(TextEditingController(text: o.label));
      otherDetailsCtrls.add(TextEditingController(text: o.details));
    }
  }

  void addOther() {
    if (others.length >= 5) {
      commonSnackBar(message: "You can add up to 5 facilities");
      return;
    }
    others.add(FacilityOther(label: "", isActive: false, details: ""));
    otherLabelCtrls.add(TextEditingController());
    otherDetailsCtrls.add(TextEditingController());
    otherEnabled.value = true;
    validateForm();
  }

  void removeOther(int index) {
    if (index < 0 || index >= others.length) return;
    others.removeAt(index);
    otherLabelCtrls.removeAt(index);
    otherDetailsCtrls.removeAt(index);
    if (others.isEmpty) otherEnabled.value = false;
    validateForm();
  }

  void toggleOtherActive(int index, bool val) {
    if (index < 0 || index >= others.length) return;
    others[index] = FacilityOther(
      id: others[index].id,
      label: otherLabelCtrls[index].text.trim(),
      isActive: val,
      details: otherDetailsCtrls[index].text.trim(),
    );
    validateForm();
  }

  void updateOtherText(int index) {
    if (index < 0 || index >= others.length) return;
    others[index] = FacilityOther(
      id: others[index].id,
      label: otherLabelCtrls[index].text.trim(),
      isActive: others[index].isActive,
      details: otherDetailsCtrls[index].text.trim(),
    );
    validateForm();
  }

  void validateForm() {
    final anyStandard = wheelchairAssistance.value ||
        doctorConsultationTieUp.value ||
        insuranceCashlessSupport.value ||
        homeSampleCollection.value ||
        digitalReport.value;

    bool othersOk = true;
    if (otherEnabled.value && others.isNotEmpty) {
      for (int i = 0; i < others.length; i++) {
        final o = others[i];
        if (o.isActive) {
          if (o.label.trim().isEmpty || o.details.trim().isEmpty) {
            othersOk = false;
            break;
          }
        }
      }
    }
    isValid.value =
        (anyStandard || (otherEnabled.value && others.isNotEmpty)) && othersOk;
  }

  Future<bool> saveFacilities() async {
    isLoading.value = true;
    try {
      final payload = Facilities(
              laboratoryId: labIDGlobal,
              wheelchairAssistance: wheelchairAssistance.value,
              doctorConsultationTieUp: doctorConsultationTieUp.value,
              insuranceCashlessSupport: insuranceCashlessSupport.value,
              homeSampleCollection: homeSampleCollection.value,
              digitalReport: digitalReport.value,
              credit_card_payment: cardPayment.value,
              health_checkup_pkg: healthPackage.value,
              upi_online: upiPayment.value
              // other: others,
              )
          .toJson();
      ResponseModel res = await _repo.createOrUpdateFacilities(payload);
      if (res.isSuccess) {
        commonSnackBar(message: "Facilities saved");
        return true;
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ?? "Failed to save");
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "Error saving facilities: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
