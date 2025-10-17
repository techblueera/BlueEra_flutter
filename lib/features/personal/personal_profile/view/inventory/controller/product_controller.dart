import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart' hide MediaType;
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/store/repo/product_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/generate_ai_product_content.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/single_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product_preview_screen.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import '../model/sub_category_root_category_response.dart';

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

class ProductListing {
  final List<String> image;
  final String name;
  final String id;
  // final Map<String, String>? selectedVariants;
  final Map<String, dynamic>? selectedVariants;
  final String? price;
  final String? mrp;
  final String? discount;

  ProductListing({
    required this.image,
    required this.name,
    required this.id,
    this.selectedVariants,
    this.price,
    this.mrp,
    this.discount,
  });
}

class SelectedColor {
  final Color color;
  final String name;

  SelectedColor(this.color, this.name);

  factory SelectedColor.fromJson(Map<String, dynamic> json) {
    return SelectedColor(
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

class ProductMoreDetails {
  final String? title;
  final String? details;

  ProductMoreDetails({this.title, this.details});

  factory ProductMoreDetails.fromJson(Map<String, dynamic> json) => ProductMoreDetails(
    title: json['title'],
    details: json['details'],
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'details': details,
  };
}

class ProductController extends GetxController{
  Rx<ApiResponse> generateAiProductContentResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSubChildORRootCategoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> searchProductCategoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addProductToInventoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addUpdateProductVariantApiResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> singleProductDetailsResponse = ApiResponse.initial('Initial').obs;

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

  RxList<SelectedColor> selectedColors = <SelectedColor>[].obs;

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

  final RxList<ProductMoreDetails> detailsList = <ProductMoreDetails>[].obs;

  String? productId;

  final selectedCategory = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  final RxBool showLinkField = false.obs;
  RxInt selectedVariantIndex = (-1).obs;

  final RxList<ProductListing> listedProducts = <ProductListing>[].obs;

  final String otherCategoryId = '68d4e332455cad1af87fac05';

  RxString selectedProductOrVariantPrice = '00,000'.obs;
  RxString selectedProductOrVariantDiscount = '0'.obs;
  RxString selectedProductOrVariantMrp = '00,000'.obs;

  /// Images used on Step 2 (second screen, preloaded + new)
  RxList<String> allProductImages = <String>[].obs;

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
      selectedColors.add(SelectedColor(color, name));
    }
  }

  void removeColor(SelectedColor selectedColor) {
    selectedColors.remove(selectedColor);
  }

  void addDetail(ProductMoreDetails detail) {
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
    final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
      context,
      'Product Image',
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
      final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
        context,
        'Product Image',
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

  void onGenerate(ProductController addProductViaAiController, String id, ProductServiceProviderType providerType) async {
    if (!_validate()) return;

    isLoading.value = true;

    final request = AddProductViaAiRequest(
      productName: productNameStep1Controller.text.trim(),
      productDescription: productDescriptionStep1Controller.text.trim(),
      // category: Get.find<ManualListingScreenController>()
      //     .selectedBreadcrumb
      //     .value
      //     ?.map((p) => p.name)
      //     .join(" > "), // no brackets, proper string
      images: step1Images.toList(),
    );

    await createProductViaAiApi(request, addProductViaAiController, id, providerType);

    isLoading.value = false;

  }

  bool _validate() {
    if(step1Images.length < 1) {
      commonSnackBar(message: 'Please take minimum one product images');
      return false;
    }

    if(!formKey.currentState!.validate()) return false;

    return true;
  }


  Future<void> createProductViaAiApi(AddProductViaAiRequest request, ProductController addProductViaAiController, String id, ProductServiceProviderType providerType) async {
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
            ApiKeys.controller: addProductViaAiController,
            ApiKeys.generateAiProductContent: generateAiProductContent,
            ApiKeys.id: id,
            ApiKeys.providerType: providerType
          },
        );
      } else {
        commonSnackBar(message: responseModel.message ?? 'something went wrong.');
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

      final responseModel = await ProductRepo().searchCategoryOfProduct(queryParams: params);
      if (responseModel.isSuccess) {
        searchProductCategoryResponse.value = ApiResponse.complete(responseModel);
        final subChildORRootCategoryResponse = SubChildORRootCategoryResponse.fromJson(responseModel.response!.data);
        List<CategoryData> categoryData = subChildORRootCategoryResponse.data??[];

        searchResults.clear();
        searchResults.assignAll(categoryData);

        /// set initially category id (If user didn't choose category itSelf)
        if(searchResults.isNotEmpty){
          selectedCategoryId.value = searchResults[0].sId??'';
        }
        else{
          selectedCategoryId.value = otherCategoryId;
        }
        log('category id--> $selectedCategoryId');
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

  Future<void> createProductViaAi(ProductController addProductViaAiController, String id, ProductServiceProviderType providerType) async {
    isCreateProductLoading.value = true;
    try {
      Map<String, dynamic> params = {
        if(productNameController.text.trim().isNotEmpty) ApiKeys.name: productNameController.text.trim(),
        if(productDescriptionController.text.trim().isNotEmpty) ApiKeys.description: productDescriptionController.text.trim(),
        ApiKeys.categoryId: selectedCategoryId,
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

      final payload = <String, dynamic>{
          // color list
          if (selectedColors.isNotEmpty)
            'color': selectedColors.map((c) => c.toJson()).toList(),

          // flatten every entry of dynamicAttributes into this same map
          ...dynamicAttributes.map(
                (k, v) => MapEntry(
              k,
              v.map((e) => {'properties': e.toString()}).toList(),
            ),
          ),
        };
      params[ApiKeys.options] = jsonEncode(payload);

      if(providerType == ProductServiceProviderType.channel){
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
      params[ApiKeys.media] = imageByPart;

      final responseModel = await ProductRepo().createProductViaAiApi(params: params);
      commonSnackBar(message: responseModel.message);
      if (responseModel.isSuccess) {
        createProductResponse.value = ApiResponse.complete(responseModel);
        // productId = responseModel.response?.data['data']['_id'];
        // Get.toNamed(
        //   RouteHelper.getProductPreviewScreenRoute(),
        // );

        productId = responseModel.response?.data['data']['_id'];
        ProductPreviewArgs productPreviewArgs = mapOwnProductToPreviewArgs();
        Get.toNamed(
          RouteHelper.getProductPreviewScreenRoute(),
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
      commonSnackBar(message: 'something went wrong.');
    } finally {
      isCreateProductLoading.value = false;
    }
  }

  ProductPreviewArgs mapOwnProductToPreviewArgs() {
    // if (src == null) return const ProductPreviewArgs(productId: '');

    return ProductPreviewArgs(
      productId: productId ?? '',
      media: step2Images.toList(),
      name: productNameController.text.trim(),
      description: productDescriptionController.text.trim(),
      tags: tags,
      features: featureControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      link: linkController.text.trim(),
      details: detailsList
          .map((d) => DetailPair(d.title, d.details))
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
        required ProductServiceProviderType providerType,
        required ProductController addProductViaAiController,
        required List<ProductListing> products
      }) async {
    isAddProductToInventoryLoading.value = true;
    try {

      final payload =
        products.map((product) {
          return {
            ApiKeys.attributes: product.selectedVariants ?? {},
            // "stock": true,
            ApiKeys.sellingPrice: int.tryParse(product.price ?? '0') ?? 0,
            ApiKeys.mrp: int.tryParse(product.mrp ?? '0') ?? 0,
          };
        }).toList();
      Map<String, dynamic> params = {
        ApiKeys.productId: productId,
        ApiKeys.owner: jsonEncode({
          ApiKeys.id: id,
          ApiKeys.type: providerType.title
        }),
        ApiKeys.variants: jsonEncode(payload)
      };

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final List<dio.MultipartFile> imageByPart = [];

        for (final path in product.image) {
          final fileName = path.split('/').last;
          imageByPart.add(
            await dio.MultipartFile.fromFile(
              path,
              filename: fileName,
            ),
          );
        }

        params['variant${i}_files'] = imageByPart;
      }

      final responseModel = await ProductRepo().addProductToInventoryApi(params: params);
      if (responseModel.isSuccess) {
        addProductToInventoryResponse.value = ApiResponse.complete(responseModel);
        if(providerType == ProductServiceProviderType.business){
          bool navigated = false;
          Get.until((route) {
            if (route.settings.name == RouteHelper.getInventoryScreenRoute()) {
              navigated = true;
            }
            return navigated;
          });

          if (!navigated) {
            Get.until((route) => Get.currentRoute == RouteHelper.getBottomNavigationBarScreenRoute());
            Get.toNamed(RouteHelper.getInventoryScreenRoute());
          }
        }else if(providerType == ProductServiceProviderType.user){
          Get.until((route) => Get.currentRoute == RouteHelper.getEarnWithBlueEraNewScreenRoute());
        }else if(providerType == ProductServiceProviderType.channel){
          Get.until((route) => Get.currentRoute == RouteHelper.getChannelScreenRoute());
        }

      } else {
        commonSnackBar(message: responseModel.message);
        addProductToInventoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      addProductToInventoryResponse.value = ApiResponse.error('error');
      commonSnackBar(message: 'something went wrong.');
    } finally {
      isAddProductToInventoryLoading.value = false;
    }
  }

  RxMap<String, dynamic> selectedVariantValues = <String, dynamic>{}.obs;
  RxBool isNextEnabled = false.obs;

  void selectVariantValue(String attributeKey, dynamic value) {
    if (attributeKey.toLowerCase() == 'color' && value is SelectedColor) {
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
    if (attributeKey.toLowerCase() == 'color' && value is SelectedColor) {
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

  addProductsInListing({required ProductListing productListing}) {
    // Make a deep copy of selectedVariants
    final copiedVariants = productListing.selectedVariants != null
        ? Map<String, dynamic>.from(productListing.selectedVariants!)
        : null;

    final newProductListing = ProductListing(id: productListing.id,

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
      log('Product: ${p.name}, Variants: ${p.selectedVariants}');
    }
  }

  var isAddUpdateProductVariantLoading = false.obs;

  Future<bool> addUpdateProductVariantApi({
    required List<SelectedColor> allColors,
    required Map<String, List<String>> allDynamicAttributes,
  }) async {
    isAddUpdateProductVariantLoading.value = true;

    try {
      final payload = <String, dynamic>{
        ApiKeys.options: {
          // color list
          if (allColors.isNotEmpty)
            'color': allColors.map((c) => c.toJson()).toList(),

          // flatten every entry of dynamicAttributes into this same map
          ...allDynamicAttributes.map(
                (k, v) => MapEntry(
              k,
              v.map((e) => {'properties': e.toString()}).toList(),
            ),
          ),
        }
      };

      final params = {
        ApiKeys.productId: productId,
        ApiKeys.updateFields: jsonEncode(payload),
      };

      final responseModel = await ProductRepo()
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
      commonSnackBar(message: 'Something went wrong.');
      return false;
    } finally {
      isAddUpdateProductVariantLoading.value = false;
    }
  }

  RxBool isSingleProductLoading = false.obs;
  Rxn<SingleProductData> singleProductData = Rxn<SingleProductData>();

  Future<void> fetchSingleProductDataApi({required String productId}) async {
    try {
      isSingleProductLoading.value = true;

      final response = await ProductRepo().fetchSingleProductApi(productId: productId);
      if (response.isSuccess) {
        singleProductDetailsResponse.value = ApiResponse.complete(response);
        final singleProductModel = SingleProductModel.fromJson(response.response!.data);
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


}