import 'dart:io';
import 'dart:math';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/gallery_upload_guard.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professonals_gallery_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/repo/professionals_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class ProfessionalsServicePhotoPhotoController extends GetxController
    with GalleryUploadGuard {
  // Use RxList to store your JSON data
  var propertyPhotosList = <String>[].obs;
  var propertyPhotosIdsList = <String>[].obs;
  var isLoading = true.obs;
  final ProfessionalsRepo _repo = ProfessionalsRepo();

  Future<void> fetchPhotos() async {
    propertyPhotosList.clear();
    propertyPhotosIdsList.clear();

    ResponseModel response = await _repo.getProfessionalsServicePhotosRepo();

    if (response.isSuccess) {
      ProfessonalsGalleryResModel hotelPropertyPhotoResModel =
      ProfessonalsGalleryResModel.fromJson(response.response?.data);

      if ((hotelPropertyPhotoResModel.data?.signedUrls?.isNotEmpty ?? false)) {
        for (var photo in hotelPropertyPhotoResModel.data?.signedUrls?? []) {
          // if (photo != null && photo.imageUrls!.isNotEmpty) {
            propertyPhotosList.add(photo);
          // }
        }
        for (var photo in hotelPropertyPhotoResModel.data?.imageKeys?? []) {
          // if (photo != null && photo.imageUrls!.isNotEmpty) {
          propertyPhotosIdsList.add(photo);
          // }
        }
        // propertyPhotosList.addAll(hotelPropertyPhotoResModel.data ?? []);
      }
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    propertyPhotosList.refresh();
    propertyPhotosIdsList.refresh();
    // propertyPhotos.assignAll(responseData);
    isLoading.value = false;
  }

  final int maxImages = 6;
  final int minImages = 1;

  // Removed: a hard-coded list of fifteen HOTEL sections ("Lobby & Reception",
  // "Swimming Pool", "Spa & Wellness", …) that arrived with the hotel gallery
  // this module was copied from, plus the `categoryImages` map it populated.
  // Both were dead — this module's upload screen never read either one, and
  // nothing outside this file referenced them. The equivalent lists in the
  // other-service, automotive and laboratory galleries WERE live and are now
  // driven by the merchant's own album titles instead.

  @override
  void onInit() {
    super.onInit();
    fetchPhotos();
  }

  // Observable list for image paths (max 6)
  var selectedImages = <String>[].obs;



  void addImage(String path) {
    if (selectedImages.length < 6) {
      selectedImages.add(path);
    } else {
      commonSnackBar(message:"Limit reached. You can upload a maximum of 6 images.");
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  // Logic to build the JSON request body

  /// Uploads the picked photos through the PRESIGNED-URL flow: POST the list of
  /// content types, get one presigned S3 url back per file, then PUT each file
  /// to its own url.
  ///
  /// Guarded like the other gallery uploads ([GalleryUploadGuard]), for the
  /// same reason and with an extra one specific to this flow: every POST here
  /// MINTS A FRESH SET of presigned urls, so a second concurrent run doesn't
  /// just re-upload the files — it uploads them to a different set of S3 keys
  /// that the first run knows nothing about. The mixin's per-file url cache is
  /// deliberately NOT used, because the urls are server-issued per request and
  /// can't be reused across runs; the in-flight guard is what does the work.
  ///
  /// [GalleryUploadGuard.uploadGalleryFilesOnce] is bypassed here for the same
  /// reason — this flow never touches [S3UploadService].
  Future buildRequestBody() async {
    await guardGalleryUpload(() => _submitGallery());
  }

  Future<void> _submitGallery() async {
    // Set before the first await so the Submit button can disable itself for
    // the length of the upload — the same shape every other gallery module
    // uses, and the visible half of the double-submit guard.
    isLoading.value = true;
    try {
      // One entry per picked file, in the SAME order as [selectedImages] — the
      // upload loop below pairs `uploadUrls[i]` with `selectedImages[i]`, so
      // the content type for a file has to be found at its own index too.
      final contentTypes = [
        for (final filePath in selectedImages) getMimeType(filePath),
      ];

      final ResponseModel response =
          await _repo.addProfessionalsServicePhotosRepo(reqBody: {
        "contentTypes": contentTypes,
      });

      final List<dynamic> urls = response.response?.data['uploadUrls'] ?? [];
      // Never index past either list: the server can answer with a different
      // number of urls than files were sent.
      final int uploadCount = min(urls.length, selectedImages.length);
      if (uploadCount == 0) {
        // `<bool>[].every(...)` is TRUE, so without this an empty url list fell
        // straight through to the success branch and reported "All photos
        // uploaded successfully!" having uploaded nothing at all.
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      final List<bool> results = await Future.wait(
        Iterable<int>.generate(uploadCount).map((index) async {
          final ResponseModel? uploadResponse =
              await ChannelRepo().uploadVideoToS3(
            file: File(selectedImages[index]),
            // The file's OWN type, not a hardcoded "image/png". The server was
            // told the real content type in `contentTypes` above and minted the
            // presigned url against it, so sending a different one here either
            // fails the signature or — where the header isn't signed — stores a
            // JPEG in S3 labelled as a PNG.
            fileType: contentTypes[index],
            preSignedUrl: urls[index],
            onProgress: (sent) {},
          );
          return uploadResponse?.statusCode == 200;
        }),
      );

      if (results.every((success) => success)) {
        // Pop AFTER the work, like every other gallery module. This used to run
        // before the first request, which returned the merchant to the previous
        // screen instantly and then uploaded headless: no progress anywhere,
        // and both the success and failure snackbars landed on whatever screen
        // they had moved on to.
        Get.back();
        commonSnackBar(message: 'All photos uploaded successfully!');
        selectedImages.clear();
        fetchPhotos();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs('ProfessionalsServicePhotoPhotoController._submitGallery ERROR $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteOtherServiceController({
    required String imgId,
  }) async {
    try {
      ResponseModel response = await _repo.deleteProfessionalsServicePhotosRepo(
        imgID: imgId,
      );

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
