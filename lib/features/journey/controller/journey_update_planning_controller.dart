import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_journey_detilas_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/reel/models/social_input_fields_model.dart';
import 'package:BlueEra/features/journey/controller/journey_planning_controller.dart';
import 'package:BlueEra/features/journey/repo/travel_repo.dart';
import 'package:dio/dio.dart' as dioObj;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class JourneyUpdatePlanningController extends GetxController {
  Rx<ApiResponse> travelCreateResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> travelEndResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> journeyDetailsResponse = ApiResponse.initial('Initial').obs;

  // Text controllers for input fields
  // final TextEditingController startFromController = TextEditingController();
  final TextEditingController exactTransportationController =
      TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController stayInfoController = TextEditingController();
  final TextEditingController foodInfoController = TextEditingController();
  final List<SocialInputFieldsModel> travelSocialLink = [
    SocialInputFieldsModel(
      name: 'YouTube',
      icon: 'assets/svg/youtube_grey.svg',
      linkController: TextEditingController(),
    ),
    SocialInputFieldsModel(
      name: 'Twitter',
      icon: 'assets/svg/x_grey.svg',
      linkController: TextEditingController(),
    ),
    SocialInputFieldsModel(
      name: 'LinkedIn',
      icon: 'assets/svg/linkedlin_grey.svg',
      linkController: TextEditingController(),
    ),
    SocialInputFieldsModel(
      name: 'Instagram',
      icon: 'assets/svg/instagram_grey.svg',
      linkController: TextEditingController(),
    ),
    SocialInputFieldsModel(
      name: 'Website',
      icon: 'assets/svg/website.svg',
      linkController: TextEditingController(),
    ),
  ];

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

  // Photo upload variables
  final ImagePicker _picker = ImagePicker();
  final RxList<String> selectedPhotos = <String>[].obs;
  final RxList<File> selectedPhotoFiles = <File>[].obs;
  final int maxPhotos = 10; // Maximum 10 photos as per requirement

  @override
  void onInit() {
    super.onInit();
    // // Initialize with two default stoppages
    // stoppages.add(StoppageData(
    //     lat: "".obs,
    //     long: "".obs,
    //     city: TextEditingController(),
    //     attractions: [TextEditingController()]));
    // stoppages.add(StoppageData(
    //     lat: "".obs,
    //     long: "".obs,
    //     city: TextEditingController(),
    //     attractions: [TextEditingController()]));

    // Add listeners to validate form
    // startFromController.addListener(validateForm);
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
    // startFromController.dispose();
    exactTransportationController.dispose();
    descriptionController.dispose();
    stayInfoController.dispose();
    foodInfoController.dispose();

    for (var stoppage in stoppages) {
      stoppage.city.dispose();
      for (var attraction in stoppage.attractions) {
        attraction.dispose();
      }
    }

    super.onClose();
  }

  // Method to add photos
  void addPhotos() async {
    if (selectedPhotos.length >= maxPhotos) {
      commonSnackBar(
        message: 'You can only upload up to $maxPhotos photos',
      );
      return;
    }

    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      for (var image in images) {
        if (selectedPhotos.length < maxPhotos) {
          selectedPhotos.add(image.path);
          selectedPhotoFiles.add(File(image.path));
        } else {
          break;
        }
      }
    }
  }

  // Method to remove a photo
  void removePhoto(int index) {
    if (index >= 0 && index < selectedPhotos.length) {
      selectedPhotos.removeAt(index);
      selectedPhotoFiles.removeAt(index);
    }
  }

  // Method to add a new attraction to a stoppage
  void addAttraction(int stoppageIndex) {
    stoppages[stoppageIndex].attractions.add(TextEditingController());
    update();
  }

  // Method to add a new stoppage
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
    isFormValid.value = /* startFromController.text.isNotEmpty &&*/
        selectedTransportationType.isNotEmpty &&
            stoppages.every((stoppage) => stoppage.city.text.isNotEmpty) &&
            stoppages.every((stoppage) => stoppage.attractions
                .every((attraction) => attraction.text.isNotEmpty));
  }

  /// Method to submit the journey plan
  Future<void> submitJourneyPlan({required String? journeyId}) async {
    if (!isFormValid.value) return;

    List<Map<String, dynamic>> stoppageList = [];
    for (int i = 0; i < stoppages.length; i++) {
      List<String> myPlaceList = [];
      for (int j = 0; j < stoppages[i].attractions.length; j++) {
        myPlaceList.add(stoppages[i].attractions[j].text);
      }
      stoppageList.add({
        ApiKeys.location: {
          ApiKeys.city: stoppages[i].city.text,
          ApiKeys.latitude: stoppages[i].lat.value,
          ApiKeys.longitude: stoppages[i].long.value,
        },
        ApiKeys.places: myPlaceList
      });
    }
    logs("stoppageList===== ${stoppageList}");

    /// Request data for social links
    dynamic socialLinkRequestData = travelSocialLink
        .where((field) => field.linkController.text.trim().isNotEmpty)
        .map((field) {
      String rawUrl = field.linkController.text.replaceAll(" ", "");
      return rawUrl;
    }).toList();
// Prepare FormData
    dioObj.FormData formData = dioObj.FormData.fromMap({
      ApiKeys.journey_id: journeyId,
      // ApiKeys.start_from: {
      //   ApiKeys.city: startFromController.text,
      //   ApiKeys.latitude: startLocationLat?.value.toString(),
      //   ApiKeys.longitude: startLocationLng?.value.toString(),
      // },
      if (selectedTransportationType.value.isNotEmpty)
        ApiKeys.start_via: selectedTransportationType.value,
      if (exactTransportationController.text.isNotEmpty)
        ApiKeys.transport_info: exactTransportationController.text,
      if (descriptionController.text.isNotEmpty)
        ApiKeys.description: descriptionController.text,
      ApiKeys.stoppages: stoppageList,
      if (stayInfoController.text.isNotEmpty)
        ApiKeys.stay_info: stayInfoController.text,
      if (foodInfoController.text.isNotEmpty)
        ApiKeys.food_info: foodInfoController.text,
      if (socialLinkRequestData.isNotEmpty)
        ApiKeys.links: socialLinkRequestData.join(","),
      if (selectedPhotoFiles.isNotEmpty)
        ApiKeys.media: await Future.wait(
          selectedPhotoFiles.map((file) async {
            return await dioObj.MultipartFile.fromFile(file.path,
                filename: file.path.split('/').last);
          }),
        ),
    });
    // return;
    try {
      ResponseModel responseModel = await TravelRepo().updateTravelJourneyPost(
        reqParma: formData,
      );
      final data = responseModel.response?.data;
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

  ///END JOURNEY...
  Future<void>? endTravelController({required String? journeyId}) async {
    try {
      ResponseModel responseModel =
          await TravelRepo().travelEndJourney(journeyId: journeyId);
      final data = responseModel.response?.data;
      if (responseModel.isSuccess) {
        commonSnackBar(
            message:
                responseModel.response?.data['message'] ?? AppStrings.success);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        travelEndResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      travelEndResponse.value = ApiResponse.error('error');
    }
    return null;
  }

  ///GET JOURNEY DETAILS...

  Future<void>? getJourneyDetails({required String? journeyId}) async {
    try {
      ResponseModel responseModel =
          await TravelRepo().journeyDetails(journeyId: journeyId);
      final data = responseModel.response?.data;
      if (responseModel.isSuccess) {
        GetJourneyDetailsModel getJourneyDetailsModel =
            GetJourneyDetailsModel.fromJson(data);

        if (getJourneyDetailsModel.data?.stoppages?.isNotEmpty ?? false) {
          List<TextEditingController> myPlaceList = [];
          getJourneyDetailsModel.data?.stoppages?.forEach((dataStoppages) {
            myPlaceList.clear();
            dataStoppages.places?.forEach((place) {
              myPlaceList.add(TextEditingController(text: place));
            });

            stoppages.add(StoppageData(
              lat: "${dataStoppages.location?.latitude}".obs,
              long: "${dataStoppages.location?.longitude}".obs,
              city: TextEditingController(text: dataStoppages.location?.city),
              attractions: myPlaceList,
            ));
          });
          //    for (int i = 0; i < ; i++) {
          // //
          //      // stoppages.add({
          //      //   ApiKeys.location: {
          //      //     ApiKeys.city: stoppages[i].city.text,
          //      //     ApiKeys.latitude: stoppages[i].lat.value,
          //      //     ApiKeys.longitude: stoppages[i].long.value,
          //      //   },
          //      //   ApiKeys.places: myPlaceList
          //      // });
          //    }
        }
        journeyDetailsResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: data['message'] ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERROR ${e.toString()}");
      journeyDetailsResponse.value = ApiResponse.error('error');
    }
    return null;
  }
}
