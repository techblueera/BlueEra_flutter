import 'dart:convert';
import 'package:BlueEra/features/common/food/binding/food_upload_binding.dart';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/common/food/model/food_ai_res_model.dart';
import 'package:BlueEra/features/common/food/repo/food_ai_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/earn_service_repo.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/uploading_progressing_dialog.dart';
import '../view/add_food_screen.dart';
import '../../reel/repo/channel_repo.dart';
import '../model/get_food_details_model.dart';
import '../model/upload_food_load_url_model.dart';

class PriceOption {
  TextEditingController labelController;
  TextEditingController priceController;

  PriceOption({
    required this.labelController,
    required this.priceController,
  });

  Map<String, dynamic> toJson() {
    return {
      "label": labelController.text,
      "price": double.tryParse(priceController.text) ?? 0.0,
    };
  }
}

class FoodUploadController extends GetxController {
  Rx<ApiResponse> foodAiResponse = ApiResponse.initial('Initial').obs;
  final foodNameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final singlePriceController = TextEditingController();
  ApiResponse uploadFileToS3Response = ApiResponse.initial('Initial');
  Rx<ApiResponse> getFoodServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> singleFoodServiceDataResponse =
      ApiResponse.initial('Initial').obs;

  final GlobalKey<FormState> formKey = GlobalKey();
  final RxInt selectedFoodSubTabIndex = 0.obs;
  // Form controllers
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController cityNameController = TextEditingController();

  // Selected options
  final RxString foodName = "".obs;
  final RxString selectedFoodType1 = "Food Item".obs;
  final RxString selectedFoodType2 = "Non-Veg".obs;
  final RxString selectedCookingMethod = "Boiled".obs;
  final RxString selectedItemNature = "Break-Fast".obs;
  final RxInt selectedFoodType1Index = 0.obs;
  final RxInt selectedFoodType2Index = 1.obs;
  final RxInt selectedCookingMethodIndex = 1.obs;
  final RxInt selectedItemNatureIndex = 1.obs;

  RxString selectedCategory = ''.obs;
  RxString selectedSubCategory = ''.obs;
  final RxList<String> imageLocalPaths = <String>[].obs;
  final RxList<Map<String, dynamic>> addOns = <Map<String, dynamic>>[].obs;
  late RxList<String> ingredients = <String>[].obs;
  late RxList<String> accompaniments = <String>[].obs;
  RxBool isSingleProduct = true.obs;
  // Image selection
  final Rx<File?> selectedImage = Rx<File?>(null);
  var priceOptions = <PriceOption>[].obs;

  bool shouldRefresh = false;
  void onChangeFoodSubTab(int index) {
    selectedFoodSubTabIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    // default 3 rows
    addPriceOption();
    addPriceOption();
    addPriceOption();
  }

  void addPriceOption() {
    priceOptions.add(
      PriceOption(
        labelController: TextEditingController(),
        priceController: TextEditingController(),
      ),
    );
  }

  void removePriceOption(int index) {
    if (priceOptions.length > 1) {
      priceOptions.removeAt(index);
    }
  }

  List<Map<String, dynamic>> get priceOptionsJson =>
      priceOptions.map((e) => e.toJson()).toList();

  // Loading state
  final RxBool isLoading = false.obs;

  // Food type 1 options
  // final List<String> foodType1Options = ["Food Item", "Beverage"];
  // final List<String> foodType1Options = [
  //   AppConstants.TIFFIN,
  //   AppConstants.BAKERY,
  //   AppConstants.SWEETS,
  //   AppConstants.OTHER
  // ];
  final List<String> foodType1Options = [TIFFIN, BAKERY, SWEETS, OTHER];
  bool isCategoryLocked = false;

  final List<String> foodType2Options = [
    "Veg",
    "Non-Veg",
    "Vigan",
    "Dairy/Sweet"
  ];

  Color getFoodTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'veg':
        return Color(0xFF296E01);
      case 'non-veg':
        return Color(0xFFA62C2B);
      case 'vigan': // assuming this means Vegan
        return Color(0xFFA8A9AD);
      case 'dairy_items/sweet':
        return Color(0xFF6B4A3A);
      default:
        return Color(0xFFA8A9AD);
    }
  }

  final List<String> cookingMethodOptions = [
    "Cold Mix",
    "Boiled",
    "Oil Fried",
    "Deshi Ghee",
    "Oil + Ghee Mix",
    "Vegetable Ghee"
  ];

  final List<String> itemNatureOptions = [
    "All Time",
    "Break-Fast",
    "Dinner",
    "Snacks",
    "Lunch"
  ];

  // Show image picker dialog
  Rx<FoodAiResModel> foodAiResponseModel = FoodAiResModel().obs;
  RxBool isGenerateFoodLoading = false.obs;

  // Generate food data
  Future<void> generateFood(
      {required ProviderType providerType, String? serviceSubType}) async {
    try {
      isGenerateFoodLoading.value = true;
      dio.MultipartFile? imageByPart =
          await multiPartImage(imagePath: selectedImage.value?.path ?? "");
      Map<String, dynamic> reqParm = {
        ApiKeys.product_details: jsonEncode({
          ApiKeys.product_name: foodNameController.text,
          ApiKeys.category: selectedFoodType1.value,
          // ApiKeys.category: selectedItemNature.value,
          ApiKeys.keywords:
              "${selectedFoodType1.value}, ${selectedFoodType2.value}, ${selectedCookingMethod.value}, ${selectedItemNature.value}",
          if (cityNameController.text.isNotEmpty)
            ApiKeys.city: cityNameController.text
        }),
        ApiKeys.images: imageByPart,
      };

      final ResponseModel responseModel =
          await FoodAiRepo().aiFoodGenerateRepo(params: reqParm);
      ;

      if (responseModel.isSuccess) {
        foodAiResponseModel.value =
            FoodAiResModel.fromJson(responseModel.response?.data);

        // FoodDetailScreen

        Get.to(
            () => SubmitFoodProductPage(
                  providerType: providerType,
                  serviceSubType: serviceSubType,
                  categoryTag: selectedFoodType1.value,
                  subCategory: selectedFoodType2.value,
                  foodDatas: foodAiResponseModel.value,
                  foodData: responseModel.response?.data,
                  imagePath: selectedImage.value?.path ?? "",
                ),
            binding: FoodUploadBinding());
        foodAiResponse.value = ApiResponse.complete(foodAiResponseModel);
      } else {
        foodAiResponse.value =
            ApiResponse.error('Failed to generate ai food response');
      }
    } catch (e) {
      logs("ERROR===== ${e}");
      foodAiResponse.value = ApiResponse.error(e.toString());
    } finally {
      isGenerateFoodLoading.value = false;
    }
  }

  List<UploadS3ImageModel> images = [];
  double? _parsePriceToDouble(String raw) {
    if (raw.trim().isEmpty) return null;
    // remove anything that's not digit or dot
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<Map<String, dynamic>> buildRequestBody(
      Map<String, dynamic> foodData, ProviderType providerType,
      {String? serviceSubType}) async {
    // Title & desc (use controller if filled, otherwise fall back to AI/model values)

    List<Map<String, dynamic>> normalizedAddOns = addOns.map((item) {
      final name = (item['name'] ?? "").toString();
      final priceStr = (item['price'] ?? "").toString();
      final parsed = _parsePriceToDouble(priceStr) ?? 0.0;
      return {
        "name": name,
        "price": parsed,
      };
    }).toList();

    final Map<String, dynamic> body = {
      "title": foodNameCtrl.text.trim(),
      ApiKeys.providerType: providerType.title,
      "description": descCtrl.text.trim(),
      "type": "food",
      "category": selectedCategory.value,
      "availability": selectedItemNature.value,
      "subCategory": selectedCookingMethod.value,
      "vegType": selectedSubCategory.value.toLowerCase(),
      "addOns": normalizedAddOns,
      "keyIngredients": ingredients,
      "servingOptions":
          List<Map<String, dynamic>>.from(foodData["servingOptions"] ?? []),
      "accompaniments": accompaniments,
      "nutritionalSummary_per100g":
          foodData["nutritionalSummary_per100g"] ?? {},
      "keyMinerals": List<String>.from(foodData["keyMinerals"] ?? []),
      "seoTags": List<String>.from(foodData["seoTags"] ?? []),
      "priceType": isSingleProduct.value ? "single" : "multiple",
      if (isSingleProduct.value == false) "priceOptions": priceOptionsJson,
      if (isSingleProduct.value && singlePriceController.text.isNotEmpty)
        "singlePrice": int.parse(singlePriceController.text),
    };

    for (var imagePath in imageLocalPaths) {
      final imageInfo = getFileInfo(File(imagePath));
      if (imageInfo.isNotEmpty) {
        images.add(
          UploadS3ImageModel(path: imagePath, mimeType: imageInfo['mimeType']!),
        );
      }
    }

    if (images.isNotEmpty) {
      body[ApiKeys.imageContentTypes] =
          images.map((img) => img.mimeType).toList();
    }
    if (serviceSubType != null) body[ApiKeys.subType] = serviceSubType;
    return body;
  }

  RxBool isAddFoodLoading = false.obs;

  Future<void> addFoodServices(
      Map<String, dynamic> foodData, ProviderType providerType,
      {String? serviceSubType}) async {
    if (formKey.currentState!.validate()) {
      try {
        isAddFoodLoading.value = true;
        Map<String, dynamic> data = await buildRequestBody(
            foodData, providerType,
            serviceSubType: serviceSubType);

        final ResponseModel responseModel;
        if (providerType == ProviderType.user) {
          responseModel = await EarnServiceRepo().addServiceRepo(params: data);
        } else {
          responseModel = await FoodAiRepo().addFoodService(queryParam: data);
        }

        if (responseModel.isSuccess) {
          UploadFoodLoadUrlModel data =
              UploadFoodLoadUrlModel.fromJson(responseModel.response?.data);

          UploadProgressDialog.update(0.2);
          List<String> preSignedUrlImages = data.uploadUrls?.images ?? [];

          if (images.length == preSignedUrlImages.length) {
            for (var i = 0; i < images.length; i++) {
              images[i].preSignedUrl = preSignedUrlImages[i];
            }

            // Upload all images with combined progress
            await uploadAllImages(images);
          }
          UploadProgressDialog.close();
          commonSnackBar(message: AppStrings.foodAddedSuccess.tr);
          Get.close(2);
        } else {
          UploadProgressDialog.close();
          commonSnackBar(message: responseModel.message);
        }
      } catch (e) {
        UploadProgressDialog.close();
        log('error-- >  $e');
      } finally {
        isAddFoodLoading.value = false;
      }
    }
  }

  Future<void> uploadAllImages(List<UploadS3ImageModel> images) async {
    if (images.isEmpty) return;

    final totalImages = images.length;

    try {
      for (var i = 0; i < totalImages; i++) {
        final image = images[i];
        final file = File(image.path);
        final fileType = image.mimeType;
        final preSignedUrl = image.preSignedUrl ?? '';

        await uploadFileToS3(
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl,
          onProgress: (progress) {
            final imageFraction = 0.8 / totalImages;
            final overallProgress =
                0.2 + (i * imageFraction) + (progress * imageFraction);

            UploadProgressDialog.update(overallProgress.clamp(0.0, 1.0));

            debugPrint(
                "Uploading ${file.path}: ${(progress * 100).toStringAsFixed(0)}%, overall: ${(overallProgress * 100).toStringAsFixed(0)}%");
          },
        );
      }
    } catch (e) {
      UploadProgressDialog.close();
      logs("ERROR===== $e");
    }
  }

  Future<void> uploadFileToS3({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async {
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
        onProgress: onProgress,
        file: file,
        fileType: fileType,
        preSignedUrl: preSignedUrl,
      );

      if (response?.isSuccess ?? false) {
        uploadFileToS3Response = ApiResponse.complete(response);
      } else {
        uploadFileToS3Response = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      uploadFileToS3Response = ApiResponse.error('error');
      logs("ERROR===== $e");
    }
  }

  RxBool isSingleFoodServiceLoading = false.obs;
  Rxn<GetFoodDetailsModel> singleFoodServiceData = Rxn<GetFoodDetailsModel>();

  Future<void> fetchSingleFoodDataApi({required String serviceId}) async {
    try {
      isSingleFoodServiceLoading.value = true;

      final response =
          await FoodAiRepo().fetchSingleFoodDataApi(serviceId: serviceId);
      if (response.isSuccess) {
        singleFoodServiceDataResponse.value = ApiResponse.complete(response);
        final singleFoodDetailsModel =
            GetFoodDetailsModel.fromJson(response.response!.data);
        singleFoodServiceData.value = singleFoodDetailsModel;
      } else {
        print("API failed with status: ${response.statusCode}");
        singleFoodServiceDataResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
      singleFoodServiceDataResponse.value = ApiResponse.error('error');
    } finally {
      isSingleFoodServiceLoading.value = false;
    }
  }
}
