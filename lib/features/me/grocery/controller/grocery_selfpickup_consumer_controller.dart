import 'dart:async';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';
import '../../../../core/routes/route_constant.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';

class GrocerySelfPickupConsumerController extends GetxController {
  Rx<ApiResponse> groceryCategoryOfChildrenResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> userGroceryCategoryResponse =
      ApiResponse.initial('Initial').obs;

  final selectedGroceryData = Rxn<GroceryNestedCategoryModel>();

  RxBool isInitialLoading = false.obs;

  RxInt selectedTabIndex = 0.obs;

  RxList<ProductVariants> selectedGroceriesVariants = <ProductVariants>[].obs;

  // Map to store quantity for each variant ID: { "variant_id": quantity }
  var cartQuantities = <String, int>{}.obs;

  // Map to store product ID for each variant ID: { "variant_id": "product_id" }
  var cartProductIds = <String, String>{}.obs;

  // Map to store product ID for each variant ID: { "variant_id": "inventory_id" }
  var cartInventoryIds = <String, String>{}.obs;

  // Map to store business info for each variant ID: { "variant_id": { businessId, businessName, logo, address } }
  var cartBusinessInfo = <String, Map<String, String>>{}.obs;

  /// Product image per variant id — fallback when the variant itself has no images.
  var cartProductImages = <String, String>{}.obs;

  // Map to store delivery type for each variant ID: { "variant_id": "SELF" | "RIDER" | "PARTNER" }
  // var cartDeliveryType = <String, String>{}.obs;

  // --- Actions ---
  void addToCart(
      ProductVariants variant,
      {String? productId, String? inventoryId,
      String? businessId, String? businessName, String? businessLogo, String? businessAddress,
      String? productImage,
      double? businessLat, double? businessLng,
      String? businessCategory,
      // String? deliveryType
      }) {
    if (variant.sId == null) return;

    if (cartQuantities.containsKey(variant.sId)) {
      cartQuantities[variant.sId!] = cartQuantities[variant.sId]! + 1;
    } else {
      selectedGroceriesVariants.add(variant);
      cartQuantities[variant.sId!] = 1;
      if (productId != null) {
        cartProductIds[variant.sId!] = productId;
      }
      if (inventoryId != null) {
        cartInventoryIds[variant.sId!] = inventoryId;
      }
      if (businessId != null) {
        // lat / lng / category travel with the rest of the business
        // metadata so the cart screen can render distance + shop-type
        // pill without re-fetching the profile.
        cartBusinessInfo[variant.sId!] = {
          'businessId': businessId,
          'businessName': businessName ?? '',
          'logo': businessLogo ?? '',
          'address': businessAddress ?? '',
          'lat': businessLat?.toString() ?? '',
          'lng': businessLng?.toString() ?? '',
          'category': businessCategory ?? '',
        };
      }
      if (productImage != null && productImage.isNotEmpty) {
        cartProductImages[variant.sId!] = productImage;
      }
      // if (deliveryType != null) {
      //   cartDeliveryType[variant.sId!] = deliveryType;
      // }
    }
  }

  void removeFromCart(ProductVariants variant) {
    if (variant.sId == null || !cartQuantities.containsKey(variant.sId)) return;

    int currentQty = cartQuantities[variant.sId]!;

    if (currentQty > 1) {
      cartQuantities[variant.sId!] = currentQty - 1;
    } else {
      // Quantity is 1, so remove completely
      cartQuantities.remove(variant.sId);
      cartProductIds.remove(variant.sId);
      cartInventoryIds.remove(variant.sId);
      cartBusinessInfo.remove(variant.sId);
      cartProductImages.remove(variant.sId);
      // cartDeliveryType.remove(variant.sId);
      selectedGroceriesVariants.removeWhere((v) => v.sId == variant.sId);
    }
  }

  String? getProductId(String? variantId) {
    if (variantId == null) return null;
    return cartProductIds[variantId];
  }

  int getQuantity(String? variantId) {
    if (variantId == null) return 0;
    return cartQuantities[variantId] ?? 0;
  }

  // --- Computed Bill Details ---

  double get totalMRP {
    double total = 0;
    for (var variant in selectedGroceriesVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;
      double mrp =
          double.tryParse(variant.pricing?.first.mrp.toString() ?? '0') ?? 0;
      total += (mrp * qty);
    }
    return total;
  }

  double get totalSellingPrice {
    double total = 0;
    for (var variant in selectedGroceriesVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;
      double sp = double.tryParse(
              variant.pricing?.first.sellingPrice.toString() ?? '0') ??
          0;
      total += (sp * qty);
    }
    return total;
  }

  double get totalSavings => totalMRP - totalSellingPrice;

  double get totalDiscountPercentage {
    if (totalMRP == 0) return 0.0;

    double percentage = (totalSavings / totalMRP) * 100;
    return percentage;
  }

  int get totalItemsCount {
    int count = 0;
    cartQuantities.forEach((key, value) {
      count += value;
    });
    return count;
  }


  List<Map<String, dynamic>> buildBulkOrderItems() {
    List<Map<String, dynamic>> items = [];

    for (var variant in selectedGroceriesVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;

      if (qty > 0) {
        double mrp =
            double.tryParse(variant.pricing?.first.mrp.toString() ?? '0') ?? 0;
        double sp = double.tryParse(
                variant.pricing?.first.sellingPrice.toString() ?? '0') ??
            0;

        items.add({
          "inventory": cartInventoryIds[variant.sId] ?? "",
          "productVariant": variant.sId ?? "",
          "quantity": qty,
          "mrp": mrp,
          "sellingPrice": sp,
        });
      }
    }

    return items;
  }

  RxBool isPlaceBulkGroceryOrderLoading = false.obs;
  Rx<ApiResponse> placeBulkGroceryOrderResponse =
      ApiResponse.initial('Initial').obs;

  Future<void> placeBulkGroceryOrderApi() async {
    // try {
      isPlaceBulkGroceryOrderLoading.value = true;
      AppLoader.show();

      final itemsList = buildBulkOrderItems();

      final Map<String, dynamic> requestBody = {
        "items": itemsList,
        "deliveryType": "self-pickup",
        "discount": totalSavings,
      };

      final response =
          await GroceryRepo().placeBulkGroceryOrderApi(params: requestBody);

      if (!response.isSuccess) {
        AppLoader.hide();
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }
      // Land on Discover (index 1) instead of the chat screen — the placed
      // order surfaces there in the "Orders in 12 Hrs." rail. The business
      // chat list is still refreshed so that rail has the new row.
      final controller = getOrPut(() => BottomBarController());
      controller.onChangeIndex(1);

      ChatViewController  chatViewController = getOrPut(() => ChatViewController());
      Get.until((route) => route.settings.name ==  RouteConstant.BottomNavigationBarScreen);
      chatViewController.emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.business_Chat_Type},);

      placeBulkGroceryOrderResponse.value = ApiResponse.complete(response);
      AppLoader.hide();
      selectedGroceriesVariants.clear();
      cartQuantities.clear();
      cartBusinessInfo.clear();
      cartProductImages.clear();



    // } catch (e) {
    //   AppLoader.hide();
    //   placeBulkGroceryOrderResponse.value = ApiResponse.error('error');
    // } finally {
    //   isPlaceBulkGroceryOrderLoading.value = false;
    // }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  MULTI-STORE (Zomato-style) — items from different grocery stores stack
  //  into separate per-store carts; the user checks out one store or all.
  //  Built on top of the existing maps (cartBusinessInfo carries the store).
  // ═══════════════════════════════════════════════════════════════════════

  bool get isEmpty => selectedGroceriesVariants.isEmpty;

  String? _businessIdOf(ProductVariants v) =>
      cartBusinessInfo[v.sId]?['businessId'];

  /// Distinct business ids currently in the cart, in first-added order.
  List<String> get storeKeys {
    final seen = <String>[];
    for (final v in selectedGroceriesVariants) {
      final bid = _businessIdOf(v);
      if (bid != null && bid.isNotEmpty && !seen.contains(bid)) seen.add(bid);
    }
    return seen;
  }

  int get storeCount => storeKeys.length;

  /// Store metadata map ({businessName, logo, address, lat, lng, category})
  /// for a business id, read off any of its variants.
  Map<String, String> storeInfoOf(String businessId) {
    for (final v in selectedGroceriesVariants) {
      final info = cartBusinessInfo[v.sId];
      if (info != null && info['businessId'] == businessId) return info;
    }
    return const {};
  }

  List<ProductVariants> variantsOf(String businessId) => selectedGroceriesVariants
      .where((v) => _businessIdOf(v) == businessId)
      .toList();

  int itemCountOf(String businessId) {
    int c = 0;
    for (final v in variantsOf(businessId)) {
      c += cartQuantities[v.sId] ?? 0;
    }
    return c;
  }

  double _spOf(ProductVariants v) =>
      double.tryParse(v.pricing?.first.sellingPrice.toString() ?? '0') ?? 0;
  double _mrpOf(ProductVariants v) =>
      double.tryParse(v.pricing?.first.mrp.toString() ?? '0') ?? 0;

  double subtotalOf(String businessId) {
    double t = 0;
    for (final v in variantsOf(businessId)) {
      t += _spOf(v) * (cartQuantities[v.sId] ?? 0);
    }
    return t;
  }

  double savingsOf(String businessId) {
    double mrp = 0, sp = 0;
    for (final v in variantsOf(businessId)) {
      final q = cartQuantities[v.sId] ?? 0;
      final m = _mrpOf(v);
      final s = _spOf(v);
      mrp += (m > 0 ? m : s) * q;
      sp += s * q;
    }
    final diff = mrp - sp;
    return diff > 0 ? diff : 0;
  }

  String? imageOf(ProductVariants v) {
    if (v.images?.isNotEmpty ?? false) {
      final url = v.images!.first.url;
      if (url != null && url.isNotEmpty) return url;
    }
    final fb = cartProductImages[v.sId];
    return (fb != null && fb.isNotEmpty) ? fb : null;
  }

  List<String?> previewImagesOf(String businessId) =>
      variantsOf(businessId).take(3).map(imageOf).toList();

  /// Drop one store's cart entirely (the × on a cart card).
  void clearStore(String businessId) {
    final ids =
        variantsOf(businessId).map((v) => v.sId).whereType<String>().toSet();
    for (final id in ids) {
      cartQuantities.remove(id);
      cartProductIds.remove(id);
      cartInventoryIds.remove(id);
      cartBusinessInfo.remove(id);
      cartProductImages.remove(id);
    }
    selectedGroceriesVariants.removeWhere((v) => ids.contains(v.sId));
  }

  void clearAll() {
    selectedGroceriesVariants.clear();
    cartQuantities.clear();
    cartProductIds.clear();
    cartInventoryIds.clear();
    cartBusinessInfo.clear();
    cartProductImages.clear();
  }

}
