import 'dart:async';
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
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/detail_item.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/repo/rental_service_repo.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;

class AddFlatRentalServiceController extends GetxController {
  Rx<ApiResponse> addFlatRentalServiceResponse = ApiResponse.initial('Initial').obs;

  final currentStep = 0.obs;
  final int totalSteps = 2;

  /// Step 1
  final formKeyStep1 = GlobalKey<FormState>();

  // Example form data
  final propertyName = TextEditingController();
  final landmark = TextEditingController();
  final location = TextEditingController();
  final pinCode = TextEditingController();
  final description = TextEditingController();
  // final landlineNumber = TextEditingController();
  // final landlineCode = TextEditingController();
  final mobile = TextEditingController();
  final charge = TextEditingController();

  // ContactType? selectedType = ContactType.Mobile;
  final selectedChargesTypes = Rxn<ChargesTypes>();

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool isFetchingAddressDetails = false.obs;


  final RxList<String> arrHighlights = <String>[].obs;
  RxList<DetailItem> arrMoreDetails = <DetailItem>[].obs;
  final RxList<String> arrMoreRestriction = <String>[].obs;

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


  /// step 2
  int maxUploadImages = 4;
  final RxList<File> roadSideImage = <File>[].obs;
  final RxList<File> roomImages = <File>[].obs;
  final RxList<File> kitchenImage = <File>[].obs;
  final RxList<File> bathroomImage = <File>[].obs;
  final RxList<File> otherImage = <File>[].obs;

  @override
  void onInit() {
    super.onInit();

    ever(currentStep, (step) {
      print('Current Step Changed: $step');
      // You can trigger animations, validations, or scroll resets here.
    });

  }

  void nextStep() {
    if (formKeyStep1.currentState?.validate() ?? false) {
      // Validate charges type
      if (selectedChargesTypes.value == null) {
        commonSnackBar(message: AppStrings.pleaseChooseChargesType.tr);
        return;
      }
      if(arrHighlights.isEmpty){
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

      // Move to next step
      if (currentStep.value < totalSteps - 1) {
        currentStep.value++;
      }
    }
    // else {
    //   commonSnackBar(message: AppStrings.pleaseFillAllFieldsCorrectly.tr);
    // }
  }


  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void onBackPressed(){
    if(currentStep.value > 0){
      previousStep();
    }else{
      Get.back();
    }
  }

  void addHighlights(List<String> highlights) {
    arrHighlights.clear();
    arrHighlights.value = highlights;
  }

  void addDetail(DetailItem detail) {
    arrMoreDetails.add(detail);
  }

  void removeDetail(int index) {
    arrMoreDetails.removeAt(index);
  }

  void addMoreRestrictions(List<String> highlights) {
    arrMoreRestriction.clear();
    arrMoreRestriction.value = highlights;
  }


  bool validateBeforePost() {
    final errors = <String>[];

    if (roadSideImage.length < 2) {
      errors.add(AppStrings.uploadAtLeast2RoadSide);
    }
    if (roomImages.length < 4) {
      errors.add(AppStrings.uploadAtLeast4Room);
    }
    if (kitchenImage.length < 2) {
      errors.add(AppStrings.uploadAtLeast2Kitchen);
    }
    if (bathroomImage.length < 2) {
      errors.add(AppStrings.uploadAtLeast2Bathroom);
    }

    if (errors.isNotEmpty) {
      commonSnackBar(message: errors.first.tr);
      return false;
    }

    return true;
  }

  RxBool isAddFlatRentalServiceLoading = false.obs;

  Future<void> addFlatRentalServiceApi() async {
     if(!validateBeforePost()) return;

      try {
        isAddFlatRentalServiceLoading.value = true;

        List<dio.MultipartFile> roadsideParts = [];
        List<dio.MultipartFile> roomParts = [];
        List<dio.MultipartFile> kitchenParts = [];
        List<dio.MultipartFile> bathroomParts = [];
        List<dio.MultipartFile> otherParts = [];

        if (roadSideImage.isNotEmpty) {
          roadsideParts = await multiPartMultipleImages(arrImages: roadSideImage);
        }
        if (roomImages.isNotEmpty) {
          roomParts = await multiPartMultipleImages(arrImages: roomImages);
        }
        if (kitchenImage.isNotEmpty) {
          kitchenParts = await multiPartMultipleImages(arrImages: kitchenImage);
        }
        if (bathroomImage.isNotEmpty) {
          bathroomParts = await multiPartMultipleImages(arrImages: bathroomImage);
        }
        if (otherImage.isNotEmpty) {
          otherParts = await multiPartMultipleImages(arrImages: otherImage);
        }

        Map<String, dynamic> params = {
          ApiKeys.type: 'Property',
          ApiKeys.name: propertyName.text,
          ApiKeys.landmark: landmark.text,
          ApiKeys.address: location.text,
          ApiKeys.lat : latitude,
          ApiKeys.lng: longitude,
          ApiKeys.pincode: pinCode.text,
          ApiKeys.description: description.text,
          ApiKeys.contactNumber: mobile.text,
          ApiKeys.priceUnit: selectedChargesTypes.value?.label,
          ApiKeys.price: charge.text,
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
          if(arrMoreDetails.isNotEmpty) ApiKeys.additionalDetails: jsonEncode(arrMoreDetails.map((e) => e.toJson()).toList()),
          if(roadsideParts.isNotEmpty) ApiKeys.roadImages: roadsideParts,
          if(roomParts.isNotEmpty) ApiKeys.roomImages: roomParts,
          if(kitchenParts.isNotEmpty) ApiKeys.kitchenImages: kitchenParts,
          if(bathroomParts.isNotEmpty) ApiKeys.bathroomImages: bathroomParts,
          if(otherParts.isNotEmpty) ApiKeys.otherImages: otherParts,
        };

        ResponseModel response = await RentalServiceRepo().addRentalServiceRepo(
          params: params,
        );

        if (response.isSuccess) {
          addFlatRentalServiceResponse.value = ApiResponse.complete(response);
          await setEarnServiceOptData(true);
          Get.until(
                (route) =>
            route.settings.name ==
                RouteHelper.getEarnServiceScreenRoute(),
          );
        } else {
          addFlatRentalServiceResponse.value = ApiResponse.error('error');
        }
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      } catch (e) {
        addFlatRentalServiceResponse.value = ApiResponse.error('error');
        commonSnackBar(message: e.toString());
      } finally {
        isAddFlatRentalServiceLoading.value = false;
      }
    }

}

