import 'dart:async';
import 'dart:convert';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/detail_item.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/stay_images_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/repo/rental_service_repo.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AddFlatRentalServiceController extends GetxController {
  Rx<ApiResponse> addFlatRentalServiceResponse = ApiResponse.initial('Initial').obs;

  final currentStep = 0.obs;
  final int totalSteps = 2;
  String? rentalId;

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
  final checkInTimeController = TextEditingController();
  final checkOutTimeController = TextEditingController();

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

  // Time variables - Start Time
  var checkInHour = RxnInt();
  var checkInMinute = RxnInt();
  var checkInPeriod = RxnString();

  // Time variables - End Time
  var checkOutHour = RxnInt();
  var checkOutMinute = RxnInt();
  var checkOutPeriod = RxnString();

  /// step 2
  final stayImagesController = getOrPut(() => StayImagesController());

  // final RxList<File> roadSideImage = <File>[].obs;
  // final RxList<File> roomImages = <File>[].obs;
  // final RxList<File> kitchenImage = <File>[].obs;
  // final RxList<File> bathroomImage = <File>[].obs;
  // final RxList<File> otherImage = <File>[].obs;

  @override
  void onInit() {
    super.onInit();

    ever(currentStep, (step) {
      print('Current Step Changed: $step');
      // You can trigger animations, validations, or scroll resets here.
    });

  }

  // Update time controllers when dropdown values change
  void updateCheckInTimeController() {
    if (checkInHour.value != null &&
        checkInMinute.value != null &&
        checkInPeriod.value != null) {
      final formattedTime =
          '${checkInHour.value.toString().padLeft(2, '0')}:${checkInMinute.value.toString().padLeft(2, '0')} ${checkInPeriod.value}';
      checkInTimeController.text = formattedTime;
    }
  }

  void updateCheckOutTimeController() {
    if (checkOutHour.value != null &&
        checkOutMinute.value != null &&
        checkOutPeriod.value != null) {
      final formattedTime =
          '${checkOutHour.value.toString().padLeft(2, '0')}:${checkOutMinute.value.toString().padLeft(2, '0')} ${checkOutPeriod.value}';
      checkOutTimeController.text = formattedTime;
    }
  }

  void nextStep() {
    if (formKeyStep1.currentState?.validate() ?? false) {
      if(arrHighlights.isEmpty){
        commonSnackBar(message: AppStrings.highlightsIsRequired.tr);
        return;
      }

      if(checkInMinute.value == null &&
           checkInHour.value == null &&
             checkInPeriod.value == null){
        commonSnackBar(message: 'Please select check in time.');
        return;
      }

      if(checkOutMinute.value == null &&
          checkOutHour.value == null &&
          checkOutPeriod.value == null){
        commonSnackBar(message: 'Please select check out time.');
        return;
      }
      if(anyFoodHabitRestriction.value){
        if(selectedFoodHabit.isEmpty){
          commonSnackBar(message: AppStrings.foodHabitRequired.tr);
          return;
        }
      }

    }
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

  RxBool isAddFlatRentalServiceLoading = false.obs;

  Future<void> addFlatRentalServiceApi() async {
    if (!(formKeyStep1.currentState?.validate() ?? true)) return;

    if(arrHighlights.isEmpty){
        commonSnackBar(message: AppStrings.highlightsIsRequired.tr);
        return;
      }

    if(checkInMinute.value == null &&
          checkInHour.value == null &&
          checkInPeriod.value == null){
        commonSnackBar(message: 'Please select check in time.');
        return;
      }

    if(checkOutMinute.value == null &&
          checkOutHour.value == null &&
          checkOutPeriod.value == null){
        commonSnackBar(message: 'Please select check out time.');
        return;
      }

    if(anyFoodHabitRestriction.value){
        if(selectedFoodHabit.isEmpty){
          commonSnackBar(message: AppStrings.foodHabitRequired.tr);
          return;
        }
      }


    try {
        isAddFlatRentalServiceLoading.value = true;

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
          ApiKeys.checkInTime: checkInTimeController.text,
          ApiKeys.checkOutTime: checkOutTimeController.text,
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
        };

        ResponseModel response = await RentalServiceRepo().addRentalServiceRepo(
          params: params,
        );

        if (response.isSuccess) {
          addFlatRentalServiceResponse.value = ApiResponse.complete(response);
          rentalId = response.response?.data['data']['_id'];
          print('rental id-- $rentalId');

          // await setEarnServiceOptData(true);

          // Move to next step
          if (currentStep.value < totalSteps - 1) {
            currentStep.value++;
          }

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

  Future<void> updateFlatRentalServiceApi() async {
    if (!(formKeyStep1.currentState?.validate() ?? true)) return;

    if(anyFoodHabitRestriction.value){
      if(selectedFoodHabit.isEmpty){
        commonSnackBar(message: AppStrings.foodHabitRequired.tr);
        return;
      }
    }

    try {
      isAddFlatRentalServiceLoading.value = true;

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
        ApiKeys.checkInTime: checkInTimeController.text,
        ApiKeys.checkOutTime: checkOutTimeController.text,
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
      };

      ResponseModel response = await RentalServiceRepo().updateRentalServiceRepo(
        rentalId: rentalId!,
        params: params,
      );

      if (response.isSuccess) {
        addFlatRentalServiceResponse.value = ApiResponse.complete(response);
        if (currentStep.value < totalSteps - 1) {
          currentStep.value++;
        }

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

  void validateStepFour(StayImagesController stayImagesController){

    for (var entry in stayImagesController.sectionUploadStatus.entries) {
      String sectionId = entry.key;
      bool isUploaded = entry.value;

      if (!isUploaded) {
        String readableName = stayImagesController.sectionNames[sectionId] ?? "Section Images"; // Fallback name
        commonSnackBar(message: "⚠️ Missing: Please upload $readableName");
        return;
      }
    }

    Get.until(
          (route) =>
      route.settings.name ==
          RouteHelper.getEarnServiceScreenRoute(),
    );


  }

}

