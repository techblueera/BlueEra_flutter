import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
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
import 'package:BlueEra/features/common/service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/repo/earn_service_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/features/common/service/model/add_service_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/detail_item.dart';
import 'package:BlueEra/features/common/service/view/add_services_screen.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddServiceController extends GetxController {
  Rx<ApiResponse> createServiceResponse = ApiResponse.initial('Initial').obs;
  ApiResponse uploadFileToS3Response = ApiResponse.initial('Initial');

  final TextEditingController facilitiesCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController serviceNameCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController minPriceCtrl = TextEditingController();
  final TextEditingController maxPriceCtrl = TextEditingController();
  final TextEditingController perUnitCtrl = TextEditingController();
  final TextEditingController minBookingCtrl = TextEditingController();

  // Create a unique GlobalKey for each instance
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxList<String> imageLocalPaths = <String>[].obs;
  final RxList<String> facilities = <String>[].obs;

  RxBool isSpecial = false.obs;
  RxBool isRange = true.obs;

  String? category;

  // Generate 24-hour railway times (00:00 → 23:30)
  final List<String> timeSlots = List.generate(
    48,
    (i) =>
        "${(i ~/ 2).toString().padLeft(2, '0')}:${(i % 2 == 0 ? "00" : "30")}",
  );

  RxString startTime = "".obs;
  RxString endTime = "".obs;

  RxList<DiscountCoupon> coupons = <DiscountCoupon>[].obs;
  RxList<DetailItem> detailsList = <DetailItem>[].obs;

  // Validation method
  String? validateServiceName(String? value) {
    if (value == null || value.isEmpty) return AppStrings.serviceNameRequired;
    if (value.length < 3) return AppStrings.serviceNameMinLength;
    return null;
  }

  String? validateServiceDescription(String? value) {
    if (value == null || value.isEmpty)
      return AppStrings.serviceDescRequired;
    if (value.length < 15)
      return AppStrings.serviceDescMinLength;
    return null;
  }

  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return AppStrings.amountRequired;

    // Try parsing the value to a number
    final amount = double.tryParse(value);
    if (amount == null) return  AppStrings.enterValidNumber;
    if (amount <= 0) return AppStrings.amountGreaterThanZero;

    return null;
  }

  String? validateMinPrice(String? value, TextEditingController maxPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.minPriceRequired;
    }

    final min = int.tryParse(value);
    if (min == null || min <= 0) {
      return  AppStrings.enterValidMinPrice;
    }

    final max = int.tryParse(maxPriceCtrl.text);
    if (max != null && min >= max) {
      return AppStrings.minLessThanMax;
    }

    return null;
  }

  String? validateMaxPrice(String? value, TextEditingController minPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.maxPriceRequired;
    }

    final max = int.tryParse(value);
    if (max == null || max <= 0) {
      return AppStrings.enterValidMaxPrice;
    }

    final min = int.tryParse(minPriceCtrl.text);
    if (min != null && max <= min) {
      return AppStrings.maxGreaterThanMin;
    }

    return null;
  }

  Future<void> pickImages(BuildContext context,[int? maxImages]) async {
    try {
      final List<String>? selected =
          await SelectProductImageDialog.showLogoDialog(maxImages: maxImages,
        context,
        AppStrings.serviceImage,
      );

      if (selected != null) {
        if (selected.isEmpty) return;
        final remaining = 5 - imageLocalPaths.length;
        if (remaining <= 0) return;
        final addList = selected.take(remaining).map((i) => i).toList();
        imageLocalPaths.addAll(addList);
      }
    } catch (e) {
      log('Image pick failed: $e');
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < imageLocalPaths.length) {
      imageLocalPaths.removeAt(index);
    }
  }

  void addFacility() {
    if (facilities.length == 10) {
      commonSnackBar(message: AppStrings.max10Facilities);
      return;
    }

    final text = facilitiesCtrl.text.trim();
    if (text.isNotEmpty) {
      facilities.add(text);
      facilitiesCtrl.clear();
    }
  }

  void removeFacility(String tag) {
    facilities.remove(tag);
  }

  void addCoupon(DiscountCoupon coupon) {
    coupons.add(coupon);
  }

  void removeCoupon(int index) {
    coupons.removeAt(index);
  }

  void addDetail(DetailItem detail) {

    detailsList.add(detail);
  }

  void removeDetail(int index) {
    detailsList.removeAt(index);
  }

  String formatTime(String time24) {
    final parts = time24.split(":");
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final suffix = hour >= 12 ? AppStrings.pm : AppStrings.am;
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return "${hour.toString().padLeft(2, '0')}:$minute $suffix";
  }

  bool isValidate() {
    if (!formKey.currentState!.validate()) return false;

    // if (imageLocalPaths.length < 2 || imageLocalPaths.length > 5) {
    //   commonSnackBar(
    //       message: (imageLocalPaths.length < 2)
    //           ? accountTypeGlobal == AppConstants.individual
    //               ? 'Please take minimum two services images'
    //               : 'Please take minimum two services images'
    //           : 'You can\'t add more than five images');
    //   return false;
    // }

    if (imageLocalPaths.length < 1 || imageLocalPaths.length > 5) {
      commonSnackBar(
          message: (imageLocalPaths.length < 1)
              ? AppStrings.minTwoImages
              : AppStrings.maxFiveImages);
      return false;
    }

    if (facilities.isEmpty) {
      commonSnackBar(message: AppStrings.addFacility);
      return false;
    }

    if (startTime.value.isEmpty) {
      commonSnackBar(message: AppStrings.startTimeRequired);
      return false;
    }

    if (endTime.value.isEmpty) {
      commonSnackBar(message: AppStrings.endTimeRequired);
      return false;
    }

    final startIndex = timeSlots.indexOf(startTime.value);
    final endIndex = timeSlots.indexOf(endTime.value);

    if (startIndex >= endIndex) {
      commonSnackBar(message: AppStrings.startBeforeEnd);
      return false;
    }

    return true;
  }

  Future<void> createServiceApi({String? channelId, required ProductServiceProviderType providerType, EarnWithBlueEraServiceTypes? serviceSubType}) async {

    /// Provider Type
    // Business --> userId
    // User    ---> userId
    // Channel ---> channelId

    if (!isValidate()) return;

    try {
      UploadProgressDialog.show(
          initialProgress: 0.0, title: AppStrings.creatingService);

      Map<String, dynamic> params = {
        ApiKeys.type: 'service',
        ApiKeys.providerType: providerType.title,
        ApiKeys.title: serviceNameCtrl.text.trim(),
        ApiKeys.description: descriptionCtrl.text.trim(),
        ApiKeys.facilities: facilities,
        ApiKeys.timings: {
          ApiKeys.start: formatTime(startTime.value),
          ApiKeys.end: formatTime(endTime.value),
          ApiKeys.special: isSpecial.value,
        },
        ApiKeys.perUnit: perUnitCtrl.text.trim(),
        if (coupons.isNotEmpty)
          ApiKeys.discounts: coupons.map((e) => e.toJson()).toList(),
        // if (detailsList.isNotEmpty)
        //   ApiKeys.extraDetails: detailsList.map((e) => e.toJson()).toList()
      };
      if(category!=null) params[ApiKeys.category]= category;
      if(serviceSubType!=null)  params[ApiKeys.subType] = serviceSubType.label;
      if(channelId!=null) params[ApiKeys.channelId] = channelId;

      if (isRange.isTrue) {
        params[ApiKeys.priceType] = 'range';
        params[ApiKeys.priceRange] = {
          ApiKeys.min: int.tryParse(minPriceCtrl.text.trim()),
          ApiKeys.max: int.tryParse(maxPriceCtrl.text.trim()),
        };
      } else {
        params[ApiKeys.priceType] = 'fixed';
      }

      // Prepare images
      List<UploadS3ImageModel> images = [];
      for (var imagePath in imageLocalPaths) {
        final imageInfo = getFileInfo(File(imagePath));
        if (imageInfo.isNotEmpty) {
          images.add(
            UploadS3ImageModel(path: imagePath, mimeType: imageInfo['mimeType']!),
          );
        }
      }

      if (images.isNotEmpty) {
        params[ApiKeys.imageContentTypes] =
            images.map((img) => img.mimeType).toList();
      }

      // Call API once
      final ResponseModel responseModel;
      if(providerType == ProductServiceProviderType.user){
        responseModel = await EarnServiceRepo().addServiceRepo(params: params);
      }else{
        responseModel = await ServiceAiRepo().addService(params: params);
      }

      if (responseModel.isSuccess) {
        createServiceResponse.value = ApiResponse.complete(responseModel);

        // First API progress = 20%
        UploadProgressDialog.update(0.2);

        // Set preSignedUrls from response
        final addServiceResponseModel =
            AddServiceResponseModel.fromJson(responseModel.response!.data);
        List<String> preSignedUrlImages =
            addServiceResponseModel.uploadUrls?.images ?? [];

        if (images.length == preSignedUrlImages.length) {
          for (var i = 0; i < images.length; i++) {
            images[i].preSignedUrl = preSignedUrlImages[i];
          }

          // Upload all images with combined progress
          await uploadAllImages(images);
        }

        log('called once only');

        // ✅ Close dialog once and navigate back
        UploadProgressDialog.close();
        commonSnackBar(message: AppStrings.serviceAddedSuccess);
        Get.close(2);
        // Get.back();
        // Get.back();
      } else {
        createServiceResponse.value = ApiResponse.error('error');
        UploadProgressDialog.close();
        commonSnackBar(message: responseModel.message);
      }
    } catch (e) {
      UploadProgressDialog.close();
      createServiceResponse.value = ApiResponse.error('error');
      log('Something went wrong--> $e');
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

            UploadProgressDialog.update(overallProgress.clamp(0.0, 1.0));

            debugPrint(
                "Uploading ${file.path}: ${(progress * 100).toStringAsFixed(0)}%, overall: ${(overallProgress * 100).toStringAsFixed(0)}%");
          },
        );
      }
    } catch (e) {
      UploadProgressDialog.close();
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
        uploadFileToS3Response = ApiResponse.complete(response);
      } else {
        uploadFileToS3Response = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      uploadFileToS3Response = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

}
