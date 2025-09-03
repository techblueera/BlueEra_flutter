import 'package:BlueEra/core/api/model/get_resume_data_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

String monthName(int month) {
  const months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return months[month];
}

class CurrentJobController extends GetxController {
  final currentJob = ''.obs;

  final workExperienceList = <Map<String, String>>[].obs;
  final experienceOptions = ['Fresher', 'Experienced'];
  // final jobModeOptions = ['Full-Time', 'Part-Time', 'Internship'];
  static const Map<String, String> jobModeMapping = {
    'Full Time': 'Full Time',
    'Part Time': 'Part Time',
    'Contract': 'Contract',
    'Internship': 'Internship',
    'Temporary': 'Temporary',
  };

  List<String> get jobModeOptions => jobModeMapping.keys.toList();

  final yesNoOptions = ['Yes', 'No'];
  final workTypeOptions = ['Remote', 'Onsite', 'Hybrid'];
  final selectedExperience = RxnString();
  final selectedJobMode = RxnString();
  final selectedCurrent = RxnString();
  final selectedWorkType = RxnString();
  final currentCompanyController = TextEditingController();
  final designationController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  final selectedDay = RxnInt();
  final selectedMonth = RxnInt();
  final selectedYear = RxnInt();
  final isDateValid = true.obs;

  final isCurrentJobFormValid = false.obs;
  Map<String, dynamic>? rawCurrentJobData;

  void validateCurrentJobForm() {
    bool dateOk = isDateValid();
    isDateValid.value = dateOk;
    bool allFieldsValid = selectedExperience.value != null &&
        selectedExperience.value!.trim().isNotEmpty &&
        selectedJobMode.value != null &&
        selectedCurrent.value != null &&
        selectedWorkType.value != null &&
        currentCompanyController.text.trim().isNotEmpty &&
        designationController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        dateOk &&
        selectedDay.value != null &&
        selectedMonth.value != null &&
        selectedYear.value != null;

    isCurrentJobFormValid.value = allFieldsValid;
  }

  @override
  void onInit() {
    currentCompanyController.addListener(validateCurrentJobForm);
    designationController.addListener(validateCurrentJobForm);
    locationController.addListener(validateCurrentJobForm);
    descriptionController.addListener(validateCurrentJobForm);

    ever(selectedExperience, (_) => validateCurrentJobForm());
    ever(selectedJobMode, (_) => validateCurrentJobForm());
    ever(selectedCurrent, (_) => validateCurrentJobForm());
    ever(selectedWorkType, (_) => validateCurrentJobForm());
    ever(selectedDay, (_) => validateCurrentJobForm());
    ever(selectedMonth, (_) => validateCurrentJobForm());
    ever(selectedYear, (_) => validateCurrentJobForm());

    super.onInit();
  }

  @override
  void onClose() {
    currentCompanyController.dispose();
    designationController.dispose();
    locationController.dispose();
    descriptionController.dispose();
  }

  void clearAllFields() {
    currentCompanyController.clear();
    designationController.clear();
    locationController.clear();
    descriptionController.clear();
    selectedExperience.value = null;
    selectedJobMode.value = null;
    selectedCurrent.value = null;
    selectedWorkType.value = null;
    selectedDay.value = null;
    selectedMonth.value = null;
    selectedYear.value = null;
    isCurrentJobFormValid.value = false;
  }

  void setCurrentJobFromModel(CurrentJob? job) {
    workExperienceList.clear();

    rawCurrentJobData = null;
    if (job == null) return;
    rawCurrentJobData = job.toJson();
    // Prepare labels for UI display
    String startLabel = "";
    if (job.startDate != null &&
        job.startDate!.month != null &&
        job.startDate!.year != null) {
      startLabel =
          '${monthName(job.startDate!.month!).substring(0, 3)}, ${job.startDate!.year}';
    }

    // Add mapped job information in expected UI format
    workExperienceList.add({
      'startLabel': startLabel,
      'endLabel': 'Present',
      'designation': job.designation ?? '',
      'companyRow': '${job.currentCompanyName ?? ''}, ${job.jobType ?? ''}',
      'locationRow': '${job.location ?? ''} - ${job.workMode ?? ''}',
      'description': job.description ?? '',
    });
  }

  Future<void> saveCurrentJob(Map<String, dynamic> params) async {
    final res = await ResumeRepo().saveCurrentJob(params: params);
    if (res.isSuccess) {
      // await fetchCurrentJobDetails();
      Get.back();
    } else {}
  }

  void setFieldsFromBackend(Map<String, dynamic> jobData) {
    selectedExperience.value = jobData['experience'];
    selectedJobMode.value = jobData['jobType'];
    currentCompanyController.text = jobData['currentCompanyName'] ?? '';
    selectedCurrent.value =
        (jobData['currentlyWorkingHere'] == true) ? "Yes" : "No";
    designationController.text = jobData['designation'] ?? '';
    selectedWorkType.value = jobData['workMode'];
    locationController.text = jobData['location'] ?? '';
    descriptionController.text = jobData['description'] ?? '';
    // Dates
    if (jobData['startDate'] != null) {
      selectedDay.value = jobData['startDate']['date'];
      selectedMonth.value = jobData['startDate']['month'];
      selectedYear.value = jobData['startDate']['year'];
    } else {
      selectedDay.value = null;
      selectedMonth.value = null;
      selectedYear.value = null;
    }
  }

  Future<void> deleteCurrentJob() async {
    final res = await ResumeRepo().deleteCurrentJob();
    if (res.isSuccess) {
      workExperienceList.clear();
      clearAllFields(); // Clean up form fields too
      // await fetchCurrentJobDetails();
      commonSnackBar(message: "Current Job deleted");
    } else {
      commonSnackBar(message: "Failed to delete job");
    }
  }
}
