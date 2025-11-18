import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExperienceController extends GetxController {
  final bool isFullTime; // true for full-time, false for part-time

  ExperienceController({required this.isFullTime});

  final previousCompanyController = TextEditingController();
  final designationController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  static const Map<String, String> jobTypeMappingFullTime = {
    'Full-time': 'Full-time', // as per backend
    'Part-time': 'Part-time', // adjust case/dashes per your API spec
    'Contract': 'Contract',
    'Internship': 'Internship',
    'Temporary': 'Temporary',
  };
  static const Map<String, String> jobTypeMappingPartTime = {
    'Freelance': 'Freelance',
  };

  final workTypeOptions = ['Work from Home', 'In-Office', 'Hybrid'];

  final portfolioLinks = <Map<String, String>>[].obs;
  final selectedJobType = RxnString();
  final selectedWorkType = RxnString();

  final selectedStartDay = RxnInt();
  final selectedStartMonth = RxnInt();
  final selectedStartYear = RxnInt();
  final selectedEndDay = RxnInt();
  final selectedEndMonth = RxnInt();
  final selectedEndYear = RxnInt();
  final isStartDateValid = false.obs;
  final isDateOrderValid = false.obs;
  final isCurrentDateValid = false.obs;

  final isFormValid = false.obs;
  final RxList<Map<String, dynamic>> experienceList =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> experienceData = <String, dynamic>{}.obs;

  bool _isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

// Returns DateTime from components or null if invalid
  DateTime? _getDate(int? day, int? month, int? year) {
    if (!_isValidDate(day, month, year)) return null;
    return DateTime(year!, month!, day!);
  }

  bool areDatesValid() {
    DateTime? startDate = _getDate(selectedStartDay.value,
        selectedStartMonth.value, selectedStartYear.value);
    DateTime? endDate = _getDate(
        selectedEndDay.value, selectedEndMonth.value, selectedEndYear.value);

    if (startDate == null || endDate == null) return false;
    return !startDate.isAfter(endDate);
  }

  bool isStartDateNotInFuture() {
    DateTime? startDate = _getDate(selectedStartDay.value,
        selectedStartMonth.value, selectedStartYear.value);
    if (startDate == null) return false;
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return !startDate.isAfter(today);
  }

  @override
  void onInit() {
    super.onInit();
    previousCompanyController.addListener(validateForm);
    designationController.addListener(validateForm);
    locationController.addListener(validateForm);
    descriptionController.addListener(validateForm);

    ever(selectedJobType, (_) => validateForm());
    ever(selectedWorkType, (_) => validateForm());
    ever(selectedStartDay, (_) => validateForm());
    ever(selectedStartMonth, (_) => validateForm());
    ever(selectedStartYear, (_) => validateForm());
    ever(selectedEndDay, (_) => validateForm());
    ever(selectedEndMonth, (_) => validateForm());
    ever(selectedEndYear, (_) => validateForm());
  }

  void clearAllFields() {
    previousCompanyController.clear();
    designationController.clear();
    locationController.clear();
    descriptionController.clear();

    selectedJobType.value = null;
    selectedWorkType.value = null;

    selectedStartDay.value = null;
    selectedStartMonth.value = null;
    selectedStartYear.value = null;

    selectedEndDay.value = null;
    selectedEndMonth.value = null;
    selectedEndYear.value = null;

    isFormValid.value = false;
  }

  void validateForm() {

    final basicFieldsValid = previousCompanyController.text.trim().isNotEmpty &&
        designationController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        selectedJobType.value?.trim().isNotEmpty == true &&
        selectedWorkType.value?.trim().isNotEmpty == true &&
        _isValidDate(selectedStartDay.value, selectedStartMonth.value,
            selectedStartYear.value) &&
        _isValidDate(selectedEndDay.value, selectedEndMonth.value,
            selectedEndYear.value);

    final validDateOrder = areDatesValid();
    final validStartDate = isStartDateNotInFuture();

    // Update individual validation observables (useful for UI hint)
    isStartDateValid.value = validStartDate;
    isDateOrderValid.value = validDateOrder;

    // Set final form validation flag
    final formIsValid = basicFieldsValid && validDateOrder && validStartDate;
    if(validDateOrder==false){
      commonSnackBar(message: "End Data Must After Start Date");
    }
    if (isFormValid.value != formIsValid) {
      isFormValid.value = formIsValid;
    }
  }

  List<String> get jobTypeOptions => isFullTime
      ? jobTypeMappingFullTime.keys.toList()
      : jobTypeMappingPartTime.keys.toList();

  void setFieldsFromData(Map<String, dynamic> data) {
    previousCompanyController.text = data['previousCompanyName'] ?? '';
    designationController.text = data['designation'] ?? '';
    locationController.text = data['location'] ?? '';
    descriptionController.text = data['description'] ?? '';
    selectedJobType.value = data['jobType'];
    selectedWorkType.value = data['workMode'];

    if (data['startDate'] != null) {
      selectedStartDay.value = data['startDate']['date'];
      selectedStartMonth.value = data['startDate']['month'];
      selectedStartYear.value = data['startDate']['year'];
    }

    if (data['endDate'] != null) {
      selectedEndDay.value = data['endDate']['date'];
      selectedEndMonth.value = data['endDate']['month'];
      selectedEndYear.value = data['endDate']['year'];
    }
    validateForm();
  }

  final ResumeRepo repo = ResumeRepo();

  void setExperienceListFromModel(List<dynamic>? experienceModelList) {
    experienceList.clear();

    if (experienceModelList == null || experienceModelList.isEmpty) {
      return;
    }

    // Map each model object into Map<String, dynamic> for UI usage
    final mappedList = experienceModelList.map<Map<String, dynamic>>((exp) {
      return {
        // Convert model to Map - you can use toJson() or manual mapping if preferred
        // Here using manual mapping based on your JSON keys:
        '_id': exp.id ?? exp.id,
        // adapt if model has `id` property; else exp['_id']
        'startDate': {
          'date': exp.startDate?.date,
          'month': exp.startDate?.month,
          'year': exp.startDate?.year,
        },
        'endDate': exp.endDate != null
            ? {
                'date': exp.endDate?.date,
                'month': exp.endDate?.month,
                'year': exp.endDate?.year,
              }
            : null,
        'previousCompanyName': exp.previousCompanyName ?? '',
        'designation': exp.designation ?? '',
        'jobType': exp.jobType ?? '',
        'workMode': exp.workMode ?? '',
        'location': exp.location ?? '',
        'description': exp.description ?? '',
      };
    }).toList();

    experienceList.assignAll(mappedList);
  }

  Future<void> saveExperience({bool isEdit = false, String? id}) async {
    String? selectedJobTypeRaw = selectedJobType.value;
    String? normalizedJobType;

    if (isFullTime) {
      normalizedJobType = jobTypeMappingFullTime[selectedJobTypeRaw ?? ''];
    } else {
      normalizedJobType = jobTypeMappingPartTime[selectedJobTypeRaw ?? ''];
    }

    if (normalizedJobType == null) {
      return; // or handle error accordingly
    }

    final params = {
      "previousCompanyName": previousCompanyController.text.trim(),
      "designation": designationController.text.trim(),
      "jobType": normalizedJobType,
      "workMode": selectedWorkType.value ?? '',
      "location": locationController.text.trim(),
      "startDate": {
        "date": selectedStartDay.value,
        "month": selectedStartMonth.value,
        "year": selectedStartYear.value,
      },
      "endDate": {
        "date": selectedEndDay.value,
        "month": selectedEndMonth.value,
        "year": selectedEndYear.value,
      },
      "description": descriptionController.text.trim(),
    };

    late ResponseModel res;
    if (isEdit) {
      if (id == null) {
        return;
      }
      res = await repo.updateExperience(
          id: id, params: params, isFullTime: isFullTime);
      commonSnackBar(message: AppStrings.experienceUpdated);
    } else {
      res = await repo.addExperience(params: params, isFullTime: isFullTime);

      commonSnackBar(message: AppStrings.experienceAdded);
    }

    if (res.isSuccess) {
      // await fetchExperience();
      Get.back();
    }
  }

  Future<ResponseModel> deleteExperience({required String id}) async {
    final res = await repo.deleteExperience(id: id, isFullTime: isFullTime);

    if (res.isSuccess) {
      experienceList.clear();
      experienceData.clear();
      clearAllFields();
      commonSnackBar(message: AppStrings.experienceDeleted);
    } else {
      commonSnackBar(message: res.message ?? AppStrings.experienceDeleteFailed);
    }
    return res;
  }

  @override
  void onClose() {
    previousCompanyController.dispose();
    designationController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
