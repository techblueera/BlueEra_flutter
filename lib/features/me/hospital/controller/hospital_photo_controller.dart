import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/gallery_upload_guard.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_gallery_res_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_gallery_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:get/get.dart';

class HospitalPhotoController extends GetxController
    with GalleryUploadGuard {
  final hospitalServiceController = Get.find<HospitalServiceAiController>();

  // Use RxList to store your JSON data
  var propertyPhotosList = <HospitalGalleryData>[].obs;
  var isLoading = true.obs;

  Future<void> fetchPhotos() async {
    propertyPhotosList.clear();

    final ResponseModel response =
        await HospitalGalleryRepo().getHospitalPropertyPhotosRepo();

    if (response.isSuccess) {
      final model = HospitalGalleryResModel.fromJson(response.response?.data);
      final withImages = (model.data ?? [])
          .where((photo) => photo.images?.isNotEmpty ?? false);
      propertyPhotosList.addAll(withImages);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
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
    if (selectedImages.length < maxImages) {
      selectedImages.add(path);
    } else {
      commonSnackBar(message: AppStrings.hospitalCtrlPhotoLimitReached.tr);
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }
  
  void clearUploadState() {
    selectedImages.clear();
    selectedCategory.value = "";
  }



  /// Guarded so a repeated Submit can't start a second concurrent run — each
  /// run re-uploaded every picked file, and [S3UploadService] mints a new key
  /// per call, so retries accumulate objects instead of overwriting. See
  /// [GalleryUploadGuard].
  ///
  /// The parallel `Future.wait` upload below is kept rather than moved to the
  /// mixin's sequential helper: this screen takes up to 20 photos and going
  /// sequential would make it markedly slower. The guard alone removes the
  /// duplicate-run problem, which is what was actually costing storage.
  Future<void> buildRequestBody() async {
    await guardGalleryUpload(() => _submitGallery());
  }

  Future<void> _submitGallery() async {
    try {
      isLoading.value = true;

      // Upload all picked files in parallel, then keep only successful URLs.
      final results = await Future.wait(
        selectedImages.map((p) => S3UploadService.uploadFile(File(p))),
      );
      final urlList = [
        for (final r in results)
          if (r.isSuccess) r.url,
      ];

      final requestBody = {
        "title": selectedCategory.value,
        "images": urlList,
        "hospitalId": hospitalIDGlobal,
      };

      final response = await HospitalGalleryRepo()
          .addHospitalPropertyPhotosRepo(reqBody: requestBody);

      if (response.isSuccess) {
        clearUploadState();
        Get.back();
        commonSnackBar(message: AppStrings.hospitalCtrlUploadSuccessfully.tr);
        fetchPhotos();
        hospitalServiceController.getHospitalFullDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a single image from a gallery category.
  /// (Method name kept for backwards compatibility with existing callers — the
  /// underlying repo is the hospital gallery, not a hotel room.)
  Future<void> deleteHotelRoomController({
    required String categoryId,
    required String imgUrl,
  }) async {
    try {
      final response = await HospitalGalleryRepo()
          .deleteHospitalPropertyPhotosRepo(
              reqBODY: {"image": imgUrl}, id: categoryId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        fetchPhotos();
        hospitalServiceController.getHospitalFullDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR $e");
    }
  }
}
