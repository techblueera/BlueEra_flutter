import 'dart:io';
import 'dart:math';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professonals_gallery_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/repo/professionals_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class ProfessionalsServicePhotoPhotoController extends GetxController {
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
      commonSnackBar(message:"Limit Reached You can upload a maximum of 6 images.");
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  // Logic to build the JSON request body

  Future buildRequestBody() async {
    try {
      List<String> urlList = [];

      Get.back();
      for (var filePath in selectedImages) {
        String mimeType = getMimeType(filePath);
        urlList.add(mimeType);
      }

      var requestBody = {
        "contentTypes": urlList,
      };

      ResponseModel response =
          await _repo.addProfessionalsServicePhotosRepo(reqBody: requestBody);
      // 1. Extract the list safely
      List<dynamic> urls = response.response?.data['uploadUrls'] ?? [];

// 2. Determine how many uploads we can actually perform
// This prevents the RangeError if URL count != Image count
      int uploadCount = min(urls.length, selectedImages.length);

      final uploadTasks = Iterable<int>.generate(uploadCount).map((index) async {
        String url = urls[index];

        // Now this is safe because index < selectedImages.length
        File fileUp = File(selectedImages[index]);

        print("Uploading file ${index + 1} of $uploadCount...");

        ResponseModel? uploadResponse = await ChannelRepo().uploadVideoToS3(
          file: fileUp,
          fileType: "image/png",
          preSignedUrl: url,
          onProgress: (sent) => print("Uploading file $index: $sent%"),
        );

        return uploadResponse?.statusCode == 200;
      });

      List<bool> results = await Future.wait(uploadTasks);
      // List<dynamic> urls = response.response?.data['uploadUrls'];
      // // Map each URL to an upload task
      // final uploadTasks = urls.asMap().entries.map((entry) async {
      //   int index = entry.key;
      //   String url = entry.value;
      //   File fileUp = File(selectedImages[index]);
      //
      //   print("Uploading file ${index + 1}...");
      //   ResponseModel? uploadResponse = await ChannelRepo().uploadVideoToS3(
      //     file: fileUp,
      //     fileType: "image/png",
      //     preSignedUrl: url,
      //     onProgress: (sent) => print("Uploading: $sent"),
      //   );
      //
      //   return uploadResponse?.statusCode == 200;
      // });
      //
      // // Execute all uploads in parallel
      // List<bool> results = await Future.wait(uploadTasks);
      //
      if (results.every((success) => success)) {
        print("All photos uploaded successfully!");
        commonSnackBar(message: "All photos uploaded successfully!");
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
