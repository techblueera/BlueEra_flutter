import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PublicationsController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();
  
  // final getResumeController = Get.find<ProfilePicController>();
  // final getResumeController = getOrPut(() => ProfilePicController());

  // Form controllers
  final titleController = TextEditingController();
  final linkController = TextEditingController();
  final descriptionController = TextEditingController();

  // Date controllers
  final dateController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();

  // Observables
  final publications = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final selectedPublication = Rxn<Map<String, dynamic>>();
  RxnString selectedPublicationId = RxnString();


  @override
  void onClose() {
    titleController.dispose();
    linkController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.onClose();
  }

  // Clear form
  void clearForm() {
    titleController.clear();
    linkController.clear();
    descriptionController.clear();
    dateController.clear();
    monthController.clear();
    yearController.clear();
    selectedPublication.value = null;
    selectedPublicationId.value = null;
  }

  // Fill form for editing - FIXED VERSION
  void fillFormForEdit(Map<String, dynamic> publication) {
    try {
      selectedPublication.value = publication;
      selectedPublicationId.value = publication['_id']?.toString() ?? '';

      titleController.text = publication['title']?.toString() ?? '';
      linkController.text = publication['link']?.toString() ?? '';
      descriptionController.text = publication['description']?.toString() ?? '';

      // FIXED: Handle date parsing with proper null checks and type conversion
      if (publication['publishedDate'] != null) {
        final publishedDate = publication['publishedDate'];

        // Safe parsing with type conversion
        dateController.text = _safeParseInt(publishedDate['date']).toString();
        monthController.text = _safeParseInt(publishedDate['month']).toString();
        yearController.text = _safeParseInt(publishedDate['year']).toString();
      }
    } catch (e) {
      print("Error in fillFormForEdit: $e");
      clearForm();
    }
  }

  // Helper method to safely parse int values
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }


  /// ADD PUBLICATION
  Future<void> addPublicationApi() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      // Create publication object as per API requirement
      final publicationData = {
        "publications": [
          {
            "title": titleController.text.trim(),
            "link": linkController.text.trim(),
            "publishedDate": {
              "date": int.parse(dateController.text),
              "month": int.parse(monthController.text),
              "year": int.parse(yearController.text)
            },
            "description": descriptionController.text.trim()
          }
        ]
      };

      final response = await _repo.addPublication(params: publicationData);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.publicationAdded);
        clearForm();
        await callAPIGetResume();

      } else {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.somethingWentWrong);
      }
    } catch (e) {
      print("ERROR in addPublicationApi: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  /// UPDATE PUBLICATION - FIXED VERSION
  Future<void> updatePublicationApi() async {
    if (!_validateForm()) return;

    final id = selectedPublicationId.value;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: AppStrings.publicationIdMissing);
      return;
    }

    final publicationData = {
      "title": titleController.text.trim(),
      "link": linkController.text.trim(),
      "publishedDate": {
        "date": _safeParseInt(dateController.text),
        "month": _safeParseInt(monthController.text),
        "year": _safeParseInt(yearController.text),
      },
      "description": descriptionController.text.trim(),
    };

    try {
      isLoading.value = true;
      final response = await _repo.updatePublication(
        id: id,
        params: publicationData,
      );

      if (response.statusCode == 200) {
        commonSnackBar(message: AppStrings.publicationUpdated);
        clearForm();
        // await getAllPublicationsApi();
        await callAPIGetResume();
      } else {
        commonSnackBar(message: response.data?['message'] ??AppStrings.publicationUpdateFailed);
      }
    } catch (e) {
      print("Update error: $e");
      commonSnackBar(message: AppStrings.publicationUpdateFailed);
    } finally {
      isLoading.value = false;
    }
  }

  /// DELETE PUBLICATION
  Future<void> deletePublicationApi(String id,int index) async {
    try {
      isLoading.value = true;
      final response = await _repo.deletePublication(id: id);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.publicationDeleted);
        publications.removeAt(index);
        // await getAllPublicationsApi();
        await callAPIGetResume();

      } else {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.somethingWentWrong);
      }
    } catch (e) {
      print("ERROR in deletePublicationApi: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  /// VALIDATE FORM
  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.publicationEnterTitle);
      return false;
    }

    if (linkController.text.trim().isEmpty) {
      commonSnackBar(message:AppStrings.publicationEnterLink);
      return false;
    }

    // Validate URL format
    if (!GetUtils.isURL(linkController.text.trim())) {
      commonSnackBar(message: AppStrings.publicationEnterValidUrl);
      return false;
    }

    if (dateController.text.trim().isEmpty ||
        monthController.text.trim().isEmpty ||
        yearController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.publicationEnterCompleteDate);
      return false;
    }

    // Validate date values with safe parsing
    try {
      final date = _safeParseInt(dateController.text);
      final month = _safeParseInt(monthController.text);
      final year = _safeParseInt(yearController.text);

      if (date < 1 || date > 31) {
        commonSnackBar(message: AppStrings.publicationEnterValidDay);
        return false;
      }

      if (month < 1 || month > 12) {
        commonSnackBar(message: AppStrings.publicationEnterValidMonth);
        return false;
      }

      if (year < 1900 || year > DateTime.now().year) {
        commonSnackBar(message: AppStrings.publicationEnterValidYear);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.publicationEnterValidNumeric);
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      commonSnackBar(message:AppStrings.publicationEnterDescription);
      return false;
    }

    return true;
  }
}
