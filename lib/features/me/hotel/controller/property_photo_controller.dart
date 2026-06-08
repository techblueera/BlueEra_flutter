import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_property_photo_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

/// Drives the property-photos screen: lists existing albums per category,
/// and handles the multi-image upload flow that batches local files through
/// S3 then registers them under a category.
class PropertyPhotoController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// Existing albums returned by the API.
  final RxList<HotelPropertyPhotoData> propertyPhotosList = <HotelPropertyPhotoData>[].obs;

  /// Available album categories shown in the upload dropdown.
  ///
  /// Each entry is the wire-key sent to the backend's `category` field —
  /// kept in English so the API contract is stable across languages.
  /// Use [categoryLabel] to resolve the localized display string at
  /// render time.
  final List<String> categories = [
    AppStrings.photoCategoryExternalViewParking.tr,
    AppStrings.photoCategoryLobbyGarden.tr,
    AppStrings.photoCategoryRooms.tr,
    AppStrings.photoCategoryRestaurantBar.tr,
    AppStrings.photoCategoryGymSwimmingPool.tr,
  ];

  /// Resolves the localized display label for a category wire-key.
  /// Falls back to the raw key if it's not one of the known options
  /// (e.g. a server-added category we haven't translated yet).
  String categoryLabel(String key) {
    switch (key) {
      case "External View & Parking":
        return AppStrings.photoCategoryExternalViewParking.tr;
      case "Lobby & Garden":
        return AppStrings.photoCategoryLobbyGarden.tr;
      case "Rooms":
        return AppStrings.photoCategoryRooms.tr;
      case "Restaurant & Bar":
        return AppStrings.photoCategoryRestaurantBar.tr;
      case "Gym & Swimming Pool":
        return AppStrings.photoCategoryGymSwimmingPool.tr;
    }
    return key;
  }

  /// Max picks before [addImage] starts rejecting.
  static const int _maxImagesPerUpload = 6;

  // ---- Upload-form state -----------------------------------------------------

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
      final ResponseModel response = await _repo.getHotelPropertyPhotosRepo();
      if (!response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      final res = HotelPropertyPhotoResModel.fromJson(response.response?.data);
      for (final photo in res.data ?? const <HotelPropertyPhotoData>[]) {
        if (photo.imageReferences?.isNotEmpty ?? false) {
          propertyPhotosList.add(photo);
        }
      }
    } catch (e) {
      logs("PropertyPhotoController.fetchPhotos ERROR $e");
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

  /// Uploads every picked file to S3 then posts the resulting URLs under
  /// [selectedCategory]. Clears the form on success.
  Future<void> buildRequestBody() async {
    try {
      isSaving.value = true;
      final urls = await _uploadAll(selectedImages);

      if (urls.isEmpty) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      final ResponseModel response = await _repo.addHotelPropertyPhotosRepo(reqBody: {
        "category": selectedCategory.value,
        "images": urls,
      });

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        clearSelection();
        await fetchPhotos();
        _refreshHotelHome();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("PropertyPhotoController.buildRequestBody ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  /// Removes a single image reference from a category album.
  ///
  /// Named `deleteHotelRoomController` for backwards compatibility with
  /// existing view callers; it actually deletes a property photo.
  Future<void> deleteHotelRoomController({
    required String categoryType,
    required String imgUrl,
  }) async {
    try {
      final ResponseModel response = await _repo.deleteHotelPropertyPhotosRepo(
        reqBody: {"category": categoryType, "imageReferences": imgUrl},
      );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message'] ?? AppStrings.successful);
        await fetchPhotos();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("PropertyPhotoController.deleteHotelRoomController ERROR $e");
    }
  }

  void clearSelection() {
    selectedImages.clear();
    selectedCategory.value = "";
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

  void _refreshHotelHome() {
    try {
      Get.find<HotelDetailController>().loadHotelData();
    } catch (_) {}
  }
}
