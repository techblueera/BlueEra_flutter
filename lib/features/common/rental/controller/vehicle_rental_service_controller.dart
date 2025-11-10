import 'dart:convert';
import 'dart:developer';
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

enum LoadCapacity { KG, TON }

class VehicleRentalServiceController extends GetxController{
  Rx<ApiResponse> addVehicleRentalServiceResponse = ApiResponse.initial('Initial').obs;

  final currentStep = 0.obs;
  int totalSteps = 5;

  final formKeyStep1 = GlobalKey<FormState>();
  final formKeyStep2 = GlobalKey<FormState>();
  final formKeyStep3 = GlobalKey<FormState>();
  final formKeyStep4 = GlobalKey<FormState>();

  final ownerNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mobileNumberCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final pinCodeCtrl = TextEditingController();
  final vehicleNameCtrl = TextEditingController();
  final vehicleRegistrationNumberCtrl = TextEditingController();
  final vehicleModelCtrl = TextEditingController();
  final seatingCapacityCtrl = TextEditingController();
  final loadCapacityCtrl = TextEditingController();
  final rcController = TextEditingController();
  final vehicleDesCtrl = TextEditingController();
  final chargeCtrl = TextEditingController();
  final pickUpLocationCtrl = TextEditingController();

  final RxList<String> arrHighlights = <String>[].obs;

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  double pickUpLocationLatitude = 0.0;
  double pickUpLocationLongitude = 0.0;
  RxString pickUpLocationAddress = ''.obs;
  RxBool isFetchingAddressDetails = false.obs;

  final Rx<RentalVehicleRegistrationType?> selectedVehicleRegistrationType = Rx<RentalVehicleRegistrationType?>(null);
  final Rx<VehicleType?> selectedVehicleType = Rx<VehicleType?>(null);
  final Rx<FuelType?> selectedFuelType = Rx<FuelType?>(null);
  final Rx<LoadCapacity> selectedLoadCapacity = LoadCapacity.KG.obs;
  final selectedChargesTypes = Rxn<ChargesTypes>();

  final Rxn<File> rcFrontImage = Rxn<File>();
  final Rxn<File> rcBackImage = Rxn<File>();
  final Rxn<File> insuranceImage = Rxn<File>();
  final Rxn<File> pucImage = Rxn<File>();
  final Rxn<File> vehicleFitnessCertificateImage = Rxn<File>();

  /// step 5
  final RxList<File> vehicleNumberPlateImages = <File>[].obs;
  final RxList<File> vehicleRightSideImages = <File>[].obs;
  final RxList<File> vehicleLeftSideImages = <File>[].obs;
  final RxList<File> vehicleFrontImages = <File>[].obs;
  final RxList<File> vehicleBackImages = <File>[].obs;
  int maxVehicleImageUpload = 4;

  /// Go to the next step

  void validateStepOne(){
    if(formKeyStep1.currentState!.validate()){
      nextStep();
    }
  }

  void validateStepTwo(){
    if(formKeyStep2.currentState!.validate()){
      if (selectedVehicleRegistrationType.value == null) {
        commonSnackBar(message: 'Please select Vehicle Registration Type.');
        return;
      }

      if (selectedVehicleType.value == null) {
        commonSnackBar(message: 'Please select Vehicle Type.');
        return;
      }

      if (selectedFuelType.value == null) {
        commonSnackBar(message: 'Please select Fuel Type.');
        return;
      }

      nextStep();

    }
  }

  void validateStepThree(){
    if(formKeyStep1.currentState!.validate()){
      if (rcFrontImage.value == null) {
        commonSnackBar(message: 'Please select RC Front Image.');
        return;
      }
      if (rcBackImage.value == null) {
        commonSnackBar(message: 'Please select RC Back Image.');
        return;
      }
      if (insuranceImage.value == null) {
        commonSnackBar(message: 'Please select Insurance Image.');
        return;
      }
      if (pucImage.value == null) {
        commonSnackBar(message: 'Please select Pollution certificate Image.');
        return;
      }
      if (vehicleFitnessCertificateImage.value == null) {
        commonSnackBar(message: 'Please select Vehicle Fitness Certificate Image.');
        return;
      }

      nextStep();

    }
  }

  void validateStepFour(){
    if(formKeyStep1.currentState!.validate()){
      if (selectedChargesTypes.value == null) {
        commonSnackBar(message: 'Please choose charges type.');
        return;
      }

      nextStep();
    }
  }

  void validateStepFive(){

    if (vehicleNumberPlateImages.isEmpty) {
      commonSnackBar(message: 'Please select Vehicle Number Plate Image.');
      return;
    }

    if (vehicleRightSideImages.isEmpty) {
      commonSnackBar(message: 'Please select Vehicle Right Side Images (at least two).');
      return;
    } else if (vehicleRightSideImages.length < 2) {
      commonSnackBar(message: 'Please select at least two Vehicle Right Side Images.');
      return;
    }

    if (vehicleLeftSideImages.isEmpty) {
      commonSnackBar(message: 'Please select Vehicle Left Side Images (at least two).');
      return;
    } else if (vehicleLeftSideImages.length < 2) {
      commonSnackBar(message: 'Please select at least two Vehicle Left Side Images.');
      return;
    }

    if (vehicleFrontImages.isEmpty) {
      commonSnackBar(message: 'Please select Vehicle Front Image.');
      return;
    }

    if (vehicleBackImages.isEmpty) {
      commonSnackBar(message: 'Please select Vehicle Back Image.');
      return;
    }

    addFlatRentalServiceApi();
  }

  void nextStep() {
    if(arrHighlights.isEmpty){
      commonSnackBar(message: 'Highlights is required.');
      return;
    }

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

  RxBool isVehicleRentalServiceLoading = false.obs;

  Future<void> addFlatRentalServiceApi() async {

    try {
      isVehicleRentalServiceLoading.value = true;

      dio.MultipartFile? rcFrontImageParts;
      dio.MultipartFile? rcBackImageParts;
      dio.MultipartFile? insuranceImageParts;
      dio.MultipartFile? pucImageParts;
      dio.MultipartFile? vehicleFitnessCertificateImageParts;
      dio.MultipartFile? vehicleNumberPlateImageUrls;
      List<dio.MultipartFile> vehicleRightSideImageUrls = [];
      List<dio.MultipartFile> vehicleLeftSideImageUrls = [];
      List<dio.MultipartFile> vehicleFrontImageUrls = [];
      List<dio.MultipartFile> vehicleBackImageUrls = [];

      if (rcFrontImage.value != null) {
        rcFrontImageParts = await multiPartImage(imagePath: rcFrontImage.value?.path);
      }
      if (rcBackImage.value != null) {
        rcBackImageParts = await multiPartImage(imagePath: rcBackImage.value?.path);
      }
      if (insuranceImage.value != null) {
        insuranceImageParts = await multiPartImage(imagePath: insuranceImage.value?.path);
      }
      if (pucImage.value != null) {
        pucImageParts = await multiPartImage(imagePath: pucImage.value?.path);
      }
      if (vehicleFitnessCertificateImage.value != null) {
        vehicleFitnessCertificateImageParts = await multiPartImage(imagePath: vehicleFitnessCertificateImage.value?.path);
      }
      if (vehicleNumberPlateImages.isNotEmpty) {
        vehicleFitnessCertificateImageParts = await multiPartImage(imagePath: vehicleFrontImages.first.path);
      }
      if (vehicleRightSideImages.isNotEmpty) {
        vehicleRightSideImageUrls = await multiPartMultipleImages(arrImages: vehicleRightSideImages);
      }
      if (vehicleLeftSideImages.isNotEmpty) {
        vehicleLeftSideImageUrls = await multiPartMultipleImages(arrImages: vehicleLeftSideImages);
      }
      if (vehicleFrontImages.isNotEmpty) {
        vehicleFrontImageUrls = await multiPartMultipleImages(arrImages: vehicleFrontImages);
      }
      if (vehicleBackImages.isNotEmpty) {
        vehicleBackImageUrls = await multiPartMultipleImages(arrImages: vehicleBackImages);
      }

      Map<String, dynamic> params = {
        ApiKeys.type: 'Vehicle',
        ApiKeys.ownerDetails: jsonEncode({
          ApiKeys.ownerName: ownerNameCtrl.text,
          ApiKeys.contactNumber: mobileNumberCtrl.text,
          ApiKeys.email: emailCtrl.text,
          ApiKeys.address: locationCtrl.text,
          ApiKeys.pincode: pinCodeCtrl.text,
          ApiKeys.landmark: landmarkCtrl.text
        }),
          ApiKeys.lat: pickUpLocationLatitude,
          ApiKeys.lng: pickUpLocationLongitude,
        ApiKeys.vehicleDetails: jsonEncode({
          ApiKeys.registrationType: selectedVehicleRegistrationType.value?.name,
          ApiKeys.vehicleType: selectedVehicleType.value?.name,
          ApiKeys.fuelType: selectedFuelType.value?.name,
          ApiKeys.brand: vehicleNameCtrl.text,
          ApiKeys.registrationNumber: vehicleRegistrationNumberCtrl.text,
          ApiKeys.yearOfManufacture: vehicleModelCtrl.text,
          ApiKeys.seatingCapacity: seatingCapacityCtrl.text,
          ApiKeys.loadCapacity: loadCapacityCtrl.text,
          ApiKeys.capacityUnit: selectedLoadCapacity.value.name,
        }),
        ApiKeys.rcNo: rcController.text,
        ApiKeys.description : vehicleDesCtrl.text,
        ApiKeys.rcImages: {
          ApiKeys.front: rcFrontImageParts,
          ApiKeys.back: rcBackImageParts,
        },
        ApiKeys.insuranceDocument : insuranceImageParts,
        ApiKeys.pollutionCertificate : pucImageParts,
        ApiKeys.fitnessCertificate : vehicleFitnessCertificateImageParts,
        ApiKeys.priceUnit: selectedChargesTypes.value?.label,
        ApiKeys.price: chargeCtrl.text,
        if(arrHighlights.isNotEmpty) ApiKeys.highlights: jsonEncode(arrHighlights),
        ApiKeys.pickupLocation: pickUpLocationCtrl.text,
        ApiKeys.vehicleNoPlateImg: vehicleNumberPlateImageUrls,
        ApiKeys.vehicleRightHandSideImage: vehicleRightSideImageUrls,
        ApiKeys.vehicleLeftSideImage: vehicleLeftSideImageUrls,
        ApiKeys.vehicleFrontImage: vehicleFrontImageUrls,
        ApiKeys.vehicleBackImage: vehicleBackImageUrls,
      };

      ResponseModel response = await RentalServiceRepo().addRentalServiceRepo(
        params: params,
      );

      if (response.isSuccess) {
        addVehicleRentalServiceResponse.value = ApiResponse.complete(response);
        Get.until(
              (route) =>
          route.settings.name ==
              RouteHelper.getEarnWithBlueEraNewScreenRoute(),
        );
      } else {
        addVehicleRentalServiceResponse.value = ApiResponse.error('error');
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    } catch (e, s) {
      log('stack trace-- $s');
      addVehicleRentalServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    }finally{
      isVehicleRentalServiceLoading.value = false;
    }
  }

}