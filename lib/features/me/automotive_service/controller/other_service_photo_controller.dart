
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/gallery_upload_guard.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:get/get.dart';

class AutomotiveServicePhotoController extends GetxController
    with GalleryUploadGuard {
  // Use RxList to store your JSON data
  var propertyPhotosList = <OtherServiceGalleryData>[].obs;
  var isLoading = true.obs;
  final OtherRepo _repo = OtherRepo();

  Future<void> fetchPhotos() async {
    propertyPhotosList.clear();

    ResponseModel response = await _repo.getOtherServicePhotosRepo();

    if (response.isSuccess) {
      OtherServiceGalleryResModel hotelPropertyPhotoResModel =
          OtherServiceGalleryResModel.fromJson(response.response?.data);

      if ((hotelPropertyPhotoResModel.data?.isNotEmpty ?? false)) {
        for (var photo in hotelPropertyPhotoResModel.data ?? []) {
          if (photo.imageUrls != null && photo.imageUrls!.isNotEmpty) {
            propertyPhotosList.add(photo);
          }
        }
        // propertyPhotosList.addAll(hotelPropertyPhotoResModel.data ?? []);
      }
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    // propertyPhotos.assignAll(responseData);
    isLoading.value = false;
  }

  final int maxImages = 6;
  final int minImages = 1;

  /// The gallery categories THIS workshop has actually created, in the order
  /// the API returned them, de-duplicated case-insensitively.
  ///
  /// This replaces a hard-coded list of fifteen hotel sections ("Lobby &
  /// Reception", "Swimming Pool", "Spa & Wellness", …) that arrived with the
  /// hotel gallery this screen was copied from — a taxonomy with nothing to
  /// say about a garage or a service centre. There is no server-side catalog
  /// of sections to swap it for: the gallery API stores a free `title` per
  /// group. So the categories ARE the ones the merchant has made, offered
  /// back as suggestions, and a new one is created simply by typing it. See
  /// [selectedCategory].
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

  @override
  void onInit() {
    super.onInit();
    fetchPhotos();
  }

  /// The category this upload will be filed under — either picked from
  /// [existingCategories] or typed fresh. Free text, because that is exactly
  /// what the API's `title` is.
  var selectedCategory = "".obs;

  // Observable list for image paths (max 6)
  var selectedImages = <String>[].obs;

  /// True while the "Other" option is chosen — the merchant is naming a
  /// category of their own rather than filing under one they already have.
  ///
  /// Tracked separately from [selectedCategory] because the two mean different
  /// things while the name is still being typed: "Other is chosen but nothing
  /// entered yet" has to keep the text field on screen, and an empty
  /// [selectedCategory] alone can't say that.
  var isCustomCategory = false.obs;

  /// Whether the upload form is complete enough to submit. `trim` so a
  /// category of nothing but spaces doesn't pass.
  bool get canSubmitUpload =>
      selectedCategory.value.trim().isNotEmpty && selectedImages.isNotEmpty;

  /// How many more photos this upload can take.
  int get remainingImageSlots => maxImages - selectedImages.length;

  /// Files this category under one of [existingCategories].
  void selectExistingCategory(String category) {
    isCustomCategory.value = false;
    selectedCategory.value = category;
  }

  /// Switches to the "Other" option: clears whatever existing category was
  /// selected and hands the naming over to the text field.
  void chooseCustomCategory() {
    isCustomCategory.value = true;
    selectedCategory.value = '';
  }

  void onCategoryChanged(String? value) {
    selectedCategory.value = value ?? '';
  }

  /// Clears the upload form. Called after a successful upload so re-opening
  /// the screen starts blank instead of showing the previous submission —
  /// this controller outlives the upload screen.
  void resetUploadForm() {
    selectedCategory.value = '';
    isCustomCategory.value = false;
    selectedImages.clear();
    clearGalleryUploadCache();
  }

  void addImage(String path) {
    if (selectedImages.length < maxImages) {
      selectedImages.add(path);
    } else {
      commonSnackBar(message: AppStrings.hotelLimitReached6Images.tr);
    }
  }

  /// Appends a batch from the multi-picker, keeping the total at or under
  /// [maxImages].
  ///
  /// The picker is already told the cap, but it only knows how many were
  /// picked in THAT pass — the merchant can come back and add more to a
  /// selection that is already part-full, so the ceiling is re-checked here
  /// against what is already held. Anything over the line is dropped with one
  /// snackbar rather than one per file.
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

  /// Uploads the picked files and registers them as ONE album.
  ///
  /// Same guard as the `me/others` fork this module was copied from — see
  /// [GalleryUploadGuard]. Both post to `/other-service/gallery`, so both had
  /// the duplicate-upload bug.
  Future<void> buildRequestBody() async {
    await guardGalleryUpload(() async {
      isLoading.value = true;
      try {
        final urls = await uploadGalleryFilesOnce(selectedImages);
        if (urls.isEmpty) {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          return;
        }

        final ResponseModel response =
            await _repo.addOtherServicePhotosRepo(reqBody: {
          // Trimmed so "Bay 1" and "Bay 1 " don't become two categories that
          // read identically in the list.
          "title": selectedCategory.value.trim(),
          "imageUrls": urls,
        });

        if (response.isSuccess) {
          Get.back();
          commonSnackBar(message: response.response?.data['message']);
          resetUploadForm();
          fetchPhotos();
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      } on Exception catch (e) {
        logs('AutomotiveServicePhotoController.buildRequestBody ERROR $e');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        isLoading.value = false;
      }
    });
  }

  ///DELETE NOTICE....
  Future<void> deleteOtherServiceController({
    required String imgId,
    required String imgUrl,
  }) async {
    try {
      ResponseModel response = await _repo.deleteOtherServicePhotosRepo(
          imgID: imgId, reqBody: {"imageUrl": imgUrl});

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        fetchPhotos();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }
}
