import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/other_profile_dirty.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class OtherServicePhotoPhotoController extends GetxController {
  // Use RxList to store your JSON data
  var propertyPhotosList = <OtherServiceGalleryData>[].obs;
  var isLoading = true.obs;
  final OtherRepo _repo = OtherRepo();


  /// Loads the gallery groups.
  ///
  /// The list is swapped in ONE assignment once the response lands, rather than
  /// cleared up front and refilled. This method runs on first open (where
  /// [isLoading] is still true and the screen shows its shimmer) but ALSO after
  /// an upload and after a delete, where `isLoading` is already false — and
  /// there the old clear-then-await emptied the list for the length of a round
  /// trip, so the merchant watched their gallery blink to "nothing" and back.
  /// The global progress dialog used to cover that; it no longer runs here
  /// (`showProgress: false` on the repo call), which is what made it visible.
  Future<void> fetchPhotos() async {
    final ResponseModel response = await _repo.getOtherServicePhotosRepo();

    if (response.isSuccess) {
      final model =
          OtherServiceGalleryResModel.fromJson(response.response?.data);
      // Groups with no images are dropped — an empty group has nothing to
      // show as its thumbnail and reads as a broken card.
      final fresh = <OtherServiceGalleryData>[
        for (final photo in model.data ?? const [])
          if (photo.imageUrls?.isNotEmpty ?? false) photo,
      ];
      propertyPhotosList.assignAll(fresh);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    isLoading.value = false;
  }

  final int maxImages = 6;
  final int minImages = 1;

  /// The gallery categories THIS business has actually created, in the order
  /// the API returned them, de-duplicated case-insensitively.
  ///
  /// This replaces a hard-coded list of fifteen hotel sections ("Lobby &
  /// Reception", "Swimming Pool", "Spa & Wellness", …) that was copied in from
  /// the hotel gallery. "Other service" is every business that isn't one of
  /// the modelled verticals — a gym, a salon, a workshop, a coaching centre —
  /// so a fixed hotel taxonomy was wrong for essentially all of them, and
  /// there is no server-side catalog of sections to swap it for: the gallery
  /// API stores a free `title` per group. So the categories ARE the ones the
  /// merchant has made, offered back as suggestions, and a new one is created
  /// simply by typing it. See [selectedCategory].
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
    urlList.clear();
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

  // Logic to build the JSON request body
  List<String> urlList = [];

  Future buildRequestBody() async {
    try {
      // Start from empty: `urlList` is a field, so without this a second
      // upload in the same session re-sent the FIRST upload's S3 urls along
      // with its own, filing those images under both categories.
      urlList.clear();
      for (var filePath in selectedImages) {
        UploadResult? result = await S3UploadService.uploadFile(File(filePath));
        if (result.isSuccess) {
          urlList.add(result.url);
        }
      }

      var requestBody = {
        // Trimmed so "Reception" and "Reception " don't become two categories
        // that read identically in the list.
        "title": selectedCategory.value.trim(),
        "imageUrls": urlList,
      };

      ResponseModel response =
          await _repo.addOtherServicePhotosRepo(reqBody: requestBody);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        resetUploadForm();
        // The Overview tab's gallery card is now stale — see
        // [OtherProfileDirty].
        OtherProfileDirty.mark(OtherProfileSection.gallery);
        fetchPhotos();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      // 5. Always hide loader at the end
      isLoading.value = false;
    }
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
        OtherProfileDirty.mark(OtherProfileSection.gallery);
        fetchPhotos();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }
}
