import 'dart:io';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum LoadCapacity { KG, TON }

class VehicleRentalServiceController extends GetxController{
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
  RxString pickUpLocationAddress = ''.obs;

  final highlights = TextEditingController();
  final RxList<String> arrHighlights = <String>[].obs;

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  double pickUpLocationLatitude = 0.0;
  double pickUpLocationLongitude = 0.0;
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
  static const String vehicleNumberPlateImageId = 'vehicleNumberPlateImageId';
  static const String vehicleRightSideImageId = 'vehicleRightSideImageId';
  static const String vehicleLeftSideImageId = 'vehicleLeftSideImageId';
  static const String vehicleFrontImageId = 'vehicleFrontImageId';
  static const String vehicleBackImageId = 'vehicleBackImageId';
  final RxList<File> vehicleNumberPlateImages = <File>[].obs;
  final RxList<File> vehicleRightSideImages = <File>[].obs;
  final RxList<File> vehicleLeftSideImages = <File>[].obs;
  final RxList<File> vehicleFrontImages = <File>[].obs;
  final RxList<File> vehicleBackImages = <File>[].obs;
  int maxVehicleImageUpload = 4;

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

  void addHighlights() {
    if(arrHighlights.length == 10){
      commonSnackBar(message: 'You can\'t add more than 10 highlights');
      return;
    }

    final text = highlights.text.trim();
    if (text.isNotEmpty) {
      arrHighlights.add(text);
      highlights.clear();
    }
  }

  void removeHighlights(String tag) {
    arrHighlights.remove(tag);
  }


}