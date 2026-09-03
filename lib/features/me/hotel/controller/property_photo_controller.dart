
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_property_photo_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/gallery_upload_guard.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Drives the property-photos screen: lists existing albums per category,
/// and handles the multi-image upload flow that batches local files through
/// S3 then registers them under a category.
class PropertyPhotoController extends GetxController
    with GalleryUploadGuard {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// Existing albums returned by the API.
  final RxList<HotelPropertyPhotoData> propertyPhotosList = <HotelPropertyPhotoData>[].obs;

  /// The album categories THIS hotel has actually created, in the order the
  /// API returned them, de-duplicated case-insensitively.
  ///
  /// This replaces a fixed five-entry list ("External View & Parking", "Lobby
  /// & Garden", "Rooms", "Restaurant & Bar", "Gym & Swimming Pool") — the
  /// original that every other gallery in the app was copied from. Those five
  /// are right for a hotel, but no hotel could add a sixth, and the list
  /// carried a data bug: the entries were `.tr` lookups, so the string POSTed
  /// as `category` was whatever the device language rendered. A Hindi phone
  /// filed its rooms under a Hindi category and an English one under "Rooms",
  /// so the same floor became two albums, and deletes — which match on that
  /// same string — only ever found the half that matched the current locale.
  ///
  /// The retired `categoryLabel()` was meant to guard that, but it switched on
  /// the ENGLISH literals while the list it was fed had already been
  /// translated: on any non-English locale nothing matched and it returned its
  /// argument unchanged, which is exactly what it would have returned anyway.
  /// Its own doc claimed the entries were "kept in English so the API contract
  /// is stable across languages" — the code had not done that for some time.
  ///
  /// Names are now entered by the hotel and stored verbatim, so what is sent,
  /// shown and deleted are the same string in every locale.
  List<String> get existingCategories {
    final seen = <String>{};
    final result = <String>[];
    for (final photo in propertyPhotosList) {
      final title = photo.category?.trim() ?? '';
      if (title.isEmpty) continue;
      if (!seen.add(title.toLowerCase())) continue;
      result.add(title);
    }
    return result;
  }

  /// Max picks before [addImage] starts rejecting.
  static const int _maxImagesPerUpload = 6;

  /// Cap on one upload, and how many more photos it can still take.
  int get maxImages => _maxImagesPerUpload;

  int get remainingImageSlots => _maxImagesPerUpload - selectedImages.length;

  // ---- Upload-form state -----------------------------------------------------

  /// The album this upload will be filed under — either picked from
  /// [existingCategories] or typed fresh.
  final RxString selectedCategory = "".obs;
  final RxList<String> selectedImages = <String>[].obs;

  /// True while the "Other" option is chosen — the hotel is naming an album of
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
  /// picked in THAT pass — the hotel can come back and add more to a selection
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

  /// Uploads every picked file to S3 then posts the resulting URLs under
  /// [selectedCategory]. Clears the form on success.
  /// Guarded so a repeated Submit can't start a second concurrent run — see
  /// [GalleryUploadGuard].
  Future<void> buildRequestBody() async {
    await guardGalleryUpload(() => _submitGallery());
  }

  Future<void> _submitGallery() async {
    try {
      isSaving.value = true;
      final urls = await uploadGalleryFilesOnce(selectedImages);

      if (urls.isEmpty) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      final ResponseModel response = await _repo.addHotelPropertyPhotosRepo(reqBody: {
        // Trimmed so "Rooms" and "Rooms " don't become two albums that read
        // identically in the list — and, since deletes match on this same
        // string, two albums only one of which a delete can find.
        "category": selectedCategory.value.trim(),
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
    // Also cleared, or the next upload would open on the "Other" branch left
    // over from this one.
    isCustomCategory.value = false;
  }

  void _refreshHotelHome() {
    try {
      Get.find<HotelDetailController>().loadHotelData();
    } catch (_) {}
  }
}
