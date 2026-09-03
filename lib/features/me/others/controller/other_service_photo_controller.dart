
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/gallery_upload_guard.dart';
import 'package:BlueEra/core/services/other_profile_dirty.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:get/get.dart';

class OtherServicePhotoPhotoController extends GetxController
    with GalleryUploadGuard {
  // Use RxList to store your JSON data
  var propertyPhotosList = <OtherServiceGalleryData>[].obs;
  var isLoading = true.obs;
  final OtherRepo _repo = OtherRepo();


  /// Loads the gallery albums — EVERY album the server returned, unfiltered.
  ///
  /// The list is swapped in ONE assignment once the response lands, rather than
  /// cleared up front and refilled. This method runs on first open (where
  /// [isLoading] is still true and the screen shows its shimmer) but ALSO after
  /// an upload and after a delete, where `isLoading` is already false — and
  /// there the old clear-then-await emptied the list for the length of a round
  /// trip, so the merchant watched their gallery blink to "nothing" and back.
  /// The global progress dialog used to cover that; it no longer runs here
  /// (`showProgress: false` on the repo call), which is what made it visible.
  ///
  /// ## Why nothing is filtered out here any more
  ///
  /// This list does TWO jobs: it draws the album cards, and it is the only
  /// source of [existingCategories] — there is no categories endpoint, so a
  /// category exists only because an album carries that `title`.
  ///
  /// It used to drop albums whose `imageUrls` was empty, which is right for the
  /// cards (no thumbnail, reads as broken) and wrong for the categories. A
  /// merchant who deleted the last photo out of "Reception" lost the category
  /// too: the chip disappeared from the upload form and they had to retype the
  /// name, where one typo ("reception", "Reception ") makes a second album that
  /// reads identically to the first.
  ///
  /// So the filter moved to where it belongs — [albumsWithPhotos], read by the
  /// card list — and the categories keep seeing every album.
  Future<void> fetchPhotos() async {
    final ResponseModel response = await _repo.getOtherServicePhotosRepo();

    if (response.isSuccess) {
      final model =
          OtherServiceGalleryResModel.fromJson(response.response?.data);
      propertyPhotosList.assignAll(model.data ?? const []);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    isLoading.value = false;
  }

  /// The albums that actually have something to show, for the card list.
  ///
  /// An album with no images has no thumbnail and renders as a broken card, so
  /// the gallery screen skips it — but it keeps its category (see
  /// [fetchPhotos]), so the merchant can still file new photos under that name.
  List<OtherServiceGalleryData> get albumsWithPhotos => [
        for (final album in propertyPhotosList)
          if (album.imageUrls?.isNotEmpty ?? false) album,
      ];

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

  /// Generic sections every physical business has, offered as a STARTING
  /// POINT so a merchant with an empty gallery isn't handed a blank text
  /// field and asked to invent a taxonomy.
  ///
  /// These are suggestions, not a fixed catalogue. The API still stores a free
  /// `title` per album, so tapping one just pre-fills that name and the "Other"
  /// chip is always there to type something else. Nothing here is sent to the
  /// server unless the merchant actually picks it.
  ///
  /// Deliberately business-AGNOSTIC. The fifteen hotel sections this screen
  /// inherited ("Swimming Pool", "Spa & Wellness") were removed because they
  /// described one vertical; these describe the parts of a shop, a garage, a
  /// salon or a coaching centre equally.
  static const List<String> _suggestedCategoryKeys = [
    AppStrings.otherGalleryCategoryExterior,
    AppStrings.otherGalleryCategoryInterior,
    AppStrings.reception,
    AppStrings.staff,
    AppStrings.services,
    AppStrings.products,
    AppStrings.awards,
  ];

  /// [_suggestedCategoryKeys] resolved through the current locale. A getter,
  /// not a stored list, so a language change is picked up on the next build.
  List<String> get suggestedCategories =>
      [for (final key in _suggestedCategoryKeys) key.tr];

  /// What the upload form actually offers as chips: the merchant's OWN
  /// categories first — those are real albums and matter more — then any
  /// suggestion they haven't already used, de-duplicated case-insensitively so
  /// a merchant who made "Reception" doesn't see it twice.
  List<String> get categoryOptions {
    final seen = <String>{};
    final result = <String>[];
    for (final category in [...existingCategories, ...suggestedCategories]) {
      final title = category.trim();
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
    // Drop the uploaded-url cache with the rest of the form, so re-picking the
    // same file for a NEW album uploads it under that album rather than
    // reusing the previous one's url.
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
  /// The gallery picker is handed [remainingImageSlots] so it can stop the
  /// merchant at selection time, but two paths still arrive over the line: the
  /// CAMERA path takes an unbounded burst, and the merchant can come back and
  /// add to a selection that is already part-full. So the ceiling is re-checked
  /// here against what is already held.
  ///
  /// When something is dropped the merchant is told exactly WHAT — how many
  /// went in, how many did not, and what the cap is. It used to answer any
  /// overflow with a flat "You can upload a maximum of 6 images", which is
  /// actively misleading when the real reason is that only two slots were left:
  /// the merchant reads "6", counts five on screen, and cannot see what went
  /// wrong.
  void addImages(List<String> paths) {
    if (paths.isEmpty) return;
    final room = remainingImageSlots;
    if (room <= 0) {
      commonSnackBar(
        message: AppStrings.otherGalleryPhotosFullFmt
            .trParams({'max': '$maxImages'}),
      );
      return;
    }

    final accepted = paths.take(room).toList();
    selectedImages.addAll(accepted);

    final skipped = paths.length - accepted.length;
    if (skipped > 0) {
      commonSnackBar(
        message: AppStrings.otherGalleryPhotosSkippedFmt.trParams({
          'added': '${accepted.length}',
          'skipped': '$skipped',
          'max': '$maxImages',
        }),
      );
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  /// Uploads the picked files and registers them as ONE album.
  ///
  /// Wrapped in [guardGalleryUpload] and driven by [uploadGalleryFilesOnce], so
  /// a repeated Submit can neither re-upload a file nor fire a second POST. See
  /// [GalleryUploadGuard] for what went wrong without those two.
  ///
  /// The url list is a LOCAL, built fresh per run and handed straight to the
  /// request. It used to be a field that each run cleared and refilled, which
  /// is what let concurrent runs post each other's half-finished lists.
  Future<void> buildRequestBody() async {
    await guardGalleryUpload(() async {
      // Owned here rather than by the caller: the submit button reads this to
      // disable itself, so it has to be set before the first await.
      isLoading.value = true;
      try {
        final urls = await uploadGalleryFilesOnce(selectedImages);
        if (urls.isEmpty) {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          return;
        }

        final ResponseModel response =
            await _repo.addOtherServicePhotosRepo(reqBody: {
          // Trimmed so "Reception" and "Reception " don't become two categories
          // that read identically in the list.
          "title": selectedCategory.value.trim(),
          "imageUrls": urls,
        });

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
      } on Exception catch (e) {
        logs('OtherServicePhotoPhotoController.buildRequestBody ERROR $e');
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
