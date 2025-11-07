import 'dart:io';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeStayRentalServiceController extends GetxController{
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
  final highlights = TextEditingController();

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
    'More than 5',
  ];

  RxBool isUnMarried = false.obs;


  static const String roomImageId = 'roomImageId';
  static const String kitchenImageId = 'kitchenImageId';
  static const String bathroomImageId = 'bathroomImageId';
  static const String roadSideImageId = 'bathroomImageId';
  static const String otherImageId = 'bathroomImageId';
  final RxList<File> roomImages = <File>[].obs;
  final RxList<File> kitchenImages = <File>[].obs;
  final RxList<File> bathroomImages = <File>[].obs;
  final RxList<File> roadSideImages = <File>[].obs;
  final RxList<File> otherImages = <File>[].obs;

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