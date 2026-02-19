import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_gallery_res_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_gallery_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class HospitalPhotoController extends GetxController {
  // Use RxList to store your JSON data
  var propertyPhotosList = <HospitalGalleryData>[].obs;
  var isLoading = true.obs;

  Future<void> fetchPhotos() async {
    propertyPhotosList.clear();

    ResponseModel response =
        await HospitalGalleryRepo().getHospitalPropertyPhotosRepo();

    if (response.isSuccess) {
      HospitalGalleryResModel hotelPropertyPhotoResModel =
      HospitalGalleryResModel.fromJson(response.response?.data);

      if ((hotelPropertyPhotoResModel.data?.isNotEmpty ?? false)) {
        for (HospitalGalleryData photo in hotelPropertyPhotoResModel.data ?? []) {
          if (photo.images != null &&
             ( photo.images?.isNotEmpty??false)) {
            propertyPhotosList.add(photo);
          }
        }
      }
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    // propertyPhotos.assignAll(responseData);
    isLoading.value = false;
  }

  var categoryImages = <String, RxList<String>>{}.obs;

  final int maxImages = 6;
  final int minImages = 1;

  // Categories from your image

  List<String> categories = [
    "Reception & Lobby",
    "OPD Departments",      // For General Medicine, Orthopedics, etc.
    "IPD Wards",             // For General, Private, and Isolation Wards
    "Management Team",       // For Directors and Senior Staff
    "Diagnostic Services",   // For CT Scan, X-Ray, and Labs
    "Operation Theater",
    "Maternity & Pediatric", // Specifically for child-friendly areas
    "Pharmacy",
    "Exterior & Parking",
    "Others",

  ];
  @override
  void onInit() {
    super.onInit();
    fetchPhotos();

    // Initialize an empty observable list for each category
    for (var cat in categories) {
      categoryImages[cat] = <String>[].obs;
    }
  }

  // Observable for the selected category string
  var selectedCategory = "".obs;

  // Observable list for image paths (max 6)
  var selectedImages = <String>[].obs;

  void onCategoryChanged(String? value) {
    if (value != null) {
      selectedCategory.value = value;
    }
  }

  void addImage(String path) {
    if (selectedImages.length < 6) {
      selectedImages.add(path);
    } else {
      commonSnackBar(message: "Limit Reached You can upload a maximum of 6 images.");
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  // Logic to build the JSON request body
  List<String> urlList = [];

  Future buildRequestBody() async {
    try {
      for (var filePath in selectedImages) {
        UploadResult? result = await S3UploadService.uploadFile(File(filePath));
        if (result.isSuccess) {
          urlList.add(result.url);
        }
      }

      var requestBody = {
        "title": selectedCategory.value,
        "images": urlList,
        "hospitalId": hospitalIDGlobal,

      };

      ResponseModel response = await HospitalGalleryRepo()
          .addHospitalPropertyPhotosRepo(reqBody: requestBody);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: "Upload successfully");
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
  Future<void> deleteHotelRoomController({
    required String categoryId,
    required String imgUrl,
  }) async {
    try {
      ResponseModel response = await HospitalGalleryRepo()
          .deleteHospitalPropertyPhotosRepo(
              reqBODY: { "image": imgUrl},id: categoryId);

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
