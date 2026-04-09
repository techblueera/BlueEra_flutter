import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_property_photo_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class PropertyPhotoController extends GetxController {
  // Use RxList to store your JSON data
  var propertyPhotosList = <HotelPropertyPhotoData>[].obs;
  var isLoading = true.obs;

  Future<void> fetchPhotos() async {
    propertyPhotosList.clear();

    ResponseModel response =
        await HotelServiceRepo().getHotelPropertyPhotosRepo();

    if (response.isSuccess) {
      HotelPropertyPhotoResModel hotelPropertyPhotoResModel =
          HotelPropertyPhotoResModel.fromJson(response.response?.data);

      if ((hotelPropertyPhotoResModel.data?.isNotEmpty ?? false)) {
        for (var photo in hotelPropertyPhotoResModel.data ?? []) {
          if (photo.imageReferences != null &&
              photo.imageReferences!.isNotEmpty) {
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

  var categoryImages = <String, RxList<String>>{}.obs;

  final int maxImages = 6;
  final int minImages = 1;

  // Categories from your image
  final List<String> categories = [
    "External View & Parking",
    "Lobby & Garden",
    "Rooms",
    "Restaurant & Bar",
    "Gym & Swimming Pool"
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
      for (var filePath in selectedImages) {
        UploadResult? result = await S3UploadService.uploadFile(File(filePath));
        if (result.isSuccess) {
          urlList.add(result.url);
        }
      }

      var requestBody = {
        "category": selectedCategory.value,
        "images": urlList,
      };

      ResponseModel response = await HotelServiceRepo()
          .addHotelPropertyPhotosRepo(reqBody: requestBody);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        fetchPhotos();
        try {
          Get.find<HotelDetailController>().loadHotelData();
        } catch (_) {}
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
    required String categoryType,
    required String imgUrl,
  }) async {
    try {
      ResponseModel response = await HotelServiceRepo()
          .deleteHotelPropertyPhotosRepo(
              reqBODY: {"category": categoryType, "imageReferences": imgUrl});

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
