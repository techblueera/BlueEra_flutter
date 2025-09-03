import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/store/models/get_channel_product_model.dart';
import 'package:BlueEra/features/common/store/repo/product_repo.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddUpdateProductController extends GetxController{
  ApiResponse addProductResponse = ApiResponse.initial('Initial');
  ApiResponse channelSingleProductResponse = ApiResponse.initial('Initial');

  RxString selectedImage = ''.obs;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController productDescriptionController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  AutovalidateMode autoValidate = AutovalidateMode.disabled;


  /// Channel data
  RxBool singleChannelLoading = true.obs;
  Rx<ProductData> ChannelSingleProduct = ProductData().obs;

  void selectImage(BuildContext context) async {
    // final appLocalizations = AppLocalizations.of(context);

    selectedImage.value = await SelectProfilePictureDialog.showLogoDialog(
        context,
        'Add Product Image'
    );
  }

  /// Add Channel Product
  Future<void> addChannelProduct(String channelId) async {
    if (formKey.currentState?.validate() ?? false) {
      if (selectedImage.isEmpty) {
        commonSnackBar(message: "Please add product picture.");
        return;
      }

      String fileName = selectedImage.split('/').last;
      dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile((selectedImage.value), filename: fileName);

      Map<String, dynamic> params = {
        ApiKeys.channelId: channelId,
        ApiKeys.image: imageByPart,
        ApiKeys.name: titleController.text.trim(),
        ApiKeys.description: productDescriptionController.text.trim(),
        ApiKeys.price: productPriceController.text.trim(),
        ApiKeys.link: linkController.text.trim(),
      };

      try {
        ResponseModel? response = await ProductRepo().addProduct(params: params);

        if (response.isSuccess) {
          addProductResponse = ApiResponse.complete(response);
          Get.back();
          commonSnackBar(message: "Product add successfully");
        } else {
          addProductResponse = ApiResponse.error('error');
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        addProductResponse = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    }
  }

  /// GET Channel Single Product...
  Future<void> getChannelSingleProductDetail({required String productId}) async {
    try {
      singleChannelLoading.value = true;
      final response = await ProductRepo().getSingleProductDetails(productId: productId);

      if (response.isSuccess) {
        channelSingleProductResponse = ApiResponse.complete(response);
        final productDataResponse = ProductData.fromJson(response.response?.data);
        ChannelSingleProduct.value = productDataResponse;
      } else {
        channelSingleProductResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      channelSingleProductResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      singleChannelLoading.value = false;
    }
  }

  /// Update Channel Product
  Future<void> updateChannelProduct(String productId) async {
    if (formKey.currentState?.validate() ?? false) {
      if (selectedImage.isEmpty) {
        commonSnackBar(message: "Please add product picture.");
        return;
      }

      Map<String, dynamic> params = {};
      log('fileName--> ${selectedImage.split('/').last}');
      bool isImageNetwork = isNetworkImage(selectedImage.value);
      if(!isImageNetwork){
        String fileName = selectedImage.split('/').last;
        dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile((selectedImage.value), filename: fileName);
        params[ApiKeys.image] = imageByPart;
      }

      params[ApiKeys.name] = titleController.text.trim();
      params[ApiKeys.description] = productDescriptionController.text.trim();
      params[ApiKeys.price] = productPriceController.text.trim();
      params[ApiKeys.link] = linkController.text.trim();

      try {
        ResponseModel? response = await ProductRepo().updateProductDetails(productId: productId, params: params);

        if (response.isSuccess) {
          addProductResponse = ApiResponse.complete(response);
          Get.back();
          commonSnackBar(message: "Product update successfully");
        } else {
          addProductResponse = ApiResponse.error('error');
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        addProductResponse = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    }
  }

}