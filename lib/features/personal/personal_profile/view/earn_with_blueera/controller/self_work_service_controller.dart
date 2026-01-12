import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/service/model/add_service_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/predefined_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_service_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/apiService/api_keys.dart';

class SelfWorkServiceController extends GetxController{
  Rx<ApiResponse> predefinedCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response =
  ApiResponse.initial('Initial').obs;

  String? designation;

  // --- Service images ---
  final RxList<String> selectedImages = <String>[].obs;

  // --- Dropdown State ---
  // 1. Years List (1 Year to 9 Years, then 10+ Years)
  final List<String> experienceYears = [
    "1 Year",
    "2 Years",
    "3 Years",
    "4 Years",
    "5 Years",
    "6 Years",
    "7 Years",
    "8 Years",
    "9 Years",
    "10+ Years"
  ];

   // 2. Months List (1 Month to 12 Months)
  final List<String> experienceMonths = [
    "1 Month",
    "2 Months",
    "3 Months",
    "4 Months",
    "5 Months",
    "6 Months",
    "7 Months",
    "8 Months",
    "9 Months",
    "10 Months",
    "11 Months",
    "12 Months"
  ];

  final selectedExperienceYear = Rxn<String>();
  final selectedExperienceMonth = Rxn<String>();
  final serviceTypes = <String>[].obs;
  final selectedServiceType = Rxn<String>();

  // Available options for each category (Mock Data)
  var selectedServices = <String>[].obs;
  var selectedInstallations = <String>[].obs;
  var selectedExpertise = <String>[].obs;
  var selectedWorkCategories = <String>[].obs;
  var selectedWhyChooseMe = <String>[].obs;

  static const String keyServiceTypes = "serviceTypes";
  static const String keyServicesOffered = "servicesOffered";
  static const String keyWork = "typesOfWork";
  static const String keyExpertise = "expertise";
  static const String keyWorkCategories = "workCategories";
  static const String keyWhyChooseMe = "whyChooseMe";

  Map<String, RxList<String>> get allCategoryMap => {
    keyServicesOffered: serviceOptions,
    keyWork: installationOptions,
    keyExpertise: expertiseOptions,
    keyWorkCategories: workCategoryOptions,
    keyWhyChooseMe: whyChooseMeOptions,
  };

  Map<String, RxList<String>> get selectedCategoryMap => {
    keyServicesOffered: selectedServices,
    keyWork: selectedInstallations,
    keyExpertise: selectedExpertise,
    keyWorkCategories: selectedWorkCategories,
    keyWhyChooseMe: selectedWhyChooseMe,
  };

  Map<String, String> get categoryTitleMap => {
    keyServicesOffered: "Service Offered",
    keyWork: "Types of Installations",
    keyExpertise: "Expertise",
    keyWorkCategories: "Work Categories",
    keyWhyChooseMe: "Why Choose Me",
  };

  final RxList<String> serviceOptions = <String>[].obs;
  final RxList<String> installationOptions = <String>[].obs;
  final RxList<String> expertiseOptions = <String>[].obs;
  final RxList<String> workCategoryOptions = <String>[].obs;
  final RxList<String> whyChooseMeOptions = <String>[].obs;

  void updateSelection(String key, List<String> newItems) {
    if (selectedCategoryMap.containsKey(key)) {
      selectedCategoryMap[key]!.assignAll(newItems);
    }
  }

  // --- About Section ---
  final TextEditingController aboutController = TextEditingController();

  RxBool isPredefinedCategoryServiceTypeLoading = false.obs;
  Future<void> fetchPredefinedCategoryServiceType({
    required String designation,
    required String selectedServiceKey}) async {
    try {
      isPredefinedCategoryServiceTypeLoading.value = true;

      final response = await EarnServiceRepo().predefinedServiceCategoryRepo(
        designation: designation,
        queryParams: {
          ApiKeys.segment : selectedServiceKey,
        },
      );

      if (response.isSuccess) {
        predefinedCategoryResponse.value = ApiResponse.complete(response);
        final predefinedCategoryModel = PredefinedCategoryModel.fromJson(response.response?.data);
        serviceTypes.value = predefinedCategoryModel.items ?? [];
      } else {
        predefinedCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      predefinedCategoryResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isPredefinedCategoryServiceTypeLoading.value = false;
    }
  }

  RxBool isServiceSelectionLoading = false.obs;
  Future<void> fetchServiceSelectionOptions({
  required String designation,
  required String selectedServiceKey}) async {
    try {
      isServiceSelectionLoading.value = true;

      final response = await EarnServiceRepo().predefinedServiceCategoryRepo(
        designation: designation,
        queryParams: {
          ApiKeys.segment : selectedServiceKey,
        },
      );

      if (response.isSuccess) {
        predefinedCategoryResponse.value = ApiResponse.complete(response);
        final predifinedCategoryModel = PredefinedCategoryModel.fromJson(response.response?.data);
        List<String> newItems = predifinedCategoryModel.items ?? [];

        RxList<String>? targetList = allCategoryMap[selectedServiceKey];

        if (targetList != null) {
          targetList.assignAll(newItems);

          // Log for verification
          log("Updated $selectedServiceKey with ${targetList.length} items");
        } else {
          log("Error: No list found for key $selectedServiceKey");
        }

      } else {
        predefinedCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      predefinedCategoryResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isServiceSelectionLoading.value = false;
    }
  }

  /// Create Self Service
  Future<void> createServiceApi(
      {required EarnServiceTypes serviceSubType}
      ) async {

    // if (!isValidate()) return;

    try {
      // UploadProgressDialog.show(
      //     initialProgress: 0.0, title: AppStrings.creatingService);

      Map<String, dynamic> params = {
        ApiKeys.type: AppConstants.service,
        ApiKeys.providerType: ProviderType.user.title,
        ApiKeys.subType: serviceSubType.label,
        ApiKeys.category: designation ?? ELECTRICIAN,
        ApiKeys.serviceType: selectedServiceType,
        ApiKeys.description: aboutController.text.trim(),
        ApiKeys.experience: {
          ApiKeys.years: selectedExperienceYear,
          ApiKeys.months:selectedExperienceMonth,
        },


        // ApiKeys.min: int.tryParse(minPriceCtrl.text.trim()),
        // ApiKeys.max: int.tryParse(maxPriceCtrl.text.trim()),


        // ApiKeys.title: serviceNameCtrl.text.trim(),
        // ApiKeys.description: descriptionCtrl.text.trim(),
        // ApiKeys.facilities: facilities,
        // ApiKeys.timings: {
        //   ApiKeys.start: formatTime(startTime.value),
        //   ApiKeys.end: formatTime(endTime.value),
        //   ApiKeys.special: isSpecial.value,
        // },
        // ApiKeys.perUnit: perUnitCtrl.text.trim(),
        // if (coupons.isNotEmpty)
        //   ApiKeys.discounts: coupons.map((e) => e.toJson()).toList(),
        // if (detailsList.isNotEmpty)
        //   ApiKeys.extraDetails: detailsList.map((e) => e.toJson()).toList()
      };

      if (selectedServices.isNotEmpty) params[ApiKeys.serviceOffered] = selectedServices;
      if (selectedInstallations.isNotEmpty) params[ApiKeys.typesOfWork] = selectedInstallations;
      if (selectedExpertise.isNotEmpty) params[ApiKeys.expertise] = selectedExpertise;
      if (selectedWorkCategories.isNotEmpty) params[ApiKeys.workCategories] = selectedWorkCategories;
      if (selectedWhyChooseMe.isNotEmpty) params[ApiKeys.whyChooseMe] = selectedWhyChooseMe;

      // String? capitalizeFirst(String name) {
      //   if (name.isEmpty) return null;
      //   return this[0].toUpperCase() + substring(1).toLowerCase();
      // }
      // if(category!=null) params[ApiKeys.category] = category;
      // if(serviceSubType!=null)  params[ApiKeys.subType] = serviceSubType.label;
      // if(channelId!=null) params[ApiKeys.channelId] = channelId;
      //
      // if (isRange.isTrue) {
      //   params[ApiKeys.priceType] = 'range';
      //   params[ApiKeys.priceRange] = {
      //     ApiKeys.min: int.tryParse(minPriceCtrl.text.trim()),
      //     ApiKeys.max: int.tryParse(maxPriceCtrl.text.trim()),
      //   };
      // } else {
      //   params[ApiKeys.priceType] = 'fixed';
      //   params[ApiKeys.singlePrice] = priceCtrl.text.trim();
      // }

      // Prepare images
      List<UploadS3ImageModel> images = [];
      for (var imagePath in selectedImages) {
        final imageInfo = getFileInfo(File(imagePath));
        if (imageInfo.isNotEmpty) {
          images.add(
            UploadS3ImageModel(
                path: imagePath,
                mimeType: imageInfo['mimeType']!
            ),
          );
        }
      }

      if (images.isNotEmpty) {
        params[ApiKeys.imageContentTypes] =
            images.map((img) => img.mimeType).toList();
      }

      final ResponseModel responseModel = await EarnServiceRepo().addServiceRepo(params: params);


      if (responseModel.isSuccess) {
        createServiceResponse.value = ApiResponse.complete(responseModel);

        // First API progress = 20%
        // UploadProgressDialog.update(0.2);

        // Set preSignedUrls from response
        final addServiceResponseModel = AddServiceResponseModel.fromJson(responseModel.response!.data);
        List<String> preSignedUrlImages =
            addServiceResponseModel.uploadUrls?.images ?? [];

        if (images.length == preSignedUrlImages.length) {
          for (var i = 0; i < images.length; i++) {
            images[i].preSignedUrl = preSignedUrlImages[i];
          }

          // Upload all images with combined progress
          await uploadAllImages(images);
        }


        // ✅ Close dialog once and navigate back
        // UploadProgressDialog.close();
        commonSnackBar(message: AppStrings.serviceAddedSuccess.tr);

        await setEarnServiceOptData(true);
        // Get.close(2);
      } else {
        createServiceResponse.value = ApiResponse.error('error');
        // UploadProgressDialog.close();
        commonSnackBar(message: responseModel.message);
      }
    } catch (e) {
      // UploadProgressDialog.close();
      createServiceResponse.value = ApiResponse.error('error');
    }
  }


  Future<void> uploadAllImages(List<UploadS3ImageModel> images) async {
    if (images.isEmpty) return;

    final totalImages = images.length;

    try {
      for (var i = 0; i < totalImages; i++) {
        final image = images[i];
        final file = File(image.path);
        final fileType = image.mimeType;
        final preSignedUrl = image.preSignedUrl ?? '';

        await uploadFileToS3(
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl,
          onProgress: (progress) {
            final imageFraction = 0.8 / totalImages;
            final overallProgress =
                0.2 + (i * imageFraction) + (progress * imageFraction);

            // UploadProgressDialog.update(overallProgress.clamp(0.0, 1.0));

            debugPrint(
                "Uploading ${file.path}: ${(progress * 100).toStringAsFixed(0)}%, overall: ${(overallProgress * 100).toStringAsFixed(0)}%");
          },
        );
      }
    } catch (e) {
      // UploadProgressDialog.close();
      log('Something went wrong during image upload. $e');
    }
  }

  Future<void> uploadFileToS3({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async
  {
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
            message: response?.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      uploadFileToS3Response.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    }
  }

}