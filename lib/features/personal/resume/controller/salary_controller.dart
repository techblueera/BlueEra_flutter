import 'package:BlueEra/core/api/model/get_resume_data_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalaryController extends GetxController {
  var grossSalary = ''.obs;
  var monthlyDeduction = ''.obs;
  var partTimeEarning = ''.obs;
  var freelanceEarning = ''.obs;

  var totalMonthlyEarning = ''.obs;
  var annualPackage = ''.obs;

  var isSalaryFormValid = false.obs;

  final grossSalaryController = TextEditingController();
  final monthlyDeductionController = TextEditingController();
  final partTimeEarningController = TextEditingController();
  final freelanceEarningController = TextEditingController();

  final workExperienceList = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();

    grossSalaryController.addListener(() {
      grossSalary.value = grossSalaryController.text;
      _calculateTotals();
      _validate();
    });

    monthlyDeductionController.addListener(() {
      monthlyDeduction.value = monthlyDeductionController.text;
      _calculateTotals();
      _validate();
    });

    partTimeEarningController.addListener(() {
      partTimeEarning.value = partTimeEarningController.text;
      _calculateTotals();
      _validate();
    });

    freelanceEarningController.addListener(() {
      freelanceEarning.value = freelanceEarningController.text;
      _calculateTotals();
      _validate();
    });
  }

  void _calculateTotals() {
    double gross =
        double.tryParse(grossSalary.value.replaceAll(',', '')) ?? 0.0;
    double deduct =
        double.tryParse(monthlyDeduction.value.replaceAll(',', '')) ?? 0.0;
    double partTime =
        double.tryParse(partTimeEarning.value.replaceAll(',', '')) ?? 0.0;
    double freelancing =
        double.tryParse(freelanceEarning.value.replaceAll(',', '')) ?? 0.0;

    double total = (gross - deduct) + partTime + freelancing;
    totalMonthlyEarning.value = total > 0 ? total.toStringAsFixed(2) : '0.00';
    annualPackage.value = total > 0 ? (total * 12).toStringAsFixed(2) : '0.00';
  }

  void _validate() {
    final gross =
        double.tryParse(grossSalary.value.replaceAll(',', '').trim()) ?? 0.0;
    final deduction =
        double.tryParse(monthlyDeduction.value.replaceAll(',', '').trim()) ??
            0.0;
    double.tryParse(grossSalary.value.replaceAll(',', '').trim()) ?? 0.0;
    final partTime =
        double.tryParse(partTimeEarning.value.replaceAll(',', '').trim()) ??
            0.0;
    final freelancing =
        double.tryParse(freelanceEarning.value.replaceAll(',', '').trim()) ??
            0.0;
    bool isFieldsFilled = grossSalary.value.trim().isNotEmpty &&
        monthlyDeduction.value.trim().isNotEmpty &&
        partTimeEarning.value.trim().isNotEmpty &&
        freelanceEarning.value.trim().isNotEmpty;
    bool isLogicValid = gross > deduction ||  (gross == deduction && (partTime > 0 || freelancing > 0));
    bool noNegatives =
        gross >= 0 && deduction >= 0 && partTime >= 0 && freelancing >= 0;
    bool atLeastOnePositive = gross > 0 || partTime > 0 || freelancing > 0;

    isSalaryFormValid.value =
        isFieldsFilled && isLogicValid && noNegatives && atLeastOnePositive;
  }

  void clearSalaryFields() {
    grossSalaryController.clear();
    monthlyDeductionController.clear();
    partTimeEarningController.clear();
    freelanceEarningController.clear();
    totalMonthlyEarning.value = '0.00';
    annualPackage.value = '0.00';
    isSalaryFormValid.value = false;
  }

  void clearAllData() {
    grossSalary.value = '';
    monthlyDeduction.value = '';
    partTimeEarning.value = '';
    freelanceEarning.value = '';

    grossSalaryController.clear();
    monthlyDeductionController.clear();
    partTimeEarningController.clear();
    freelanceEarningController.clear();

    workExperienceList.clear();

    _calculateTotals();
    _validate();
  }

  void setSalaryDetails(SalaryDetails? salaryDetails) {
    if (salaryDetails == null) {
      clearAllData();
      return;
    }

    grossSalary.value = salaryDetails.grossSalary?.toString() ?? '';
    monthlyDeduction.value = salaryDetails.monthlyDeduction?.toString() ?? '';
    partTimeEarning.value =
        salaryDetails.monthlyEarningViaPartTime?.toString() ?? '';
    freelanceEarning.value =
        salaryDetails.monthlyEarningViaFreelancing?.toString() ?? '';

    // Update TextControllers if used in UI forms
    grossSalaryController.text = grossSalary.value;
    monthlyDeductionController.text = monthlyDeduction.value;
    partTimeEarningController.text = partTimeEarning.value;
    freelanceEarningController.text = freelanceEarning.value;

    // Calculate totals and validate after setup
    _calculateTotals();
    _validate();

    // Update the workExperienceList reactive list for your card UI
    workExperienceList.clear();

    // Only add the item if grossSalary is available and > 0
    if ((salaryDetails.grossSalary ?? 0) > 0) {
      workExperienceList.add({
        'grossSalary': grossSalary.value,
        'monthlyDeduction': monthlyDeduction.value,
        'partTimeEarning': partTimeEarning.value,
        'freelanceEarning': freelanceEarning.value,
        'annualPackage': salaryDetails.annualPackage?.toString() ?? '0',
      });
    }
  }

  // Future<void> fetchSalaryDetails() async {
  //   var res = await ResumeRepo().fetchSalaryDetails(params: {});
  //   if (res.isSuccess) {
  //     var data = res.response?.data;
  //     grossSalaryController.text = data['grossSalary']?.toString() ?? '';
  //     monthlyDeductionController.text = data['monthlyDeduction']?.toString() ?? '';
  //     partTimeEarningController.text = data['partTimeearning']?.toString() ?? '';
  //     freelanceEarningController.text = data['freelanceEarning']?.toString() ?? '';

  //     workExperienceList.clear();
  //     if (data != null) {
  //       workExperienceList.add({
  //         'title': "₹ ${grossSalaryController.text} LPA",
  //         'grossSalary': grossSalaryController.text,
  //         'monthlyDeduction': monthlyDeductionController.text,
  //         'partTimeEarning': partTimeEarningController.text,
  //         'freelanceEarning': freelanceEarningController.text,
  //       });
  //     }
  //   } else {
  //     workExperienceList.clear();
  //   }
  // }
// Future<void> fetchSalaryDetails() async {
//   var res = await ResumeRepo().fetchSalaryDetails(params: {});
//   if (res.isSuccess) {
//     var data = res.response?.data;

//     // Clear previous data
//     workExperienceList.clear();

//     // Only add item if grossSalary exists and > 0
//     final grossSalaryStr = data['grossSalary']?.toString() ?? '';
//     final grossSalaryValue = double.tryParse(grossSalaryStr.replaceAll(',', '')) ?? 0;

//     if (grossSalaryValue > 0) {
//       grossSalaryController.text = grossSalaryStr;
//       monthlyDeductionController.text = data['monthlyDeduction']?.toString() ?? '';
//       partTimeEarningController.text = data['monthlyEarningViaPartTime']?.toString() ?? '';
//       freelanceEarningController.text = data['monthlyEarningViaFreelancing']?.toString() ?? '';

//       workExperienceList.add({
//         'title': "₹ ${data['annualPackage']?.toString() ?? '0'}", // We'll fix title in next part
//         'grossSalary': grossSalaryController.text,
//         'monthlyDeduction': monthlyDeductionController.text,
//         'partTimeEarning': partTimeEarningController.text,
//         'freelanceEarning': freelanceEarningController.text,
//         'annualPackage': data['annualPackage']?.toString() ?? '0',
//       });
//     } else {
//       clearSalaryFields();
//     }
//   } else {
//     workExperienceList.clear();
//   }
// }

  Future<void> addOrUpdateSalary(Map<String, dynamic> params) async {
    try {
      var res = await ResumeRepo().updateSalary(params: params);
      if (res.isSuccess) {
        final profilePicController = Get.find<ProfilePicController>();
        await profilePicController.getMyResume();
        Get.back();
        commonSnackBar(message: "Salary details updated");
      } else {
        commonSnackBar(message: res.message ?? "Failed to update salary");
      }
    } catch (e) {
      commonSnackBar(message: "Error while updating salary");
    }
  }

  Future<void> deleteSalary() async {
    try {
      var res = await ResumeRepo().deleteSalary();
      if (res.isSuccess) {
        clearSalaryFields();
        workExperienceList.clear();
        commonSnackBar(message: "Salary details deleted");
      } else {
        commonSnackBar(message: res.message ?? "Failed to delete salary");
      }
    } catch (e) {
      commonSnackBar(message: "Error while deleting salary");
    }
  }
}
