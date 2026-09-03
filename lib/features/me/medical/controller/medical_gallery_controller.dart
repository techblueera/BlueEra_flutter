import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class MedicalGalleryController extends GetxController {
  var galleryList = <OtherServiceGalleryData>[].obs;
  var isLoading = true.obs;
  var isUploading = false.obs;

  /// The gallery categories THIS pharmacy has actually created, in the order
  /// the API returned them, de-duplicated case-insensitively.
  ///
  /// This replaces a fixed six-entry list. Those entries were at least
  /// medically sensible (unlike the hotel taxonomy the sibling galleries
  /// inherited), but they carried a data problem the others didn't: they were
  /// `AppStrings.medicalGallery*.tr`, so the string POSTed as the album
  /// `title` was whatever the device language rendered. A Hindi phone filed
  /// "उपकरण फ़ोटो" and an English one "Equipment Photos" — the same shelf,
  /// stored as two different albums, and neither readable to the other. They
  /// were also frozen at construction, since `.tr` in a field initializer is
  /// evaluated once rather than re-read on a locale change.
  ///
  /// Titles are now whatever the pharmacy typed, stored verbatim and shown
  /// back verbatim, with an "Other" option for the next one. There is no
  /// server-side catalog to swap the list for: the gallery API stores a free
  /// `title` per group. See [selectedCategory].
  List<String> get existingCategories {
    final seen = <String>{};
    final result = <String>[];
    for (final photo in galleryList) {
      final title = photo.title?.trim() ?? '';
      if (title.isEmpty) continue;
      if (!seen.add(title.toLowerCase())) continue;
      result.add(title);
    }
    return result;
  }

  /// The album this upload will be filed under — either picked from
  /// [existingCategories] or typed fresh. Free text, because that is exactly
  /// what the API's `title` is.
  var selectedCategory = ''.obs;
  var selectedImages = <String>[].obs;
  final int maxImages = 6;

  /// True while the "Other" option is chosen — the pharmacy is naming an album
  /// of its own rather than filing under one it already has.
  ///
  /// Tracked separately from [selectedCategory] because the two mean different
  /// things while the name is still being typed: "Other is chosen but nothing
  /// entered yet" has to keep the text field on screen, and an empty
  /// [selectedCategory] alone can't say that.
  var isCustomCategory = false.obs;

  /// Whether the upload form is complete enough to submit. `trim` so an album
  /// name of nothing but spaces doesn't pass.
  bool get canSubmitUpload =>
      selectedCategory.value.trim().isNotEmpty && selectedImages.isNotEmpty;

  /// How many more photos this upload can take.
  int get remainingImageSlots => maxImages - selectedImages.length;

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

  @override
  void onInit() {
    super.onInit();
    fetchGallery();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FETCH ALL GALLERY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchGallery() async {
    try {
      isLoading.value = true;
      galleryList.clear();

      ResponseModel response = await MedicalRepo().fetchMedicalGalleryRepo();

      if (response.isSuccess) {
        OtherServiceGalleryResModel model = OtherServiceGalleryResModel.fromJson(response.response?.data);
        if (model.data != null && model.data!.isNotEmpty) {
          for (var photo in model.data!) {
            if (photo.imageUrls != null && photo.imageUrls!.isNotEmpty) {
              galleryList.add(photo);
            }
          }
        }
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // IMAGE SELECTION
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void onCategoryChanged(String? value) {
    selectedCategory.value = value ?? '';
  }

  void addImage(String path) {
    if (selectedImages.length < maxImages) {
      selectedImages.add(path);
    } else {
      commonSnackBar(message: _limitReachedMessage);
    }
  }

  /// Appends a batch from the multi-picker, keeping the total at or under
  /// [maxImages].
  ///
  /// The picker is already told the cap, but it only knows how many were
  /// picked in THAT pass — the pharmacy can come back and add more to a
  /// selection that is already part-full, so the ceiling is re-checked here
  /// against what is already held. Anything over the line is dropped with one
  /// snackbar rather than one per file.
  void addImages(List<String> paths) {
    if (paths.isEmpty) return;
    final room = remainingImageSlots;
    if (room <= 0) {
      commonSnackBar(message: _limitReachedMessage);
      return;
    }
    selectedImages.addAll(paths.take(room));
    if (paths.length > room) {
      commonSnackBar(message: _limitReachedMessage);
    }
  }

  /// Read at call time, not at construction, so it follows a locale change.
  String get _limitReachedMessage =>
      '${AppStrings.medicalLimitReachedPrefix.tr} $maxImages '
      '${AppStrings.medicalLimitReachedSuffix.tr}';

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  void resetUploadForm() {
    selectedCategory.value = '';
    isCustomCategory.value = false;
    selectedImages.clear();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // UPLOAD â†’ S3 â†’ CREATE GALLERY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> uploadAndCreateGallery() async {
    if (selectedCategory.value.trim().isEmpty) {
      commonSnackBar(message: AppStrings.medicalPleaseSelectCategory.tr);
      return;
    }
    if (selectedImages.isEmpty) {
      commonSnackBar(message: AppStrings.medicalPleaseSelectAtLeastOneImage.tr);
      return;
    }

    try {
      isUploading.value = true;
      List<String> uploadedUrls = [];

      // Upload each image to S3
      for (var filePath in selectedImages) {
        UploadResult result = await S3UploadService.uploadFile(File(filePath));
        if (result.isSuccess) {
          uploadedUrls.add(result.url);
        } else {
          commonSnackBar(message: result.message);
          return;
        }
      }

      if (uploadedUrls.isEmpty) {
        commonSnackBar(message: AppStrings.medicalFailedToUploadImages.tr);
        return;
      }

      // POST to gallery API
      Map<String, dynamic> body = {
        // Trimmed so "Equipment" and "Equipment " don't become two albums that
        // read identically in the list.
        'title': selectedCategory.value.trim(),
        'imageUrls': uploadedUrls,
      };

      ResponseModel response = await MedicalRepo().createMedicalGalleryRepo(params: body);

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalGalleryUploadedSuccessfully.tr);
        resetUploadForm();
        Get.back();
        fetchGallery();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUploading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // DELETE GALLERY IMAGE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> deleteGalleryImage({
    required String galleryId,
    required String imageUrl,
  }) async {
    try {
      ResponseModel response = await MedicalRepo().deleteMedicalGalleryImageRepo(
        galleryId: galleryId,
        params: {'imageUrl': imageUrl},
      );

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalImageDeletedSuccessfully.tr);
        fetchGallery();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // DELETE ENTIRE GALLERY ENTRY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> deleteGalleryEntry({required String galleryId}) async {
    try {
      ResponseModel response = await MedicalRepo().deleteMedicalGalleryRepo(galleryId: galleryId);

      if (response.isSuccess) {
        galleryList.removeWhere((g) => g.id == galleryId);
        commonSnackBar(message: response.message ?? AppStrings.medicalGalleryDeleted.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
