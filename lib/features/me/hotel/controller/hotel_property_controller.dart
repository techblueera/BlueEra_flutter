import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get.dart';

class HotelPropertyController extends GetxController {
  // Mocking the raw response from your input
  var policyData = {}.obs;
  var is24Hours = false.obs;

  // This map stores the user selections: { "catalogNodeId": value }
  var userSelections = <String, dynamic>{}.obs;

  // This map stores toggle states (isActive/isEnabled)
  var activeStates = <String, bool>{}.obs;

  List<String> timeSlots =
      List.generate(24, (i) => "${i.toString().padLeft(2, '0')}:00");

// Helper to find a specific child node by its KEY



  Future<void> submitData() async {
    // Map the local state back to your requested format
    var reqBODY = {
      "nodes": activeStates.entries.map((e) {
        var node = {
          "catalogNodeId": e.key,
          "isActive": e.value,
        };
        if (userSelections.containsKey(e.key)) {
          node["data"] = userSelections[e.key];
        }
        return node;
      }).toList()
    };
    ResponseModel response =
        await HotelServiceRepo().addHotelPoliciesRepo(reqBody: reqBODY);

    if (response.isSuccess) {
      Get.back();
      commonSnackBar(message: response.response?.data['message']);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}