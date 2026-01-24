import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/repo/rental_service_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/widget/show_home_description_suggestion_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeStayRentalServiceController extends GetxController{
  Rx<ApiResponse> addHomeStayRentalServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> generateHomeRentalServiceResponse = ApiResponse.initial('Initial').obs;

  final currentStep = 0.obs;
  int totalSteps = 4;

  final formKeyStep1 = GlobalKey<FormState>();
  final formKeyStep2 = GlobalKey<FormState>();

  final propertyNameCtrl = TextEditingController();
  final mobileNumberCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final pinCodeCtrl = TextEditingController();
  final nearByRailwayCtrl = TextEditingController();
  final nearByAirportCtrl = TextEditingController();
  final nearByBusStandCtrl = TextEditingController();
  final nearByFamousPlaceCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final bedsCountCtrl = TextEditingController();
  final chargeCtrl = TextEditingController();

  final RxList<String> arrHighlights = <String>[].obs;
  final RxList<String> arrMoreRestriction = <String>[].obs;

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool isFetchingAddressDetails = false.obs;

  int maxHomeImageUpload = 4;

  final RxString selectedAdults = ''.obs;
  final RxString selectedChildren = ''.obs;

  final selectedChargesTypes = Rxn<ChargesTypes>();

  final List<String> peopleCountOptions = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];

  RxBool isUnMarried = false.obs;
  RxBool isAllowStudentOrBachelor = false.obs;
  RxBool anyFoodHabitRestriction = false.obs;

  RxMap<String, bool> selectedHabits = <String, bool>{
    'all': false,
    'vegetarian': false,
    'nonVegetarian': false,
  }.obs;

  final List<Map<String, String>> foodHabits = [
    {'id': 'all', 'label': AppStrings.all},
    {'id': 'vegetarian', 'label': AppStrings.vegetarian},
    {'id': 'nonVegetarian', 'label': AppStrings.nonVegetarian},
  ];

  String get selectedFoodHabit {
    if (selectedHabits['all'] == true) return AppStrings.all;
    if (selectedHabits['vegetarian'] == true) return AppStrings.vegetarian;
    if (selectedHabits['nonVegetarian'] == true) return AppStrings.nonVegetarian;
    return '';
  }

  final RxList<File> roomImages = <File>[].obs;
  final RxList<File> kitchenImages = <File>[].obs;
  final RxList<File> bathroomImages = <File>[].obs;
  final RxList<File> roadSideImages = <File>[].obs;
  final RxList<File> otherImages = <File>[].obs;

  void validateStepOne(){
    if(formKeyStep1.currentState!.validate()){
      nextStep();
    }
  }

  void validateStepTwo(){
    if(formKeyStep2.currentState!.validate()){
      if(arrHighlights.isEmpty) {
        commonSnackBar(message: AppStrings.highlightsIsRequired.tr);
        return;
      }

      // if(!isUnMarried.value){
      //   commonSnackBar(message: AppStrings.unmarriedCouplesRequired.tr);
      //   return;
      // }
      //
      // if(!isAllowStudentOrBachelor.value){
      //   commonSnackBar(message: AppStrings.studentsOrBachelorsRequired.tr);
      //   return;
      // }

      if(anyFoodHabitRestriction.value){
        if(selectedFoodHabit.isEmpty){
          commonSnackBar(message: AppStrings.foodHabitRequired.tr);
          return;
        }
      }

      nextStep();

    }
  }

  void validateStepThree(){
      if (roomImages.length < 4) {
        commonSnackBar(message: AppStrings.uploadAtLeast4Room.tr);
        return;
      }
      if (kitchenImages.length < 2) {
        commonSnackBar(message: AppStrings.uploadAtLeast2Kitchen.tr);
        return;
      }
      if (bathroomImages.length < 2) {
        commonSnackBar(message: AppStrings.uploadAtLeast2Bathroom.tr);
        return;
      }

      nextStep();

  }

  void validateStepFour(){
    if (roadSideImages.length < 2) {
      commonSnackBar(message: AppStrings.uploadAtLeast2RoadSide.tr);
       return;
    }

    addHomeStayRentalServiceApi();
  }

  /// Go to the next step
  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }
  }

  /// Go to the previous step
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void onBackPressed(){
    if(currentStep.value > 0){
      previousStep();
    }else{
      Get.back();
    }
  }

  void addHighlights(List<String> highlights) {

    // if(arrHighlights.length == 10){
    //   commonSnackBar(message: 'You can\'t add more than 10 highlights');
    //   return;
    // }

    arrHighlights.clear();

    arrHighlights.value = highlights;
  }

  void addMoreRestrictions(List<String> highlights) {
    arrMoreRestriction.clear();
    arrMoreRestriction.value = highlights;
  }

  RxBool isHomeStayRentalServiceLoading = false.obs;

  Future<void> addHomeStayRentalServiceApi() async {

    try {
      isHomeStayRentalServiceLoading.value = true;

      List<dio.MultipartFile> roadsideParts = [];
      List<dio.MultipartFile> roomParts = [];
      List<dio.MultipartFile> kitchenParts = [];
      List<dio.MultipartFile> bathroomParts = [];
      List<dio.MultipartFile> otherParts = [];

      if (roomImages.isNotEmpty) {
        roomParts = await multiPartMultipleImages(arrImages: roomImages);
      }
      if (kitchenImages.isNotEmpty) {
        kitchenParts = await multiPartMultipleImages(arrImages: kitchenImages);
      }
      if (bathroomImages.isNotEmpty) {
        bathroomParts = await multiPartMultipleImages(arrImages: bathroomImages);
      }
      if (roadSideImages.isNotEmpty) {
        roadsideParts = await multiPartMultipleImages(arrImages: roadSideImages);
      }
      if (otherImages.isNotEmpty) {
        otherParts = await multiPartMultipleImages(arrImages: otherImages);
      }

      Map<String, dynamic> params = {
        ApiKeys.type: 'Property',
        ApiKeys.name: propertyNameCtrl.text,
        ApiKeys.contactNumber: mobileNumberCtrl.text,
        ApiKeys.address: locationCtrl.text,
        ApiKeys.landmark: landmarkCtrl.text,
        ApiKeys.lat : latitude,
        ApiKeys.lng: longitude,
        ApiKeys.pincode: pinCodeCtrl.text,
        ApiKeys.nearbyLocations: jsonEncode({
          ApiKeys.railwayStation: nearByRailwayCtrl.text,
          ApiKeys.airport: nearByAirportCtrl.text,
          ApiKeys.busStand: nearByBusStandCtrl.text,
          ApiKeys.famousPlace: nearByFamousPlaceCtrl.text
        }),
        ApiKeys.description: descriptionCtrl.text,
        ApiKeys.maxPeople: jsonEncode({
          ApiKeys.adults: selectedAdults.value,
          ApiKeys.children: selectedChildren.value,
        }),
        ApiKeys.beds: bedsCountCtrl.text,
        ApiKeys.priceUnit: selectedChargesTypes.value?.label,
        ApiKeys.price: chargeCtrl.text,
        if(arrHighlights.isNotEmpty) ApiKeys.highlights: jsonEncode(arrHighlights),
        ApiKeys.restrictions: jsonEncode({
          ApiKeys.unmarriedCoupleAllowed: isUnMarried.value,
          ApiKeys.studentOrBachelorAllowed: isAllowStudentOrBachelor.value,
          ApiKeys.foodRestriction: {
            ApiKeys.isFoodRestriction: anyFoodHabitRestriction.value,
            if (anyFoodHabitRestriction.value) ApiKeys.allowedFood: selectedFoodHabit
          },
        }),
        if(arrMoreRestriction.isNotEmpty) ApiKeys.additionalRules: jsonEncode(arrMoreRestriction),
        if(roomParts.isNotEmpty) ApiKeys.roomImages: roomParts,
        if(kitchenParts.isNotEmpty) ApiKeys.kitchenImages: kitchenParts,
        if(bathroomParts.isNotEmpty) ApiKeys.bathroomImages: bathroomParts,
        if(roadsideParts.isNotEmpty) ApiKeys.roadImages: roadsideParts,
        if(otherParts.isNotEmpty) ApiKeys.otherImages: otherParts,
      };

      ResponseModel response = await RentalServiceRepo().addRentalServiceRepo(
        params: params,
      );

      if (response.isSuccess) {
        addHomeStayRentalServiceResponse.value = ApiResponse.complete(response);
        await setEarnServiceOptData(true);
        Get.until(
              (route) =>
          route.settings.name ==
              RouteHelper.getEarnServiceAvailableOptionsScreenRoute(),
        );
      } else {
        addHomeStayRentalServiceResponse.value = ApiResponse.error('error');
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    } catch (e) {
      addHomeStayRentalServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    }finally{
      isHomeStayRentalServiceLoading.value = false;
    }
  }

  RxBool isGenerateHomeRentalServiceLoading = false.obs;
  var descriptionSuggestions = <String>[].obs;
  var selectedDescription = "".obs;

  Future<void> generateHomeDescriptionApi() async {
    if(bedsCountCtrl.text.isEmpty || arrHighlights.isEmpty){
      commonSnackBar(message: AppStrings.enterBedCountAndHighlights.tr);
      return;
    }

    try {
      isGenerateHomeRentalServiceLoading.value = true;
      descriptionSuggestions.clear();
      selectedDescription.value = '';

      Map<String, dynamic> params = {
        ApiKeys.propertyName: propertyNameCtrl.text,
        ApiKeys.noOfBeds: bedsCountCtrl.text,
        ApiKeys.propertyLocation: locationCtrl.text,
        ApiKeys.propertyHighlight: jsonEncode(arrHighlights)
      };

      ResponseModel response = await RentalServiceRepo().generateHomeDescriptionRepo(
        params: params,
      );

      if (response.isSuccess) {
        generateHomeRentalServiceResponse.value = ApiResponse.complete(response);

        final List<dynamic>? responseData = response.response?.data['description_suggestions'];

        if (responseData != null && responseData.isNotEmpty) {
          descriptionSuggestions.value =
              responseData.map((e) => e.toString()).toList();

          await showHomeDescriptionSuggestionsDialog();
        } else {
          commonSnackBar(message: AppStrings.homeDescriptionSuggestionsNotFound.tr);
        }
      }
    } catch (e) {
      generateHomeRentalServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    } finally{
      isGenerateHomeRentalServiceLoading.value = false;
    }
  }


}