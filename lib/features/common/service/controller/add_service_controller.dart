import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/common/service/model/add_service_response_model.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/model/service_ai_generate_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/earn_service_repo.dart';
import 'package:BlueEra/features/me/product/model/detail_item.dart';
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

  // Context owned by the controller for both add & update flows. For the
  // add flow ServiceController writes these in before navigating to
  // AddServicesScreenNew. For the edit flow the caller populates them via
  // [populateFromService].
  ProviderType? providerType;
  String? category;
  String? serviceSubType;
  String? channelId;

  /// When non-null we're editing an existing service and should PUT.
  String? serviceId;

  /// Already-uploaded photos (URLs) for the service being edited. Kept
  /// separate from [imageLocalPaths] since those are `File` paths for new
  /// images the user is adding.
  final RxList<String> existingPhotoUrls = <String>[].obs;

  // ── Deferred edit hand-off ────────────────────────────────────────────
  // Callers stash the edit context here right before Get.to; the add
  // screen's initState calls [consumePendingEdit] on its first frame. This
  // keeps the tap-to-navigation latency low by moving ~10 TextField /
  // RxList writes off the current frame.
  GetServiceModel? _editService;
  ProviderType? _editProviderType;
  String? _editServiceSubType;
  String? _editChannelId;

  void stashEdit({
    required GetServiceModel service,
    required ProviderType providerType,
    String? serviceSubType,
    String? channelId,
  }) {
    _editService = service;
    _editProviderType = providerType;
    _editServiceSubType = serviceSubType;
    _editChannelId = channelId;
  }

  bool consumePendingEdit() {
    final svc = _editService;
    final pt = _editProviderType;
    if (svc == null || pt == null) return false;
    populateFromService(
      service: svc,
      providerType: pt,
      serviceSubType: _editServiceSubType,
      channelId: _editChannelId,
    );
    _editService = null;
    _editProviderType = null;
    _editServiceSubType = null;
    _editChannelId = null;
    return true;
  }

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
    if (value == null || value.isEmpty) return AppStrings.serviceNameRequired.tr;
    if (value.length < 3) return AppStrings.serviceNameMinLength.tr;
    return null;
  }

  String? validateServiceDescription(String? value) {
    if (value == null || value.isEmpty)
      return AppStrings.serviceDescRequired.tr;
    if (value.length < 15)
      return AppStrings.serviceDescMinLength.tr;
    return null;
  }

  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return AppStrings.amountRequired.tr;

    // Try parsing the value to a number
    final amount = double.tryParse(value);
    if (amount == null) return  AppStrings.enterValidNumber.tr;
    if (amount <= 0) return AppStrings.amountGreaterThanZero.tr;

    return null;
  }

  String? validateMinPrice(String? value, TextEditingController maxPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.minPriceRequired.tr;
    }

    final min = int.tryParse(value);
    if (min == null || min <= 0) {
      return  AppStrings.enterValidMinPrice.tr;
    }

    final max = int.tryParse(maxPriceCtrl.text);
    if (max != null && min >= max) {
      return AppStrings.minLessThanMax.tr;
    }

    return null;
  }

  String? validateMaxPrice(String? value, TextEditingController minPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.maxPriceRequired.tr;
    }

    final max = int.tryParse(value);
    if (max == null || max <= 0) {
      return AppStrings.enterValidMaxPrice.tr;
    }

    final min = int.tryParse(minPriceCtrl.text);
    if (min != null && max <= min) {
      return AppStrings.maxGreaterThanMin.tr;
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
      commonSnackBar(message: AppStrings.max10Facilities.tr);
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
    final suffix = hour >= 12 ? AppStrings.pm.tr : AppStrings.am.tr;
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

    final totalPhotos = imageLocalPaths.length + existingPhotoUrls.length;
    if (totalPhotos < 1 || totalPhotos > 5) {
      commonSnackBar(
          message: (totalPhotos < 1)
              ? AppStrings.minTwoImages.tr
              : AppStrings.maxFiveImages.tr);
      return false;
    }

    if (facilities.isEmpty) {
      commonSnackBar(message: AppStrings.addFacility.tr);
      return false;
    }

    if (startTime.value.isEmpty) {
      commonSnackBar(message: AppStrings.startTimeRequired.tr);
      return false;
    }

    if (endTime.value.isEmpty) {
      commonSnackBar(message: AppStrings.endTimeRequired.tr);
      return false;
    }

    final startIndex = timeSlots.indexOf(startTime.value);
    final endIndex = timeSlots.indexOf(endTime.value);

    if (startIndex >= endIndex) {
      commonSnackBar(message: AppStrings.startBeforeEnd.tr);
      return false;
    }

    return true;
  }

  /// Populates the controller from the AI-generated suggestion used by the
  /// add flow. [selectedImagePath] is the local image the user picked on
  /// [ServiceUploadScreen].
  void populateFromAi({
    required ServiceAiGenerateModel ai,
    required String selectedImagePath,
    required ProviderType providerType,
    required String category,
    String? serviceSubType,
    String? channelId,
  }) {
    serviceId = null; // add mode
    this.providerType = providerType;
    this.category = category;
    this.serviceSubType = serviceSubType;
    this.channelId = channelId;
    serviceNameCtrl.text = ai.serviceName ?? '';
    descriptionCtrl.text = ai.serviceDescription ?? '';
    facilities
      ..clear()
      ..addAll(ai.serviceFacilities ?? []);
    imageLocalPaths
      ..clear()
      ..add(selectedImagePath);
    existingPhotoUrls.clear();
  }

  /// Populates the controller from an existing service (edit flow).
  void populateFromService({
    required GetServiceModel service,
    required ProviderType providerType,
    String? serviceSubType,
    String? channelId,
  }) {
    serviceId = service.id;
    this.providerType = providerType;
    category = service.category;
    this.serviceSubType = serviceSubType ?? service.type;
    this.channelId = channelId;

    serviceNameCtrl.text = service.title ?? '';
    descriptionCtrl.text = service.description ?? '';
    perUnitCtrl.text = service.perUnit ?? '';

    facilities
      ..clear()
      ..addAll(service.facilities ?? []);

    existingPhotoUrls
      ..clear()
      ..addAll(service.photos ?? []);
    imageLocalPaths.clear();

    // Pricing
    if (service.priceType == 'range') {
      isRange.value = true;
      minPriceCtrl.text = service.priceRange?.min?.toString() ?? '';
      maxPriceCtrl.text = service.priceRange?.max?.toString() ?? '';
      priceCtrl.clear();
    } else {
      isRange.value = false;
      priceCtrl.text = service.priceRange?.min?.toString() ?? '';
      minPriceCtrl.clear();
      maxPriceCtrl.clear();
    }

    // Timings (server returns "03:30 AM"; dropdown wants "03:30").
    final t = (service.timings != null && service.timings!.isNotEmpty)
        ? service.timings!.first
        : null;
    isSpecial.value = t?.special ?? false;
    startTime.value = _parseTo24h(t?.start) ?? '';
    endTime.value = _parseTo24h(t?.end) ?? '';

    minBookingCtrl.clear();
    coupons.clear();
    detailsList.clear();
  }

  /// Converts "03:30 AM" -> "03:30" (24h) to match [timeSlots].
  String? _parseTo24h(String? time12) {
    if (time12 == null || time12.trim().isEmpty) return null;
    final parts = time12.trim().split(' ');
    if (parts.length < 2) return time12;
    final tp = parts[0].split(':');
    if (tp.length < 2) return time12;
    int hour = int.tryParse(tp[0]) ?? 0;
    final minute = tp[1];
    final suffix = parts[1].toUpperCase();
    if (suffix == 'PM' && hour != 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, "0")}:$minute';
  }

  Map<String, dynamic> _buildServiceParams() {
    final params = <String, dynamic>{
      ApiKeys.type: 'service',
      ApiKeys.providerType: providerType?.title,
      ApiKeys.title: serviceNameCtrl.text.trim(),
      ApiKeys.description: descriptionCtrl.text.trim(),
      ApiKeys.facilities: facilities.toList(),
      ApiKeys.timings: {
        ApiKeys.start: formatTime(startTime.value),
        ApiKeys.end: formatTime(endTime.value),
        ApiKeys.special: isSpecial.value,
      },
      ApiKeys.perUnit: perUnitCtrl.text.trim(),
      if (coupons.isNotEmpty)
        ApiKeys.discounts: coupons.map((e) => e.toJson()).toList(),
    };
    if (category != null) params[ApiKeys.category] = category;
    if (serviceSubType != null) params[ApiKeys.subType] = serviceSubType;
    if (channelId != null) params[ApiKeys.channelId] = channelId;

    if (isRange.isTrue) {
      params[ApiKeys.priceType] = 'range';
      params[ApiKeys.priceRange] = {
        ApiKeys.min: int.tryParse(minPriceCtrl.text.trim()),
        ApiKeys.max: int.tryParse(maxPriceCtrl.text.trim()),
      };
    } else {
      params[ApiKeys.priceType] = 'fixed';
      params[ApiKeys.singlePrice] = priceCtrl.text.trim();
    }
    return params;
  }

  /// POST a brand-new service. Uses controller state — callers populate
  /// [providerType]/[category]/[serviceSubType]/[channelId] via
  /// [populateFromAi] before invoking.
  Future<void> createServiceApi() async {
    if (providerType == null || category == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    if (!isValidate()) return;

    try {
      UploadProgressDialog.show(
          initialProgress: 0.0, title: AppStrings.creatingService);

      final params = _buildServiceParams();

      // Prepare images (only local files need upload on create).
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

      final ResponseModel responseModel;
      if (providerType == ProviderType.user) {
        responseModel = await EarnServiceRepo().addServiceRepo(params: params);
      } else {
        responseModel = await ServiceAiRepo().addService(params: params);
      }

      if (responseModel.isSuccess) {
        createServiceResponse.value = ApiResponse.complete(responseModel);
        UploadProgressDialog.update(0.2);

        final addServiceResponseModel =
            AddServiceResponseModel.fromJson(responseModel.response!.data);
        List<String> preSignedUrlImages =
            addServiceResponseModel.uploadUrls?.images ?? [];

        if (images.length == preSignedUrlImages.length) {
          for (var i = 0; i < images.length; i++) {
            images[i].preSignedUrl = preSignedUrlImages[i];
          }
          await uploadAllImages(images);
        }

        UploadProgressDialog.close();
        commonSnackBar(message: AppStrings.serviceAddedSuccess.tr);
        Get.close(2);
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

  /// PUT /services/{id}. Sends the merged set of kept server photos +
  /// freshly-picked local images (images uploaded to S3 via pre-signed URLs
  /// before the request if the backend issues them).
  Future<void> updateServiceApi() async {
    final id = serviceId;
    if (id == null || id.isEmpty) return;
    if (!isValidate()) return;

    try {
      UploadProgressDialog.show(
          initialProgress: 0.0, title: AppStrings.creatingService);

      final params = _buildServiceParams();

      // Newly-added local images that still need to be uploaded.
      final List<UploadS3ImageModel> newImages = [];
      for (var imagePath in imageLocalPaths) {
        final imageInfo = getFileInfo(File(imagePath));
        if (imageInfo.isNotEmpty) {
          newImages.add(
            UploadS3ImageModel(
                path: imagePath, mimeType: imageInfo['mimeType']!),
          );
        }
      }
      if (newImages.isNotEmpty) {
        params[ApiKeys.imageContentTypes] =
            newImages.map((img) => img.mimeType).toList();
      }
      // Preserve already-uploaded photos.
      params[ApiKeys.photos] = existingPhotoUrls.toList();

      final ResponseModel responseModel = await EarnServiceRepo()
          .updateServiceRepo(serviceId: id, params: params);

      if (responseModel.isSuccess) {
        createServiceResponse.value = ApiResponse.complete(responseModel);
        UploadProgressDialog.update(0.2);

        final data = responseModel.response?.data;
        if (data is Map<String, dynamic>) {
          final respModel = AddServiceResponseModel.fromJson(data);
          final urls = respModel.uploadUrls?.images ?? [];
          if (newImages.length == urls.length) {
            for (var i = 0; i < newImages.length; i++) {
              newImages[i].preSignedUrl = urls[i];
            }
            await uploadAllImages(newImages);
          }
        }

        UploadProgressDialog.close();
        commonSnackBar(message: AppStrings.serviceAddedSuccess.tr);
        Get.back(result: true);
      } else {
        createServiceResponse.value = ApiResponse.error('error');
        UploadProgressDialog.close();
        commonSnackBar(message: responseModel.message);
      }
    } catch (e) {
      UploadProgressDialog.close();
      createServiceResponse.value = ApiResponse.error('error');
      log('Update failed--> $e');
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
