
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/controller/location_controller.dart';
import '../model/medical_admin_product_details.dart';
import '../model/medical_lab_details.dart';
import '../repo/medical_repo.dart';

class MedicalModelController extends GetxController {
  final medicalRepo = MedicalRepo();
  final RxList<MedicalCategory> medicalCategoryDataList =
      <MedicalCategory>[].obs;
  final RxList<MedicalProductDetailsModel> medicalProductDetails =
      <MedicalProductDetailsModel>[].obs;
  Rx<ApiResponse> getMedicalCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getMedicalProductListResponse =
      ApiResponse.initial('Initial').obs;
  final RxList<MedicalProductDetailsModel> selectedProducts =
      <MedicalProductDetailsModel>[].obs;

  final productNameController=TextEditingController();
  final productDescriptionController=TextEditingController();
  final productBasePriceController=TextEditingController();
  final productSellingPriceController=TextEditingController();
  final productQuantityController=TextEditingController();
  final productVariantWeightController=TextEditingController();
  RxList<String> pickedVariantImagePathList=<String>[].obs;
  Rx<File?> pickedProductImage = Rx<File?>(null);
  RxBool addProductLoading=false.obs;
  // Variant controllers


  void clearProductForm() {
    pickedProductImage.value=null;
    pickedVariantImagePathList.clear();
    productVariantWeightController.clear();
    productNameController.clear();
    productDescriptionController.clear();
    productBasePriceController.clear();
    productSellingPriceController.clear();
    productQuantityController.clear();
  }

  void disposePeoductForm() {
    productNameController.dispose();
    productDescriptionController.dispose();
    productBasePriceController.dispose();
    productSellingPriceController.dispose();
    productQuantityController.dispose();
  }

  bool isSelected(MedicalProductDetailsModel product) {
    return selectedProducts.any((p) => p.id == product.id);
  }

  void toggleProduct(MedicalProductDetailsModel product) {
    final index = selectedProducts.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      selectedProducts.removeAt(index);
    } else {
      selectedProducts.add(product);
    }
  }


  void clearSelection() {
    selectedProducts.clear();
  }
  void setPickedProductImage(File? pickedImage){
    pickedProductImage.value=pickedImage;
  }
  Future<void> fetchMedicalCategoryData(String categoryTopic) async {
    ResponseModel response = await medicalRepo.fetchMedicalCategoryData();
    if (response.isSuccess) {
      final modelJson = response.response?.data['data'];
      List<dynamic> modelList = modelJson;
      medicalCategoryDataList.value =
          modelList.map((e) => MedicalCategory.fromJson(e)).toList();
      getMedicalCategoryResponse.value =
          ApiResponse.complete(medicalCategoryDataList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getMedicalCategoryResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> fetchMedicalAdminProducts(String categoryTopic) async {
    ResponseModel response =
        await medicalRepo.fetchMedicalAdminProduct(categoryTopic);
    if (response.isSuccess) {
      final modelJson = response.response?.data['data'];

      List<dynamic> modelList = modelJson;

      medicalProductDetails.value =
          modelList.map((e) => MedicalProductDetailsModel.fromJson(e)).toList();
      getMedicalProductListResponse.value =
          ApiResponse.complete(medicalProductDetails);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getMedicalProductListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }



  Future<List<Map<String, dynamic>>> getVariantImages() async {
    return await Future.wait(
      pickedVariantImagePathList.map((e) async {
        String? publicUrl =
        await getPreSignUrl(selectedFile: File(e));

        return {
          ApiKeys.url: publicUrl,
          ApiKeys.altText: "Product Variant Image",
        };
      }),
    );
  }

  Future<void> addMedicalProduct(String catId) async {
    addProductLoading.value=true;
    String? publicUrl= await getPreSignUrl();
    List<Map<String, dynamic>>? variantsImages= await  getVariantImages();
    final locationController = getOrPut(() => LocationController());
    final locationData = await locationController.checkPermissionAndSetData();
    Map<String,dynamic> params={
      ApiKeys.categoryId: catId,
      ApiKeys.name: productNameController.text,
      ApiKeys.description: productDescriptionController.text,
      ApiKeys.image: publicUrl,
      ApiKeys.variant: {
        ApiKeys.weight: productVariantWeightController.text,
        ApiKeys.images: variantsImages,
        ApiKeys.inventories: [
          {
            ApiKeys.pincode: locationData?.pinCode,
            ApiKeys.cityName: locationData?.city,
            ApiKeys.batches: [
              {
                ApiKeys.quantity: productQuantityController.text,
                ApiKeys.mrp: productBasePriceController.text,
                ApiKeys.sellingPrice: productSellingPriceController.text
              }
            ],
          }
        ]
      },
    };

    ResponseModel response =
        await medicalRepo.MedicalAddProduct(params);
    if (response.isSuccess) {
      addProductLoading.value=false;
      Get.back();
      fetchMedicalAdminProducts(catId);
    } else {
      addProductLoading.value=false;

      commonSnackBar(message: AppStrings.somethingWentWrong);
      getMedicalProductListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }




  Future<void> fetchProductVarients(String productId) async {
    ResponseModel response =
    await medicalRepo.getProductVarientbyId(productId);
    if (response.isSuccess) {
      final modelJson = response.response?.data['data'];

      List<dynamic> modelList = modelJson;

      medicalProductDetails.value =
          modelList.map((e) => MedicalProductDetailsModel.fromJson(e)).toList();
      getMedicalProductListResponse.value =
          ApiResponse.complete(medicalProductDetails);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getMedicalProductListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
  Future<void> addProductVariant({
    required String productId,
  }) async {
    addProductLoading.value = true;

    List<Map<String, dynamic>> variantImages = await getVariantImages();

    final locationController = getOrPut(() => LocationController());
    final locationData = await locationController.checkPermissionAndSetData();
    Map<String, dynamic> params =  {
      ApiKeys.productId: productId,
      ApiKeys.weight: productVariantWeightController.text,
      ApiKeys.images: variantImages,
      ApiKeys.inventories: [
        {
          ApiKeys.pincode: locationData?.pinCode,
          ApiKeys.cityName: locationData?.city,
          ApiKeys.batches: [
            {
              ApiKeys.quantity: productQuantityController.text,
              ApiKeys.mrp: productBasePriceController.text,
              ApiKeys.sellingPrice: productSellingPriceController.text
            }
          ],
        }
      ]
    };
    ResponseModel response =
    await medicalRepo.addProductVarientbyId(params);

    addProductLoading.value = false;

    if (response.isSuccess) {
      VariantModel variant =
      VariantModel.fromJson(response.data);
      addVariantToProduct(variant,productId);
      Get.back();
      fetchMedicalAdminProducts(productId);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  void addVariantToProduct(VariantModel newVariant,String id) {
    final productIndex = selectedProducts.indexWhere(
          (p) => p.id == id,
    );

    if (productIndex == -1) {
      print("Product not found for variant");
      return;
    }

    final product = selectedProducts[productIndex];

    /// initialize list if null
    product.variants ??= [];

    /// add variant
    product.variants!.add(newVariant);

    /// very important for GetX to update UI
    selectedProducts[productIndex] = product;
  }


  void setVariantForEdit(VariantModel variant) {
    productVariantWeightController.text =
        variant.weight?.toString() ?? '';

    if (variant.inventories != null &&
        variant.inventories!.isNotEmpty &&
        variant.inventories!.first.batches != null &&
        variant.inventories!.first.batches!.isNotEmpty) {
      final batch = variant.inventories!.first.batches!.first;

      productQuantityController.text = batch.quantity?.toString() ?? '';
      productBasePriceController.text = batch.mrp?.toString() ?? '';
      productSellingPriceController.text =
          batch.sellingPrice?.toString() ?? '';
    }

    pickedVariantImagePathList.clear();
    for (final img in variant.images ?? []) {
      if (img.url != null) {
        pickedVariantImagePathList.add(img.url!);
      }
    }
  }





  Future<String?> getPreSignUrl({File? selectedFile}) async {
    File? selectedFiles = selectedFile??pickedProductImage.value;
    String? fileNames;
    String? fileTypes;

    Map<String, String?> fileInfo = getFileInfo(selectedFiles ?? File(""));
    fileNames = fileInfo['fileName'];
    fileTypes = fileInfo['mimeType'];

    final uploadParams = {
      ApiKeys.fileName: fileNames,
      ApiKeys.fileType: fileTypes,
    };

    ResponseModel response =
    await medicalRepo.getHealthAndServiceImageUpload(uploadParams);
    if (response.isSuccess) {
      await uploadFileToS3(
          file: selectedFiles ?? File(''),
          fileType: fileTypes ?? '',
          preSignedUrl: response.response?.data['uploadUrl']);
      return response.response?.data['publicUrl'];
    } else {
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    }
    return null;
  }

  Future<void> uploadFileToS3(
      {required File file,
        required String fileType,
        required String preSignedUrl}) async {
    try {
      ResponseModel? response = await medicalRepo.uploadVideoToS3(
          onProgress: (double progress) {
            // VideoUploadProgress.value = (progress * 100).toStringAsFixed(2);
          },
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);
      if (response?.isSuccess ?? false) {
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
