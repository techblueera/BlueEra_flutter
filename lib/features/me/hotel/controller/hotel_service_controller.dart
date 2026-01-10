import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/ai_hotel_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/hotel/view/ai_hotel_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelServiceController extends GetxController {
  ///GENERATE VIA AI SCHOOL DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxDouble lat = 0.0.obs;
  RxDouble lng = 0.0.obs;
  // Text Editing Controllers for the Form
  final policeController = TextEditingController();
  final hospitalController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  RxString cityName = "".obs;
  RxString pinCodeName = "".obs;
  RxString stateName = "".obs;
  RxString policeStationName = "".obs;
  RxString hospitalName = "".obs;
  RxString phoneNumber = "".obs;
  RxString hotelAddress = "".obs;

  // Load existing data into controllers before opening Bottom Sheet
  void prepareEditFields() {
    final emergency =
        aiHotelResModel?.value.data?.screens?.contactUs?.emergency;
    policeController.text = emergency?.policeStation ?? "";
    hospitalController.text = emergency?.hospital ?? "";
    phoneController.text = emergency?.phone ?? "";
    validateFields();
    // Note: City/State/Pincode aren't in your original JSON,
    // but we handle them for your custom fields
  }

// Reactive variable to track button state
  var isFormValid = false.obs;

  // Function to validate all fields
  void validateFields() {
    bool isValid = policeStationName.value.isNotEmpty &&
        hospitalName.value.isNotEmpty &&
        phoneNumber.value.length == 10 &&
      cityName.value.isNotEmpty &&
       stateName.value.isNotEmpty &&
        pinCodeName.value.length == 6;

    isFormValid.value = isValid;
  }

  void updateEmergencyDetails() {
    final emergency =
        aiHotelResModel?.value.data?.screens?.contactUs?.emergency;
    if (emergency != null) {
      emergency.policeStation = policeController.text;
      emergency.hospital = hospitalController.text;
      emergency.phone = phoneController.text;
      // Update local state and refresh UI
      aiHotelResModel?.refresh();
      Get.back(); // Close Bottom Sheet
      commonSnackBar(message: "Success Contact details updated locally");
    }
  }

  clearAiGenerateFiled() {
    searchController.clear();
    websiteController.clear();
    policeController.clear();
    phoneController.clear();
    hospitalController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
    cityName.value = "";
    stateName.value = "";
    pinCodeName.value = "";
    policeStationName.value = "";
    hospitalName.value = "";
    phoneNumber.value = "";
  }

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    policeController.dispose();
    phoneController.dispose();
    hospitalController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  Rx<AiHotelResModel>? aiHotelResModel = AiHotelResModel().obs;

  Future<void> aiHotelFetchDetailsController() async {
    String hotelName = searchController.text;
    hotelAddress.value = searchController.text;
    String website = websiteController.text;
    // Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
          await HotelServiceRepo().aiHotelFetchDetailsRepo(reqBody: {
        // "name":
        //     "MAHARAJA HOTEL, Reemapark Society, Mahavirnagar, Harikurpa Society, Motera, Ahmedabad, Gujarat, India",
        // "url": "https://maharaja.ahmedabadhotels.net/en/",
        // "address":
        //     "MAHARAJA HOTEL, Reemapark Society, Mahavirnagar, Harikurpa Society, Motera, Ahmedabad, Gujarat, India"
        ApiKeys.name: hotelName,
        ApiKeys.url: website,
        ApiKeys.address: hotelName,
      });
      if (response.isSuccess) {
        final data = response.response?.data;
        aiHotelResModel?.value = AiHotelResModel.fromJson(data);

        Get.to(HotelPreviewScreen());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: e.toString());
    }
  }

  Future<void> createHotelServiceController() async {
    try {
      AiHotelData data = aiHotelResModel?.value.data ?? AiHotelData();
      final reqData = {
        "name": data.appMetadata?.appName,
        "pincode": pinCodeName.value,
        "address":  hotelAddress.value,
        "city": cityName.value,
        "state": stateName.value,
        "contactNumber": phoneNumber.value,
        "email": data.screens?.contactUs?.reception?.email ?? "",
        "checkInTime": data.screens?.hotelPolicies?.checkInTime ?? "12:00 PM",
        "checkOutTime": data.screens?.hotelPolicies?.checkOutTime ?? "11:00 AM",
        "website": data.screens?.contactUs?.website ?? "",
        "description": data.screens?.aboutProperty?.description ?? "",
        "departments": [
          {
            "title": "Reception",
            "email": data.screens?.contactUs?.reception?.email ?? "",
            "phone": data.screens?.contactUs?.reception?.phone ?? "",
          }
        ],
        "emergencyContacts": {
          "phone": data.screens?.contactUs?.emergency?.phone ?? "",
          "policeStation":
              data.screens?.contactUs?.emergency?.policeStation ?? "",
          "hospital": data.screens?.contactUs?.emergency?.hospital ?? "",
          "fireBrigade": data.screens?.contactUs?.emergency?.fireBrigade ?? ""
        }
      };

      ResponseModel response =
          await HotelServiceRepo().createHotelServiceRepo(reqBody: reqData);
      if (response.isSuccess) {
        hotelAddress.value="";
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: e.toString());
    }
  }




}
