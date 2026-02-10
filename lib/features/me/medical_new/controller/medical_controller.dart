import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_product_model.dart';
import 'package:BlueEra/features/me/medical_new/model/my_medical_super_category_model.dart';
import 'package:BlueEra/features/me/medical_new/view/edit_medical_varient_dialog.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_varient_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/my_medical_products_response.dart';
import 'package:BlueEra/features/me/medical_new/repo/medical_repo.dart';

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

  void toggleSelection(MedicalProductData p) {
    if (selectedMedicalProducts.contains(p)) {
      selectedMedicalProducts.remove(p);
    } else {
      if (selectedMedicalProducts.length >= 10) {
        commonSnackBar(
            message: 'You can’t select more than 10 medical products at a time.');
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
    showDialog(
      context: context,
      barrierDismissible: !isCreateNewMedicalProductNewVariantLoading.value,
      builder: (_) {
        return MedicalVariantDialog(
          title: "Add More Variant",
          onSubmit: (weight, unit, mrp, sellingPrice) {
            createNewMedicalProductNewVariant(
                medicalItem: groceryItem,
                productId: groceryItem.sId ?? '',
                weight: weight,
                unit: unit,
                mrp: mrp,
                sellingPrice: sellingPrice);
          },
          isAddGroceryProductNewVariantLoading: isCreateNewMedicalProductNewVariantLoading.value,
        );
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

      // log('current tab key-- $currentTabKey');
      Map<String, dynamic> queryParams = {
        ApiKeys.page: medicalCategoryProductsPage,
        ApiKeys.limit: pageLimit
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
      log('success-- ${response.isSuccess}');
    } catch (e) {
      addMedicalProductVariantResponse.value = ApiResponse.error('error');
    } finally {
      isAddMedicalProductsLoading.value = false;
    }
  }

  List<Map<String, dynamic>> buildInventoryPayload() {
    List<Map<String, dynamic>> payload = [];
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController());
    String city = viewBusinessDetailsController.businessProfileDetails?.data?.cityStatePincode ?? LocationService.userCurrentAddress.value.city;
    String postalCode = viewBusinessDetailsController.businessProfileDetails?.data?.pincode ?? LocationService.userCurrentAddress.value.postalCode;

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

  /// Fetch Grocery Products
  RxBool myMedicalCategoryLoading = true.obs;
  RxList<MyMedicalSuperCategoryModel> myMedicalCategoryList = <MyMedicalSuperCategoryModel>[].obs;

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
      log("ERROR===== $e");
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

    try {
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
    } catch (e) {
      fetchMyMedicalProductsResponse.value = ApiResponse.error('error');
      log("ERROR===== $e");
    } finally{
      if (isLoadMore) {
        isMyMedicalDataLoadingMore.value = false;
      } else {
        isMyMedicalDataFirstLoading.value = false;
      }
    }
  }

  /// Fetch Grocery Products
  RxBool medicalNestedCategoryLoading = true.obs;
  RxList<MedicalNestedCategoryModel> medicalNestedCategoryList = <MedicalNestedCategoryModel>[].obs;

  Future<void> fetchGroceryNestedCategory() async {
    try {
      medicalNestedCategoryLoading.value = true;
      medicalNestedCategoryList.clear();

      final cachedData = await HiveServices().getMedicalNestedCategories();
      if (cachedData != null && cachedData.isNotEmpty) {
        medicalNestedCategoryLoading.value = false;
        medicalNestedCategoryList.assignAll(cachedData);
        return;
      }

      ResponseModel responseModel = await MedicalRepo().fetchGroceryNestedCategoryRepo();
      if (responseModel.isSuccess) {
        fetchMyMedicalCategoryResponse.value = ApiResponse.complete(responseModel);

        if (responseModel.response?.data != null && responseModel.response!.data is List) {
          medicalNestedCategoryList.value = (responseModel.response!.data as List)
              .map((json) => MedicalNestedCategoryModel.fromJson(json))
              .toList();
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


}
