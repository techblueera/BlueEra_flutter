import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/grocery/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/grocery/repo/food_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http_parser/http_parser.dart';

class GroceryVariantController extends GetxController {
  // Text Controllers
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final mrpController = TextEditingController();
  final priceController = TextEditingController();
  var foodImages = <XFile>[].obs;

  // Observable list of variants
  var variantList = <Map<String, dynamic>>[].obs;
  var isFormValid = false.obs;

  void removeImage(int index, RxList<XFile> targetList) {
    targetList.removeAt(index);
  }

  // Track if we are editing an item
  int? editingIndex;

  void validate() {
    isFormValid.value = nameController.text.trim().isNotEmpty &&
        quantityController.text.trim().isNotEmpty &&
        mrpController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  void addOrUpdateVariant() {
    final variant = {
      "variantName": nameController.text.trim(),
      "mrp": int.tryParse(mrpController.text.trim()) ?? 0,
      "quantityLabel": quantityController.text.trim(),
      "baseSellingPrice": int.tryParse(priceController.text.trim()) ?? 0,
    };

    if (editingIndex != null) {
      // Update existing
      variantList[editingIndex!] = variant;
    } else {
      // Add new
      variantList.add(variant);
    }

    clearAllField();
    logs("variantList=== ${variantList}");
  }

  void deleteVariant(int index) {
    variantList.removeAt(index);
  }

  void prepareEdit(int index) {
    editingIndex = index;
    final item = variantList[index];
    nameController.text = item['variantName'];
    mrpController.text = item['mrp'].toString();
    quantityController.text = item['quantityLabel'];
    priceController.text = item['baseSellingPrice'].toString();
    validate(); // Refresh validation for edit mode
  }

  void clearAllField() {
    nameController.clear();
    quantityController.clear();
    mrpController.clear();
    priceController.clear();
    isFormValid.value = false;
    editingIndex = null;
  }

  void validateVariantPrice() {
    isFormValid.value = mrpController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  Future<void> createFoodProductViaAiApi(
      {required FoodGenAiData foodData}) async {
    try {
      final foodServiceController = Get.find<FoodServiceController>();
      Map<String, dynamic> params = {};

      // prepare product details json
      final productDetailsMap = {
        "name": nameController.text,
        "category": foodServiceController.selectedFoodTypeID.value,
        "dietaryType": foodData.dietaryType,
        "ingredients": foodData.ingredients
      };
      params["productData"] = jsonEncode(productDetailsMap);
      params['variantData'] = jsonEncode(variantList);
      // prepare images multipart
      List<dio.MultipartFile> imageByPart = [];
      for (final file in foodImages) {
        final fileName = file.path.split('/').last;
        final imageInfo = getFileInfo(File(file.path));
        final mimeType = imageInfo['mimeType'];

        imageByPart.add(await dio.MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType ?? 'application/octet-stream'),
        ));
      }
      params["productImages"] = imageByPart;

      // call repo
      final responseModel =
          await FoodRepo().createFoodCategoryRepo(params: params);

      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);

        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      print('stack trace-- $s');
      commonSnackBar(message: e.toString());
    }
  }
}
