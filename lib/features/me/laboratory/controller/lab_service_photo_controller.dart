import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

/// Drives the laboratory's property-photos albums screen: lists existing
/// albums by category, handles the multi-image upload (S3 then API), and
/// per-image deletion.
///
/// Class name doubles "Photo" intentionally — preserved for backwards
/// compatibility with three existing view consumers.
class LabServicePhotoPhotoController extends GetxController {
  final LabServiceRepo _repo = LabServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// Existing albums returned by the API.
  final RxList<OtherServiceGalleryData> propertyPhotosList =
      <OtherServiceGalleryData>[].obs;

  /// Available album categories shown in the upload dropdown.
  final List<String> categories = const [
    'External View & Parking',
    'Exterior Photos',
    'Interior Photos',
    'Equipment Photos',
    'Team/Staff Photos',
    'Lobby & Reception',
    'Rooms',
    'Bathrooms',
    'Conference & Meeting Rooms',
    'Cleanliness & Hygiene',
    'Safety & Security',
    'Staff & Customer Service',
  ];

  /// Max picks before [addImage] starts rejecting.
  static const int _maxImagesPerUpload = 6;

  // ---- Upload-form state ----------------------------------------------------

  final RxString selectedCategory = "".obs;
  final RxList<String> selectedImages = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPhotos();
  }

  Future<void> fetchPhotos() async {
    try {
      isLoading.value = true;
      propertyPhotosList.clear();
      final ResponseModel response = await _repo.getOtherServicePhotosRepo();
      if (!response.isSuccess) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }
      final res =
          OtherServiceGalleryResModel.fromJson(response.response?.data);
      for (final photo in res.data ?? const <OtherServiceGalleryData>[]) {
        if (photo.imageUrls?.isNotEmpty ?? false) {
          propertyPhotosList.add(photo);
        }
      }
    } catch (e) {
      logs("LabServicePhotoController.fetchPhotos ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  void onCategoryChanged(String? value) {
    if (value != null) selectedCategory.value = value;
  }

  void addImage(String path) {
    if (selectedImages.length >= _maxImagesPerUpload) {
      commonSnackBar(message: AppStrings.hotelLimitReached6Images.tr);
      return;
    }
    selectedImages.add(path);
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  /// Uploads every picked file to S3 then registers them under
  /// [selectedCategory]. Clears the form on success.
  Future<void> buildRequestBody() async {
    try {
      isSaving.value = true;
      final urls = await _uploadAll(selectedImages);
      if (urls.isEmpty) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      final ResponseModel response =
          await _repo.addOtherServicePhotosRepo(reqBody: {
        "title": selectedCategory.value,
        "imageUrls": urls,
      });

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        selectedImages.clear();
        selectedCategory.value = "";
        await fetchPhotos();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("LabServicePhotoController.buildRequestBody ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteOtherServiceController({
    required String imgId,
    required String imgUrl,
  }) async {
    try {
      final ResponseModel response = await _repo.deleteOtherServicePhotosRepo(
        imgID: imgId,
        reqBody: {"imageUrl": imgUrl},
      );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message: response.response?.data['message'] ?? AppStrings.successful);
        await fetchPhotos();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("LabServicePhotoController.deleteOtherService ERROR $e");
    }
  }

  /// Uploads a batch of local file paths sequentially and returns the
  /// resulting S3 URLs for those that succeed.
  Future<List<String>> _uploadAll(List<String> paths) async {
    final urls = <String>[];
    for (final path in paths) {
      final result = await S3UploadService.uploadFile(File(path));
      if (result.isSuccess) urls.add(result.url);
    }
    return urls;
  }
}
