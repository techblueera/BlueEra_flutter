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

  /// The album categories THIS lab has actually created, in the order the API
  /// returned them, de-duplicated case-insensitively.
  ///
  /// This replaces a fixed twelve-entry list that still carried the hotel
  /// sections it was derived from — "Lobby & Reception", "Rooms",
  /// "Bathrooms", "Conference & Meeting Rooms" — none of which describe a
  /// diagnostic lab. There is no server-side catalog of album categories to
  /// swap it for: the gallery API stores a free `title` per album. So the
  /// categories ARE the ones the lab has made, offered back as suggestions,
  /// and a new one is created simply by typing it. See [selectedCategory].
  List<String> get existingCategories {
    final seen = <String>{};
    final result = <String>[];
    for (final photo in propertyPhotosList) {
      final title = photo.title?.trim() ?? '';
      if (title.isEmpty) continue;
      if (!seen.add(title.toLowerCase())) continue;
      result.add(title);
    }
    return result;
  }

  /// Max picks before [addImage] starts rejecting.
  static const int _maxImagesPerUpload = 6;

  // ---- Upload-form state ----------------------------------------------------

  /// The album this upload will be filed under — either picked from
  /// [existingCategories] or typed fresh. Free text, because that is exactly
  /// what the API's `title` is.
  final RxString selectedCategory = "".obs;
  final RxList<String> selectedImages = <String>[].obs;

  /// True while the "Other" option is chosen — the lab is naming an album of
  /// its own rather than filing under one it already has.
  ///
  /// Tracked separately from [selectedCategory] because the two mean different
  /// things while the name is still being typed: "Other is chosen but nothing
  /// entered yet" has to keep the text field on screen, and an empty
  /// [selectedCategory] alone can't say that.
  final RxBool isCustomCategory = false.obs;

  /// Whether the upload form is complete enough to submit. `trim` so an album
  /// name of nothing but spaces doesn't pass.
  bool get canSubmitUpload =>
      selectedCategory.value.trim().isNotEmpty && selectedImages.isNotEmpty;

  /// Cap on one upload, and how many more photos it can still take.
  int get maxImages => _maxImagesPerUpload;

  int get remainingImageSlots => _maxImagesPerUpload - selectedImages.length;

  /// Files this upload under one of [existingCategories].
  void selectExistingCategory(String category) {
    isCustomCategory.value = false;
    selectedCategory.value = category;
  }

  /// Switches to the "Other" option: clears whatever existing album was
  /// selected and hands the naming over to the text field.
  void chooseCustomCategory() {
    isCustomCategory.value = true;
    selectedCategory.value = '';
  }

  /// Clears the upload form, so a cancelled attempt doesn't leak into the
  /// next one — this controller outlives the upload screen.
  void resetUploadForm() {
    selectedCategory.value = '';
    isCustomCategory.value = false;
    selectedImages.clear();
  }

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
    selectedCategory.value = value ?? '';
  }

  void addImage(String path) {
    if (selectedImages.length >= _maxImagesPerUpload) {
      commonSnackBar(message: AppStrings.hotelLimitReached6Images.tr);
      return;
    }
    selectedImages.add(path);
  }

  /// Appends a batch from the multi-picker, keeping the total at or under
  /// [_maxImagesPerUpload].
  ///
  /// The picker is already told the cap, but it only knows how many were
  /// picked in THAT pass — the lab can come back and add more to a selection
  /// that is already part-full, so the ceiling is re-checked here against what
  /// is already held. Anything over the line is dropped with one snackbar
  /// rather than one per file.
  void addImages(List<String> paths) {
    if (paths.isEmpty) return;
    final room = remainingImageSlots;
    if (room <= 0) {
      commonSnackBar(message: AppStrings.hotelLimitReached6Images.tr);
      return;
    }
    selectedImages.addAll(paths.take(room));
    if (paths.length > room) {
      commonSnackBar(message: AppStrings.hotelLimitReached6Images.tr);
    }
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
        // Trimmed so "Sample Collection" and "Sample Collection " don't become
        // two albums that read identically in the list.
        "title": selectedCategory.value.trim(),
        "imageUrls": urls,
      });

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        // Also clears `isCustomCategory`, which the inline pair above didn't
        // know about — otherwise the next upload would open on the "Other"
        // branch left over from this one.
        resetUploadForm();
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
