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
import 'package:BlueEra/features/me/medical/service/medical_local_store.dart';
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

  /// True when no `pricing[]` row matched the shop's pincode, so these are
  /// other cities' prices shown as a guide rather than what this shop sells
  /// at. Callers can label or de-emphasise them; nothing is hidden, because a
  /// merchant picking catalog items still needs a reference price.
  final bool isIndicative;

  const PriceResult({
    required this.sellingRange,
    required this.mrpRange,
    required this.discountRange,
    this.isIndicative = false,
  });
}

class MedicalController extends GetxController {
  Rx<ApiResponse> medicalCategoryResponse =
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

  /// Reactive, so the catalogue cards can show a live per-product variant
  /// count from inside their own Obx. The pre-publish variant screen still
  /// repaints through `update()` / GetBuilder — both notifications are sent.
  RxMap<String, List<VariantsData>> selectedProductVariants =
      <String, List<VariantsData>>{}.obs;

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

  RxMap<String, List<VariantsData>> selectedSnapSearchProductVariants = <String, List<VariantsData>>{}.obs;
  Rxn<SnapSearchData> productSnapSearchData = Rxn<SnapSearchData>();

  void toggleSnapSearchVariant(String productId, VariantsData variant) {
    // Never selectable: already in this pharmacy's own inventory. The snap
    // rows paint it locked; this is the guard behind them, so a stocked
    // variant cannot enter the cart however the row was tapped.
    if (isVariantStocked(variant.sId)) return;

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

      // State work before cosmetics — same ordering rule as the manual publish
      // path, and for the same reason: nothing after this may gate the cart
      // clear or the refresh.
      clearMedicalSelection();
      // Drops the freshness stamp AND the saved snapshot, then refetches — a
      // re-entry must not paint the pre-publish catalogue off disk.
      markInventoryChanged();

      Get.until((route) =>
          route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
      commonSnackBar(
        message: response.message ?? AppStrings.medicalProductsAddedSuccessfully.tr,
      );
      log('addMedicalSnapSearchProductNewVariant: published ${payload.length} variant(s)');
    } catch (e, s) {
      log('addMedicalSnapSearchProductNewVariant error: $e\n$s');
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
              // Same resolver as the manual publish path — this shop's pincode
              // row first, `pricing[0]` only as a fallback.
              "mrp": resolvePublishPricing(variant.pricing)?.mrp,
              "sellingPrice":
                  resolvePublishPricing(variant.pricing)?.sellingPrice,
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
        // Edit the row that will actually be PUBLISHED, not blindly
        // `pricing[0]`. For a shop whose pincode has its own catalog row those
        // are different entries, and editing index 0 would have looked like it
        // did nothing — the publish would still send the shop's own row.
        final target = resolvePublishPricing(variant.pricing);
        return EditMedicalVarientDialog(
          title: title,
          mrp: target?.mrp?.toString() ?? "",
          selling: target?.sellingPrice?.toString() ?? "",
          onSubmit: (mrp, sellingPrice) {
            target?.mrp = int.tryParse(mrp);
            target?.sellingPrice = int.tryParse(sellingPrice);
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

    selectedProductVariants.refresh();
    update(); // refresh UI
  }

  bool isVariantSelected(String productId, String variantId) {
    return selectedProductVariants[productId]?.any((v) => v.sId == variantId) ??
        false;
  }

  /// Variant-level selection, the way food does it: ticking the FIRST variant
  /// of a product is what puts the product in the cart, unticking the LAST one
  /// is what takes it out.
  ///
  /// So [selectedMedicalProducts] always means "products with at least one
  /// variant chosen" — which is what the floating cart counts and what the
  /// publish payload is built from. Selecting a whole product (the old Add
  /// button) published every pack the catalogue carries; a pharmacy stocking
  /// only the strip of 10 had no way to say so.
  void toggleVariantSelection(MedicalProductData product, VariantsData variant) {
    final productId = product.sId ?? '';
    final variantId = variant.sId ?? '';
    if (productId.isEmpty || variantId.isEmpty) return;

    // Never selectable: already in this pharmacy's own inventory, and a second
    // record against one catalogue variant is a duplicate row with a second
    // price. The sheet paints it locked; this is the guard behind it.
    if (isVariantStocked(variantId)) return;

    final current = List<VariantsData>.from(
        selectedProductVariants[productId] ?? const <VariantsData>[]);
    final idx = current.indexWhere((v) => v.sId == variantId);

    if (idx != -1) {
      current.removeAt(idx);
    } else {
      // The cap counts PRODUCTS, not variants, so it can only bite on the
      // first variant of a product that isn't in the cart yet.
      final bool isNewProduct =
          !selectedMedicalProducts.any((p) => p.sId == productId);
      if (isNewProduct && selectedMedicalProducts.length >= maxLimit) {
        commonSnackBar(message: AppStrings.medicalCannotSelectMore10);
        return;
      }
      current.add(variant);
    }

    if (current.isEmpty) {
      selectedProductVariants.remove(productId);
      selectedMedicalProducts.removeWhere((p) => p.sId == productId);
    } else {
      selectedProductVariants[productId] = current;
      if (!selectedMedicalProducts.any((p) => p.sId == productId)) {
        selectedMedicalProducts.add(product);
      }
    }

    selectedProductVariants.refresh();
    selectedMedicalProducts.refresh();
    update();
  }

  /// How many variants of [productId] are in the cart — the number the card's
  /// Add button shows.
  int selectedVariantCount(String? productId) =>
      selectedProductVariants[productId ?? '']?.length ?? 0;

  bool get canSubmitProducts {
    // An empty cart used to pass this loop vacuously, so Publish stayed lit
    // with nothing to send. Reachable now that unticking the last variant on
    // the variant screen empties the cart in place.
    if (selectedMedicalProducts.isEmpty) return false;
    for (final p in selectedMedicalProducts) {
      final variants = selectedProductVariants[p.sId];

      // If no entry OR empty variants list â†’ invalid
      if (variants == null || variants.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// The pincode the catalog is being browsed for — the shop's own pincode,
  /// falling back to the device's. Identical to what
  /// [fetchGroceryCategoryProducts] sends as `?pincode=`, so what the card
  /// shows and what the server was asked for can't drift apart.
  String get activePincode {
    final businessPincode = getOrPut(() => ViewBusinessDetailsController(),
                permanent: true)
            .businessProfileDetails
            .value
            ?.data
            ?.pincode
            ?.toString() ??
        '';
    if (businessPincode.trim().isNotEmpty) return businessPincode.trim();
    return LocationService.userCurrentAddress.value.postalCode.trim();
  }

  /// The one `pricing[]` row that applies to this shop — the entry whose
  /// `pincode` matches [activePincode] — or null when the catalog carries no
  /// price for this area.
  ///
  /// Every price surface should go through this instead of reaching for
  /// `pricing[0]`: index 0 is just whichever city the backend happened to
  /// write first (Delhi, in the sample payload), so a Surat shop was being
  /// shown a Delhi price as if it were its own.
  Pricing? resolveLocalPricing(List<Pricing>? pricingList, {String? pincode}) {
    final target = (pincode ?? activePincode).trim();
    if (target.isEmpty || pricingList == null) return null;
    for (final p in pricingList) {
      if ((p.pincode ?? '').trim() == target) return p;
    }
    return null;
  }

  /// `₹90`, or `—` when there is nothing to show. Public so the screens that
  /// format a single [Pricing] row themselves stay consistent with the cards.
  String formatMoney(num? value) => _money(value);

  /// The pricing row a **publish** is seeded from: this shop's pincode when
  /// the catalog has one, otherwise the first row.
  ///
  /// The fallback is deliberate and must stay. The add-variant screen and
  /// [buildInventoryPayload] both go through here so the price a merchant is
  /// shown before publishing is exactly the price that gets published. Using
  /// the strict [resolveLocalPricing] on the screen alone made it read "MRP
  /// not set / Price not set" for a catalog that has no Surat row, while the
  /// POST still happily sent the Delhi figures — display and payload
  /// disagreeing is worse than either one being approximate.
  Pricing? resolvePublishPricing(List<Pricing>? pricingList) {
    if (pricingList == null || pricingList.isEmpty) return null;
    return resolveLocalPricing(pricingList) ?? pricingList.first;
  }

  /// Resolves a variant's `pricing[]` into the three display strings.
  ///
  /// `pricing` is one row **per city**, and the catalog carries cities this
  /// shop doesn't sell in — a Surat pharmacy searching with `pincode=395010`
  /// still gets rows for Delhi and Mumbai back. So the entry matching
  /// [activePincode] is used when there is one, and only when there isn't do
  /// we fall back to a range across the other cities, flagged as indicative
  /// via [PriceResult.isIndicative] so a caller can label it.
  ///
  /// The old version skipped that step entirely and always min/max'd every
  /// city, which is why a ₹90 (Delhi) / ₹92 (Mumbai) product advertised
  /// "₹90 - ₹92" to a shop in Surat that has neither price.
  PriceResult getPriceDetails(List<Pricing>? v, {String? pincode}) {
    const empty = PriceResult(
      sellingRange: '—',
      mrpRange: '—',
      discountRange: '—',
    );

    // Rows with an actual selling price. An entry missing one can't be shown
    // and must not drag a range down to zero either.
    final priced =
        (v ?? const <Pricing>[]).where((p) => p.sellingPrice != null).toList();
    if (priced.isEmpty) return empty;

    double discountOf(Pricing p) {
      final mrp = p.mrp?.toDouble() ?? 0;
      final selling = p.sellingPrice?.toDouble() ?? 0;
      if (mrp <= 0 || selling > mrp) return 0;
      return ((mrp - selling) / mrp) * 100;
    }

    // Exact match on the pincode we searched with → that IS this shop's
    // price, so show one number rather than a range.
    final local = resolveLocalPricing(priced, pincode: pincode);

    if (local != null) {
      return PriceResult(
        sellingRange: _money(local.sellingPrice),
        mrpRange: _money(local.mrp),
        discountRange: _percent(discountOf(local)),
        isIndicative: false,
      );
    }

    String rangeOf(Iterable<num?> values, String Function(num?) format) {
      final present =
          values.whereType<num>().map((n) => n.toDouble()).toList()..sort();
      if (present.isEmpty) return '—';
      final min = present.first;
      final max = present.last;
      return min == max ? format(min) : '${format(min)} - ${format(max)}';
    }

    // Discounts are min/max'd over the per-row values, not derived from the
    // min/max price pair — that pairing produced descending nonsense like
    // "10% - 8% Off" because the cheapest row isn't the biggest discount.
    final discounts = priced.map(discountOf).toList()..sort();

    return PriceResult(
      sellingRange: rangeOf(priced.map((p) => p.sellingPrice), _money),
      mrpRange: rangeOf(priced.map((p) => p.mrp), _money),
      discountRange: discounts.first == discounts.last
          ? _percent(discounts.first)
          : '${_percent(discounts.first, withSuffix: false)} - ${_percent(discounts.last)}',
      isIndicative: true,
    );
  }

  /// `₹90`, not `₹90.0` — paise only appear when the value actually has them.
  String _money(num? value) {
    if (value == null) return '—';
    final asDouble = value.toDouble();
    final text = asDouble == asDouble.roundToDouble()
        ? asDouble.round().toString()
        : asDouble.toStringAsFixed(2);
    return '₹$text';
  }

  String _percent(double value, {bool withSuffix = true}) {
    final text = '${value.round()}%';
    return withSuffix ? '$text ${AppStrings.offCaps.tr}' : text;
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
        // As in the snap-search dialog above: edit the row that gets
        // published, not whichever city the catalog listed first.
        final target = resolvePublishPricing(variant.pricing);
        return EditMedicalVarientDialog(
          title: title,
          mrp: target?.mrp?.toString() ?? "",
          selling: target?.sellingPrice?.toString() ?? "",
          onSubmit: (mrp, sellingPrice) {
            target?.mrp = int.tryParse(mrp);
            target?.sellingPrice = int.tryParse(sellingPrice);
            // The edit lands in-place on a model object, which notifies
            // nothing. `update()` covers the GetBuilder screens; the cart rows
            // are an Obx over this map, so it needs poking too or the row
            // keeps showing the old price.
            selectedProductVariants.refresh();
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
      // Put it straight in the cart. The merchant created this pack in order
      // to publish it, and the review card now lists only what's picked — an
      // unticked new variant would simply vanish.
      toggleVariantSelection(medicalItem, newVariant);
      // The variant list is a plain List on the model, so nothing above
      // notifies the pickers. The variant sheet's Obx watches this map — poke
      // it so the row the merchant just created appears without reopening.
      selectedProductVariants.refresh();
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

      // ORDER MATTERS. State work first, cosmetics last.
      //
      // This used to snackbar before clearing and refetching, and
      // `response.message` threw on this endpoint's array body — so the throw
      // took out the cart clear AND both refresh calls, silently, leaving the
      // merchant on a Products tab that didn't contain what they had just
      // published. Nothing after this point is allowed to gate the data work.
      clearMedicalSelection();
      // Drops the freshness stamp AND the saved snapshot, then refetches (not
      // awaited: the pop and the snackbar shouldn't wait on two GETs).
      markInventoryChanged();

      Get.until((route) =>
                  route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
      commonSnackBar(
        message: response.message ?? AppStrings.medicalInventoryUpdatedSuccessfully.tr,
      );
      log('addMedicalProductNewVariant: published ${payload.length} variant(s)');
    } catch (e, s) {
      // Never swallow this again — an empty catch here is exactly what made
      // the missing refresh invisible.
      log('addMedicalProductNewVariant failed: $e\n$s');
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
              // Prefer this shop's own pincode row; `pricing[0]` (whichever
              // city the catalog listed first) is only the fallback. Same
              // resolver the add-variant screen displays from, so what the
              // merchant sees is what gets published.
              "mrp": resolvePublishPricing(variant.pricing)?.mrp,
              "sellingPrice":
                  resolvePublishPricing(variant.pricing)?.sellingPrice,
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
    bool silent = false,
  }) async {
    await Future.wait([
      fetchMyMedicalCategory(silent: silent),
      fetchMedicalBusinessProducts(
        businessId: businessId,
        otherStore: otherStore,
        silent: silent,
      ),
    ]);
  }

  /// Freshness guard for the Products tab, keyed per store — so re-opening the
  /// tab reuses what's already loaded instead of refetching on every visit.
  final FetchCache _medicalProductsTabCache = FetchCache();

  /// Products-tab fetch that no-ops while the data is still loaded & fresh.
  /// Use on tab open / screen re-entry; call [fetchMedicalProductsTabData]
  /// directly for an explicit refresh (pull-to-refresh, post-publish).
  ///
  /// Three layers, cheapest first:
  /// 1. [_medicalProductsTabCache] — same store, fetched < 5 min ago, still in
  ///    memory.
  /// 2. [MedicalLocalStore] — the saved snapshot. **If there is one, that is
  ///    the answer and no request is made.**
  /// 3. The network — only when nothing is saved.
  ///
  /// The snapshot is not a head start on a request; it replaces the request.
  /// What keeps it honest is that every write the merchant makes (publish,
  /// inventory edit, variant edit, delete, stock toggle) runs
  /// [markInventoryChanged], which refetches and rewrites it — so the only way
  /// to be looking at stale stock is for it to have changed somewhere other
  /// than this device, and pull-to-refresh on the tab is the escape hatch.
  Future<void> fetchMedicalProductsTabDataIfNeeded({
    required String businessId,
    bool otherStore = false,
  }) async {
    // No id, nothing to fetch — but RESOLVE the tab's state rather than
    // returning silently. Nothing re-runs the dispatcher, so a bare `return`
    // leaves the Products tab shimmering on `Status.INITIAL` for good, with no
    // error and no retry. See `FoodMainScreen._fetchProductsTab`.
    if (businessId.isEmpty) {
      log('medical: businessId unresolved — Products tab has nothing to fetch');
      _resolveCategoryFailure(silent: false);
      _resolveBusinessProductsFailure(silent: false);
      return;
    }

    final signature = 'medical|$businessId|$otherStore';
    final hasData = myMedicalCategoryList.isNotEmpty ||
        medicalBusinessProductsList.isNotEmpty;
    if (_medicalProductsTabCache.isFresh(signature, hasData: hasData)) return;

    if (await _hydrateMedicalDataFromCache(businessId, otherStore)) {
      // Stamped so a tab switch doesn't go back to disk either.
      _medicalProductsTabCache.mark(signature);
      return;
    }

    await fetchMedicalProductsTabData(
      businessId: businessId,
      otherStore: otherStore,
    );
    // Stamp only once BOTH lists actually loaded.
    //
    // Categories alone used to be enough, and that is what stranded the tab:
    // `hasData` on the guard is an OR across the two lists, so a run where the
    // categories landed and the top-selling request did not stamped the guard
    // anyway — and every later entry then took the early return and never
    // retried the half that failed, leaving its shimmer running.
    //
    // COMPLETE means the REQUEST succeeded, not that rows came back, so an
    // empty catalogue still stamps and still gets its 5-minute reuse.
    if (fetchMyMedicalCategoryResponse.value.status == Status.COMPLETE &&
        fetchMedicalBusinessProductsResponse.value.status == Status.COMPLETE) {
      _medicalProductsTabCache.mark(signature);
    }
  }

  /// Records a failed category fetch.
  ///
  /// A silent refresh normally leaves the status alone — that is the point of
  /// `silent`: keep the rendered rows and their COMPLETE state while
  /// replacements are fetched, so the tab doesn't blink. **But a status that
  /// has never resolved is not worth protecting.** The Products tab renders
  /// its shimmer on `Status.INITIAL`, so a silent failure over an unresolved
  /// status left that shimmer running with nothing scheduled to stop it. Same
  /// failure mode the food tab was fixed for; see
  /// `FoodMainScreen._fetchProductsTab`.
  void _resolveCategoryFailure({required bool silent}) {
    final unresolved =
        fetchMyMedicalCategoryResponse.value.status == Status.INITIAL;
    if (!silent || unresolved) {
      fetchMyMedicalCategoryResponse.value = ApiResponse.error('error');
    }
  }

  /// Top-selling counterpart of [_resolveCategoryFailure].
  void _resolveBusinessProductsFailure({required bool silent}) {
    final unresolved =
        fetchMedicalBusinessProductsResponse.value.status == Status.INITIAL;
    if (!silent || unresolved) {
      fetchMedicalBusinessProductsResponse.value = ApiResponse.error('error');
    }
  }

  /// Paints the Products tab from the last saved snapshot.
  ///
  /// Returns true only when something was actually restored — false sends the
  /// caller to the network. Deliberately tolerant: a snapshot that fails to
  /// parse (a model changed shape since it was written) counts as a miss, so a
  /// bad cache degrades into a normal fetch rather than an error the user sees.
  ///
  /// Both lists must restore for this to report success. Restoring one and
  /// declaring victory would leave the other permanently empty, since a `true`
  /// return means no request is made.
  Future<bool> _hydrateMedicalDataFromCache(
      String storeId, bool otherStore) async {
    // Owner scope only. A customer browsing someone else's pharmacy has no way
    // to invalidate a snapshot — they can't publish, edit or restock anything —
    // so a cache-first read with no revalidation would freeze that shelf on
    // their device indefinitely. Their fetches stay live (in-memory guard
    // only), exactly as before.
    if (otherStore || storeId.isEmpty) return false;

    List<MyMedicalSuperCategoryModel>? categories;
    List<BusinessProductData>? topSelling;
    try {
      final entry =
          await MedicalLocalStore.readCategories(storeId, otherStore: false);
      if (entry != null && !entry.isEmpty) {
        categories = entry.items
            .whereType<Map>()
            .map((e) => MyMedicalSuperCategoryModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      log('medical: category cache hydrate failed — $e');
    }
    try {
      final entry =
          await MedicalLocalStore.readTopSelling(storeId, otherStore: false);
      if (entry != null && !entry.isEmpty) {
        topSelling = GroceryBusinessProductsModel.fromJson({
          'data': entry.items,
        }).data;
      }
    } catch (e) {
      log('medical: top-selling cache hydrate failed — $e');
    }

    // Half a snapshot is not a snapshot: publish nothing unless both sides
    // restored, or the missing list would stay empty with no request coming.
    if (categories == null ||
        categories.isEmpty ||
        topSelling == null ||
        topSelling.isEmpty) {
      return false;
    }

    myMedicalCategoryList.value = categories;
    fetchMyMedicalCategoryResponse.value = ApiResponse.complete();
    // Starts as `true` and is only ever cleared by a fetch's `finally` — a
    // hydrate makes no fetch, so without this the Products tab shimmers over
    // data it already has.
    myMedicalCategoryLoading.value = false;

    medicalBusinessProductsList.value = topSelling;
    // The snapshot only ever holds page 1, so "load more" resumes at page 2 —
    // and a short page means the server had nothing after it.
    _medicalBusinessProductsPage = 2;
    _medicalBusinessProductsHasMore =
        topSelling.length >= _medicalBusinessProductsLimit;
    fetchMedicalBusinessProductsResponse.value = ApiResponse.complete();
    return true;
  }

  /// Called after any inventory write (publish / inventory edit / variant edit
  /// / delete / stock toggle) that the merchant just made.
  ///
  /// The sheets already patch their own models in place, so the screen is
  /// correct the moment the call returns. What this fixes is everything the
  /// patch cannot reach: the 5-minute freshness guard that would otherwise
  /// short-circuit the next tab entry, the sibling list that still holds the
  /// old row, and the disk snapshot, which must never outlive the change that
  /// invalidated it.
  ///
  /// The server is the source of truth for the rewrite: rather than editing the
  /// cached JSON — which would mean re-implementing every mutation against a
  /// second data shape — the snapshot is **deleted** and then rebuilt from a
  /// refetch.
  ///
  /// Deleting first, rather than overwriting when the refetch lands, is what
  /// makes the race safe. The merchant can leave the add-medicine flow and be
  /// back on the tab before the refetch resolves; with the old snapshot still
  /// on disk, that re-entry would hydrate the pre-mutation list and stamp it
  /// fresh, hiding the change until the guard expired.
  void markInventoryChanged({String? storeId}) {
    _medicalProductsTabCache.invalidate();
    medicalBusinessProductsList.refresh();
    myMedicalCategoryList.refresh();
    // The write that got us here also changed which catalogue variants this
    // pharmacy holds, and the add flow badges what is already stocked. Done
    // here rather than at each call site so a new write path cannot forget it.
    markStockedVariantsChanged(storeId: storeId);

    final id = (storeId == null || storeId.isEmpty) ? businessId : storeId;
    if (id.isEmpty) return;
    // Fire-and-forget: the caller is a sheet closing on a completed write, or a
    // publish popping back, and nothing on screen is waiting for this.
    unawaited(MedicalLocalStore.clearStore(id).then(
      (_) => fetchMedicalProductsTabData(businessId: id, silent: true),
    ));
  }

  // ─── Already-stocked variants ──────────────────────────────────────────────
  // Medical mirror of the food flow — see
  // `FoodServiceController.fetchStockedVariantIdsIfNeeded`. The medical add
  // flow selects a whole PRODUCT, so the gate lands on the card: a product
  // whose every variant is already stocked is not offerable, and a partly
  // stocked one says how far along it is.

  /// productVariant ids this pharmacy ALREADY has in its inventory.
  final RxSet<String> stockedVariantIds = <String>{}.obs;

  /// Freshness guard, keyed per store, so re-entering the add flow reuses the
  /// answer instead of refetching.
  final FetchCache _stockedVariantIdsCache = FetchCache();

  /// Load the stocked-variant set, cheapest source first:
  ///
  /// 1. in-memory, same store, fetched < 5 min ago;
  /// 2. the saved snapshot on disk;
  /// 3. the network.
  ///
  /// The snapshot REPLACES the request rather than racing it: the only thing
  /// that changes this set on this device is the merchant publishing or
  /// deleting, and both run [markInventoryChanged].
  Future<void> fetchStockedVariantIdsIfNeeded() async {
    final id = businessId;
    if (id.isEmpty) return;

    final signature = 'medicalStockedVariants|$id';
    if (_stockedVariantIdsCache.isFresh(signature,
        hasData: stockedVariantIds.isNotEmpty)) {
      return;
    }

    try {
      final entry = await MedicalLocalStore.readStockedVariantIds(id);
      if (entry != null && !entry.isEmpty) {
        stockedVariantIds
          ..clear()
          ..addAll(entry.items.map((e) => e.toString()));
        _stockedVariantIdsCache.mark(signature);
        return;
      }
    } catch (e) {
      log('medical: stocked-variant cache hydrate failed — $e');
    }

    await fetchStockedVariantIds();
  }

  /// Unguarded fetch. Use for an explicit refresh; screen entry should go
  /// through [fetchStockedVariantIdsIfNeeded].
  Future<void> fetchStockedVariantIds() async {
    final id = businessId;
    if (id.isEmpty) return;
    try {
      final response =
          await MedicalRepo().getInventoryProductVariantIdsRepo(businessId: id);
      if (!response.isSuccess) return;

      final raw = response.response?.data?['data']?['productVariantIds'];
      if (raw is! List) return;
      final ids = [
        for (final value in raw)
          if ((value?.toString() ?? '').trim().isNotEmpty) value.toString(),
      ];

      stockedVariantIds
        ..clear()
        ..addAll(ids);
      _stockedVariantIdsCache.mark('medicalStockedVariants|$id');
      unawaited(MedicalLocalStore.writeStockedVariantIds(id, ids: ids));
    } catch (e, s) {
      log('medical fetchStockedVariantIds error: $e\n$s');
    }
  }

  /// Whether [variantId] is a catalogue variant the pharmacy already stocks.
  ///
  /// An EMPTY set means "not loaded / this store has nothing", and both answer
  /// false — the selection screens stay fully usable when the lookup fails
  /// rather than locking every card on a request that did not come back.
  bool isVariantStocked(String? variantId) {
    final id = (variantId ?? '').trim();
    return id.isNotEmpty && stockedVariantIds.contains(id);
  }

  /// Every variant of [product] is already stocked — the card can say so
  /// instead of offering an add that would publish duplicates.
  ///
  /// A product with NO variants answers false: `every` on an empty list is
  /// vacuously true, which would wrongly lock the card.
  bool isProductFullyStocked(MedicalProductData product) {
    final variants = product.variants ?? const <VariantsData>[];
    if (variants.isEmpty) return false;
    return variants.every((v) => isVariantStocked(v.sId));
  }

  /// How many of [product]'s variants are already stocked.
  int stockedVariantCount(MedicalProductData product) {
    final variants = product.variants ?? const <VariantsData>[];
    return variants.where((v) => isVariantStocked(v.sId)).length;
  }

  /// The set changed under us — a publish added variants, a delete removed one.
  ///
  /// Drops the guard AND the snapshot, then refetches. Without the snapshot
  /// delete a re-entry would paint the pre-publish set straight off disk and
  /// keep offering a variant the merchant just added.
  void markStockedVariantsChanged({String? storeId}) {
    final id = (storeId == null || storeId.isEmpty) ? businessId : storeId;
    _stockedVariantIdsCache.invalidate();
    if (id.isEmpty) return;
    unawaited(
      MedicalLocalStore.writeStockedVariantIds(id, ids: const [])
          .then((_) => fetchStockedVariantIds()),
    );
  }

  /// [silent] keeps the rendered list on screen while the call runs (hydrated
  /// from disk, or refreshed after a write) instead of blinking back to a
  /// skeleton.
  Future<void> fetchMedicalBusinessProducts({
    required String businessId,
    bool otherStore = false,
    bool isLoadMore = false,
    bool silent = false,
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
        // Paging always restarts, but a silent refresh keeps the rendered rows
        // until the replacements arrive — clearing here is what would make the
        // rail blink on every hydrate and after every write.
        _medicalBusinessProductsPage = 1;
        _medicalBusinessProductsHasMore = true;
        if (!silent) {
          fetchMedicalBusinessProductsResponse.value =
              ApiResponse.initial('Initial');
          medicalBusinessProductsList.clear();
        }
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
        // A failed SILENT refresh must not replace what the user is reading
        // with an error — the hydrated list stays, and the guard was already
        // left un-stamped so the next entry retries.
        if (!silent) {
          fetchMedicalBusinessProductsResponse.value =
              ApiResponse.error('error');
        }
        return;
      }

      final parsed =
          GroceryBusinessProductsModel.fromJson(responseModel.response?.data);
      final newItems = parsed.data ?? [];

      if (isLoadMore) {
        medicalBusinessProductsList.addAll(newItems);
      } else {
        medicalBusinessProductsList.value = newItems;
        // Page 1 only — that is exactly what the tab renders, and it keeps the
        // snapshot small however deep the user paged. Owner scope only — see
        // [_hydrateMedicalDataFromCache].
        if (!otherStore && businessId.isNotEmpty) {
          final raw = responseModel.response?.data;
          final rawItems =
              (raw is Map && raw['data'] is List) ? raw['data'] as List : const [];
          unawaited(MedicalLocalStore.writeTopSelling(
            businessId,
            otherStore: false,
            items: rawItems,
          ));
        }
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
      _resolveBusinessProductsFailure(silent: silent);
      log("fetchMedicalBusinessProducts failed: $e\n$s");
    } finally {
      if (isLoadMore) isMedicalBusinessProductsLoadingMore.value = false;
    }
  }

  /// [silent] keeps the rendered categories on screen while the call runs —
  /// see [fetchMedicalBusinessProducts].
  ///
  /// This endpoint is owner-only (it takes no store id and answers for the
  /// logged-in pharmacy), so its snapshot is always keyed to the global
  /// `businessId`.
  Future<void> fetchMyMedicalCategory({bool silent = false}) async {
    try {
      if (!silent) myMedicalCategoryLoading.value = true;
      ResponseModel responseModel = await MedicalRepo().fetchGroceryCategoryWithVariantRepo();
      if (responseModel.isSuccess) {
        fetchMyMedicalCategoryResponse.value = ApiResponse.complete(responseModel);
        final List listData = responseModel.response?.data ?? [];

        myMedicalCategoryList.value = listData
            .map((e) => MyMedicalSuperCategoryModel.fromJson(e))
            .toList();

        // Persist the raw payload, not the parsed models: the next open
        // rebuilds them with this same `fromJson`, so there is one parser to
        // keep right. See [_hydrateMedicalDataFromCache].
        if (businessId.isNotEmpty) {
          unawaited(MedicalLocalStore.writeCategories(
            businessId,
            otherStore: false,
            items: listData,
          ));
        }

        log("Loaded ${myMedicalCategoryList.length}");
      } else {
        _resolveCategoryFailure(silent: silent);
      }
    } catch (e) {
      _resolveCategoryFailure(silent: silent);
      log("ERROR===== 2 $e");
    } finally{
      if (!silent) myMedicalCategoryLoading.value = false;
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

      // 1) Cache-first — inside the TTL the saved tree IS the answer and the
      //    endpoint is not called at all. Unlike the pharmacy's own stock this
      //    tree can only change on the backend — nothing the merchant does
      //    invalidates it — so age is its only refresh trigger.
      //
      //    The list is NOT cleared up front any more: doing that emptied the
      //    grid for the length of the request even when a perfectly good tree
      //    was about to be restored.
      final entry = await MedicalLocalStore.readCatalogCategories();
      if (entry != null && !entry.isEmpty) {
        final cached = entry.items
            .whereType<Map>()
            .map((e) =>
                MedicalNestedCategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (cached.isNotEmpty) {
          medicalNestedCategoryList.assignAll(cached);
          if (!entry.isOlderThan(MedicalLocalStore.catalogTtl)) {
            medicalNestedCategoryLoading.value = false;
            return;
          }
        }
      }

      // 2) Network refresh.
      ResponseModel responseModel = await MedicalRepo().fetchGroceryNestedCategoryRepo();
      if (responseModel.isSuccess) {
        fetchMyMedicalCategoryResponse.value = ApiResponse.complete(responseModel);

        if (responseModel.response?.data != null && responseModel.response!.data is List) {
          final List<dynamic> rawList =
              responseModel.response!.data as List<dynamic>;
          medicalNestedCategoryList.value = rawList
              .map((json) => MedicalNestedCategoryModel.fromJson(json))
              .toList();
          // Level-0 categories the snap-search grid renders (all of them).
          log('level-0 categories (${medicalNestedCategoryList.length}): '
              '${medicalNestedCategoryList.map((e) => '${e.name} [${e.key}] level=${e.level}').toList()}');
          // The RAW payload is what's saved (not `toJson()` of the models), so
          // the next open rebuilds it with the same `fromJson` a live response
          // goes through.
          await MedicalLocalStore.writeCatalogCategories(rawList);
        }
      } else if (medicalNestedCategoryList.isEmpty) {
        // Only surface an error when there's no cached tree on screen.
        fetchMyMedicalCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      log('stack trace -- $s');
      if (medicalNestedCategoryList.isEmpty) {
        fetchMyMedicalCategoryResponse.value = ApiResponse.error('error');
      }
    } finally{
      medicalNestedCategoryLoading.value = false;
    }
  }

  // ── Categories: progressive level → subtree drill-down ──────────────────
  // See docs/backend/MEDICAL_CATEGORIES_FLUTTER_GUIDE.md.

  /// Level-0 roots for the snap-search grid, loaded via
  /// `GET /categories/nested?level=0` — flat, WITHOUT the subtree payload.
  ///
  /// Deliberately separate from [medicalNestedCategoryList], which holds the
  /// FULL nested tree: `medical_category_screen.dart` renders each root's
  /// `children` inline and would break if that call were narrowed to level 0.
  RxList<MedicalNestedCategoryModel> medicalRootCategoryList =
      <MedicalNestedCategoryModel>[].obs;
  RxBool medicalRootCategoryLoading = true.obs;

  /// Loads the level-0 roots. Cheap by design — no `children` come back, so a
  /// tapped root is expanded by [fetchMedicalCategorySubtree].
  /// Cache-first under its own key, like the full tree: this is the grid the
  /// snap-search screen opens on, so it was re-asked on every visit.
  static const String _kMedicalLevel0 = 'level0';

  Future<void> fetchMedicalRootCategories() async {
    try {
      medicalRootCategoryLoading.value = true;

      final entry =
          await MedicalLocalStore.readCatalogChild(_kMedicalLevel0);
      if (entry != null && !entry.isEmpty) {
        final cached = entry.items
            .whereType<Map>()
            .map((e) => MedicalNestedCategoryModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList();
        if (cached.isNotEmpty) {
          medicalRootCategoryList.value = cached;
          if (!entry.isOlderThan(MedicalLocalStore.catalogTtl)) {
            medicalRootCategoryLoading.value = false;
            return;
          }
        }
      }

      ResponseModel responseModel = await MedicalRepo()
          .fetchGroceryNestedCategoryRepo(queryParams: {'level': 0});
      if (responseModel.isSuccess && responseModel.response?.data is List) {
        final List<dynamic> rawList =
            responseModel.response!.data as List<dynamic>;
        medicalRootCategoryList.value = rawList
            .map((json) => MedicalNestedCategoryModel.fromJson(json))
            .toList();
        if (rawList.isNotEmpty) {
          await MedicalLocalStore.writeCatalogChild(_kMedicalLevel0, rawList);
        }
      } else if (medicalRootCategoryList.isEmpty) {
        // Only clear when there is no cached grid on screen — a failed refresh
        // must not empty a list the merchant is already looking at.
        medicalRootCategoryList.clear();
      }
    } catch (e, s) {
      log('stack trace -- $s');
      if (medicalRootCategoryList.isEmpty) medicalRootCategoryList.clear();
    } finally {
      medicalRootCategoryLoading.value = false;
    }
  }

  /// Expands one root into its full nested subtree via
  /// `GET /categories/nested?categoryId=<id>`. Returns the node — its
  /// `children` are the level-1 categories, each nested down to the level-3
  /// leaves — or null when the call fails.
  ///
  /// Unlike the level query, this responds with a single OBJECT, not a list.
  ///
  /// The caller owns the loading state — [MedicalLevel2CategoryScreen] opens
  /// first and shimmers while this runs, so there's no shared "expanding" flag
  /// for the grid that launched it.
  /// Cache-first, one entry per category id. This is the drill-down the
  /// merchant taps through on the way to a medicine, so the same subtree gets
  /// asked for again on every pass; inside [MedicalLocalStore.catalogTtl] the
  /// saved node IS the answer and no request is made.
  Future<MedicalNestedCategoryModel?> fetchMedicalCategorySubtree(
      String categoryId) async {
    if (categoryId.isEmpty) return null;
    try {
      final entry = await MedicalLocalStore.readCatalogChild(categoryId);
      final cached = entry?.map;
      if (cached != null &&
          cached.isNotEmpty &&
          !entry!.isOlderThan(MedicalLocalStore.catalogTtl)) {
        return MedicalNestedCategoryModel.fromJson(cached);
      }

      ResponseModel responseModel = await MedicalRepo()
          .fetchGroceryNestedCategoryRepo(
              queryParams: {'categoryId': categoryId});
      final data = responseModel.response?.data;
      if (responseModel.isSuccess && data is Map) {
        final normalised = Map<String, dynamic>.from(data);
        unawaited(MedicalLocalStore.writeCatalogChild(categoryId, normalised));
        return MedicalNestedCategoryModel.fromJson(normalised);
      }
      // A stale saved node beats nothing at all when the network says no.
      if (cached != null && cached.isNotEmpty) {
        return MedicalNestedCategoryModel.fromJson(cached);
      }
      return null;
    } catch (e, s) {
      log('stack trace -- $s');
      return null;
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
      // Stock/price just changed on the server — the saved snapshot must not
      // outlive it. See [markInventoryChanged].
      markInventoryChanged();
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
      // A deleted inventory row must not come back from disk on the next open.
      markInventoryChanged();
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
        // Only a DIRECT update (200) changed the catalogue. A 202 means a
        // change request is pending approval — nothing to invalidate yet, and
        // dropping the snapshot then would just cost a pointless refetch.
        markInventoryChanged();
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
      // Same reason as [deleteInventory].
      markInventoryChanged();
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
