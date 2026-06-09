import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/core/constants/app_enum.dart' hide MediaType;
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/product/model/generate_ai_product_content.dart';
import 'package:BlueEra/features/me/manufacturer/model/manufacturer_product_catalog_response.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/manufacturer/model/manufacturer_single_product_model.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/manufacturer/repo/manufacturer_product_repo.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_preview_screen.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import '../model/manufacturer_sub_category_root_category_response.dart';

class ManufacturerAddProductViaAiRequest {
  final String? productName;
  final String? productDescription;
  // final String? category;
  final String? key;
  final List<String>? images;

  ManufacturerAddProductViaAiRequest({
    this.productName,
    this.productDescription,
    // this.category,
    this.key,
    this.images,
  });

  ManufacturerAddProductViaAiRequest copyWith({
    String? productName,
    String? productDescription,
    // String? category,
    String? key,
    List<String>? images,
  }) {
    return ManufacturerAddProductViaAiRequest(
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      // category: category ?? this.category,
      key: key ?? this.key,
      images: images ?? this.images,
    );
  }
}

class ManufacturerProductListing {
  final List<String> image;
  final String name;
  final String id;
  // final Map<String, String>? selectedVariants;
  final Map<String, dynamic>? selectedVariants;
  final String? price;
  final String? mrp;
  final String? discount;

  ManufacturerProductListing({
    required this.image,
    required this.name,
    required this.id,
    this.selectedVariants,
    this.price,
    this.mrp,
    this.discount,
  });
}

class ManufacturerSelectedColor {
  final Color color;
  final String name;

  ManufacturerSelectedColor(this.color, this.name);

  factory ManufacturerSelectedColor.fromJson(Map<String, dynamic> json) {
    return ManufacturerSelectedColor(
      hexToColor(json['color_code'] ?? '#000000'),
      json['color_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color_code': colorToHex(color),
      'color_name': name,
    };
  }

}

class ManufacturerProductMoreDetails {
  final String? title;
  final String? details;

  ManufacturerProductMoreDetails({this.title, this.details});

  factory ManufacturerProductMoreDetails.fromJson(Map<String, dynamic> json) => ManufacturerProductMoreDetails(
    title: json['title'],
    details: json['details'],
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'details': details,
  };
}

class ManufacturerProductController extends GetxController{
  Rx<ApiResponse> generateAiProductContentResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSubChildORRootCategoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> searchProductCategoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addProductToInventoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addUpdateProductVariantApiResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> singleProductDetailsResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> nestedProductCategoryResponse = ApiResponse.initial('Initial').obs;

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

  final TextEditingController productNameStep1Controller = TextEditingController();
  final TextEditingController productDescriptionStep1Controller = TextEditingController();

  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productDescriptionController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final RxList<TextEditingController> featureControllers = <TextEditingController>[].obs;
  final TextEditingController linkController = TextEditingController();
  final RxList<TextEditingController> userGuideLineControllers = <TextEditingController>[].obs;
  final TextEditingController productWarrantyController = TextEditingController();
  final TextEditingController productExpiryDurationController = TextEditingController();

  final RxList<String> tags = <String>[].obs;

  final TextEditingController warrantyController = TextEditingController();
  final TextEditingController guidelineController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController availableStockController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController materialController = TextEditingController();

  RxList<ManufacturerSelectedColor> selectedColors = <ManufacturerSelectedColor>[].obs;

  Map<String, TextEditingController> dynamicControllers = {}; // key -> controller
  RxMap<String, RxList<String>> dynamicAttributes = <String, RxList<String>>{}.obs; // key -> list of values

  var loading = false.obs;

  final searchController = TextEditingController();

  /// Search results
  var searchResults = <CategoryData>[].obs;

  /// Is search active
  var isSearchActive = false.obs;

  /// Search debounce timer
  Timer? _searchDebounce;

  final formKeyStep1 = GlobalKey<FormState>();
  final formKeyStep2 = GlobalKey<FormState>();
  final formKeyStep3 = GlobalKey<FormState>();
  // final formKeyStep4 = GlobalKey<FormState>();

  final RxList<ManufacturerProductMoreDetails> detailsList = <ManufacturerProductMoreDetails>[].obs;

  String? productId;

  final Rxn<String> selectedCategory = Rxn<String>();
  final RxString selectedCategoryId = ''.obs;

  // Home-made product category (flat list, tagId via slugId) — used when
  // providerType == user.
  final Rxn<CollapsibleGridModel> selectedHomeMadeCategory = Rxn<CollapsibleGridModel>();

  // Nested category selection — used when providerType == business.
  var selectedProductLevel0 = Rxn<ProductNestedCategoryResponse>();
  var selectedProductLevel1 = Rxn<ProductNestedCategoryResponse>();
  var selectedProductLevel2 = Rxn<ProductNestedCategoryResponse>();
  var selectedProductLevel3 = Rxn<ProductNestedCategoryResponse>();

  ProductNestedCategoryResponse? get _deepestNestedCategory =>
      selectedProductLevel3.value ??
      selectedProductLevel2.value ??
      selectedProductLevel1.value ??
      selectedProductLevel0.value;

  final RxBool showLinkField = false.obs;
  RxInt selectedVariantIndex = (-1).obs;

  final RxList<ManufacturerProductListing> listedProducts = <ManufacturerProductListing>[].obs;

  /// AI-generated variants (with per-variant pricing) captured from the
  /// generate step, used to build the create + variant request bodies.
  List<AiVariantData> aiVariantData = <AiVariantData>[];

  final String otherCategoryId = '68d4e332455cad1af87fac05';

  RxString selectedProductOrVariantPrice = '00,000'.obs;
  RxString selectedProductOrVariantDiscount = '0'.obs;
  RxString selectedProductOrVariantMrp = '00,000'.obs;

  /// Images used on Step 2 (second screen, preloaded + new)
  RxList<String> allProductImages = <String>[].obs;

  List<Map<String, String>> get categoryDropdownList =>
      Get.find<AuthController>().businessOnboardingProductsCategories.map((category) {
    return {
      'display': category.name ?? '',
      'value': category.tagId ?? '',
    };
  }).toList();
  final Rxn<Map<String, String>> selectedProductCategory = Rxn<Map<String, String>>();

  // ManufacturerProduct Snap Search Data
  // Rxn<ManufacturerProductSnapSearchData> productSnapSearchData = Rxn<ManufacturerProductSnapSearchData>();
  final List<Map<String, String>> productSnapSearchConfig = [
    {
      'title': 'Upload Photo',
      'icon': AppIconAssets.cameraAddOutlineIcon,
      'image': AppImageAssets.groceryImageFirst,
    },
    {
      'title': 'Search Manually',
      'icon': AppIconAssets.search,
      'image': AppImageAssets.groceryImageSecond,
    },
  ];

  @override
  void onClose() {
    productNameController.dispose();
    productDescriptionController.dispose();
    warrantyController.dispose();
    guidelineController.dispose();
    brandController.dispose();
    mrpController.dispose();
    sellingPriceController.dispose();
    availableStockController.dispose();
    tagsController.dispose();
    linkController.dispose();
    for (final c in featureControllers) {
      c.dispose();
    }
    for (final c in userGuideLineControllers) {
      c.dispose();
    }
    materialController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }


  void addColor(Color color, String name) {
    // if (selectedColors.length == 5) {
    //   commonSnackBar(message: 'You can\'t add more than 5 colors');
    //   return;
    // }

    if (!selectedColors.any((c) => c.color == color)) {
      selectedColors.add(ManufacturerSelectedColor(color, name));
    }
  }

  void removeColor(ManufacturerSelectedColor selectedColor) {
    selectedColors.remove(selectedColor);
  }

  void addDetail(ManufacturerProductMoreDetails detail) {
    detailsList.add(detail);
  }

  void removeDetail(int index) {
    detailsList.removeAt(index);
  }

  void addTag() {
    if(tags.length == 10){
      commonSnackBar(message: 'You can\'t add more than 10 tags/Keywords');
      return;
    }

    final text = tagsController.text.trim();
    if (text.isNotEmpty) {
      tags.add(text);
      tagsController.clear();
    }
  }

  void removeTag(String tag) {
    tags.remove(tag);
  }

  // Features management
  void addFeature() {
    featureControllers.add(TextEditingController());
  }

  void removeFeature(int index) {
    if (index >= 0 && index < featureControllers.length) {
      final ctrl = featureControllers.removeAt(index);
      ctrl.dispose();
    }
  }

  /// Add images to Step 1
  void addImagesStep1(List<String> images) {
    final remaining = maxStep1Images.value - step1Images.length;
    step1Images.addAll(images.take(remaining));
  }

  /// Remove image from Step 1
  void removeImageStep1(int index) {
    if (index >= 0 && index < step1Images.length) {
      step1Images.removeAt(index);
      update();
    }
  }

  /// Pick images for Step 1
  Future<void> pickImagesStep1(BuildContext context) async {
    final List<String>? selected = await PhotoPickerService.pickMultiplePhotos(
      context,
      AppStrings.productImage,
      // 'ManufacturerProduct Image',
    );
    if (selected != null && selected.isNotEmpty) {
      final remaining = maxStep1Images.value - step1Images.length;
      step1Images.addAll(selected.take(remaining));
      update();
    }
  }

  /// Preload Step 1 images to Step 2
  void preloadStep1ImagesToStep2() {
    step2Images.value = List.from(step1Images);
    update();
  }

  void addUserGuideLine() {
    userGuideLineControllers.add(TextEditingController());
  }

  void removedUserGuideLine(int index) {
    if (index >= 0 && index < userGuideLineControllers.length) {
      final ctrl = userGuideLineControllers.removeAt(index);
      ctrl.dispose();
    }
  }

  /// Pick new images for Step 2
  Future<void> pickImagesStep2(BuildContext context) async {
    try {
      final List<String>? selected = await PhotoPickerService.pickMultiplePhotos(
        context,
        AppStrings.productImage,

      );
      if (selected != null && selected.isNotEmpty) {
        final remaining = maxStep2Images.value - step2Images.length;
        if (remaining <= 0) return;
        step2Images.addAll(selected.take(remaining));
        update();
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
      update();
    }
  }

  bool canAddMoreStep1() => step1Images.length < maxStep1Images.value;
  bool canAddMoreStep2() => step2Images.length < maxStep2Images.value;

  void onGenerate(ManufacturerProductController addProductViaAiController, String id, ProviderType providerType) async {
    if (!_validate(providerType)) return;

    isLoading.value = true;

    final String? keyValue;
    if (providerType == ProviderType.business) {
      final nested = _deepestNestedCategory;
      keyValue = nested?.key ?? nested?.sId;
    } else {
      keyValue = selectedHomeMadeCategory.value?.slugId;
    }

    final request = ManufacturerAddProductViaAiRequest(
      productName: productNameStep1Controller.text.trim(),
      productDescription: productDescriptionStep1Controller.text.trim(),
      key: keyValue,
      images: step1Images.toList(),
    );

    await createProductViaAiApi(request, addProductViaAiController, id, providerType);

    isLoading.value = false;

  }

  bool _validate(ProviderType providerType) {
    if(step1Images.length < 1) {
      commonSnackBar(message: AppStrings.pleaseTakeMinimumOneProductImage.tr);
      return false;
    }

    if (providerType == ProviderType.business) {
      if (_deepestNestedCategory == null) {
        commonSnackBar(message: 'Please select a product category');
        return false;
      }
    } else {
      if (selectedHomeMadeCategory.value == null) {
        commonSnackBar(message: 'Please select a product category');
        return false;
      }
    }

    if(!formKey.currentState!.validate()) return false;

    return true;
  }


  Future<void> createProductViaAiApi(ManufacturerAddProductViaAiRequest request, ManufacturerProductController addProductViaAiController, String id, ProviderType providerType) async {
    try {
      Map<String, dynamic> params = {};

      // prepare product details json
      final productDetailsMap = {
        "product_name": request.productName,
        "description": request.productDescription,
        "key": request.key,
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
      final responseModel = await ManufacturerProductRepo().generateAiProductContentRepo(params: params);

      if (responseModel.isSuccess) {
        generateAiProductContentResponse.value = ApiResponse.complete(responseModel);

        final generateAiProductContent = GenerateAiProductContent.fromJson(
          responseModel.response!.data,
        );

        // Capture the AI variants (with per-variant pricing) so the
        // "Post Product" request can attach price to each variant option.
        addProductViaAiController.aiVariantData =
            generateAiProductContent.variantData;

        Get.toNamed(
          RouteHelper.getManufacturerAddProductViaAiStep2Route(),
          arguments: {
            ApiKeys.controller: addProductViaAiController,
            ApiKeys.generateAiProductContent: generateAiProductContent,
            ApiKeys.id: id,
            ApiKeys.providerType: providerType
          },
        );
      } else {
        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
        generateAiProductContentResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print('stack trace-- $s');
      generateAiProductContentResponse.value = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    }
  }

  /// Search method
  void onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isEmpty) {
        clearSearch();
      } else {
        performSearch(query.trim());
      }
    });
  }

  /// Perform search API call
  Future<void> performSearch(String keyword) async {
    try {
      isSearchActive.value = true;
      loading.value = true;

      Map<String, dynamic> params = {
        ApiKeys.q: keyword
      };

      final responseModel = await ManufacturerProductRepo().searchCategoryOfProduct(queryParams: params);
      if (responseModel.isSuccess) {
        searchProductCategoryResponse.value = ApiResponse.complete(responseModel);
        final subChildORRootCategoryResponse = ManufacturerSubChildORRootCategoryResponse.fromJson(responseModel.response!.data);
        List<CategoryData> categoryData = subChildORRootCategoryResponse.data??[];

        searchResults.clear();
        searchResults.assignAll(categoryData);

        // /// set initially category id (If user didn't choose category itSelf)
        // if(searchResults.isNotEmpty){
        //   selectedCategoryId.value = searchResults[0].sId??'';
        // }
        // else{
        //   selectedCategoryId.value = otherCategoryId;
        // }
        // log('category id--> $selectedCategoryId');
      } else {
        searchProductCategoryResponse.value = ApiResponse.error('error');
      }

      loading.value = false;
    } catch (e) {
      searchProductCategoryResponse.value = ApiResponse.error('error');
      loading.value = false;
    }
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchResults.clear();
    isSearchActive.value = false;
  }

  // // Add dynamic value
  // void addDynamicValue(String key, String value) {
  //   if (!dynamicAttributes.containsKey(key)) {
  //     dynamicAttributes[key] = <String>[].obs;
  //     dynamicControllers[key] = TextEditingController();
  //   }
  //   dynamicAttributes[key]!.add(value);
  //   dynamicControllers[key]!.clear();
  //   update([key]);
  // }
  //
  // // Remove dynamic value
  // void removeDynamicValue(String key, String value) {
  //   dynamicAttributes[key]?.remove(value);
  //   if (dynamicAttributes[key]?.isEmpty ?? true) {
  //     dynamicAttributes.remove(key);
  //     dynamicControllers.remove(key);
  //   }
  //   update([key]);
  // }

  var isCreateProductLoading = false.obs;

  Future<void> createProductViaAi(ManufacturerProductController addProductViaAiController, String id, ProviderType providerType) async {
    isCreateProductLoading.value = true;
    try {
      Map<String, dynamic> params = {
        if(productNameController.text.trim().isNotEmpty) ApiKeys.name: productNameController.text.trim(),
        if(productDescriptionController.text.trim().isNotEmpty) ApiKeys.description: productDescriptionController.text.trim(),
        if (providerType == ProviderType.business) ...{
          if (_deepestNestedCategory?.key != null)
            ApiKeys.category_key: _deepestNestedCategory!.key,
          ApiKeys.category_id: _deepestNestedCategory?.sId ?? '',
        } else ...{
          if (selectedHomeMadeCategory.value?.slugId != null)
            ApiKeys.category_key: selectedHomeMadeCategory.value!.slugId,
            // ApiKeys.category_id: selectedHomeMadeCategory.value?.slugId ?? '',
        },
        if(brandController.text.trim().isNotEmpty) ApiKeys.brand: brandController.text.trim(),
        if(productWarrantyController.text.trim().isNotEmpty) ApiKeys.productWarranty: productWarrantyController.text.trim(),
        if(mrpController.text.trim().isNotEmpty) ApiKeys.mrpPerUnit: mrpController.text.trim(),
        if(productExpiryDurationController.text.trim().isNotEmpty) ApiKeys.expiryDuration: productExpiryDurationController.text.trim(),
        // if (tags.isNotEmpty) ApiKeys.tags: tags,
        if(tags.isNotEmpty) ApiKeys.tags: jsonEncode(tags),
        if(detailsList.isNotEmpty) ApiKeys.addMoreDetails: jsonEncode(detailsList.map((e) => e.toJson()).toList()),
        if(featureControllers.isNotEmpty) ApiKeys.addProductFeatures: jsonEncode(featureControllers
            .where((c) => c.text.trim().isNotEmpty)
            .map((c) => {ApiKeys.title: c.text.trim()})
            .toList()),
        if(linkController.text.trim().isNotEmpty) ApiKeys.linkOrReferealWebsite: linkController.text.trim(),
        if (userGuideLineControllers.isNotEmpty)
        ApiKeys.guideLine: jsonEncode(userGuideLineControllers.map((value) => value.text).toList()),
        ApiKeys.providerType: providerType.title
      };

      if (aiVariantData.isNotEmpty) {
        // Send the full per-variant objects exactly as generated by the AI
        // (variantName, value, attributes, unit, quantity, pricing,
        // weight, dimensions, specification, isActive).
        params[ApiKeys.variantData] =
            jsonEncode(aiVariantData.map((v) => v.toJson()).toList());
      } else {
        // Fallback (no AI variants): `variantData` must be an ARRAY of variant
        // objects, so build it from the selected attribute axes via the
        // Cartesian-product builder instead of a grouped attribute map.
        params[ApiKeys.variantData] = jsonEncode(
          _buildVariantDataPayload(
            allColors: selectedColors.toList(),
            allDynamicAttributes:
                dynamicAttributes.map((k, v) => MapEntry(k, v.toList())),
          ),
        );
      }

      if(providerType == ProviderType.channel){
        params[ApiKeys.channelId] = id;
      }

      List<dio.MultipartFile> imageByPart = [];

      for (final path in addProductViaAiController.step2Images) {
        final fileName = path.split('/').last;
        final imageInfo = getFileInfo(File(path));
        final mimeType = imageInfo['mimeType'];
        imageByPart.add(
            await dio.MultipartFile.fromFile(
              path,
              filename: fileName,
              contentType: MediaType.parse(mimeType ?? 'application/octet-stream'),
            ));
      }
      params[ApiKeys.productImages] = imageByPart;

      final responseModel = await ManufacturerProductRepo().createProductViaAiApi(params: params);
      // `message` is dynamic and is null for the success (201) response, so
      // only show a snackbar when the API actually returned a message.
      final responseMsg = responseModel.message;
      if (responseMsg is String && responseMsg.trim().isNotEmpty) {
        commonSnackBar(message: responseMsg);
      }
      if (responseModel.isSuccess) {
        createProductResponse.value = ApiResponse.complete(responseModel);

        // Response shape: { product: {...}, variants: [...] }. Fall back to the
        // older { data: {...} } / bare-object shapes just in case.
        final resData = responseModel.response?.data;
        productId = (resData is Map
                ? (resData['product']?['_id'] ??
                    resData['data']?['_id'] ??
                    resData['_id'])
                : null)
            ?.toString();
        ManufacturerProductPreviewArgs productPreviewArgs = mapOwnProductToPreviewArgs();
        Get.toNamed(
          RouteHelper.getManufacturerProductPreviewScreenRoute(),
          arguments: {
              ApiKeys.isFromProductCreation: true,
              ApiKeys.argProductData: productPreviewArgs,
              ApiKeys.id: id,
              ApiKeys.providerType: providerType
          },

        );

      } else {
        createProductResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print('stack trace-- $s');
      createProductResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isCreateProductLoading.value = false;
    }
  }

  ManufacturerProductPreviewArgs mapOwnProductToPreviewArgs() {
    // if (src == null) return const ManufacturerProductPreviewArgs(productId: '');

    return ManufacturerProductPreviewArgs(
      productId: productId ?? '',
      media: step2Images.toList(),
      name: productNameController.text.trim(),
      description: productDescriptionController.text.trim(),
      tags: tags,
      features: featureControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      link: linkController.text.trim(),
      details: detailsList
          .map((d) => ManufacturerDetailPair(d.title, d.details))
          .toList(),
      MRPPrice: mrpController.text.trim(),
      warranty: productWarrantyController.text.trim(),
      expiry: productExpiryDurationController.text.trim(),
      userGuide: userGuideLineControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      selectedColors: selectedColors.toList(),
      dynamicAttributes: dynamicAttributes.map(
            (k, v) => MapEntry(k, v.toList()), // convert RxList -> List
      ),
    );
  }

  var isAddProductToInventoryLoading = false.obs;

  Future<void> addProductToInventory(
      {
        required String id,
        required ProviderType providerType,
        required ManufacturerProductController addProductViaAiController,
        required List<ManufacturerProductListing> products
      }) async {
    isAddProductToInventoryLoading.value = true;
    try {
      // pincode / city come from the user's current location.
      final pincode = LocationService.userCurrentAddress.value.postalCode;
      final cityName = LocationService.userCurrentAddress.value.city;

      // The composed listings are attribute combinations that don't exist as
      // stored variants yet (variants are created per single attribute). So
      // first create each composition as a real variant (full attributes +
      // price), then resolve their server ids from a fresh fetch.
      final comboVariantData = products.map((p) {
        final attrs = _attrsForRequest(p.selectedVariants ?? {});
        return {
          'variantName': p.name,
          'value': _comboValueLabel(p.selectedVariants ?? {}),
          ApiKeys.attributes: attrs,
          'pricing': [
            {
              ApiKeys.mrp: int.tryParse(p.mrp ?? '0') ?? 0,
              ApiKeys.sellingPrice: int.tryParse(p.price ?? '0') ?? 0,
              'currency': 'INR',
            }
          ],
          'isActive': true,
        };
      }).toList();

      if (comboVariantData.isNotEmpty) {
        final createRes =
            await ManufacturerProductRepo().addUpdateProductVariantApi(
          params: {ApiKeys.variantData: comboVariantData},
          productId: productId ?? '',
        );
        if (!createRes.isSuccess) {
          commonSnackBar(message: createRes.message);
          addProductToInventoryResponse.value = ApiResponse.error('error');
          return;
        }
      }

      // Refetch so the just-created combination variants (with ids) are present.
      await fetchSingleProductDataApi(productId: productId ?? '');
      final serverVariants = singleProductData.value?.variants ?? const [];

      // One inventory entry per variant, with a single minimal batch.
      final payload = <Map<String, dynamic>>[];
      for (final product in products) {
        final variantId =
            _resolveServerVariantId(product.selectedVariants, serverVariants);
        if (variantId.isEmpty) {
          log('addProductToInventory: no server variant matched for '
              '${product.selectedVariants}');
          continue;
        }
        payload.add({
          ApiKeys.productVariant: variantId,
          ApiKeys.ownerType: providerType.title,
          ApiKeys.pincode: pincode,
          ApiKeys.cityName: cityName,
          ApiKeys.batches: [
            {
              ApiKeys.quantity: '1',
              ApiKeys.mrp: int.tryParse(product.mrp ?? '0') ?? 0,
              ApiKeys.sellingPrice: int.tryParse(product.price ?? '0') ?? 0,
            }
          ],
        });
      }

      if (payload.isEmpty) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        addProductToInventoryResponse.value = ApiResponse.error('error');
        return;
      }

      final responseModel =
          await ManufacturerProductRepo().addProductToInventoryApi(params: payload);
      if (responseModel.isSuccess) {
        addProductToInventoryResponse.value = ApiResponse.complete(responseModel);
        // Flag the catalog for refresh so the manufacturer Products tab
        // re-fetches and shows the just-published product when we land on it.
        if (Get.isRegistered<ManufacturerInventoryController>()) {
          Get.find<ManufacturerInventoryController>().productDataNeedsRefresh =
              true;
        }
        if(providerType == ProviderType.business){
          navigateToInventorySectionAfterAddProduct();
        }else if(providerType == ProviderType.user){
          navigateToEarnWithBlueEraSectionAfterAddProduct();
        }else if(providerType == ProviderType.channel){
          navigateToChannelSectionAfterAddProduct();
        }

      } else {
        commonSnackBar(message: responseModel.message);
        addProductToInventoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      addProductToInventoryResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isAddProductToInventoryLoading.value = false;
    }
  }

  /// Normalises an attributes map to `key → string value`, flattening colors
  /// to their name so a composed listing and a server variant can be compared
  /// on equal footing.
  Map<String, String> _normalizeAttrs(Map<String, dynamic> attrs) {
    final out = <String, String>{};
    attrs.forEach((k, v) {
      if (v == null) return;
      final String value;
      if (v is ManufacturerSelectedColor) {
        value = v.name;
      } else if (v is Map) {
        value = (v['color_name'] ?? v['value'] ?? v.toString()).toString();
      } else {
        value = v.toString();
      }
      out[k.trim().toLowerCase()] = value.trim().toLowerCase();
    });
    return out;
  }

  /// Converts a selected-attributes map into a JSON-safe map for the variant
  /// request (colors become `{color_name, color_code}`).
  Map<String, dynamic> _attrsForRequest(Map<String, dynamic> selected) {
    final out = <String, dynamic>{};
    selected.forEach((k, v) {
      if (v == null) return;
      if (v is ManufacturerSelectedColor) {
        out[k] = {'color_name': v.name, 'color_code': colorToHex(v.color)};
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  /// Human label for a composed combination (e.g. "60g / Good day").
  String _comboValueLabel(Map<String, dynamic> selected) {
    return selected.values
        .map((v) => v is ManufacturerSelectedColor
            ? v.name
            : (v is Map
                ? (v['color_name'] ?? v['value'] ?? v.toString()).toString()
                : v.toString()))
        .where((s) => s.isNotEmpty)
        .join(' / ');
  }

  /// Finds the server variant `id` whose attributes match the [selected]
  /// combination — exact match first, then a looser "server contains all
  /// selected" match. Returns '' when nothing matches.
  String _resolveServerVariantId(
      Map<String, dynamic>? selected, List<dynamic> variants) {
    if (selected == null || selected.isEmpty) return '';
    final sel = _normalizeAttrs(selected);

    for (final v in variants) {
      final va =
          _normalizeAttrs(Map<String, dynamic>.from(v.attributesMap as Map));
      if (va.length == sel.length &&
          sel.entries.every((e) => va[e.key] == e.value)) {
        return v.id as String;
      }
    }
    for (final v in variants) {
      final va =
          _normalizeAttrs(Map<String, dynamic>.from(v.attributesMap as Map));
      if (sel.entries.every((e) => va[e.key] == e.value)) {
        return v.id as String;
      }
    }
    return '';
  }

  /// Builds the `variantData` array from the current attribute selections.
  /// Every combination of color × each dynamic-attribute value becomes one
  /// variant. Pricing / unit / weight / dimensions / specification are taken
  /// from a matching AI variant when one exists, otherwise from the first AI
  /// variant used as a template.
  List<Map<String, dynamic>> _buildVariantDataPayload({
    required List<ManufacturerSelectedColor> allColors,
    required Map<String, List<String>> allDynamicAttributes,
  }) {
    final axes = <MapEntry<String, List<dynamic>>>[];

    if (allColors.isNotEmpty) {
      axes.add(MapEntry('color', allColors.map((c) => c.toJson()).toList()));
    }
    allDynamicAttributes.forEach((key, values) {
      if (values.isNotEmpty) {
        axes.add(MapEntry(key, List<dynamic>.from(values)));
      }
    });

    if (axes.isEmpty) {
      return aiVariantData.map((v) => v.toJson()).toList();
    }

    var combos = <Map<String, dynamic>>[<String, dynamic>{}];
    for (final axis in axes) {
      final next = <Map<String, dynamic>>[];
      for (final combo in combos) {
        for (final value in axis.value) {
          next.add({...combo, axis.key: value});
        }
      }
      combos = next;
    }

    final template = aiVariantData.isNotEmpty ? aiVariantData.first : null;
    final productName = productNameController.text.trim();

    return combos.map((attrs) {
      AiVariantData? existing;
      for (final v in aiVariantData) {
        if (_attributesMatch(v.attributes, attrs)) {
          existing = v;
          break;
        }
      }
      final base = existing ?? template;

      final valueLabel = attrs.values
          .map((v) => v is Map
              ? (v['color_name'] ?? v['value'] ?? '').toString()
              : v.toString())
          .where((s) => s.isNotEmpty)
          .join(' / ');

      return AiVariantData(
        variantName:
            productName.isNotEmpty ? '$productName / $valueLabel' : valueLabel,
        value: valueLabel,
        attributes: attrs,
        unit: base?.unit,
        quantity: base?.quantity,
        pricing: base?.pricing ?? const [],
        weight: base?.weight,
        dimensions: base?.dimensions,
        specification: base?.specification ?? const {},
        isActive: true,
      ).toJson();
    }).toList();
  }

  /// True when [a] and [b] hold the same attribute keys and (stringified)
  /// values.
  bool _attributesMatch(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key].toString() != entry.value.toString()) return false;
    }
    return true;
  }

  void navigateToInventorySectionAfterAddProduct() {

    Get.until((route) {
      print("🔍 Scanning route → ${route.settings.name}");

      // STOP at the manufacturer screen (so the user lands back on the
      // Products tab), else fall back to the bottom nav.
      if(route.settings.name == RouteHelper.getManufacturerScreenRoute()) return route.settings.name == RouteHelper.getManufacturerScreenRoute();
      else return route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute();
    });
  }

  Future<void> navigateToEarnWithBlueEraSectionAfterAddProduct() async {
    Get.until(
          (route) =>
      route.settings.name ==
          RouteHelper.getEarnServiceDashboardViewRoute(),
    );

    // if (userProfessionGlobal == BIKE_RIDER) {
    //   Get.until((route) => Get.currentRoute == RouteHelper.getGigWorkerOptionsScreenRoute());
    // } else {
    //   Get.until((route) => Get.currentRoute == RouteHelper.getSelfEmployeeScreenRoute());
    // }

  }

  void navigateToChannelSectionAfterAddProduct(){
    Get.until((route) => Get.currentRoute == RouteHelper.getChannelScreenRoute());
  }

  RxMap<String, dynamic> selectedVariantValues = <String, dynamic>{}.obs;
  RxBool isNextEnabled = false.obs;

  void selectVariantValue(String attributeKey, dynamic value) {
    if (attributeKey.toLowerCase() == 'color' && value is ManufacturerSelectedColor) {
      final colorMap = value.toJson();
      if (selectedVariantValues[attributeKey] != colorMap) {
        selectedVariantValues[attributeKey] = colorMap;
      } else {
        selectedVariantValues.remove(attributeKey);
      }
    } else {
      if (selectedVariantValues[attributeKey] == value) {
        selectedVariantValues.remove(attributeKey);
      } else {
        selectedVariantValues[attributeKey] = value.toString();
      }
    }
    _updateNextButtonState();
  }

  bool isValueSelected(String attributeKey, dynamic value) {
    final selected = selectedVariantValues[attributeKey];
    if (attributeKey.toLowerCase() == 'color' && value is ManufacturerSelectedColor) {
      if (selected is Map) {
        return selected['color_code'] == colorToHex(value.color)
            && selected['color_name'] == value.name;
      }
      return false;
    } else {
      return selectedVariantValues[attributeKey]?.toString() == value.toString();
    }
  }


  void _updateNextButtonState() {
    // Collect all existing keys dynamically
    final existingKeys = <String>[];
    if (selectedColors.isNotEmpty) existingKeys.add('color');
    existingKeys.addAll(dynamicAttributes.keys);

    // Enable Next only if each existing key has a selection
    isNextEnabled.value =
        existingKeys.isNotEmpty &&
            existingKeys.every((key) => selectedVariantValues.containsKey(key));
  }

  addProductsInListing({required ManufacturerProductListing productListing}) {
    // Make a deep copy of selectedVariants
    final copiedVariants = productListing.selectedVariants != null
        ? Map<String, dynamic>.from(productListing.selectedVariants!)
        : null;

    final newProductListing = ManufacturerProductListing(id: productListing.id,

      image: List<String>.from(productListing.image),
      name: productListing.name,
      selectedVariants: copiedVariants,
      price: productListing.price,
      mrp: productListing.mrp,
      discount: productListing.discount,
    );

    log('Selected variants -- ${newProductListing.selectedVariants}');

    listedProducts.add(newProductListing);
    listedProducts.refresh();

    log('All listed products variants:');
    for (var p in listedProducts) {
      log('ManufacturerProduct: ${p.name}, Variants: ${p.selectedVariants}');
    }
  }

  var isAddUpdateProductVariantLoading = false.obs;

  Future<bool> addUpdateProductVariantApi({
    required List<ManufacturerSelectedColor> allColors,
    required Map<String, List<String>> allDynamicAttributes,
  }) async {
    isAddUpdateProductVariantLoading.value = true;

    try {
      // Body wraps the full per-variant array under `variantData`; productId
      // goes in the URL, not the body. The array is built dynamically from the
      // current attribute selections (color + dynamic attributes).
      final params = {
        ApiKeys.variantData: _buildVariantDataPayload(
          allColors: allColors,
          allDynamicAttributes: allDynamicAttributes,
        ),
      };

      final responseModel = await ManufacturerProductRepo()
          .addUpdateProductVariantApi(params: params, productId: productId ?? '');

      if (responseModel.isSuccess) {
        addUpdateProductVariantApiResponse.value =
            ApiResponse.complete(responseModel);
        return true;
      } else {
        commonSnackBar(message: responseModel.message);
        addUpdateProductVariantApiResponse.value =
            ApiResponse.error('error');
        return false;
      }
    } catch (e) {
      addUpdateProductVariantApiResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isAddUpdateProductVariantLoading.value = false;
    }
  }

  /// Creates new variants on the server for [attributeKey] — one minimal entry
  /// per added [values] (just the attribute key/value, nothing else). On
  /// success the product is refetched and the on-screen option axes are rebuilt
  /// from the API response, so the screen reflects the server (single source of
  /// truth).
  Future<bool> addAttributeVariantsApi({
    required String attributeKey,
    required List<String> values,
  }) async {
    if (values.isEmpty) return false;
    isAddUpdateProductVariantLoading.value = true;

    try {
      // Send only the property being added (e.g. {"Pack Size": "500g"}).
      final variantData = values
          .map((v) => {
                'attributes': {attributeKey: v},
              })
          .toList();

      final responseModel = await ManufacturerProductRepo().addUpdateProductVariantApi(
        params: {ApiKeys.variantData: variantData},
        productId: productId ?? '',
      );

      if (responseModel.isSuccess) {
        addUpdateProductVariantApiResponse.value =
            ApiResponse.complete(responseModel);
        // Pull the saved variants back from the API and rebuild the axes.
        await refreshVariantOptionsFromApi();
        return true;
      } else {
        commonSnackBar(message: responseModel.message);
        addUpdateProductVariantApiResponse.value = ApiResponse.error('error');
        return false;
      }
    } catch (e) {
      addUpdateProductVariantApiResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isAddUpdateProductVariantLoading.value = false;
    }
  }

  /// Creates color variants that carry BOTH the color name and its hex code as
  /// two attributes ([colorKey] → name, [colorCodeKey] → code) in a single
  /// variant entry. Other attributes stay individual; colors are paired.
  Future<bool> addColorComboVariantApi({
    required String colorKey,
    required String colorCodeKey,
    required List<Map<String, String>> colors,
  }) async {
    if (colors.isEmpty) return false;
    isAddUpdateProductVariantLoading.value = true;

    try {
      final variantData = colors
          .map((c) => {
                'attributes': {
                  colorKey: c['name'],
                  colorCodeKey: c['code'],
                },
              })
          .toList();

      final responseModel =
          await ManufacturerProductRepo().addUpdateProductVariantApi(
        params: {ApiKeys.variantData: variantData},
        productId: productId ?? '',
      );

      if (responseModel.isSuccess) {
        addUpdateProductVariantApiResponse.value =
            ApiResponse.complete(responseModel);
        await refreshVariantOptionsFromApi();
        return true;
      } else {
        commonSnackBar(message: responseModel.message);
        addUpdateProductVariantApiResponse.value = ApiResponse.error('error');
        return false;
      }
    } catch (e) {
      addUpdateProductVariantApiResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isAddUpdateProductVariantLoading.value = false;
    }
  }

  /// Refetches the product and rebuilds [dynamicAttributes] / [selectedColors]
  /// from the server variants, making the API the single source of truth for
  /// what the create-variant screen shows.
  Future<void> refreshVariantOptionsFromApi() async {
    final id = productId;
    if (id == null || id.isEmpty) return;

    await fetchSingleProductDataApi(productId: id);
    final variants = singleProductData.value?.variants ?? const [];
    if (variants.isEmpty) return;

    final Map<String, List<String>> rebuiltAttrs = {};
    final List<ManufacturerSelectedColor> rebuiltColors = [];

    for (final v in variants) {
      v.attributesMap.forEach((key, value) {
        if (value == null) return;
        if (key.toLowerCase() == 'color' && value is Map) {
          final name = (value['color_name'] ?? '').toString();
          final code = (value['color_code'] ?? '#000000').toString();
          if (name.isNotEmpty && !rebuiltColors.any((c) => c.name == name)) {
            rebuiltColors.add(ManufacturerSelectedColor(hexToColor(code), name));
          }
        } else {
          final str = value.toString();
          if (str.isEmpty) return;
          final list = rebuiltAttrs.putIfAbsent(key, () => <String>[]);
          if (!list.contains(str)) list.add(str);
        }
      });
    }

    dynamicAttributes.assignAll({
      for (final e in rebuiltAttrs.entries) e.key: e.value.obs,
    });
    selectedColors.assignAll(rebuiltColors);
    dynamicAttributes.refresh();
    selectedColors.refresh();
  }

  RxBool isSingleProductLoading = false.obs;
  Rxn<ManufacturerSingleProductData> singleProductData = Rxn<ManufacturerSingleProductData>();

  Future<void> fetchSingleProductDataApi({required String productId}) async {
    try {
      isSingleProductLoading.value = true;

      final response = await ManufacturerProductRepo().fetchSingleProductApi(productId: productId);
      if (response.isSuccess) {
        singleProductDetailsResponse.value = ApiResponse.complete(response);
        final singleProductModel = ManufacturerSingleProductModel.fromJson(response.response!.data);
        singleProductData.value = singleProductModel.data;
      } else {
        print("API failed with status: ${response.statusCode}");
        singleProductDetailsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
    } finally {
      isSingleProductLoading.value = false;
      singleProductDetailsResponse.value = ApiResponse.error('error');
    }
  }

  /// Fetch ManufacturerProduct Nested Categories
  RxList<ProductNestedCategoryResponse> productsNestedCategoryList = <ProductNestedCategoryResponse>[].obs;

  Future<void> fetchProductsNestedCategory({String? groceryCatKey}) async {
    try {
      nestedProductCategoryResponse.value = ApiResponse.initial('Initial');
      productsNestedCategoryList.clear();

      // Cache-first for the top-level (no category key) fetch. Nested
      // sub-levels (groceryCatKey != null) always hit the network.
      if (groceryCatKey == null) {
        final cached = HiveServices().getProductNestedCategories();
        if (cached != null && cached.isNotEmpty) {
          productsNestedCategoryList.assignAll(cached);
          nestedProductCategoryResponse.value = ApiResponse.complete();
          return;
        }
      }

      Map<String, dynamic> queryParams = {};
      if(groceryCatKey!=null) queryParams[ApiKeys.categoryKey] = groceryCatKey;

      ResponseModel responseModel = await ManufacturerProductRepo().productNestedCategoryRepo(
          queryParams: queryParams
      );
      if (responseModel.isSuccess) {
        nestedProductCategoryResponse.value = ApiResponse.complete(responseModel);
        productsNestedCategoryList.value = (responseModel.response?.data ?? [])
            .map<ProductNestedCategoryResponse>((e) => ProductNestedCategoryResponse.fromJson(e))
            .toList();
        if (groceryCatKey == null && productsNestedCategoryList.isNotEmpty) {
          await HiveServices()
              .saveProductNestedCategories(productsNestedCategoryList);
        }
      } else {
        nestedProductCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      log('stack trace -- $s');
      nestedProductCategoryResponse.value = ApiResponse.error('error');
    }
  }

  // ── Owner Info (set from route arguments) ─────────────────────────────
  String? ownerID;
  ProviderType? ownerProviderType;

  // ── Inventory ManufacturerProduct Search by Category ─────────────────────────────
  RxList<ManufacturerSelectedVariant> inventoryProductList = <ManufacturerSelectedVariant>[].obs;
  RxBool isInventoryProductFirstLoading = false.obs;
  RxBool isInventoryProductLoadingMore = false.obs;
  int inventoryProductPage = 1;
  bool inventoryProductHasMore = true;

  Future<void> fetchInventoryProducts({
    required String categoryId,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isInventoryProductLoadingMore.value || !inventoryProductHasMore) return;
      isInventoryProductLoadingMore.value = true;
    } else {
      isInventoryProductFirstLoading.value = true;
      inventoryProductPage = 1;
      inventoryProductHasMore = true;
      inventoryProductList.clear();
    }

    try {
      const int limit = 20;
      final Map<String, dynamic> params = {
        ApiKeys.categoryId: categoryId,
        ApiKeys.page: inventoryProductPage,
        ApiKeys.limit: limit,
      };

      final responseModel = await ManufacturerProductRepo()
          .fetchSearchProductViaCategoryRepo(queryParams: params);

      if (responseModel.isSuccess) {
        final response = ManufacturerProductCatalogResponse.fromJson(
          responseModel.response?.data,
        );
        final newData = flattenProducts(response.data);

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            inventoryProductList.addAll(newData);
          } else {
            inventoryProductList.assignAll(newData);
          }
          inventoryProductPage++;
        } else {
          inventoryProductHasMore = false;
        }
      } else {
        inventoryProductHasMore = false;
      }
    } catch (e, s) {
      log('fetchInventoryProducts error: $s');
    } finally {
      if (isLoadMore) {
        isInventoryProductLoadingMore.value = false;
      } else {
        isInventoryProductFirstLoading.value = false;
      }
    }
  }

  // ── ManufacturerProduct Selection (Cart) ─────────────────────────────────────────
  RxList<ManufacturerSelectedVariant> selectedProducts = <ManufacturerSelectedVariant>[].obs;
  int productMaxLimit = 10;

  bool get isProductMaxLimitHit => selectedProducts.length >= productMaxLimit;

  void toggleProductSelection(ManufacturerSelectedVariant product) {
    final index =
        selectedProducts.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      selectedProducts.removeAt(index);
    } else {
      if (isProductMaxLimitHit) {
        commonSnackBar(
            message: 'You can\'t select more than $productMaxLimit products at a time.');
        return;
      }
      selectedProducts.add(product);
    }
  }

  bool isProductSelected(String variantId) {
    return selectedProducts.any((p) => p.id == variantId);
  }
}