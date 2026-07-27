import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
// The medical business-products endpoint ships grocery's exact response shape
// (see docs/backend/MEDICAL_TOP_SELLING_BACKEND_GUIDE.md), so the model and its
// grouping helper are shared rather than duplicated.
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart';
import 'package:BlueEra/features/me/medical/model/my_medical_super_category_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_change_request_model.dart';
import 'package:BlueEra/features/me/medical/model/missing_product_request_model.dart';
import 'package:BlueEra/features/me/medical/model/snap_search_result_model.dart';
import 'package:BlueEra/features/me/medical/view/edit_medical_varient_dialog.dart';
import 'package:BlueEra/features/me/medical/widget/edit_medical_inventory_bottom_sheet.dart';
import 'package:BlueEra/features/me/medical/widget/add_medical_variant_bottom_sheet.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/my_medical_products_response.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';

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

class MedicalController extends GetxController {
  Rx<ApiResponse> medicalCategoryResponse =
    ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> medicalCategoryOfChildrenResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createNewMedicalProductNewVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addMedicalProductVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyMedicalProductsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyMedicalCategoryResponse =
      ApiResponse.initial('Initial').obs;

  final selectedMedicalData = Rxn<MedicalNestedCategoryModel>();

  RxList<MedicalProductData> selectedMedicalProducts = <MedicalProductData>[].obs;

  int maxLimit = 10;

  bool get isMaxLimitHit => selectedMedicalProducts.length == maxLimit;

  Map<String, List<VariantsData>> selectedProductVariants = {};

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SNAP SEARCH IMAGE SLOT SYSTEM
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  final List<Map<String, String>> medicalSnapSearchConfig = [
    {
      'title': 'Upload Photo',
      'image': 'assets/category/medical/medical_upload_photo_med.png',
    },
    {
      'title': 'Upload List',
      'image': 'assets/category/medical/medical_upload_photo.png',
    },
  ];

  final RxMap<String, File?> medicalSnapSearchImagesMap = <String, File?>{}.obs;
  int maxUploadImages = 2;

  RxMap<String, List<VariantsData>> selectedSnapSearchProductVariants = <String, List<VariantsData>>{}.obs;
  Rxn<SnapSearchData> productSnapSearchData = Rxn<SnapSearchData>();

  void toggleSnapSearchVariant(String productId, VariantsData variant) {
    selectedSnapSearchProductVariants.putIfAbsent(productId, () => []);
    final selectedList = selectedSnapSearchProductVariants[productId]!;

    if (selectedList.any((v) => v.sId == variant.sId)) {
      selectedList.removeWhere((v) => v.sId == variant.sId);
      if (selectedList.isEmpty) {
        selectedSnapSearchProductVariants.remove(productId);
      }
    } else {
      selectedList.add(variant);
    }

    selectedSnapSearchProductVariants.refresh();
  }

  bool isSnapSearchVariantSelected(String productId, String variantId) {
    return selectedSnapSearchProductVariants[productId]?.any((v) => v.sId == variantId) ?? false;
  }

  bool get canSubmitSnapSearchProducts {
    bool hasAtLeastOneVariant = selectedSnapSearchProductVariants.values.any((variants) => variants.isNotEmpty);
    return hasAtLeastOneVariant;
  }

  Future<void> addImagesBySlot(String title) async {
    if (medicalSnapSearchImagesMap.values.any((v) => v != null)) {
      commonSnackBar(message: AppStrings.medicalPleaseRemoveCurrentImage);
      return;
    }

    final selectedImages = await pickSnapSearchImages(title);
    if (selectedImages == null || selectedImages.isEmpty) return;

    medicalSnapSearchImagesMap[title] = File(selectedImages.first);

    fetchMedicalSnapSearchApi();
  }

  void removeImageBySlot(String title) {
    medicalSnapSearchImagesMap[title] = null;
    medicalSnapSearchImagesMap.refresh();
  }

  Future<List<String>?> pickSnapSearchImages(String title) async {
    final List<String>? selected =
        await PhotoPickerService.pickMultiplePhotos(Get.context!, title);
    return (selected != null && selected.isNotEmpty) ? selected : null;
  }

  Rx<ApiResponse> medicalSnapSearchResponse = ApiResponse.initial('Initial').obs;

  Future<void> fetchMedicalSnapSearchApi() async {
    final List<File> activeImages = medicalSnapSearchImagesMap.values
        .where((file) => file != null)
        .cast<File>()
        .toList();

    if (activeImages.isEmpty) {
      commonSnackBar(message: AppStrings.medicalPleaseUploadAtLeastOnePhoto);
      return;
    }

    try {
      medicalSnapSearchResponse.value = ApiResponse.loading('Loading');
      productSnapSearchData.value = null;

      List<dio.MultipartFile> imageByPart = [];

      for (final image in activeImages) {
        final fileName = image.path.split('/').last;
        imageByPart.add(
          await dio.MultipartFile.fromFile(
            image.path,
            filename: fileName,
          ),
        );
      }

      Map<String, dynamic> params = {
        ApiKeys.images: imageByPart,
      };

      ResponseModel responseModel = await MedicalRepo().snapSearchRepo(
        params: params,
      );

      if (responseModel.isSuccess) {
        medicalSnapSearchResponse.value = ApiResponse.complete(responseModel);
        var snapSearchResultModel =
            SnapSearchResultModel.fromJson(responseModel.response?.data);
        productSnapSearchData.value = snapSearchResultModel.data;
      } else {
        medicalSnapSearchResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      medicalSnapSearchResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    }
  }

  RxBool isAddMedicalSnapSearchProductsLoading = false.obs;
  Future<void> addMedicalSnapSearchProductNewVariant({bool isSnapSearch = false}) async {
    try {
      isAddMedicalSnapSearchProductsLoading.value = true;

      final payload = buildSnapSearchInventoryPayload();
      if (payload.isEmpty) return;

      print(jsonEncode(payload));

      final response = await MedicalRepo().addGroceryProductVariantRepo(
        params: payload,
      );

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      Get.until((route) =>
          route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
      commonSnackBar(
        message: response.message ?? AppStrings.medicalProductsAddedSuccessfully.tr,
      );
      // Same as the manual path: empty the basket, then refresh Top Selling +
      // inventory so the just-published items are on the tab we popped back to.
      clearMedicalSelection();
      invalidateMedicalProductsTabCache();
      unawaited(fetchMedicalProductsTabData(businessId: businessId));
      log('success-- ${response.isSuccess}');
    } catch (e) {
      log('addMedicalSnapSearchProductNewVariant error: $e');
    } finally {
      isAddMedicalSnapSearchProductsLoading.value = false;
    }
  }

  List<Map<String, dynamic>> buildSnapSearchInventoryPayload() {
    List<Map<String, dynamic>> payload = [];
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    final businessData = viewBusinessDetailsController.businessProfileDetails.value?.data;

    String city = (businessData?.cityStatePincode != null && businessData!.cityStatePincode!.isNotEmpty)
        ? businessData.cityStatePincode!
        : LocationService.userCurrentAddress.value.city;
    String postalCode;
    if (businessData?.pincode == null || businessData?.pincode == 0) {
      postalCode = LocationService.userCurrentAddress.value.postalCode;
    } else {
      postalCode = businessData!.pincode.toString();
    }

    if (postalCode.isEmpty || postalCode == "0") {
      commonSnackBar(message: AppStrings.medicalEnableGpsOrPincode);
      return [];
    }

    selectedSnapSearchProductVariants.forEach((productId, variants) {
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

  void openSnapSearchEditVariantDialog({
    required BuildContext context,
    required String title,
    required VariantsData variant,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return EditMedicalVarientDialog(
          title: title,
          mrp: variant.pricing?[0].mrp?.toString() ?? "",
          selling: variant.pricing?[0].sellingPrice?.toString() ?? "",
          onSubmit: (mrp, sellingPrice) {
            variant.pricing?[0].mrp = int.tryParse(mrp);
            variant.pricing?[0].sellingPrice = int.tryParse(sellingPrice);
            selectedSnapSearchProductVariants.refresh();
            Get.back();
          },
        );
      },
    );
  }

  void toggleSelection(MedicalProductData p) {
    if (selectedMedicalProducts.contains(p)) {
      selectedMedicalProducts.remove(p);
    } else {
      if (selectedMedicalProducts.length >= 10) {
        commonSnackBar(
            message: AppStrings.medicalCannotSelectMore10);
        return;
      }
      selectedMedicalProducts.add(p);
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
    for (final p in selectedMedicalProducts) {
      final variants = selectedProductVariants[p.sId];

      // If no entry OR empty variants list â†’ invalid
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

    // Safely map â†’ remove null â†’ convert to double
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
        ? "â‚¹$minSelling"
        : "â‚¹$minSelling - â‚¹$maxSelling";

    final mrpRange = minMrp == maxMrp ? "â‚¹$minMrp" : "â‚¹$minMrp - â‚¹$maxMrp";

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return EditMedicalVarientDialog(
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
    required MedicalProductData groceryItem,
  }) {
    // Don't allow adding variants if product has no existing variants
    if (groceryItem.variants == null || groceryItem.variants!.isEmpty) {
      commonSnackBar(message: AppStrings.medicalProductDoesNotSupportVariants);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !isCreateNewMedicalProductNewVariantLoading.value,
      enableDrag: !isCreateNewMedicalProductNewVariantLoading.value,
      builder: (_) {
        return Obx(() => AddMedicalVariantBottomSheet(
              title: groceryItem.name ?? AppStrings.medicalAddVariant.tr,
              isLoading: isCreateNewMedicalProductNewVariantLoading.value,
              onSubmit: (weight, unit, mrp, sellingPrice) {
                createNewMedicalProductNewVariant(
                  medicalItem: groceryItem,
                  productId: groceryItem.sId ?? '',
                  weight: weight,
                  unit: unit,
                  mrp: mrp,
                  sellingPrice: sellingPrice,
                );
              },
            ));
      },
    );
  }


  RxBool isMedicalCategoryProductsLoading = false.obs;
  RxList<MedicalProductData> arrMedicalCategoryProducts = <MedicalProductData>[].obs;
  RxBool isMedicalCategoryProductsLoadingMore = false.obs;
  int medicalCategoryProductsPage = 1;
  bool medicalCategoryProductsHasMore = true;

  Future<void> fetchGroceryCategoryProducts({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        // if (isGroceryCategoryProductsLoadingMore.value || !groceryCategoryProductsHasMore) return;
        isMedicalCategoryProductsLoadingMore.value = true;
      } else {
        arrMedicalCategoryProducts.clear();
        isMedicalCategoryProductsLoading.value = true;
        medicalCategoryProductsPage = 1;
        medicalCategoryProductsHasMore = true;
      }

      final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
      String postalCode = viewBusinessDetailsController.businessProfileDetails.value?.data?.pincode.toString() ?? LocationService.userCurrentAddress.value.postalCode;

      Map<String, dynamic> queryParams = {
        ApiKeys.page: medicalCategoryProductsPage,
        ApiKeys.limit: pageLimit,
        ApiKeys.searchTerm: selectedMedicalData.value?.key,
        if (postalCode.isNotEmpty) ApiKeys.pincode: postalCode,
      };

      final response = await MedicalRepo()
          .searchGroceryCategoryRepo(queryParam: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      medicalCategoryResponse.value = ApiResponse.complete(response);

      final medicalProductModel = MedicalProductModel.fromJson(response.response?.data);
      List<MedicalProductData> newItems = medicalProductModel.data ?? [];

      if (newItems.isNotEmpty) {
          if (isLoadMore) {
            arrMedicalCategoryProducts.addAll(newItems);
          } else {
            arrMedicalCategoryProducts.assignAll(newItems);
          }

          medicalCategoryProductsPage++;
      } else {
        medicalCategoryProductsHasMore = false;
      }

      log('total Medical Products-- ${arrMedicalCategoryProducts.length}');
      update();
    } catch (e, s) {
      medicalCategoryResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isMedicalCategoryProductsLoadingMore.value = false;
      } else {
        isMedicalCategoryProductsLoading.value = false;
      }
    }
  }

  RxBool isCreateNewMedicalProductNewVariantLoading = false.obs;
  Future<void> createNewMedicalProductNewVariant(
      {required MedicalProductData medicalItem,
      required String productId,
      required String weight,
      required String unit,
      required String mrp,
      required String sellingPrice}) async {
    try {
      isCreateNewMedicalProductNewVariantLoading.value = true;
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

      final response = await MedicalRepo().createNewGroceryProductVariantRepo(
        productId: productId,
        params: data,
      );

      if (!response.isSuccess) {
        createNewMedicalProductNewVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      createNewMedicalProductNewVariantResponse.value = ApiResponse.complete(response);
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

      medicalItem.variants?.insert(
        medicalItem.variants!.length,
        newVariant,
      );
      update();
      Get.back();
    } catch (e) {
      createNewMedicalProductNewVariantResponse.value = ApiResponse.error('error');
    } finally {
      isCreateNewMedicalProductNewVariantLoading.value = false;
    }
  }

  RxBool isAddMedicalProductsLoading = false.obs;
  Future<void> addMedicalProductNewVariant() async {
    try {
      isAddMedicalProductsLoading.value = true;

      final payload = buildInventoryPayload();
      if(payload.isEmpty) return;

      print(jsonEncode(payload));

      final response = await MedicalRepo().addGroceryProductVariantRepo(
        params: payload,
      );

      if (!response.isSuccess) {
        addMedicalProductVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      addMedicalProductVariantResponse.value = ApiResponse.complete(response);
      // final jsonData = response.response?.data;

      Get.until((route) =>
                  route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
      commonSnackBar(
        message: response.message ?? AppStrings.somethingWentWrong,
      );
      // The basket is published — empty it before anything can re-open the
      // add flow and find the same items still in the cart.
      clearMedicalSelection();
      // We just landed back on the Products tab and both its lists are stale —
      // the item the merchant published isn't in either. Drop the freshness
      // stamp so nothing short-circuits, then refetch Top Selling + inventory.
      // Not awaited: the snackbar and the pop shouldn't wait on two GETs.
      invalidateMedicalProductsTabCache();
      unawaited(fetchMedicalProductsTabData(businessId: businessId));
      log('success-- ${response.isSuccess}');
    } catch (e) {
      addMedicalProductVariantResponse.value = ApiResponse.error('error');
    } finally {
      isAddMedicalProductsLoading.value = false;
    }
  }

  /// Empties the add-product basket after a successful publish.
  ///
  /// This screen's controller used to be deleted on the way out, which wiped
  /// the selection as a side effect. It now survives (so the Products tab can
  /// reuse its cached lists), which means the basket has to be cleared on
  /// purpose — otherwise re-entering "Add Product" shows the items that were
  /// just published still sitting in the cart.
  ///
  /// Covers both publish paths: the manual category pick and snap-search.
  void clearMedicalSelection() {
    selectedMedicalProducts.clear();
    selectedProductVariants.clear();

    selectedSnapSearchProductVariants.clear();
    productSnapSearchData.value = null;
    medicalSnapSearchResponse.value = ApiResponse.initial('Initial');
    // Drop the captured photos too — otherwise the snap-search screen reopens
    // showing the shelf picture whose products were already published, and its
    // "one image at a time" guard blocks a new capture.
    medicalSnapSearchImagesMap.clear();

    // selectedProductVariants is a plain Map, so the variant screen's
    // GetBuilder won't repaint on its own.
    update();
  }

  List<Map<String, dynamic>> buildInventoryPayload() {
    List<Map<String, dynamic>> payload = [];
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    String city = viewBusinessDetailsController.businessProfileDetails.value?.data?.cityStatePincode ?? LocationService.userCurrentAddress.value.city;
    String postalCode = viewBusinessDetailsController.businessProfileDetails.value?.data?.pincode.toString() ?? LocationService.userCurrentAddress.value.postalCode;

    if(postalCode.isEmpty){
      commonSnackBar(message: AppStrings.medicalEnableLocationPermission);
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
              // Opening stock for the batch. Was `variant.weight`, which is the
              // pack SIZE (e.g. 500 mg), not a stock count — and it's null on
              // most catalog variants, so every publish sent quantity: null and
              // the item landed with totalStock: 0.
              "quantity": 1,
              "mrp": variant.pricing?[0].mrp,
              "sellingPrice": variant.pricing?[0].sellingPrice,
            }
          ],
        });
      }
    });

    return payload;
  }

  /// Fetch Grocery Products
  RxBool myMedicalCategoryLoading = true.obs;
  RxList<MyMedicalSuperCategoryModel> myMedicalCategoryList = <MyMedicalSuperCategoryModel>[].obs;

  // ─── "Top Selling" — store-wide products (business-products API) ─────────
  // Reuses grocery's model + grouping + card: the backend ships this endpoint
  // with grocery's exact response shape on purpose, so duplicating the parsing
  // would only be a second thing to keep in sync.
  // See docs/backend/MEDICAL_TOP_SELLING_BACKEND_GUIDE.md.
  Rx<ApiResponse> fetchMedicalBusinessProductsResponse =
      ApiResponse.initial('Initial').obs;
  RxList<BusinessProductData> medicalBusinessProductsList =
      <BusinessProductData>[].obs;
  RxBool isMedicalBusinessProductsLoadingMore = false.obs;
  int _medicalBusinessProductsPage = 1;
  bool _medicalBusinessProductsHasMore = true;
  static const int _medicalBusinessProductsLimit = 20;
  static const int medicalBusinessProductsPreviewLimit = 20;

  bool get medicalBusinessProductsHasMore => _medicalBusinessProductsHasMore;

  /// Products-tab data: the Top Selling rail + the category-with-inventory
  /// grid. Fires both in parallel, mirroring grocery's [fetchAllGroceryData].
  ///
  /// [businessId] is always explicit — merchant-side callers pass the global
  /// `businessId`, the customer-side rail passes another store's id with
  /// [otherStore] true. Threaded as a parameter (rather than read off the
  /// global in here) both because grocery does it that way and because a
  /// parameter of that name would shadow the global anyway.
  Future<void> fetchMedicalProductsTabData({
    required String businessId,
    bool otherStore = false,
  }) async {
    await Future.wait([
      fetchMyMedicalCategory(),
      fetchMedicalBusinessProducts(
        businessId: businessId,
        otherStore: otherStore,
      ),
    ]);
  }

  /// Freshness guard for the Products tab, keyed per store — so re-opening the
  /// tab reuses what's already loaded instead of refetching on every visit.
  final FetchCache _medicalProductsTabCache = FetchCache();

  /// Products-tab fetch that no-ops while the data is still loaded & fresh.
  /// Use on tab open / screen re-entry; call [fetchMedicalProductsTabData]
  /// directly for an explicit refresh (pull-to-refresh, post-publish).
  Future<void> fetchMedicalProductsTabDataIfNeeded({
    required String businessId,
    bool otherStore = false,
  }) async {
    final signature = 'medical|$businessId|$otherStore';
    final hasData = myMedicalCategoryList.isNotEmpty ||
        medicalBusinessProductsList.isNotEmpty;
    if (_medicalProductsTabCache.isFresh(signature, hasData: hasData)) return;
    await fetchMedicalProductsTabData(
      businessId: businessId,
      otherStore: otherStore,
    );
    if (fetchMyMedicalCategoryResponse.value.status == Status.COMPLETE) {
      _medicalProductsTabCache.mark(signature);
    }
  }

  /// Drops the freshness stamp so the next `*IfNeeded()` refetches. Called
  /// after publishing, where the lists are known-stale.
  void invalidateMedicalProductsTabCache() =>
      _medicalProductsTabCache.invalidate();

  Future<void> fetchMedicalBusinessProducts({
    required String businessId,
    bool otherStore = false,
    bool isLoadMore = false,
  }) async {
    try {
      if (isLoadMore) {
        // Guard against overlapping load-more calls and stop once the server
        // says there are no more pages.
        if (!_medicalBusinessProductsHasMore ||
            isMedicalBusinessProductsLoadingMore.value ||
            fetchMedicalBusinessProductsResponse.value.status ==
                Status.INITIAL) {
          return;
        }
        isMedicalBusinessProductsLoadingMore.value = true;
      } else {
        fetchMedicalBusinessProductsResponse.value =
            ApiResponse.initial('Initial');
        _medicalBusinessProductsPage = 1;
        _medicalBusinessProductsHasMore = true;
        medicalBusinessProductsList.clear();
      }

      final Map<String, dynamic> params = {
        ApiKeys.businessId: businessId,
        ApiKeys.page: _medicalBusinessProductsPage,
        ApiKeys.limit: _medicalBusinessProductsLimit,
      };

      final ResponseModel responseModel = otherStore
          ? await MedicalRepo()
              .fetchPublicMedicalBusinessProductsRepo(params: params)
          : await MedicalRepo()
              .fetchMedicalBusinessProductsRepo(params: params);

      if (!responseModel.isSuccess) {
        fetchMedicalBusinessProductsResponse.value = ApiResponse.error('error');
        return;
      }

      final parsed =
          GroceryBusinessProductsModel.fromJson(responseModel.response?.data);
      final newItems = parsed.data ?? [];

      if (isLoadMore) {
        medicalBusinessProductsList.addAll(newItems);
      } else {
        medicalBusinessProductsList.value = newItems;
      }

      if (newItems.isNotEmpty) _medicalBusinessProductsPage++;
      // Short page → last page; no point asking for another.
      if (newItems.length < _medicalBusinessProductsLimit) {
        _medicalBusinessProductsHasMore = false;
      }

      fetchMedicalBusinessProductsResponse.value =
          ApiResponse.complete(responseModel);
      log("Loaded ${medicalBusinessProductsList.length} medical business products");
    } catch (e, s) {
      fetchMedicalBusinessProductsResponse.value = ApiResponse.error('error');
      log("fetchMedicalBusinessProducts failed: $e\n$s");
    } finally {
      if (isLoadMore) isMedicalBusinessProductsLoadingMore.value = false;
    }
  }

  Future<void> fetchMyMedicalCategory() async {
    try {
      myMedicalCategoryLoading.value = true;
      ResponseModel responseModel = await MedicalRepo().fetchGroceryCategoryWithVariantRepo();
      if (responseModel.isSuccess) {
        fetchMyMedicalCategoryResponse.value = ApiResponse.complete(responseModel);
        final List listData = responseModel.response?.data ?? [];

        myMedicalCategoryList.value = listData
            .map((e) => MyMedicalSuperCategoryModel.fromJson(e))
            .toList();

        log("Loaded ${myMedicalCategoryList.length}");
      } else {
        fetchMyMedicalCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchMyMedicalCategoryResponse.value = ApiResponse.error('error');
      log("ERROR===== 2 $e");
    } finally{
      myMedicalCategoryLoading.value = false;
    }
  }


  /// Fetch Grocery Products
  RxList<Products> myMedicalProductsList = <Products>[].obs;
  RxBool isMyMedicalDataFirstLoading = false.obs;
  RxBool isMyMedicalDataLoadingMore = false.obs;
  int myMedicalDataPage = 1;
  bool myMedicalDataHasMore = true;
  int pageLimit = 20;

  Future<void> fetchMyGroceryProducts({
    required String categoryId,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isMyMedicalDataLoadingMore.value || !myMedicalDataHasMore) return;
      isMyMedicalDataLoadingMore.value = true;
    } else {
      isMyMedicalDataFirstLoading.value = true;
      myMedicalDataPage = 1;
      myMedicalDataHasMore = true;
    }

    // try {
      Map<String, dynamic> params = {
        ApiKeys.page: myMedicalDataPage,
        ApiKeys.limit: pageLimit,
        'categoryId': categoryId
      };

      ResponseModel responseModel = await MedicalRepo().fetchMyGroceryProductsRepo(queryParam: params);
      if (responseModel.isSuccess) {
        fetchMyMedicalProductsResponse.value = ApiResponse.complete(responseModel);
        final data = responseModel.response?.data;
        MyMedicalProductsModel myGroceryProductsModel = MyMedicalProductsModel.fromJson(data);
        List<Products> newItems = myGroceryProductsModel.data?[0].category?.products ?? [];

        if (newItems.isNotEmpty) {
          // if(!isSubCategoryProducts){
            if (isLoadMore) {
              myMedicalProductsList.addAll(newItems);
            } else {
              myMedicalProductsList.clear();
              myMedicalProductsList.assignAll(newItems);
            }
          // }else{
          //   extractAllVariantsFromResponse(
          //       newItems,
          //       isLoadMore: isLoadMore,
          //   );
          // }

          myMedicalDataPage++;
        } else {
          myMedicalDataHasMore = false;
        }

        log("Loaded ${newItems.length} items | Total: ${ myMedicalProductsList.length}");
      } else {
        fetchMyMedicalProductsResponse.value = ApiResponse.error('error');
      }
    // } catch (e) {
    //   fetchMyMedicalProductsResponse.value = ApiResponse.error('error');
    //   log("ERROR===== 1 $e");
    // } finally{
      if (isLoadMore) {
        isMyMedicalDataLoadingMore.value = false;
      } else {
        isMyMedicalDataFirstLoading.value = false;
      }
    // }
  }

  /// Fetch Grocery Products
  RxBool medicalNestedCategoryLoading = true.obs;
  RxList<MedicalNestedCategoryModel> medicalNestedCategoryList = <MedicalNestedCategoryModel>[].obs;

  Future<void> fetchGroceryNestedCategory() async {
    try {
      medicalNestedCategoryLoading.value = true;
      medicalNestedCategoryList.clear();

      // final cachedData = await HiveServices().getMedicalNestedCategories();
      // if (cachedData != null && cachedData.isNotEmpty) {
      //   medicalNestedCategoryLoading.value = false;
      //   medicalNestedCategoryList.assignAll(cachedData);
      //   return;
      // }

      ResponseModel responseModel = await MedicalRepo().fetchGroceryNestedCategoryRepo();
      if (responseModel.isSuccess) {
        fetchMyMedicalCategoryResponse.value = ApiResponse.complete(responseModel);

        if (responseModel.response?.data != null && responseModel.response!.data is List) {
          medicalNestedCategoryList.value = (responseModel.response!.data as List)
              .map((json) => MedicalNestedCategoryModel.fromJson(json))
              .toList();
          // Level-0 categories the snap-search grid renders (all of them).
          log('level-0 categories (${medicalNestedCategoryList.length}): '
              '${medicalNestedCategoryList.map((e) => '${e.name} [${e.key}] level=${e.level}').toList()}');
          await HiveServices().saveMedicalNestedCategories(medicalNestedCategoryList);
        }
      } else {
        fetchMyMedicalCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      log('stack trace -- $s');
      fetchMyMedicalCategoryResponse.value = ApiResponse.error('error');
    } finally{
      medicalNestedCategoryLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // INVENTORY UPDATE / DELETE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  RxBool isUpdateInventoryLoading = false.obs;
  Future<void> updateInventory({
    required String inventoryId,
    required List<Map<String, dynamic>> batches,
    int? reorderPoint,
  }) async {
    try {
      isUpdateInventoryLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.batches: batches,
      };
      if (reorderPoint != null) body['reorderPoint'] = reorderPoint;

      ResponseModel response = await MedicalRepo().updateMedicalInventoryRepo(
        inventoryId: inventoryId,
        params: body,
      );

      if (!response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      commonSnackBar(message: response.message ?? AppStrings.medicalInventoryUpdatedSuccessfully.tr);
      update();
    } catch (e, s) {
      log('updateInventory error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUpdateInventoryLoading.value = false;
    }
  }

  /// Opens a bottom sheet for editing inventory (price + quantity).
  /// Price can only be decreased, not increased.
  void openEditInventoryBottomSheet({
    required BuildContext context,
    required String title,
    required MedicalProductVariants variant,
    String? categoryId,
  }) {
    final inventory = variant.inventory;
    final batch = inventory?.batches?.firstOrNull;
    final pricing = variant.pricing?.firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Obx(() => EditMedicalInventoryBottomSheet(
              title: title,
              currentMrp: pricing?.mrp?.toString() ?? '0',
              currentSellingPrice: pricing?.sellingPrice?.toString() ?? '0',
              currentQuantity: batch?.quantity?.toString() ?? '0',
              isLoading: isUpdateInventoryLoading.value,
              onSubmit: (mrp, sellingPrice, quantity) async {
                if (inventory?.inventoryId == null) {
                  commonSnackBar(message: AppStrings.medicalInventoryNotFound);
                  return;
                }

                final updatedBatches = <Map<String, dynamic>>[
                  {
                    if (batch?.sId != null) '_id': batch!.sId,
                    if (batch?.batchNumber != null)
                      'batchNumber': batch!.batchNumber,
                    'quantity': int.tryParse(quantity) ?? 0,
                    'mrp': num.tryParse(mrp) ?? 0,
                    'sellingPrice': num.tryParse(sellingPrice) ?? 0,
                  }
                ];

                await updateInventory(
                  inventoryId: inventory!.inventoryId!,
                  batches: updatedBatches,
                );

                // Update local data
                if (pricing != null) {
                  pricing.mrp = num.tryParse(mrp);
                  pricing.sellingPrice = num.tryParse(sellingPrice);
                }
                if (batch != null) {
                  batch.quantity = int.tryParse(quantity);
                }

                Get.back();
                if (categoryId != null) {
                  fetchMyGroceryProducts(categoryId: categoryId);
                }
              },
            ));
      },
    );
  }

  RxBool isDeleteInventoryLoading = false.obs;
  Future<void> deleteInventory({
    required String inventoryId,
    String? categoryId,
  }) async {
    try {
      isDeleteInventoryLoading.value = true;

      ResponseModel response = await MedicalRepo().deleteMedicalInventoryRepo(
        inventoryId: inventoryId,
      );

      if (!response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      commonSnackBar(message: response.message ?? AppStrings.medicalInventoryDeleted.tr);
      if (categoryId != null) {
        fetchMyGroceryProducts(categoryId: categoryId);
      }
    } catch (e, s) {
      log('deleteInventory error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isDeleteInventoryLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // VARIANT UPDATE / DELETE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  RxBool isUpdateVariantLoading = false.obs;
  Future<void> updateVariant({
    required String variantId,
    String? variantName,
    List<Map<String, dynamic>>? pricing,
  }) async {
    try {
      isUpdateVariantLoading.value = true;
      Map<String, dynamic> body = {};
      if (variantName != null) body['variantName'] = variantName;
      if (pricing != null) body[ApiKeys.pricing] = pricing;

      ResponseModel response = await MedicalRepo().updateMedicalVariantRepo(
        variantId: variantId,
        params: body,
      );

      if (!response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      /// 200 = direct update (admin), 202 = change request submitted (business)
      final statusCode = response.response?.statusCode;
      if (statusCode == 202) {
        commonSnackBar(message: AppStrings.medicalUpdateRequestSubmitted);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.medicalVariantUpdated.tr);
      }
      update();
    } catch (e, s) {
      log('updateVariant error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUpdateVariantLoading.value = false;
    }
  }

  RxBool isDeleteVariantLoading = false.obs;
  Future<void> deleteVariant({required String variantId}) async {
    try {
      isDeleteVariantLoading.value = true;

      ResponseModel response = await MedicalRepo().deleteMedicalVariantRepo(
        variantId: variantId,
      );

      if (!response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      commonSnackBar(message: response.message ?? AppStrings.medicalVariantDeleted.tr);
      update();
    } catch (e, s) {
      log('deleteVariant error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isDeleteVariantLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CHANGE REQUESTS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Rx<ApiResponse> changeRequestsResponse = ApiResponse.initial('Initial').obs;
  RxList<MedicalChangeRequest> changeRequestsList = <MedicalChangeRequest>[].obs;

  RxBool isChangeRequestsLoading = false.obs;
  Future<void> fetchChangeRequests({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      isChangeRequestsLoading.value = true;

      ResponseModel response = await MedicalRepo().fetchMedicalChangeRequestsRepo(
        queryParams: {
          ApiKeys.status: status,
          ApiKeys.page: page,
          ApiKeys.limit: limit,
        },
      );

      if (response.isSuccess) {
        changeRequestsResponse.value = ApiResponse.complete(response);
        final parsed = MedicalChangeRequestsResponse.fromJson(response.response?.data);
        changeRequestsList.assignAll(parsed.data ?? []);
      } else {
        changeRequestsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      changeRequestsResponse.value = ApiResponse.error('error');
      log('fetchChangeRequests error: $s');
    } finally {
      isChangeRequestsLoading.value = false;
    }
  }

  Future<void> approveChangeRequest({required String requestId}) async {
    try {
      ResponseModel response = await MedicalRepo().approveMedicalChangeRequestRepo(
        requestId: requestId,
      );

      if (response.isSuccess) {
        changeRequestsList.removeWhere((r) => r.sId == requestId);
        commonSnackBar(message: response.message ?? AppStrings.medicalChangeRequestApproved.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('approveChangeRequest error: $s');
    }
  }

  Future<void> rejectChangeRequest({
    required String requestId,
    String? rejectionReason,
  }) async {
    try {
      ResponseModel response = await MedicalRepo().rejectMedicalChangeRequestRepo(
        requestId: requestId,
        params: rejectionReason != null ? {'rejectionReason': rejectionReason} : null,
      );

      if (response.isSuccess) {
        changeRequestsList.removeWhere((r) => r.sId == requestId);
        commonSnackBar(message: response.message ?? AppStrings.medicalChangeRequestRejected.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('rejectChangeRequest error: $s');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // MISSING PRODUCT REQUESTS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Rx<ApiResponse> missingProductsResponse = ApiResponse.initial('Initial').obs;
  RxList<MissingProductRequestData> myMissingProductRequests = <MissingProductRequestData>[].obs;

  RxBool isMissingProductsLoading = false.obs;
  Future<void> fetchMyMissingProductRequests({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      isMissingProductsLoading.value = true;
      Map<String, dynamic> params = {
        ApiKeys.page: page,
        ApiKeys.limit: limit,
      };
      if (status != null) params[ApiKeys.status] = status;

      ResponseModel response = await MedicalRepo().fetchMyMissingProductRequestsRepo(
        queryParams: params,
      );

      if (response.isSuccess) {
        missingProductsResponse.value = ApiResponse.complete(response);
        final parsed = MyMissingProductRequestsResponse.fromJson(response.response?.data);
        myMissingProductRequests.assignAll(parsed.data ?? []);
      } else {
        missingProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      missingProductsResponse.value = ApiResponse.error('error');
      log('fetchMyMissingProductRequests error: $s');
    } finally {
      isMissingProductsLoading.value = false;
    }
  }

  RxBool isCreateMissingProductLoading = false.obs;
  Future<void> createMissingProductRequest({
    required String name,
    required String brand,
    required String searchKeywords,
    required String unit,
    required num approxPrice,
    required String cityName,
    required String pincode,
    String? productImagePath,
  }) async {
    try {
      isCreateMissingProductLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.name: name,
        ApiKeys.brand: brand,
        'searchKeywords': searchKeywords,
        ApiKeys.unit: unit,
        'approxPrice': approxPrice,
        ApiKeys.cityName: cityName,
        ApiKeys.pincode: pincode,
      };

      bool isMultipart = false;
      if (productImagePath != null && productImagePath.isNotEmpty) {
        final fileName = productImagePath.split('/').last;
        body['productImage'] = await dio.MultipartFile.fromFile(
          productImagePath,
          filename: fileName,
        );
        isMultipart = true;
      }

      ResponseModel response = await MedicalRepo().createMissingProductRequestRepo(
        params: body,
        isMultipart: isMultipart,
      );

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalMissingProductRequestRaised.tr);
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('createMissingProductRequest error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isCreateMissingProductLoading.value = false;
    }
  }

  RxBool isBulkMissingProductLoading = false.obs;
  Future<void> createBulkMissingProductRequests({
    required String cityName,
    required String pincode,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      isBulkMissingProductLoading.value = true;
      Map<String, dynamic> body = {
        ApiKeys.cityName: cityName,
        ApiKeys.pincode: pincode,
        'items': items,
      };

      ResponseModel response = await MedicalRepo().createBulkMissingProductRequestsRepo(
        params: body,
      );

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalMissingProductRequestsRaised.tr);
        Get.back();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('createBulkMissingProductRequests error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isBulkMissingProductLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // SMART CART (Snap & Search)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Rx<ApiResponse> snapSearchResponse = ApiResponse.initial('Initial').obs;
  final snapSearchResult = Rxn<SnapSearchData>();

  RxBool isSnapSearchLoading = false.obs;
  Future<void> snapSearch({required List<String> imagePaths}) async {
    try {
      isSnapSearchLoading.value = true;
      snapSearchResult.value = null;

      List<dio.MultipartFile> imageFiles = [];
      for (final path in imagePaths) {
        final fileName = path.split('/').last;
        imageFiles.add(
          await dio.MultipartFile.fromFile(path, filename: fileName),
        );
      }

      Map<String, dynamic> params = {
        ApiKeys.images: imageFiles,
      };

      ResponseModel response = await MedicalRepo().snapSearchRepo(params: params);

      if (response.isSuccess) {
        snapSearchResponse.value = ApiResponse.complete(response);
        final parsed = SnapSearchResultModel.fromJson(response.response?.data);
        snapSearchResult.value = parsed.data;
        productSnapSearchData.value = parsed.data;
        medicalSnapSearchResponse.value = ApiResponse.complete(response);

        Get.toNamed(RouteHelper.getAddMedicalSnapSearchScreenRoute());
      } else {
        snapSearchResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      snapSearchResponse.value = ApiResponse.error('error');
      log('snapSearch error: $s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSnapSearchLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BUSINESS ORDERS (status/me, orders/me)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Rx<ApiResponse> orderStatusMeResponse = ApiResponse.initial('Initial').obs;

  RxBool isOrderStatusMeLoading = false.obs;
  Future<void> fetchOrderStatusMe() async {
    try {
      isOrderStatusMeLoading.value = true;
      ResponseModel response = await MedicalRepo().fetchMedicalOrderStatusMeRepo();
      if (response.isSuccess) {
        orderStatusMeResponse.value = ApiResponse.complete(response);
      } else {
        orderStatusMeResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      orderStatusMeResponse.value = ApiResponse.error('error');
      log('fetchOrderStatusMe error: $s');
    } finally {
      isOrderStatusMeLoading.value = false;
    }
  }

  Rx<ApiResponse> ordersMeResponse = ApiResponse.initial('Initial').obs;

  RxBool isOrdersMeLoading = false.obs;
  Future<void> fetchOrdersMe({
    int page = 1,
    int limit = 10,
    String? orderStatus,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      isOrdersMeLoading.value = true;
      Map<String, dynamic> params = {
        ApiKeys.page: page,
        ApiKeys.limit: limit,
        ApiKeys.sortBy: sortBy,
        'sortOrder': sortOrder,
      };
      if (orderStatus != null) params['orderStatus'] = orderStatus;

      ResponseModel response = await MedicalRepo().fetchMedicalOrdersMeRepo(
        queryParams: params,
      );
      if (response.isSuccess) {
        ordersMeResponse.value = ApiResponse.complete(response);
      } else {
        ordersMeResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      ordersMeResponse.value = ApiResponse.error('error');
      log('fetchOrdersMe error: $s');
    } finally {
      isOrdersMeLoading.value = false;
    }
  }

}
