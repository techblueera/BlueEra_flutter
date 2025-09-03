import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/journey/repo/travel_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JourneyPlanningController extends GetxController {
  // Text controllers for input fields
  final TextEditingController startFromController = TextEditingController();
  final TextEditingController exactTransportationController =
      TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  Rx<ApiResponse> travelCreateResponse = ApiResponse.initial('Initial').obs;

  // Observable variables for form validation
  RxBool isFormValid = false.obs;

  // Observable variables for transportation type selection
  RxString selectedTransportationType = "".obs;

  // Observable lists for stoppage data
  RxList<StoppageData> stoppages = <StoppageData>[].obs;

  // Added variables to store location data
  RxDouble? startLocationLat = 0.0.obs;
  RxDouble? startLocationLng = 0.0.obs;
  RxString startLocationAddress = "".obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with two default stoppages
    stoppages.add(StoppageData(
        lat: "".obs,
        long: "".obs,
        city: TextEditingController(),
        attractions: [TextEditingController()]));
    stoppages.add(StoppageData(
        lat: "".obs,
        long: "".obs,
        city: TextEditingController(),
        attractions: [TextEditingController()]));

    // Add listeners to validate form
    startFromController.addListener(validateForm);
    exactTransportationController.addListener(validateForm);
  }

  // Method to set start location data
  void setStartLocation(double? lat, double? lng, String address) {
    if (lat != null) startLocationLat?.value = lat;
    if (lng != null) startLocationLng?.value = lng;
    startLocationAddress.value = address;
  }

  @override
  void onClose() {
    // Dispose all controllers
    startFromController.dispose();
    exactTransportationController.dispose();
    descriptionController.dispose();

    for (var stoppage in stoppages) {
      stoppage.city.dispose();
      for (var attraction in stoppage.attractions) {
        attraction.dispose();
      }
    }

    super.onClose();
  }

  // Method to add a new attraction to a stoppage
  void addAttraction(int stoppageIndex) {
    stoppages[stoppageIndex].attractions.add(TextEditingController());
    update();
  }

  // Method to add a new stoppage
  // Add a new stoppage
  void addStoppage() {
    stoppages.add(StoppageData(
        lat: "".obs,
        long: "".obs,
        city: TextEditingController(),
        attractions: [TextEditingController()]));
    validateForm();
  }

  // Method to set the selected transportation type
  void setTransportationType(String type) {
    selectedTransportationType.value = type;
    validateForm();
  }

  // Method to validate the form
  void validateForm() {
    isFormValid.value = startFromController.text.isNotEmpty &&
        selectedTransportationType.isNotEmpty &&
        stoppages.every((stoppage) => stoppage.city.text.isNotEmpty) &&
        stoppages.every((stoppage) => stoppage.attractions
            .every((attraction) => attraction.text.isNotEmpty));
  }

  // Method to submit the journey plan
  Future<void> submitJourneyPlan() async {
    if (!isFormValid.value) return;

    List<Map<String, dynamic>> stoppageList = [];
    List<String> myPlaceList = [];
    for (int i = 0; i < stoppages.length; i++) {
      myPlaceList.clear();
      print(
          'Stoppage ${i + 1}: ${stoppages[i].city.text}=====${stoppages[i].lat},${stoppages[i].long}');
      for (int j = 0; j < stoppages[i].attractions.length; j++) {
        print('  Attraction ${j + 1}: ${stoppages[i].attractions[j].text}');
        myPlaceList.add(stoppages[i].attractions[j].text);
      }

      stoppageList.add({
        "location": {
          "city": stoppages[i].city.text,
          "latitude": stoppages[i].lat.value,
          "longitude": stoppages[i].long.value,
        },
        "places": myPlaceList
      });
    }
    var reqParm = {
      ApiKeys.start_from: {
        ApiKeys.city: "${startFromController.text}",
        ApiKeys.latitude: startLocationLat?.value.toString(),
        ApiKeys.longitude: startLocationLng?.value.toString(),
      },
      if (selectedTransportationType.value.isNotEmpty)
        ApiKeys.start_via: selectedTransportationType.value,
      if (exactTransportationController.text.isNotEmpty)
        ApiKeys.transport_info: exactTransportationController.text,
      if (descriptionController.text.isNotEmpty)
        ApiKeys.description: descriptionController.text,
      ApiKeys.stoppages: stoppageList,
    };
    // return;
    try {
      ResponseModel responseModel = await TravelRepo().travelCreatePost(
        reqParma: reqParm,
      );
      final data = responseModel.response?.data;
      // clearData();
      if (responseModel.isSuccess) {
        commonSnackBar(
            message:
                responseModel.response?.data['message'] ?? AppStrings.success);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        travelCreateResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      travelCreateResponse.value = ApiResponse.error('error');
    }
  }
}

// Class to hold stoppage data
class StoppageData {
  TextEditingController city;
  RxList<TextEditingController> attractions;
  RxBool isDropdownOpen = false.obs;
  RxString selectedCity = "".obs;
  RxString lat = "".obs;
  RxString long = "".obs;

  // List of cities for dropdown

  StoppageData(
      {required this.city,
      required List<TextEditingController> attractions,
      required this.lat,
      required this.long})
      : attractions = attractions.obs;
}
