import 'dart:convert';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/add_place_req_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_one_controller.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/features/common/map/repo/add_place_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step two of adding a place: contact details and visiting hours, then the
/// submit. Registered by AddPlaceBinding with the step one and visiting-hours
/// controllers it reads when submitting.
class AddPlaceStepTwoController extends GetxController {
  AddPlaceStepTwoController(
      {required AddPlaceRepo repo,
      required AddPlaceStepOneController stepOne,
      required VisitingHoursSelectorController visitingHours})
      : _repo = repo,
        _stepOne = stepOne,
        _visitingHours = visitingHours;

  final AddPlaceRepo _repo;
  final AddPlaceStepOneController _stepOne;
  final VisitingHoursSelectorController _visitingHours;

  final TextEditingController shortDescriptionController =
      TextEditingController();
  final TextEditingController mobileCodeController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Rx<ContactType?> selectedType = Rx<ContactType?>(ContactType.Mobile);
  RxBool validate = false.obs;

  RxMap<String, TimeOfDay> startTimes = <String, TimeOfDay>{}.obs;
  RxMap<String, TimeOfDay> endTimes = <String, TimeOfDay>{}.obs;

  @override
  void onClose() {
    shortDescriptionController.dispose();
    mobileCodeController.dispose();
    mobileNumberController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void setContactType(ContactType type) {
    selectedType.value = type;
  }

  void validateForm() {
    final emailIsNotEmpty = emailController.text.isNotEmpty;
    validate.value = emailIsNotEmpty;
  }

  /// Submits the place for review. Returns true when it was received.
  Future<bool> submitPlace() async {
    final addPlaceController = _stepOne;
    final visitingHoursSelectorController = _visitingHours;

    // Format visiting hours data for API in the required JSON format
    List<Map<String, dynamic>> visitingHoursData = [];

    visitingHoursSelectorController.visitingHours.forEach((day, isOpen) {
      if (isOpen) {
        // Only include days that are toggled on (open)
        final startTime = visitingHoursSelectorController
            .formatTime(visitingHoursSelectorController.startTimes[day]!);
        final endTime = visitingHoursSelectorController
            .formatTime(visitingHoursSelectorController.endTimes[day]!);

        // Format as a Map with day, open status, startTime and endTime
        visitingHoursData.add({
          "day": day,
          "open": true,
          "startTime": startTime,
          "endTime": endTime
        });
      }
    });

    logs("Visiting Hours: $visitingHoursData");

    // Convert the list of maps to a JSON string
    final visitingHoursJson =
        visitingHoursData.isNotEmpty ? jsonEncode(visitingHoursData) : null;
    logs("Visiting Hours:2222 $visitingHoursJson");

    try {
      // Add category IDs to the form data

      ResponseModel responseModel = await _repo.addPlacePost(
          placeReq: AddPlaceReqModel(
        photoPath: addPlaceController.selectedImages,
        category: addPlaceController.selectedCategoryIds,
        // Use the selected category IDs
        name: addPlaceController.placesController.text,
        latitude: addPlaceController.lat.value,
        longitude: addPlaceController.long.value,
        address: addPlaceController.landmarkController.text,
        email: emailController.text,
        phone: mobileNumberController.text,
        isCommercial: addPlaceController.isConfirmCheck.value,
        shortDescription: shortDescriptionController.text,
        visitingHours: visitingHoursJson,
      ));
      final data = responseModel.response?.data;
      if (responseModel.isSuccess) return true;
      commonSnackBar(
          message: data['message'] ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      logs("ERROR ${e.toString()}");
      return false;
    }
  }
}
