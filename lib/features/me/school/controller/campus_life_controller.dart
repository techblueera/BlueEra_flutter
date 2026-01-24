import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/campus_life_categories_res_model.dart';
import 'package:BlueEra/core/api/model/get_all_campus_life_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CampusLifeController extends GetxController {
  var categoryList = <CampusLifeCategoriesData>[].obs;
  var isLoading = false.obs;

  var isImageUpdated = false.obs;

  // Observables for the form
  var selectedCategoryId = "".obs;
  var selectedSubCategoryId = "".obs;
  var campusImages = <Map<String, String>>[].obs; // Stores {url, caption}
  var localImageFile = Rxn<File>();

  Rx<ApiResponse> getAllCampusCategoryResponse =
      ApiResponse.initial('Initial').obs;

  Rx<ApiResponse> getAllCampusLifeResponse = ApiResponse.initial('Initial').obs;

  @override
  void onInit() {
    fetchAllCampusCategories();
    fetchCampusDetailsController();
    super.onInit();
  }

  ///GET ALL CAMPUS CATEGORY...
  Future<void> fetchAllCampusCategories({bool isRefresh = false}) async {
    try {
      ResponseModel response = await SchoolRepo().campusLifeCategoriesRepo();

      if (response.isSuccess && response.response?.data != null) {
        CampusLifeCategoriesResModel? resModel =
            CampusLifeCategoriesResModel.fromJson(response.response?.data);
        categoryList.addAll(resModel.data ?? []);
        getAllCampusCategoryResponse.value = ApiResponse.complete(resModel);
      } else {
        getAllCampusCategoryResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getAllCampusCategoryResponse.value = ApiResponse.error(e.toString());
      commonSnackBar(message: "Error: $e");
    } finally {
      isLoading(false);
    }
  }

  ///CREATE CAMPUS LIFE...

  /// SUBMIT OR EDIT DATA
  Future<void> submitCampusData({
    bool isEdit = false,
    String? docId,
    String? caption,
  }) async {
    try {
      isLoading.value = true;

      List<Map<String, String>> uploadedImages = [];

      // 1. Handle Image Upload if a new file is selected
      // if (isImageUpdated.value && localImageFile.value != null) {
      // Upload each file to S3
      for (int i = 0; i < imageFiles.length; i++) {
        UploadResult? result = await S3UploadService.uploadFile(imageFiles[i]);
        if (result.isSuccess) {
          uploadedImages.add({
            "url": result.url,
            "caption": imageCaptions[i].text.isEmpty
                ? "Campus Image"
                : imageCaptions[i].text,
          });
        } else {
          commonSnackBar(message: "Image upload failed");
        }
      }
      // }

      // 2. Construct Request Body
      Map<String, dynamic> body = {
        "schoolId": schoolIDGlobal,
        "category": selectedCategory.value?.id,
        "subcategory": selectedSubCategory.value?.id,
        "images": uploadedImages
      };

      // 3. API Calling Logic
      ResponseModel response;
      if (isEdit) {
        response = await SchoolRepo().updateCampusCategoryLifeRepo(
          campusId: docId ?? "",
          reqBody: body,
        );
      } else {
        response = await SchoolRepo().createCampusLifeRepo(
          reqBody: body,
        );
      }

      // 4. Handle Response
      if (response.isSuccess) {
        Get.back(); // Close the form
        commonSnackBar(
          message: response.response?.data['message'] ?? AppStrings.successful,
        );

        // Refresh the list after success
        // Assuming you have a fetch method in this or another controller
        await fetchCampusDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  ///GET CAMPUS LIFE LISTING....
  var getAllCampusLifeDataList = <GetAllCampusLifeData>[].obs;

  Future<void> fetchCampusDetailsController() async {
    try {
      // Calling your Repo
      ResponseModel response = await SchoolRepo().getAllCampusLifeRepo();

      if (response.isSuccess && response.response?.data != null) {
        GetAllCampusLifeResModel getAllCampusLifeResModel =
            GetAllCampusLifeResModel.fromJson(response.response?.data);
        getAllCampusLifeDataList.assignAll(getAllCampusLifeResModel.data ?? []);
        getAllCampusLifeResponse.value =
            ApiResponse.complete(getAllCampusLifeResModel);
      } else {
        String errorMsg =
            response.response?.data['message'] ?? AppStrings.somethingWentWrong;
        getAllCampusLifeResponse.value = ApiResponse.error(errorMsg);
        // commonSnackBar(message: errorMsg);
      }
    } catch (e) {
      getAllCampusLifeResponse.value = ApiResponse.error(e.toString());
      // commonSnackBar(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  ///DELETE CAMPUS LIFE...

  ///DELETE NOTICE....
  Future<void> deleteCampusLifeController({
    required String entriesID,
    required String imageID,
  }) async {
    try {
      ResponseModel response =
          await SchoolRepo().deleteCampusCategoryLifeRepo(entriesId: entriesID, imageId: imageID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        getAllCampusLifeDataList.clear();
        await fetchCampusDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  // All categories from API

  // Observables for the dropdowns
  var selectedCategory = Rxn<CampusLifeCategoriesData>();
  var selectedSubCategory = Rxn<SubCategories>();

  // Available subcategories for the second dropdown
  var availableSubCategories = <SubCategories>[].obs;

  // Called when Category dropdown changes
  void onCategoryChanged(CampusLifeCategoriesData? category) {
    selectedCategory.value = category;
    selectedSubCategory.value = null; // Reset subcategory

    if (category != null && category.subCategories != null) {
      availableSubCategories.assignAll(category.subCategories!);
    } else {
      availableSubCategories.clear();
    }
    _runValidation();
  }

  void onSubCategoryChanged(SubCategories? sub) {
    selectedSubCategory.value = sub;
    _runValidation();
  }

  void textFiledChanged() {
    _runValidation();
  }

  // List to store multiple images
  var imageFiles = <File>[].obs;
  var imageCaptions = <TextEditingController>[].obs;

  var isFormValid = false.obs;

  void _runValidation() {
    // Enable button if category, subcategory, and at least one image exist
    isFormValid.value = selectedCategory.value != null &&
        selectedSubCategory.value != null &&
        imageFiles.isNotEmpty &&
     imageCaptions.every((controller) => controller.text.trim().isNotEmpty);
        // imageCaptions.isNotEmpty;
  }

  void addImage(String path) {
    if (imageFiles.length < 6) {
      imageFiles.add(File(path));
      imageCaptions.add(TextEditingController());
      _runValidation();
    } else {
      commonSnackBar(message: "Maximum 6 images allowed");
    }
  }

  void removeImage(int index) {
    imageFiles.removeAt(index);
    imageCaptions.removeAt(index);
    _runValidation();
  }
}
