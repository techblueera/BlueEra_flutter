import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/generate_ai_product_content.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';


class AddProductViaAiRequest {
  final String? productName;
  final String? productDescription;
  // final String? category;
  final List<String>? images;

  AddProductViaAiRequest({
    this.productName,
    this.productDescription,
    // this.category,
    this.images,
  });

  AddProductViaAiRequest copyWith({
    String? productName,
    String? productDescription,
    String? category,
    List<String>? images,
  }) {
    return AddProductViaAiRequest(
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      // category: category ?? this.category,
      images: images ?? this.images,
    );
  }

}


class AddProductViaAiController extends GetxController{
  // Rx<ApiResponse> createServiceResponse = ApiResponse.initial('Initial').obs;
  // Rx<ApiResponse> createServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> generateAiProductContentResponse = ApiResponse.initial('Initial').obs;

  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productDescriptionController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  // final RxList<String> imageLocalPaths = <String>[].obs;

  RxBool isLoading = false.obs;

  /// Images selected on Step 1 (first screen)
  RxList<String> step1Images = <String>[].obs;

  /// Images used on Step 2 (second screen, preloaded + new)
  RxList<String> step2Images = <String>[].obs;

  /// Max images
  final RxInt maxStep1Images = 1.obs;
  final RxInt maxStep2Images = 5.obs;

  /// Add images to Step 1
  void addImagesStep1(List<String> images) {
    final remaining = maxStep1Images.value - step1Images.length;
    step1Images.addAll(images.take(remaining));
  }

  /// Remove image from Step 1
  void removeImageStep1(int index) {
    if (index >= 0 && index < step1Images.length) {
      step1Images.removeAt(index);
    }
  }

  /// Pick images for Step 1
  Future<void> pickImagesStep1(BuildContext context) async {
    try {
      final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
        context,
        'Product Image',
      );

      if (selected != null && selected.isNotEmpty) {
        final remaining = maxStep1Images.value - step1Images.length;
        if (remaining <= 0) {
          commonSnackBar(
            message: 'Limit reached\nYou can upload up to $maxStep1Images images only.',
          );
          return;
        }

        step1Images.addAll(selected.take(remaining));
      }
    } catch (e) {
      commonSnackBar(message: 'Image pick failed: $e');
    }
  }

  /// Preload Step 1 images to Step 2
  void preloadStep1ImagesToStep2() {
    step2Images.value = List.from(step1Images);
  }

  /// Pick new images for Step 2
  Future<void> pickImagesStep2(BuildContext context) async {
    try {
      final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
        context,
        'Product Image',
      );
      if (selected != null && selected.isNotEmpty) {
        final remaining = maxStep2Images.value - step2Images.length;
        if (remaining <= 0) return;
        step2Images.addAll(selected.take(remaining));
      }
    } catch (e) {
      commonSnackBar(message: 'Image pick failed: $e');
    }
  }

  /// Remove image from Step 2
  /// Step 1 images (preloaded) cannot be removed
  void removeImageStep2(int index) {
    // Only allow removal if index >= step1Images.length
    if (index >= step1Images.length && index < step2Images.length) {
      step2Images.removeAt(index);
    }
  }

  bool canAddMoreStep1() => step1Images.length < maxStep1Images.value;
  bool canAddMoreStep2() => step2Images.length < maxStep2Images.value;

  void onGenerate() async {
    if (!_validate()) return;

    isLoading.value = true;

    final request = AddProductViaAiRequest(
      productName: productNameController.text.trim(),
      productDescription: productDescriptionController.text.trim(),
      // category: Get.find<ManualListingScreenController>()
      //     .selectedBreadcrumb
      //     .value
      //     ?.map((p) => p.name)
      //     .join(" > "), // no brackets, proper string
      images: step1Images.toList(),
    );

    await createProductViaAiApi(request);

    isLoading.value = false;

    // Get.toNamed(
    //   RouteHelper.getAddProductViaAiStep2Route(),
    //   arguments: {
    //     ApiKeys.generateAiProductContent: GenerateAiProductContent(),
    //   },
    // );
  }

  bool _validate() {
    if(step1Images.length < 1) {
      commonSnackBar(message: 'Please take minimum one product images');
      return false;
    }

    if(!formKey.currentState!.validate()) return false;

    return true;
  }


  Future<void> createProductViaAiApi(AddProductViaAiRequest request) async {
    try {
      Map<String, dynamic> params = {};

      // prepare product details json
      final productDetailsMap = {
        "product_name": request.productName,
        "description": request.productDescription,
        // "category": request.category,
      };
      String productDetailsString = jsonEncode(productDetailsMap);
      params[ApiKeys.productDetails] = productDetailsString;

      // prepare images multipart
      List<dio.MultipartFile> imageByPart = [];
      for (final path in request.images ?? []) {
        final fileName = path.split('/').last;
        final imageInfo = getFileInfo(File(path));
        final mimeType = imageInfo['mimeType'];

        imageByPart.add(await dio.MultipartFile.fromFile(
          path,
          filename: fileName,
          contentType: MediaType.parse(mimeType ?? 'application/octet-stream'),
        ));
      }
      params[ApiKeys.images] = imageByPart;

      // call repo
      final responseModel = await InventoryRepo().generateAiProductContent(params: params);

      if (responseModel.isSuccess) {
        generateAiProductContentResponse.value = ApiResponse.complete(responseModel);

        final generateAiProductContent = GenerateAiProductContent.fromJson(
          responseModel.response!.data,
        );

        Get.toNamed(
          RouteHelper.getAddProductViaAiStep2Route(),
          arguments: {
            ApiKeys.addProductViaAiRequest: request,
            ApiKeys.generateAiProductContent: generateAiProductContent,
          },
        );
      } else {
        generateAiProductContentResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print('stack trace-- $s');
      generateAiProductContentResponse.value = ApiResponse.error('error');
      commonSnackBar(message: 'something went wrong.');
    }
  }



}