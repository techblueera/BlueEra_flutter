import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/repo/rental_service_repo.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum LoadCapacity { KG, TON }

class VehicleRentalServiceController extends GetxController {
  Rx<ApiResponse> addVehicleRentalServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadImagesResponse = ApiResponse.initial('Initial').obs;

  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

  String? rentalId;
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
  final securityDepositCtrl = TextEditingController();
  final pickUpLocationCtrl = TextEditingController();

  final RxList<String> arrHighlights = <String>[].obs;
  final RxList<String> arrMoreRestriction = <String>[].obs;

  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  double pickUpLocationLatitude = 0.0;
  double pickUpLocationLongitude = 0.0;
  RxString pickUpLocationAddress = ''.obs;
  RxBool isFetchingAddressDetails = false.obs;

  // final Rx<RentalVehicleRegistrationType?> selectedVehicleRegistrationType = Rx<RentalVehicleRegistrationType?>(null);
  // final Rx<VehicleType?> selectedVehicleType = Rx<VehicleType?>(null);
  // final Rx<FuelType?> selectedFuelType = Rx<FuelType?>(null);
  final Rx<LoadCapacity> selectedLoadCapacity = LoadCapacity.KG.obs;
  final selectedChargesTypes = Rxn<ChargesTypes>();

  RxBool isAllowAadharCard = false.obs;
  RxBool isAllowAddressProof = false.obs;
  RxBool isAllowDrivingLicense = false.obs;

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

  final RxMap<String, bool> vehicleImagesUploadStatus = <String, bool>{
    CommonMultipleImageSectionController.vehicleNumberPlateImageId: false,
    CommonMultipleImageSectionController.vehicleRightSideImageId: false,
    CommonMultipleImageSectionController.vehicleLeftSideImageId: false,
    CommonMultipleImageSectionController.vehicleFrontImageId: false,
    CommonMultipleImageSectionController.vehicleBackImageId: false,
  }.obs;

  final Map<String, String> _vehicleSectionNames = {
    CommonMultipleImageSectionController.vehicleNumberPlateImageId: "Number Plate Photo",
    CommonMultipleImageSectionController.vehicleRightSideImageId: "Right Side Photo",
    CommonMultipleImageSectionController.vehicleLeftSideImageId: "Left Side Photo",
    CommonMultipleImageSectionController.vehicleFrontImageId: "Front View Photo",
    CommonMultipleImageSectionController.vehicleBackImageId: "Back View Photo",
  };

  /// Go to the next step
  void validateStepOne() {
    if (formKeyStep1.currentState!.validate()) {
      nextStep();
    }
  }

  void validateStepTwo() {
    if (!(formKeyStep2.currentState!.validate())) return;

    if (deliveryPartnerController.selectedVehicleRegistrationType.value ==
          null) {
        commonSnackBar(message: AppStrings.pleaseSelectVehicleRegType.tr);
        return;
      }

      if (deliveryPartnerController.selectedVehicleType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectVehicleType.tr);
        return;
      }

      if (deliveryPartnerController.selectedVehicleUseType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectFuelType.tr);
        return;
      }

      if (deliveryPartnerController.selectedFuelType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectFuelType.tr);
        return;
      }

      nextStep();
  }

  void validateStepThree() {
    if (!(formKeyStep3.currentState!.validate())) return;
      if (selectedChargesTypes.value == null) {
        commonSnackBar(message: AppStrings.pleaseChooseChargesType.tr);
        return;
      }

    if(rentalId==null) addFlatRentalServiceApi();
    else updateFlatRentalServiceApi();

  }

  void validateStepFour(MyDocumentsController myDocumentsController) {

    final Map<String, String> _requiredDocuments = {
      DocumentKeys.vehicleRC: "Vehicle RC",
      DocumentKeys.insuranceDocument: "Insurance Document",
      DocumentKeys.puc: "Pollution Certificate",
      DocumentKeys.vehicleFitnessCertificate: "Vehicle Fitness Certificate",
    };

    for (var entry in _requiredDocuments.entries) {
      String docKey = entry.key;
      String docName = entry.value;

      // 1. Check Status
      DocStatus status = myDocumentsController.getStatus(docKey);

      // 2. If Not Uploaded (or Rejected), Show Error & Stop
      if (status == DocStatus.notUploaded) {
        commonSnackBar(message: "⚠️ Missing: Please upload $docName");
        return;
      }
    }

    nextStep();
  }

  void validateStepFive() {
    for (var entry in vehicleImagesUploadStatus.entries) {
      String sectionId = entry.key;
      bool isUploaded = entry.value;

      if (!isUploaded) {
        String readableName = _vehicleSectionNames[sectionId] ?? "Section Images"; // Fallback name
        commonSnackBar(message: "⚠️ Missing: Please upload $readableName");
        return;
      }
    }

    Get.until(
          (route) =>
      route.settings.name ==
          RouteHelper.getSelfEmployeeScreenRoute(),
    );


    // if (vehicleNumberPlateImages.isEmpty) {
    //   commonSnackBar(message: AppStrings.pleaseSelectNumberPlateImage.tr);
    //   return;
    // }
    //
    // if (vehicleRightSideImages.isEmpty) {
    //   commonSnackBar(message: AppStrings.pleaseSelectRightSideImages.tr);
    //   return;
    // } else if (vehicleRightSideImages.length < 2) {
    //   commonSnackBar(message: AppStrings.pleaseSelectAtLeastTwoRight.tr);
    //   return;
    // }
    //
    // if (vehicleLeftSideImages.isEmpty) {
    //   commonSnackBar(message: AppStrings.pleaseSelectLeftSideImages.tr);
    //   return;
    // } else if (vehicleLeftSideImages.length < 2) {
    //   commonSnackBar(message: AppStrings.pleaseSelectAtLeastTwoLeft.tr);
    //   return;
    // }
    //
    // if (vehicleFrontImages.isEmpty) {
    //   commonSnackBar(message: AppStrings.pleaseSelectFrontImage.tr);
    //   return;
    // }
    //
    // if (vehicleBackImages.isEmpty) {
    //   commonSnackBar(message: AppStrings.pleaseSelectBackImage.tr);
    //   return;
    // }

    // addFlatRentalServiceApi();
  }

  void nextStep() {
    // if(arrHighlights.isEmpty){
    //   commonSnackBar(message: AppStrings.highlightsIsRequired.tr);
    //   return;
    // }

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

  void onBackPressed() {
    if (currentStep.value > 0) {
      previousStep();
    } else {
      Get.back();
    }
  }

  void addHighlights(List<String> highlights) {
    arrHighlights.clear();
    arrHighlights.value = highlights;
  }

  void addMoreRestrictions(List<String> highlights) {
    arrMoreRestriction.clear();
    arrMoreRestriction.value = highlights;
  }

  RxBool isVehicleRentalServiceLoading = false.obs;
  Future<void> addFlatRentalServiceApi() async {
    try {
      isVehicleRentalServiceLoading.value = true;

      // dio.MultipartFile? rcFrontImageParts;
      // dio.MultipartFile? rcBackImageParts;
      // dio.MultipartFile? insuranceImageParts;
      // dio.MultipartFile? pucImageParts;
      // dio.MultipartFile? vehicleFitnessCertificateImageParts;
      // dio.MultipartFile? vehicleNumberPlateImageUrls;
      // List<dio.MultipartFile> vehicleRightSideImageUrls = [];
      // List<dio.MultipartFile> vehicleLeftSideImageUrls = [];
      // List<dio.MultipartFile> vehicleFrontImageUrls = [];
      // List<dio.MultipartFile> vehicleBackImageUrls = [];

      // if (rcFrontImage.value != null) {
      //   rcFrontImageParts =
      //       await multiPartImage(imagePath: rcFrontImage.value?.path);
      // }
      // if (rcBackImage.value != null) {
      //   rcBackImageParts =
      //       await multiPartImage(imagePath: rcBackImage.value?.path);
      // }
      // if (insuranceImage.value != null) {
      //   insuranceImageParts =
      //       await multiPartImage(imagePath: insuranceImage.value?.path);
      // }
      // if (pucImage.value != null) {
      //   pucImageParts = await multiPartImage(imagePath: pucImage.value?.path);
      // }
      // if (vehicleFitnessCertificateImage.value != null) {
      //   vehicleFitnessCertificateImageParts = await multiPartImage(
      //       imagePath: vehicleFitnessCertificateImage.value?.path);
      // }
      // if (vehicleNumberPlateImages.isNotEmpty) {
      //   vehicleFitnessCertificateImageParts =
      //       await multiPartImage(imagePath: vehicleFrontImages.first.path);
      // }
      // if (vehicleRightSideImages.isNotEmpty) {
      //   vehicleRightSideImageUrls =
      //       await multiPartMultipleImages(arrImages: vehicleRightSideImages);
      // }
      // if (vehicleLeftSideImages.isNotEmpty) {
      //   vehicleLeftSideImageUrls =
      //       await multiPartMultipleImages(arrImages: vehicleLeftSideImages);
      // }
      // if (vehicleFrontImages.isNotEmpty) {
      //   vehicleFrontImageUrls =
      //       await multiPartMultipleImages(arrImages: vehicleFrontImages);
      // }
      // if (vehicleBackImages.isNotEmpty) {
      //   vehicleBackImageUrls =
      //       await multiPartMultipleImages(arrImages: vehicleBackImages);
      // }

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
          ApiKeys.registrationType:
              deliveryPartnerController.selectedVehicleRegistrationType.value,
          ApiKeys.vehicleType:
              deliveryPartnerController.selectedVehicleType.value,
          ApiKeys.fuelType: deliveryPartnerController.selectedFuelType.value,
          ApiKeys.vehicleUsesType:
              deliveryPartnerController.selectedVehicleUseType.value,
          ApiKeys.brand: vehicleNameCtrl.text,
          ApiKeys.registrationNumber: vehicleRegistrationNumberCtrl.text,
          ApiKeys.yearOfManufacture: vehicleModelCtrl.text,
          ApiKeys.seatingCapacity: seatingCapacityCtrl.text,
          ApiKeys.loadCapacity: loadCapacityCtrl.text,
          ApiKeys.capacityUnit: selectedLoadCapacity.value.name,
        }),
        ApiKeys.description: vehicleDesCtrl.text,
        ApiKeys.priceUnit: selectedChargesTypes.value?.label,
        ApiKeys.price: chargeCtrl.text,
        if (arrHighlights.isNotEmpty) ApiKeys.highlights: jsonEncode(arrHighlights),
        if(arrMoreRestriction.isNotEmpty) ApiKeys.additionalRules: jsonEncode(arrMoreRestriction),
        ApiKeys.pickupLocation: pickUpLocationCtrl.text,
        ApiKeys.securityDeposit: securityDepositCtrl.text.trim(),
        ApiKeys.documentRequired: jsonEncode({
          ApiKeys.adharCard: isAllowAadharCard.value,
          ApiKeys.addressProof: isAllowAddressProof.value,
          ApiKeys.drivingLicense: isAllowDrivingLicense.value
        })
      };

      ResponseModel response = await RentalServiceRepo().addRentalServiceRepo(
        params: params,
      );

      if (response.isSuccess) {
        addVehicleRentalServiceResponse.value = ApiResponse.complete(response);
        rentalId = response.response?.data['data']['_id'];
        print('rental id-- $rentalId');

        // await setEarnServiceOptData(true);
        nextStep();
      } else {
        addVehicleRentalServiceResponse.value = ApiResponse.error('error');
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    } catch (e, s) {
      log('stack trace-- $s');
      addVehicleRentalServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    } finally {
      isVehicleRentalServiceLoading.value = false;
    }
  }

  Future<void> updateFlatRentalServiceApi() async {
    try {
      isVehicleRentalServiceLoading.value = true;

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
          ApiKeys.registrationType:
          deliveryPartnerController.selectedVehicleRegistrationType.value,
          ApiKeys.vehicleType:
          deliveryPartnerController.selectedVehicleType.value,
          ApiKeys.fuelType: deliveryPartnerController.selectedFuelType.value,
          ApiKeys.vehicleUsesType:
          deliveryPartnerController.selectedVehicleUseType.value,
          ApiKeys.brand: vehicleNameCtrl.text,
          ApiKeys.registrationNumber: vehicleRegistrationNumberCtrl.text,
          ApiKeys.yearOfManufacture: vehicleModelCtrl.text,
          ApiKeys.seatingCapacity: seatingCapacityCtrl.text,
          ApiKeys.loadCapacity: loadCapacityCtrl.text,
          ApiKeys.capacityUnit: selectedLoadCapacity.value.name,
        }),
        ApiKeys.description: vehicleDesCtrl.text,
        ApiKeys.priceUnit: selectedChargesTypes.value?.label,
        ApiKeys.price: chargeCtrl.text,
        if (arrHighlights.isNotEmpty) ApiKeys.highlights: jsonEncode(arrHighlights),
        if(arrMoreRestriction.isNotEmpty) ApiKeys.additionalRules: jsonEncode(arrMoreRestriction),
        ApiKeys.pickupLocation: pickUpLocationCtrl.text,
        ApiKeys.securityDeposit: securityDepositCtrl.text.trim(),
        ApiKeys.documentRequired: jsonEncode({
          ApiKeys.adharCard: isAllowAadharCard.value,
          ApiKeys.addressProof: isAllowAddressProof.value,
          ApiKeys.drivingLicense: isAllowDrivingLicense.value
        })
      };

      ResponseModel response = await RentalServiceRepo().updateRentalServiceRepo(
        rentalId: rentalId!,
        params: params,
      );

      if (response.isSuccess) {
        addVehicleRentalServiceResponse.value = ApiResponse.complete(response);
        // await setEarnServiceOptData(true);
        nextStep();
      } else {
        addVehicleRentalServiceResponse.value = ApiResponse.error('error');
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    } catch (e, s) {
      log('stack trace-- $s');
      addVehicleRentalServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    } finally {
      isVehicleRentalServiceLoading.value = false;
    }
  }

  bool isUploadImagesLoading = false;
  Future<void> uploadVehicleImagesApi(
      {required List<File> images, required String sectionId}) async {
    try {
      isUploadImagesLoading = true;
      update();

      final imageConfig = {
        CommonMultipleImageSectionController.vehicleNumberPlateImageId: (
          msg: AppStrings.pleaseSelectNumberPlateImage.tr,
          apiKey: ApiKeys.vehicleNoPlateImg
        ),
        CommonMultipleImageSectionController.vehicleRightSideImageId: (
          msg: AppStrings.pleaseSelectRightSideImages.tr,
          apiKey: ApiKeys.vehicleRightHandSideImage
        ),
        CommonMultipleImageSectionController.vehicleLeftSideImageId: (
          msg: AppStrings.pleaseSelectLeftSideImages.tr,
          apiKey: ApiKeys.vehicleLeftSideImage
        ),
        CommonMultipleImageSectionController.vehicleFrontImageId: (
          msg: AppStrings.pleaseSelectFrontImage.tr,
          apiKey: ApiKeys.vehicleFrontImage
        ),
        CommonMultipleImageSectionController.vehicleBackImageId: (
          msg: AppStrings.pleaseSelectBackImage.tr,
          apiKey: ApiKeys.vehicleBackImage
        ),
      };

      final config = imageConfig[sectionId];

      if (config == null) return;

      if (images.isEmpty) {
        commonSnackBar(message: config.msg);
        return;
      } else if (sectionId ==
              CommonMultipleImageSectionController.vehicleRightSideImageId &&
          images.length < 2) {
        commonSnackBar(message: AppStrings.pleaseSelectAtLeastTwoRight.tr);
        return;
      } else if (sectionId ==
              CommonMultipleImageSectionController.vehicleRightSideImageId &&
          images.length < 2) {
        commonSnackBar(message: AppStrings.pleaseSelectAtLeastTwoRight.tr);
        return;
      }

      List<dio.MultipartFile> imageParts =
          await multiPartMultipleImages(arrImages: images);

      Map<String, dynamic> params = {
        config.apiKey: imageParts,
      };

      ResponseModel response = await RentalServiceRepo().uploadRentalImagesRepo(
        rentalId: rentalId!,
        params: params,
      );

      if (response.isSuccess) {
        uploadImagesResponse.value = ApiResponse.complete(response);
        Get.back();
        vehicleImagesUploadStatus[sectionId] = true;
      } else {
        uploadImagesResponse.value = ApiResponse.error('error');
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    } catch (e) {
      uploadImagesResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    } finally {
      isUploadImagesLoading = false;
      update();
    }
  }
}
