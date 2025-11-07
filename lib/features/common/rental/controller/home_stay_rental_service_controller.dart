import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/common/rental/repo/rental_service_repo.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeStayRentalServiceController extends GetxController{
  Rx<ApiResponse> addHomeStayRentalServiceResponse = ApiResponse.initial('Initial').obs;

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

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool isFetchingAddressDetails = false.obs;

  int maxHomeImageUpload = 4;

  final RxString selectedAdults = ''.obs;
  final RxString selectedChildren = ''.obs;

  final selectedChargesTypes = Rxn<ChargesTypes>();

  final List<String> peopleCountOptions = [
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
      nextStep();
    }
  }

  void validateStepThree(){
      if (roomImages.length < 4) {
        commonSnackBar(message: 'Please upload at least 4 room images');
        return;
      }
      if (kitchenImages.length < 2) {
        commonSnackBar(message: 'Please upload at least 2 kitchen images');
        return;
      }
      if (bathroomImages.length < 2) {
        commonSnackBar(message: 'Please upload at least 2 bathroom images');
        return;
      }

      nextStep();

  }

  void validateStepFour(){
    if (roadSideImages.length < 2) {
      commonSnackBar(message: 'Please upload at least 2 road side images');
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
          ApiKeys.unmarriedCoupleAllowed: nearByAirportCtrl.text,
        }),
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
        Get.until(
              (route) =>
          route.settings.name ==
              RouteHelper.getEarnWithBlueEraNewScreenRoute(),
        );
      } else {
        addHomeStayRentalServiceResponse.value = ApiResponse.error('error');
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    } catch (e) {
      addHomeStayRentalServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }finally{
      isHomeStayRentalServiceLoading.value = false;
    }
  }


}