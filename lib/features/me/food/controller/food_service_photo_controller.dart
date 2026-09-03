import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

class FoodServicePhotoPhotoController extends GetxController {
  // Use RxList to store your JSON data
  var propertyPhotosList = <OtherServiceGalleryData>[].obs;
  var isLoading = true.obs;
  final FoodRepo _repo = FoodRepo();

  Future<void> fetchPhotos() async {
    propertyPhotosList.clear();

    ResponseModel response = await _repo.getFoodServicePhotosRepo();

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

  /// The gallery categories THIS restaurant has actually created, in the order
  /// the API returned them, de-duplicated case-insensitively.
  ///
  /// This replaces a fixed twenty-entry list. Unlike the hotel taxonomy the
  /// other galleries inherited, that list was at least food-shaped — but it
  /// was still somebody else's idea of how a kitchen photographs itself, it
  /// could not be added to, and it trailed off into the hotel entries it was
  /// derived from ("Lobby & Reception", "Washrooms & Restrooms"). There is no
  /// server-side catalog of sections to swap it for: the gallery API stores a
  /// free `title` per group. So the categories ARE the ones the restaurant has
  /// made, offered back as suggestions, with an "Other" option for the next
  /// one. See [selectedCategory].
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

  /// True while the "Other" option is chosen — the restaurant is naming a
  /// category of its own rather than filing under one it already has.
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

  /// Clears the upload form, so a cancelled attempt doesn't leak into the next
  /// one — this controller outlives the upload screen.
  void resetUploadForm() {
    selectedCategory.value = '';
    isCustomCategory.value = false;
    selectedImages.clear();
  }

  void addImage(String path) {
    if (selectedImages.length < maxImages) {
      selectedImages.add(path);
    } else {
      commonSnackBar(message: AppStrings.foodPhotoLimitReached.tr);
    }
  }

  /// Appends a batch from the multi-picker, keeping the total at or under
  /// [maxImages].
  ///
  /// The picker is already told the cap, but it only knows how many were
  /// picked in THAT pass — the restaurant can come back and add more to a
  /// selection that is already part-full, so the ceiling is re-checked here
  /// against what is already held. Anything over the line is dropped with one
  /// snackbar rather than one per file.
  void addImages(List<String> paths) {
    if (paths.isEmpty) return;
    final room = remainingImageSlots;
    if (room <= 0) {
      commonSnackBar(message: AppStrings.foodPhotoLimitReached.tr);
      return;
    }
    selectedImages.addAll(paths.take(room));
    if (paths.length > room) {
      commonSnackBar(message: AppStrings.foodPhotoLimitReached.tr);
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  // Logic to build the JSON request body

  Future buildRequestBody() async {
    AppLoader.show();
    try {
      List<String> urlList = [];
      for (var filePath in selectedImages) {
        UploadResult? result = await S3UploadService.uploadFile(File(filePath));
        if (result.isSuccess) {
          urlList.add(result.url);
        }
      }

      var requestBody = {
        // Trimmed so "Desserts" and "Desserts " don't become two categories
        // that read identically in the list.
        "title": selectedCategory.value.trim(),
        "imageUrls": urlList,
        ApiKeys.businessId: businessId,
      };

      ResponseModel response =
          await _repo.addFoodServicePhotosRepo(reqBody: requestBody);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        resetUploadForm();
        fetchPhotos();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      AppLoader.hide();
      isLoading.value = false;
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteOtherServiceController({
    required String imgId,
    required String imgUrl,
  }) async {
    AppLoader.show();
    try {
      ResponseModel response = await _repo.deleteFoodServicePhotosRepo(
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
    } finally {
      AppLoader.hide();
    }
  }
}
