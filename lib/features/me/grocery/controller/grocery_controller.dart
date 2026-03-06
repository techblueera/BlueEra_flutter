import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/model/children_of_grocery_category_response.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/model/my_grocery_products_reponse.dart';
import 'package:BlueEra/features/me/grocery/model/my_grocery_category_with_variants_model.dart';
import 'package:BlueEra/features/me/grocery/view/edit_grocery_varient_dialog.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_varient_dialog.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PriceResult {
  final String sellingRange;
  final String mrpRange;
  final String discountRange;

  PriceResult({
    required this.sellingRange,
    required this.mrpRange,
    required this.discountRange,
  });
}

class GroceryController extends GetxController {
  Rx<ApiResponse> groceryCategoryResponse =
    ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groceryCategoryOfChildrenResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createNewGroceryProductNewVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addGroceryProductVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyGroceryProductsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyGroceryCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchGroceryBusinessProductsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> grocerySnapSearchResponse =
      ApiResponse.initial('Initial').obs;

  final selectedGroceryData = Rxn<GroceryNestedCategoryModel>();

  RxList<GroceryProductData> selectedGroceries = <GroceryProductData>[].obs;

  RxInt selectedHorizontalTabIndex = 0.obs;
  String get currentTabKey =>
      selectedHorizontalTabIndex.value == 0
          ? (selectedGroceryData.value?.key ?? '')
          : arrChildrenOfGroceryCategory[selectedHorizontalTabIndex.value - 1].key ?? '';

  int maxLimit = 10;

  bool get isMaxLimitHit => selectedGroceries.length == maxLimit;

  Map<String, List<VariantsData>> selectedProductVariants = {};

  Rx<OnboardingCategoryModel?> selectedGroceryCategoryData = Rx<OnboardingCategoryModel?>(null);

  final RxList<File> grocerySnapSearchImages = <File>[].obs;
  Rxn<ProductSnapSearchData> productSnapSearchData = Rxn<ProductSnapSearchData>();
  // RxList<FoundProducts> groceryFoundProducts = <FoundProducts>[].obs;
  List<String> grocerySnapSearchPhotos = [
    AppImageAssets.groceryImageFirst,
    AppImageAssets.groceryImageSecond,
    AppImageAssets.groceryImageThird,
    AppImageAssets.groceryImageFourth
  ];
  int maxUploadImages = 4;

  void toggleSelection(GroceryProductData p) {
    if (selectedGroceries.contains(p)) {
      selectedGroceries.remove(p);
    } else {
      if (selectedGroceries.length >= 10) {
        commonSnackBar(
            message: 'You can’t select more than 10 products at a time.');
        return;
      }
      selectedGroceries.add(p);
    }
  }

  void toggleVariant(String productId, VariantsData variant) {
    selectedProductVariants.putIfAbsent(productId, () => []);

    final selectedList = selectedProductVariants[productId]!;

    // Check if variant already exists (compare by sId)
    final exists = selectedList.any((v) => v.sId == variant.sId);

    if (exists) {
      // REMOVE variant
      selectedList.removeWhere((v) => v.sId == variant.sId);
    } else {
      // ADD variant
      selectedList.add(variant);
    }

    update(); // refresh UI
  }

  bool isVariantSelected(String productId, String variantId) {
    return selectedProductVariants[productId]?.any((v) => v.sId == variantId) ??
        false;
  }

  bool get canSubmitProducts {
    for (final p in selectedGroceries) {
      final variants = selectedProductVariants[p.sId];

      // If no entry OR empty variants list → invalid
      if (variants == null || variants.isEmpty) {
        return false;
      }
    }
    return true;
  }

  PriceResult getPriceDetails(List<Pricing>? v) {
    final pricingList = v;

    if (pricingList==null) {
      return PriceResult(
        sellingRange: "0",
        mrpRange: "0",
        discountRange: "0%",
      );
    }

    // Safely map → remove null → convert to double
    final sellingPrices = pricingList
        .map((e) => e.sellingPrice)
        .where((p) => p != null)
        .map((p) => p!.toDouble())
        .toList();

    final mrpPrices = pricingList
        .map((e) => e.mrp)
        .where((p) => p != null)
        .map((p) => p!.toDouble())
        .toList();

    if (sellingPrices.isEmpty || mrpPrices.isEmpty) {
      return PriceResult(
        sellingRange: "0",
        mrpRange: "0",
        discountRange: "0%",
      );
    }

    // Find MIN/MAX
    final minSelling = sellingPrices.reduce((a, b) => a < b ? a : b);
    final maxSelling = sellingPrices.reduce((a, b) => a > b ? a : b);

    final minMrp = mrpPrices.reduce((a, b) => a < b ? a : b);
    final maxMrp = mrpPrices.reduce((a, b) => a > b ? a : b);

    // Discount %
    double discount(num mrp, num selling) {
      if (mrp == 0) return 0;
      final d = ((mrp - selling) / mrp) * 100;
      return d < 0 ? 0 : d;
    }

    final minDiscount = discount(minMrp, minSelling);
    final maxDiscount = discount(maxMrp, maxSelling);

    // Format ranges
    final sellingRange = minSelling == maxSelling
        ? "₹$minSelling"
        : "₹$minSelling - ₹$maxSelling";

    final mrpRange = minMrp == maxMrp ? "₹$minMrp" : "₹$minMrp - ₹$maxMrp";

    final discountRange = minDiscount == maxDiscount
        ? "${minDiscount.toStringAsFixed(0)}% ${AppStrings.offCaps.tr}"
        : "${minDiscount.toStringAsFixed(0)}% - ${maxDiscount.toStringAsFixed(0)}% ${AppStrings.offCaps.tr}";

    return PriceResult(
      sellingRange: sellingRange,
      mrpRange: mrpRange,
      discountRange: discountRange,
    );
  }

  void openEditVariantDialog({
    required BuildContext context,
    required String title,
    required VariantsData variant,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return EditGroceryVarientDialog(
          title: title,
          mrp: variant.pricing?[0].mrp?.toString() ?? "",
          selling: variant.pricing?[0].sellingPrice?.toString() ?? "",
          onSubmit: (mrp, sellingPrice) {
            variant.pricing?[0].mrp = int.tryParse(mrp);
            variant.pricing?[0].sellingPrice = int.tryParse(sellingPrice);
            update();
            Get.back();
          },
        );
      },
    );
  }

  void openAddVariantDialog({
    required BuildContext context,
    required GroceryProductData groceryItem,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isCreateNewGroceryProductNewVariantLoading.value,
      builder: (_) {
        return GroceryVariantDialog(
          title: "Add More Variant",
          onSubmit: (weight, unit, mrp, sellingPrice) {
            createNewGroceryProductNewVariant(
                groceryItem: groceryItem,
                productId: groceryItem.sId ?? '',
                weight: weight,
                unit: unit,
                mrp: mrp,
                sellingPrice: sellingPrice);
          },
          isAddGroceryProductNewVariantLoading: isCreateNewGroceryProductNewVariantLoading.value,
        );
      },
    );
  }

  /// Pick and add images
  Future<void> addImages() async {
    final selectedImages = await pickImages('Shop Product Photos');
    if (selectedImages == null || selectedImages.isEmpty) return;

    final newFiles = selectedImages.map((e) => File(e)).toList();
    final remaining = maxUploadImages - grocerySnapSearchImages.length;
    if (remaining <= 0) {
      commonSnackBar(
          message:
          '${AppStrings.youCanOnlyUpload.tr} $maxUploadImages ${AppStrings.images.tr}');
      return;
    }

    grocerySnapSearchImages.addAll(newFiles.take(remaining));
  }

  Future<List<String>?> pickImages(String title) async {
    final List<String>? selected =
    await SelectProductImageDialog.showLogoDialog(Get.context!, title);
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }
    return null;
  }

  /// Remove image
  void removeImageAt({
    required int index,
  }) {
    if (index >= 0 && index < grocerySnapSearchImages.length) {
      grocerySnapSearchImages.removeAt(index);
    }
  }

  RxBool isInitialLoading = false.obs;
  Future<void> fetchBoth() async {
    try {
      isInitialLoading.value = true;
      await Future.wait([
        fetchChildrenOfGroceryCategory(),
        fetchGroceryCategoryProducts(),
      ]);
     } catch (e) {
    } finally {
      isInitialLoading.value = false;
    }
  }

  RxBool isGroceryCategoryOfChildrenLoading = false.obs;
  RxList<ChildrenOfGroceryCategoryResponse> arrChildrenOfGroceryCategory =
      <ChildrenOfGroceryCategoryResponse>[].obs;

  Future<void> fetchChildrenOfGroceryCategory() async {
    try {

      isGroceryCategoryOfChildrenLoading.value = true;
      final response =
      await GroceryRepo().groceryCategoryOfChildrenRepo(key: currentTabKey);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      arrChildrenOfGroceryCategory.value =
          ChildrenOfGroceryCategoryResponse.fromJsonList(jsonData);
      groceryCategoryOfChildrenResponse.value = ApiResponse.complete(response);
      update();
    } catch (e) {
      groceryCategoryOfChildrenResponse.value = ApiResponse.error('error');
      update();
    } finally {
      isGroceryCategoryOfChildrenLoading.value = false;
    }
  }

  RxBool isGroceryCategoryProductsLoading = false.obs;
  RxList<GroceryProductData> arrGroceryCategoryProducts = <GroceryProductData>[].obs;
  RxBool isGroceryCategoryProductsLoadingMore = false.obs;
  int groceryCategoryProductsPage = 1;
  bool groceryCategoryProductsHasMore = true;

  Future<void> fetchGroceryCategoryProducts({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        // if (isGroceryCategoryProductsLoadingMore.value || !groceryCategoryProductsHasMore) return;
        isGroceryCategoryProductsLoadingMore.value = true;
      } else {
        arrGroceryCategoryProducts.clear();
        isGroceryCategoryProductsLoading.value = true;
        groceryCategoryProductsPage = 1;
        groceryCategoryProductsHasMore = true;
      }

      // log('current tab key-- $currentTabKey');
      Map<String, dynamic> queryParams = {
        ApiKeys.key: currentTabKey,
        ApiKeys.page: groceryCategoryProductsPage,
        ApiKeys.limit: pageLimit
      };

      final response = await GroceryRepo()
          .searchGroceryCategoryRepo(queryParam: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      groceryCategoryResponse.value = ApiResponse.complete(response);

      final groceryProductModel = GroceryProductModel.fromJson(response.response?.data);
      List<GroceryProductData> newItems = groceryProductModel.data ?? [];

      if (newItems.isNotEmpty) {
          if (isLoadMore) {
            arrGroceryCategoryProducts.addAll(newItems);
          } else {
            arrGroceryCategoryProducts.assignAll(newItems);
          }

          groceryCategoryProductsPage++;
      } else {
        groceryCategoryProductsHasMore = false;
      }

      log('total grocery-- ${arrGroceryCategoryProducts.length}');
      update();
    } catch (e, s) {
      groceryCategoryResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isGroceryCategoryProductsLoadingMore.value = false;
      } else {
        isGroceryCategoryProductsLoading.value = false;
      }
    }
  }

  RxBool isCreateNewGroceryProductNewVariantLoading = false.obs;
  Future<void> createNewGroceryProductNewVariant(
      {required GroceryProductData groceryItem,
      required String productId,
      required String weight,
      required String unit,
      required String mrp,
      required String sellingPrice}) async {
    try {
      isCreateNewGroceryProductNewVariantLoading.value = true;
      Map<String, dynamic> data = {
        ApiKeys.variantData: jsonEncode({
          ApiKeys.weight: int.parse(weight),
          ApiKeys.unit: unit,
          ApiKeys.pricing: [
            {
              ApiKeys.mrp: int.tryParse(mrp),
              ApiKeys.sellingPrice: int.tryParse(sellingPrice),
            }
          ]
        })
      };

      final response = await GroceryRepo().createNewGroceryProductVariantRepo(
        productId: productId,
        params: data,
      );

      if (!response.isSuccess) {
        createNewGroceryProductNewVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      createNewGroceryProductNewVariantResponse.value = ApiResponse.complete(response);
      final jsonData = response.response?.data;
      log('id-- > ${jsonData['_id']}');
      final newVariant = VariantsData(
        weight: int.tryParse(weight),
        sId: jsonData['_id'],
        product: productId,
        unit: unit,
        variantName: "${weight}${unit}",
        pricing: [
          Pricing(
            mrp: int.tryParse(mrp),
            sellingPrice: int.tryParse(sellingPrice),
          )
        ],
        images: [],
        sku: null,
        barcode: null,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
        iV: 0,
      );

      groceryItem.variants?.insert(
        groceryItem.variants!.length,
        newVariant,
      );
      update();
      Get.back();
    } catch (e) {
      createNewGroceryProductNewVariantResponse.value = ApiResponse.error('error');
    } finally {
      isCreateNewGroceryProductNewVariantLoading.value = false;
    }
  }

  RxBool isAddGroceryProductsLoading = false.obs;
  Future<void> addGroceryProductNewVariant() async {
    try {
      isAddGroceryProductsLoading.value = true;

      final payload = buildInventoryPayload();
      if(payload.isEmpty) return;

      print(jsonEncode(payload));

      final response = await GroceryRepo().addGroceryProductVariantRepo(
        params: payload,
      );

      if (!response.isSuccess) {
        addGroceryProductVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      addGroceryProductVariantResponse.value = ApiResponse.complete(response);
      // final jsonData = response.response?.data;

      Get.until((route) =>
                  route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
      commonSnackBar(
        message: response.message ?? AppStrings.somethingWentWrong,
      );
      log('success-- ${response.isSuccess}');
    } catch (e) {
      addGroceryProductVariantResponse.value = ApiResponse.error('error');
    } finally {
      isAddGroceryProductsLoading.value = false;
    }
  }

  List<Map<String, dynamic>> buildInventoryPayload() {
    List<Map<String, dynamic>> payload = [];
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController());
    String city = viewBusinessDetailsController.businessProfileDetails?.data?.cityStatePincode ?? LocationService.userCurrentAddress.value.city;
    String postalCode = viewBusinessDetailsController.businessProfileDetails?.data?.pincode.toString() ?? LocationService.userCurrentAddress.value.postalCode;

    if(postalCode.isEmpty){
      commonSnackBar(message: 'Please enable your location permission for adding grocery');
      return [];
    }

    selectedProductVariants.forEach((productId, variants) {
      for (final variant in variants) {
        payload.add({
          "productVariant": variant.sId ?? "",
          "pincode": postalCode,
          "cityName": city,
          "batches": [
            {
              "quantity": variant.weight,
              "mrp": variant.pricing?[0].mrp,
              "sellingPrice": variant.pricing?[0].sellingPrice,
            }
          ],
        });
      }
    });

    return payload;
  }

  Future<void> fetchGrocerySnapSearchApi() async {
    if (grocerySnapSearchImages.length < 2) {
      commonSnackBar(message: "Please upload at least 2 photos");
      return;
    }

    try {

      grocerySnapSearchResponse.value = ApiResponse.loading('Loading');

      List<dio.MultipartFile> imageByPart = [];

      for (final image in grocerySnapSearchImages) {
        final fileName = image.path.split('/').last;
        imageByPart.add(
            await dio.MultipartFile.fromFile(
              image.path,
              filename: fileName,
            ));
      }
      Map<String, dynamic> params = {
        ApiKeys.images : imageByPart
      };

      ResponseModel responseModel = await GroceryRepo().fetchGrocerySnapSearchRepo(
        params: params
      );
      if (responseModel.isSuccess) {
        grocerySnapSearchResponse.value = ApiResponse.complete(responseModel);
        var grocerySnapSearchResponseModel = GrocerySnapSearchResponseModel.fromJson(responseModel.response?.data);
        productSnapSearchData.value = grocerySnapSearchResponseModel.data;
        // groceryFoundProducts.value = grocerySnapSearchResponseModel.data?.foundProducts ?? [];
      } else {
        grocerySnapSearchResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      grocerySnapSearchResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    }
  }


  /// Fetch Grocery Products
  RxBool myGroceryLoading = true.obs;
  RxList<MyGroceryCategoryWithVariantsModel> myGroceryCategoryList = <MyGroceryCategoryWithVariantsModel>[].obs;
  RxList<BusinessProductData> groceryBusinessProductsList = <BusinessProductData>[].obs;

  Future<void> fetchAllMyGroceryData() async {
    try {
      myGroceryLoading.value = true;

      // 1. Run both repo calls in parallel
      await Future.wait([
        fetchMyGroceryCategoryWithVariants(),
        fetchGroceryBusinessProductsRepo(),
      ]);

    } catch (e) {
    } finally {
      myGroceryLoading.value = false;
    }
  }

  Future<void> fetchMyGroceryCategoryWithVariants() async {
    try {
      ResponseModel responseModel = await GroceryRepo().fetchGroceryCategoryWithVariantRepo();
      if (responseModel.isSuccess) {
        fetchMyGroceryCategoryResponse.value = ApiResponse.complete(responseModel);
        final List listData = responseModel.response?.data ?? [];

        myGroceryCategoryList.value = listData
            .map((e) => MyGroceryCategoryWithVariantsModel.fromJson(e))
            .toList();

        log("Loaded ${myGroceryCategoryList.length}");
      } else {
        fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
      log("ERROR===== $e");
     }
  }

  Future<void> fetchGroceryBusinessProductsRepo() async {
    try {
      Map<String, dynamic> params = {
        ApiKeys.businessId: userId,
        ApiKeys.sortBy: "discount_high_to_low",
      };
      ResponseModel responseModel = await GroceryRepo().fetchGroceryBusinessProductsRepo(
        params: params
      );
      if (responseModel.isSuccess) {

        fetchGroceryBusinessProductsResponse.value = ApiResponse.complete(responseModel);
        var groceryBusinessProductsModel = GroceryBusinessProductsModel.fromJson(responseModel.response?.data);
        groceryBusinessProductsList.value = groceryBusinessProductsModel.data ?? [];

        log("Loaded ${groceryBusinessProductsList.length}");
      }else{
        fetchGroceryBusinessProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      fetchGroceryBusinessProductsResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    }
  }

  /// Fetch Grocery Products
  RxList<Products> myGroceryProductsList = <Products>[].obs;
  // RxList<Variants> myGroceryProductsVariantsList = <Variants>[].obs;
  RxBool isMyGroceryDataFirstLoading = false.obs;
  RxBool isMyGroceryDataLoadingMore = false.obs;
  int myGroceryDataPage = 1;
  bool myGroceryDataHasMore = true;
  int pageLimit = 20;

  Future<void> fetchMyGroceryProducts({
    required String categoryId,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isMyGroceryDataLoadingMore.value || !myGroceryDataHasMore) return;
      isMyGroceryDataLoadingMore.value = true;
    } else {
      isMyGroceryDataFirstLoading.value = true;
      myGroceryDataPage = 1;
      myGroceryDataHasMore = true;
    }

    try {
      Map<String, dynamic> params = {
        ApiKeys.page: myGroceryDataPage,
        ApiKeys.limit: pageLimit,
        'categoryId': categoryId
      };

      ResponseModel responseModel = await GroceryRepo().fetchMyGroceryProductsRepo(queryParam: params);
      if (responseModel.isSuccess) {
        fetchMyGroceryProductsResponse.value = ApiResponse.complete(responseModel);
        final data = responseModel.response?.data;
        MyGroceryProductsModel myGroceryProductsModel = MyGroceryProductsModel.fromJson(data);
        List<Products> newItems = myGroceryProductsModel.data?[0].category?.products ?? [];

        if (newItems.isNotEmpty) {
          // if(!isSubCategoryProducts){
            if (isLoadMore) {
              myGroceryProductsList.addAll(newItems);
            } else {
              myGroceryProductsList.clear();
              myGroceryProductsList.assignAll(newItems);
            }
          // }else{
          //   extractAllVariantsFromResponse(
          //       newItems,
          //       isLoadMore: isLoadMore,
          //   );
          // }

          myGroceryDataPage++;
        } else {
          myGroceryDataHasMore = false;
        }

        log("Loaded ${newItems.length} items | Total: ${ myGroceryProductsList.length}");
      } else {
        fetchMyGroceryProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchMyGroceryProductsResponse.value = ApiResponse.error('error');
      log("ERROR===== $e");
    } finally{
      if (isLoadMore) {
        isMyGroceryDataLoadingMore.value = false;
      } else {
        isMyGroceryDataFirstLoading.value = false;
      }
    }
  }

  /// Fetch Grocery Products
  RxBool groceryNestedCategoryLoading = true.obs;
  RxList<GroceryNestedCategoryModel> groceryNestedCategoryList = <GroceryNestedCategoryModel>[].obs;

  Future<void> fetchGroceryNestedCategory(String groceryTagId) async {
    try {
      groceryNestedCategoryLoading.value = true;
      groceryNestedCategoryList.clear();

      final cachedData = await HiveServices().getGroceryNestedCategories(groceryTagId);
      if (cachedData != null && cachedData.isNotEmpty) {
        groceryNestedCategoryLoading.value = false;
        groceryNestedCategoryList.assignAll(cachedData);
        return;
      }

      ResponseModel responseModel = await GroceryRepo().fetchGroceryNestedCategoryRepo(
          queryParams: {ApiKeys.categoryKey: groceryTagId}
      );
      if (responseModel.isSuccess) {
        fetchMyGroceryCategoryResponse.value = ApiResponse.complete(responseModel);
        final GroceryNestedCategoryModel groceryNestedCategoryModel = GroceryNestedCategoryModel.fromJson(responseModel.response?.data);
        groceryNestedCategoryList.value = groceryNestedCategoryModel.children ?? [];
        await HiveServices().saveGroceryNestedCategories(groceryTagId, groceryNestedCategoryList);
      } else {
        fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      log('stack trace -- $s');
      fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
    } finally{
      groceryNestedCategoryLoading.value = false;
    }
  }


  /// if variant  has image then it will work
  // void extractAllVariantsFromResponse(
  //     List<MyGroceryProductsData> groceryProductData,
  //     {bool isLoadMore = false}
  //     ) {
  //   if (!isLoadMore) {
  //     myGroceryProductsVariantsList.clear();
  //   }
  //
  //   for (final data in groceryProductData) {
  //     final category = data.category;
  //     if (category == null) continue;
  //
  //     final products = category.products ?? [];
  //     for (final product in products) {
  //       final variants = product.variants ?? [];
  //       myGroceryProductsVariantsList.addAll(variants);
  //     }
  //   }
  // }

  /// if variant not has image then we need to fetch from product image and we will overwrite variant image (current scenario)
  // void extractAllVariantsFromResponse(
  //     List<Products> products, {
  //       bool isLoadMore = false,
  //     }) {
  //   debugPrint("📦 START: Extracting variants. isLoadMore: $isLoadMore");
  //
  //   if (!isLoadMore) {
  //     myGroceryProductsVariantsList.clear();
  //     debugPrint("🧹 Cleared existing variants list.");
  //   }
  //
  //   int variantsAddedCount = 0;
  //
  //   for (final product in products) {
  //     // 1. Safely extract the parent product's image
  //     Images? productImage;
  //     if (product.images != null && product.images!.isNotEmpty) {
  //       productImage = product.images![0];
  //     }
  //
  //     final variants = product.variants ?? [];
  //
  //     // 2. Loop through variants to attach the image
  //     for (final variant in variants) {
  //       // Logic Fix: Initialize list if null, then ADD the image (don't access index 0)
  //       bool appliedFallback = false;
  //
  //       if (productImage != null) {
  //         if (variant.images == null) {
  //           variant.images = [productImage]; // Initialize with parent image
  //           appliedFallback = true;
  //         } else if (variant.images!.isEmpty) {
  //           variant.images!.add(productImage); // Add parent image to empty list
  //           appliedFallback = true;
  //         }
  //       }
  //
  //       if (appliedFallback) {
  //         debugPrint("   📎 Attached parent image to Variant ID: ${variant.sId}");
  //       }
  //
  //       myGroceryProductsVariantsList.add(variant);
  //       variantsAddedCount++;
  //     }
  //   }
  //
  //   debugPrint("✅ END: Total variants added in this batch: $variantsAddedCount");
  //   debugPrint("📊 Total variants in list: ${myGroceryProductsVariantsList.length}");
  // }



}
