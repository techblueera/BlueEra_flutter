import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_service_upload_model.dart';
import 'package:BlueEra/features/common/delivery_partner/repo/delivery_partner_repo.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum RiderProfileStep {
  personalInfo,
  addressInfo,
  personalIdentificationInfo,
  drivingInfo,
  vehicleImagesInfo,
  vehicleInfo
}

class DeliveryPartnerController extends GetxController{
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingPersonalInformationResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingAddressResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingPersonalIdentificationResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingDrivingVerificationResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingVehicleImagesResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingVehicleInformationResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> ridersOnboardingStatusResponse = ApiResponse.initial('Initial').obs;

  final stepStatus = <RiderProfileStep, bool>{}.obs;
  String? riderVerificationStatus;

  /// step 1
  final fullNameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final emailController = TextEditingController();
  Rx<GenderType?> selectedGender = Rx<GenderType?>(null);
  RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;
  final GlobalKey<FormState> formKeyStep1 = GlobalKey<FormState>();

  /// step 2
  final GlobalKey<FormState> formKeyStep2 = GlobalKey<FormState>();
  final locationController = TextEditingController();
  final landmarkController = TextEditingController();
  final pinCodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  RxString currentAddress = ''.obs;
  double latitude = 0.0;
  double longitude = 0.0;
  RxBool enabledLiveLocation = false.obs;
  RxBool isFetchingAddressDetails = false.obs;

  /// step 3
  final GlobalKey<FormState> formKeyStep3 = GlobalKey<FormState>();
  static const String livePhotoImageId = 'livePhotoImageId';
  final aadharController = TextEditingController();
  final panNumberController = TextEditingController();
  int maxLiveUploadImages = 2;

  final RxList<File> livePhoto = <File>[].obs;
  final Rxn<File> aadharFrontImage = Rxn<File>();
  final Rxn<File> aadharBackImage = Rxn<File>();
  final Rxn<File> panCardImage = Rxn<File>();

  /// step 4
  final GlobalKey<FormState> formKeyStep4 = GlobalKey<FormState>();
  final rcController = TextEditingController();
  final drivingLicenseController = TextEditingController();
  final Rxn<File> rcFrontImage = Rxn<File>();
  final Rxn<File> rcBackImage = Rxn<File>();
  final Rxn<File> drivingLicenseFrontImage = Rxn<File>();
  final Rxn<File> drivingLicenseBackImage = Rxn<File>();

  /// step 5

  final RxList<File> vehicleNumberPlateImages = <File>[].obs;
  final RxList<File> vehicleRightSideImages = <File>[].obs;
  final RxList<File> vehicleLeftSideImages = <File>[].obs;
  final RxList<File> vehicleFrontImages = <File>[].obs;
  final RxList<File> vehicleBackImages = <File>[].obs;
  int maxVehicleImageUpload = 4;

  /// steps 6
  final GlobalKey<FormState> formKeyStep6 = GlobalKey<FormState>();
  final vehicleNameController = TextEditingController();
  final vehicleRegistrationNumberController = TextEditingController();
  final vehicleModelController = TextEditingController();

  final RxBool isTermsAccepted = false.obs;
  Rx<VehicleRegistrationType?> selectedVehicleRegistrationType = Rx<VehicleRegistrationType?>(null);
  Rx<VehicleType?> selectedVehicleType = Rx<VehicleType?>(null);
  Rx<FuelType?> selectedFuelType = Rx<FuelType?>(null);

  Future<RiderServiceUploadModel?> uploadInit(
      {required String fileType}) async {
    try {
      ResponseModel response = await DeliveryPartnerRepo().initRiderServiceUploadRepo(fileType: fileType);;

      if (response.isSuccess) {
        uploadInitResponse.value = ApiResponse.complete(response);
        final riderServiceUploadModel = RiderServiceUploadModel.fromJson(response.response?.data);
        return riderServiceUploadModel;
      }
    } catch (e) {
      uploadInitResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    }
    return null;
  }

  RxBool isRiderStatusLoading = true.obs;

  /// ridersOnboardingStatusRepoApi
  Future<void> ridersOnboardingStatusRepoApi() async {
    try {

      ResponseModel response = await DeliveryPartnerRepo().ridersOnboardingStatusRepo();

      if (response.isSuccess) {
        ridersOnboardingStatusResponse.value = ApiResponse.complete(response);
        final riderOnboardingStatusResponse = RiderOnboardingStatusResponse.fromJson(response.response?.data);

        riderVerificationStatus = riderOnboardingStatusResponse.data?.verificationStatus;
        stepStatus.assignAll({
          RiderProfileStep.personalInfo: riderOnboardingStatusResponse.data?.personalInformation ?? false,
          RiderProfileStep.addressInfo: riderOnboardingStatusResponse.data?.address ?? false,
          RiderProfileStep.personalIdentificationInfo: riderOnboardingStatusResponse.data?.personalIdentification ?? false,
          RiderProfileStep.drivingInfo: riderOnboardingStatusResponse.data?.drivingVerification ?? false,
          RiderProfileStep.vehicleImagesInfo: riderOnboardingStatusResponse.data?.vehicleImages ?? false,
          RiderProfileStep.vehicleInfo: riderOnboardingStatusResponse.data?.vehicleInformation ?? false,
        });

      } else {
        ridersOnboardingStatusResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      ridersOnboardingStatusResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }finally{
      isRiderStatusLoading.value = false;
    }
  }

  RiderVerificationState get riderVerificationState {
    final status = riderVerificationStatus?.toLowerCase();

    switch (status) {
      case 'completed':
        return RiderVerificationState.completed;

      case 'rejected':
        return RiderVerificationState.rejected;

      case 'pending':
        return RiderVerificationState.pending;

      default:
        return RiderVerificationState.pending;
    }
  }

  Future<void> uploadFileToS3Api({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async {
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
        onProgress: onProgress,
        file: file,
        fileType: fileType,
        preSignedUrl: preSignedUrl,
      );

      if (response?.isSuccess ?? false) {
        uploadFileToS3Response.value = ApiResponse.complete(response);
      } else {
        uploadFileToS3Response.value = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      uploadFileToS3Response.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<String?> _uploadToS3(File file) async {
    try {
      final fileInfo = getFileInfo(file);
      final mimeType = fileInfo['mimeType']!;

      final initModel = await uploadInit(fileType: mimeType);
      if (initModel == null) return null;

      await uploadFileToS3Api(
        file: file,
        fileType: mimeType,
        preSignedUrl: initModel.uploadURL ?? '',
        onProgress: (progress) {
          debugPrint(" Uploading ${file.path.split('/').last}: ${(progress * 100).toStringAsFixed(0)}%");
        },
      );

      return initModel.fileUrl;
    } catch (e) {
      debugPrint("Upload failed for ${file.path}: $e");
      return null;
    }
  }

  RxBool isPersonalInformationLoading = false.obs;

  /// ridersOnboardingPersonalInformationApi (Step 1)
  Future<void> ridersOnboardingPersonalInformationApi() async {
    if(formKeyStep1.currentState!.validate()){
      try {
        isPersonalInformationLoading.value = true;
        Map<String, dynamic> params = {
          ApiKeys.name: fullNameController.text,
          ApiKeys.gender: selectedGender.value?.name,
          ApiKeys.dob: '${selectedYear}-${selectedMonth}-${selectedDay}',
          ApiKeys.contactNo: mobileNumberController.text,
          ApiKeys.email: emailController.text,
        };

        ResponseModel response = await DeliveryPartnerRepo().ridersOnboardingPersonalInformationRepo(
          params: params,
        );

        if (response.isSuccess) {
          ridersOnboardingPersonalInformationResponse.value = ApiResponse.complete(response);
          Get.toNamed(RouteHelper.getAddressLocationRidingScreenRoute());
        } else {
          ridersOnboardingPersonalInformationResponse.value = ApiResponse.error('error');
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        ridersOnboardingPersonalInformationResponse.value = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally{
        isPersonalInformationLoading.value = false;
      }
    }
  }

  RxBool isRidersAddressLoading = false.obs;

  /// ridersOnboardingPersonalInformationApi (Step 2)
  Future<void>  ridersOnboardingAddressApi() async {
    if(formKeyStep2.currentState!.validate()){
      try {
        isRidersAddressLoading.value = true;
        Map<String, dynamic> params = {
          ApiKeys.homeLocation: {
            ApiKeys.latitude: latitude,
            ApiKeys.longitude: longitude
          },
          ApiKeys.streetAddress: locationController.text,
          ApiKeys.landmark: landmarkController.text,
          ApiKeys.pincode: pinCodeController.text,
          ApiKeys.city: cityController.text,
          ApiKeys.state: stateController.text,
          ApiKeys.locationPermission: enabledLiveLocation.value,
        };

        ResponseModel response = await DeliveryPartnerRepo().ridersOnboardingAddressRepo(
          params: params,
        );

        if (response.isSuccess) {
          ridersOnboardingAddressResponse.value = ApiResponse.complete(response);
          Get.toNamed(RouteHelper.getPersonalIdentificationRidingScreenRoute());
        } else {
          ridersOnboardingAddressResponse.value = ApiResponse.error('error');
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        ridersOnboardingAddressResponse.value = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally{
        isRidersAddressLoading.value = false;
      }
    }
  }

  RxBool isRiderPersonalIdentificationLoading = false.obs;

  /// ridersOnboardingPersonalInformationApi (Step 3)
  Future<void> ridersOnboardingPersonalIdentificationApi() async {
    if(formKeyStep3.currentState!.validate()){
      // ---------- 1️⃣ VALIDATION ----------
      if (livePhoto.isEmpty) {
        commonSnackBar(message: AppStrings.pleaseSelectYourPhoto.tr);
        return;
      }
      if (aadharFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectAadharFrontImage.tr);
        return;
      }
      if (aadharBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectAadharBackImage.tr);
        return;
      }
      if (panCardImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectPanCardImage.tr);
        return;
      }

      try {
        isRiderPersonalIdentificationLoading.value = true;

        // ---------- 2️⃣ INITIALIZE ----------
        List<String> userPictureUrls = [];
        String? aadharFrontImageUrl;
        String? aadharBackImageUrl;
        String? panCardImageUrl;

        // ---------- 3️⃣ UPLOAD LIVE PHOTOS ----------
        for (final photo in livePhoto) {
          final fileUrl = await _uploadToS3(photo);
          if (fileUrl != null && fileUrl.isNotEmpty) {
            userPictureUrls.add(fileUrl);
          }
        }

        // ---------- 4️⃣ UPLOAD AADHAR FRONT ----------
        aadharFrontImageUrl = await _uploadToS3(aadharFrontImage.value!);

        // ---------- 5️⃣ UPLOAD AADHAR BACK ----------
        aadharBackImageUrl = await _uploadToS3(aadharBackImage.value!);

        // ---------- 6️⃣ UPLOAD PAN CARD ----------
        panCardImageUrl = await _uploadToS3(panCardImage.value!);

        // ---------- 7️⃣ PREPARE PAYLOAD ----------
        final params = {
          ApiKeys.aadharNo: aadharController.text,
          ApiKeys.panNo: panNumberController.text,
          ApiKeys.userPicture: userPictureUrls,
          ApiKeys.aadharImages: {
            ApiKeys.front: aadharFrontImageUrl,
            ApiKeys.back: aadharBackImageUrl,
          },
          ApiKeys.panImages: {
            ApiKeys.front: panCardImageUrl,
          },
        };

        // ---------- 8️⃣ API CALL ----------
        final response = await DeliveryPartnerRepo()
            .ridersOnboardingPersonalIdentificationRepo(params: params);

        // ---------- 9️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          ridersOnboardingPersonalIdentificationResponse.value =
              ApiResponse.complete(response);
          Get.toNamed(RouteHelper.getDrivingVerificationRidingScreenRoute());
        } else {
          ridersOnboardingPersonalIdentificationResponse.value =
              ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
      } catch (e, s) {
        debugPrint('❌ ridersOnboardingPersonalIdentificationApi error: $e\n$s');
        ridersOnboardingPersonalIdentificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally{
        isRiderPersonalIdentificationLoading.value = false;
      }
    }
  }

  RxBool isRiderDrivingVerificationLoading = false.obs;

  /// ridersOnboardingDrivingVerificationApi (Step 4)
  Future<void> ridersOnboardingDrivingVerificationApi() async {
    if(formKeyStep3.currentState!.validate()) {
      // ---------- 1️⃣ VALIDATION ----------
      if (rcFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectRcFrontImage.tr);
        return;
      }
      if (rcBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectRcBackImage.tr);
        return;
      }
      if (drivingLicenseFrontImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectDlFrontImage.tr);
        return;
      }
      if (drivingLicenseBackImage.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectDlBackImage.tr);
        return;
      }

      try {
        isRiderDrivingVerificationLoading.value = true;

        // ---------- 2️⃣ INITIALIZE ----------
        String? rcFrontImageUrl;
        String? rcBackImageUrl;
        String? drivingLicenseFrontImageUrl;
        String? drivingLicenseBackImageUrl;

        // ---------- 3️⃣ UPLOAD RC IMAGES ----------
        rcFrontImageUrl = await _uploadToS3(rcFrontImage.value!);
        rcBackImageUrl = await _uploadToS3(rcBackImage.value!);

        // ---------- 4️⃣ UPLOAD DRIVING LICENSE IMAGES ----------
        drivingLicenseFrontImageUrl = await _uploadToS3(drivingLicenseFrontImage.value!);
        drivingLicenseBackImageUrl = await _uploadToS3(drivingLicenseBackImage.value!);

        // ---------- 5️⃣ PREPARE PAYLOAD ----------
        final params = {
          ApiKeys.rcNo: rcController.text,
          ApiKeys.dlNo: drivingLicenseController.text,
          ApiKeys.rcImages: {
            ApiKeys.front: rcFrontImageUrl,
            ApiKeys.back: rcBackImageUrl,
          },
          ApiKeys.dlImages: {
            ApiKeys.front: drivingLicenseFrontImageUrl,
            ApiKeys.back: drivingLicenseBackImageUrl,
          },
        };

        // ---------- 6️⃣ CALL API ----------
        final response = await DeliveryPartnerRepo()
            .ridersOnboardingDrivingVerificationRepo(params: params);

        // ---------- 7️⃣ HANDLE RESPONSE ----------
        if (response.isSuccess) {
          ridersOnboardingDrivingVerificationResponse.value =
              ApiResponse.complete(response);
          Get.toNamed(RouteHelper.getVehicleImagesRidingScreenRoute());
        } else {
          ridersOnboardingDrivingVerificationResponse.value =
              ApiResponse.error('error');
          commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong,
          );
        }
      } catch (e, s) {
        debugPrint('❌ ridersOnboardingDrivingVerificationApi error: $e\n$s');
        ridersOnboardingDrivingVerificationResponse.value =
            ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }finally{
        isRiderDrivingVerificationLoading.value = false;
      }
    }
  }

  RxBool isRiderVehicleImagesLoading = false.obs;

  /// ridersOnboardingVehicleImagesApi (Step 5)
  Future<void> ridersOnboardingVehicleImagesApi() async {
    // ---------- 1️⃣ VALIDATION ----------
    if (vehicleNumberPlateImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectNumberPlateImage.tr);
      return;
    }

    if (vehicleRightSideImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectRightSideImages.tr);
      return;
    } else if (vehicleRightSideImages.length < 2) {
      commonSnackBar(message: AppStrings.pleaseSelectAtLeastTwoRight.tr);
      return;
    }

    if (vehicleLeftSideImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectLeftSideImages.tr);
      return;
    } else if (vehicleLeftSideImages.length < 2) {
      commonSnackBar(message: AppStrings.pleaseSelectAtLeastTwoLeft.tr);
      return;
    }


    if (vehicleFrontImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectFrontImage.tr);
      return;
    }

    if (vehicleBackImages.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseSelectBackImage.tr);
      return;
    }

    try {
      isRiderVehicleImagesLoading.value = true;

      // ---------- 2️⃣ INITIALIZE ----------
      List<String> vehicleNumberPlateImageUrls = [];
      List<String> vehicleRightSideImageUrls = [];
      List<String> vehicleLeftSideImageUrls = [];
      List<String> vehicleFrontImageUrls = [];
      List<String> vehicleBackImageUrls = [];

      // ---------- 3️⃣ UPLOAD NUMBER PLATE IMAGES ----------
      for (final photo in vehicleNumberPlateImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleNumberPlateImageUrls.add(fileUrl);
        }
      }

      // ---------- 4️⃣ UPLOAD RIGHT SIDE IMAGES ----------
      for (final photo in vehicleRightSideImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleRightSideImageUrls.add(fileUrl);
        }
      }

      // ---------- 5️⃣ UPLOAD LEFT SIDE IMAGES ----------
      for (final photo in vehicleLeftSideImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleLeftSideImageUrls.add(fileUrl);
        }
      }

      // ---------- 6️⃣ UPLOAD FRONT IMAGES ----------
      for (final photo in vehicleFrontImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleFrontImageUrls.add(fileUrl);
        }
      }

      // ---------- 7️⃣ UPLOAD BACK IMAGES ----------
      for (final photo in vehicleBackImages) {
        final fileUrl = await _uploadToS3(photo);
        if (fileUrl != null && fileUrl.isNotEmpty) {
          vehicleBackImageUrls.add(fileUrl);
        }
      }

      // ---------- 8️⃣ PREPARE PAYLOAD ----------
      final params = {
        ApiKeys.vehicleNoPlateImg: vehicleNumberPlateImageUrls.first,
        ApiKeys.vehicleRightHandSideImage: vehicleRightSideImageUrls,
        ApiKeys.vehicleLeftSideImage: vehicleLeftSideImageUrls,
        ApiKeys.vehicleFrontImage: vehicleFrontImageUrls.first,
        ApiKeys.vehicleBackImage: vehicleBackImageUrls.first,
      };

      // ---------- 9️⃣ API CALL ----------
      final response = await DeliveryPartnerRepo()
          .ridersOnboardingVehicleImagesRepo(params: params);

      // ---------- 🔟 HANDLE RESPONSE ----------
      if (response.isSuccess) {
        ridersOnboardingVehicleImagesResponse.value =
            ApiResponse.complete(response);
        Get.toNamed(RouteHelper.getVehicleInformationRidingScreenRoute());
      } else {
        ridersOnboardingVehicleImagesResponse.value =
            ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e, s) {
      debugPrint('❌ ridersOnboardingVehicleImagesApi error: $e\n$s');
      ridersOnboardingVehicleImagesResponse.value =
          ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      isRiderVehicleImagesLoading.value = false;
    }
  }

  RxBool isRiderVehicleInformationLoading = false.obs;

  /// ridersOnboardingPersonalInformationApi (Step 6)
  Future<void>  ridersOnboardingVehicleInformationApi() async {
    if(formKeyStep6.currentState!.validate()){
      if (selectedVehicleRegistrationType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectVehicleRegType.tr);
        return;
      }

      if (selectedVehicleType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectVehicleType.tr);
        return;
      }

      if (selectedFuelType.value == null) {
        commonSnackBar(message: AppStrings.pleaseSelectFuelType.tr);
        return;
      }

      if (!isTermsAccepted.value) {
        commonSnackBar(message: AppStrings.pleaseAcceptTermsAndConditions.tr);
        return;
      }


      try {
        isRiderVehicleInformationLoading.value = true;

        Map<String, dynamic> params = {
          ApiKeys.registrationType: selectedVehicleRegistrationType.value?.name,
          ApiKeys.registrationNo: vehicleRegistrationNumberController.text,
          ApiKeys.vehicleType: selectedVehicleType.value?.name,
          ApiKeys.vehicleName: vehicleNameController.text,
          ApiKeys.vehicleModelYear: vehicleModelController.text,
          ApiKeys.fuelType: selectedFuelType.value?.name,
        };

        ResponseModel response = await DeliveryPartnerRepo().ridersOnboardingVehicleInformationRepo(
          params: params,
        );

        if (response.isSuccess) {
          ridersOnboardingVehicleInformationResponse.value = ApiResponse.complete(response);
          Get.until(
                (route) =>
            route.settings.name ==
                RouteHelper.getEarnWithBlueEraNewScreenRoute(),
          );
        } else {
          ridersOnboardingVehicleInformationResponse.value = ApiResponse.error('error');
          commonSnackBar(
              message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        ridersOnboardingVehicleInformationResponse.value = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }finally{
        isRiderVehicleInformationLoading.value = false;
      }
    }
  }

  Future<void> addLivePhoto() async {
    final selectedPath =
        await SelectProfilePictureDialog.pickFromCamera(
        Get.context!,
        cropAspectRatio: CropAspectRatio(width: 3, height: 4)
      );
    if (selectedPath != null) {
      livePhoto.add(File(selectedPath));
    }
    update([livePhotoImageId]);
  }

  Future<void> removeLivePhoto(int index) async {
    livePhoto.removeAt(index);
    update([livePhotoImageId]);
  }

}