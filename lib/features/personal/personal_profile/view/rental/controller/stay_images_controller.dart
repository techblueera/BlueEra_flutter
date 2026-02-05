import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/repo/rental_service_repo.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

class StayImagesController extends GetxController {
  Rx<ApiResponse> uploadImagesResponse = ApiResponse.initial('Initial').obs;

  final RxList<File> roomImages = <File>[].obs;
  final RxList<File> kitchenImages = <File>[].obs;
  final RxList<File> bathroomImages = <File>[].obs;
  final RxList<File> roadSideImages = <File>[].obs;
  final RxList<File> otherImages = <File>[].obs;

  int maxHomeImageUpload = 4;
  RxBool isUploadImagesLoading = false.obs;

  final RxMap<String, bool> sectionUploadStatus = <String, bool>{
    CommonMultipleImageSectionController.roomImageId: false,
    CommonMultipleImageSectionController.kitchenImageId: false,
    CommonMultipleImageSectionController.bathroomImageId: false,
    CommonMultipleImageSectionController.roadSideImageId: false,
    CommonMultipleImageSectionController.otherImageId: false,
  }.obs;

  Future<void> uploadRentalImagesApi(
      {required List<File> images, required String sectionId}) async {
    try {
      isUploadImagesLoading.value = true;

      final imageConfig = {
        CommonMultipleImageSectionController.roomImageId: (
          msg: 'Please select at least one room image',
          apiKey: ApiKeys.roomImages
        ),
        CommonMultipleImageSectionController.kitchenImageId: (
          msg: 'Please select at least one kitchen image',
          apiKey: ApiKeys.kitchenImages
        ),
        CommonMultipleImageSectionController.bathroomImageId: (
          msg: 'Please select at least one bathroom image',
          apiKey: ApiKeys.bathroomImages
        ),
        CommonMultipleImageSectionController.roadSideImageId: (
          msg: 'Please select at least one road-side image',
          apiKey: ApiKeys.roadImages
        ),
        CommonMultipleImageSectionController.otherImageId: (
          msg: 'Please select other images',
          apiKey: ApiKeys.otherImages
        ),
      };

      final config = imageConfig[sectionId];

      if (config == null) return;

      if (images.isEmpty) {
        commonSnackBar(message: config.msg);
        return;
      }

      List<dio.MultipartFile> imageParts =
          await multiPartMultipleImages(arrImages: images);

      Map<String, dynamic> params = {
        ApiKeys.type: 'Property',
        config.apiKey: imageParts,
      };

      ResponseModel response = await RentalServiceRepo().uploadRentalImagesRepo(
        params: params,
      );

      if (response.isSuccess) {
        uploadImagesResponse.value = ApiResponse.complete(response);
        Get.back();
        sectionUploadStatus[sectionId] = true;
      } else {
        uploadImagesResponse.value = ApiResponse.error('error');
      }
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    } catch (e) {
      uploadImagesResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    } finally {
      isUploadImagesLoading.value = false;
    }
  }
}
