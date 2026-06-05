import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// Shared cart for the home made product flow. Registered once at the list
/// screen (the flow entry) so the floating cart bar on both the list and the
/// store details screen — plus the cart page — all observe the same instance.
/// A cart belongs to a single seller ([store]); placing an order POSTs to
/// `earn-service/homeProductOrders` then opens the chat.
class HmpCartController extends GetxController {
  final _repo = ProductRepo();

  /// The seller the current cart belongs to (set when the first item is
  /// added). Null when the cart is empty.
  final Rxn<EarnProfileModel> store = Rxn<EarnProfileModel>();

  /// product id -> quantity (reactive source of truth).
  final RxMap<String, int> quantities = <String, int>{}.obs;

  /// product id -> model (plain lookup; reactivity is driven by [quantities]).
  final Map<String, GetProductData> _itemById = {};

  final RxBool isPlacingOrder = false.obs;

  // ── Field helpers off a [GetProductData] ──
  static String idOf(GetProductData p) => p.product.details?.id ?? '';

  static String nameOf(GetProductData p) => p.product.details?.name ?? '';

  static String? imageOf(GetProductData p) {
    final media = p.product.details?.media ?? const [];
    return media.isNotEmpty ? media.first : null;
  }

  static Variant? _variantOf(GetProductData p) {
    final variants = p.product.sellerClassification?.variants ?? const [];
    return variants.isNotEmpty ? variants.first : null;
  }

  static double sellingPriceOf(GetProductData p) {
    final v = _variantOf(p);
    final sp = v?.sellingPrice ?? p.product.details?.mrpPerUnit ?? 0;
    return sp.toDouble();
  }

  static double mrpOf(GetProductData p) {
    final v = _variantOf(p);
    final mrp = v?.mrp ?? p.product.details?.mrpPerUnit ?? 0;
    return mrp.toDouble();
  }

  int qty(String? id) => id == null ? 0 : (quantities[id] ?? 0);

  /// Whether [fromStore] differs from the seller the cart already holds.
  bool isDifferentStore(EarnProfileModel fromStore) =>
      quantities.isNotEmpty &&
      store.value != null &&
      store.value!.id != fromStore.id;

  void add(GetProductData item, EarnProfileModel fromStore) {
    final id = idOf(item);
    if (id.isEmpty) return;
    store.value = fromStore;
    _itemById[id] = item;
    quantities[id] = (quantities[id] ?? 0) + 1;
  }

  void remove(GetProductData item) {
    final id = idOf(item);
    if (id.isEmpty) return;
    final current = quantities[id] ?? 0;
    if (current <= 1) {
      quantities.remove(id);
      _itemById.remove(id);
    } else {
      quantities[id] = current - 1;
    }
    if (quantities.isEmpty) store.value = null;
  }

  List<GetProductData> get lines => quantities.keys
      .map((id) => _itemById[id])
      .whereType<GetProductData>()
      .toList();

  bool get isEmpty => quantities.isEmpty;

  int get totalItems => quantities.values.fold(0, (sum, q) => sum + q);

  double get totalPrice {
    double total = 0;
    quantities.forEach((id, q) {
      final item = _itemById[id];
      if (item != null) total += sellingPriceOf(item) * q;
    });
    return total;
  }

  double get totalMrp {
    double total = 0;
    quantities.forEach((id, q) {
      final item = _itemById[id];
      if (item == null) return;
      final mrp = mrpOf(item);
      final sp = sellingPriceOf(item);
      total += (mrp > 0 ? mrp : sp) * q;
    });
    return total;
  }

  double get totalSavings {
    final s = totalMrp - totalPrice;
    return s > 0 ? s : 0;
  }

  List<String?> get previewImages => lines.take(3).map(imageOf).toList();

  void clear() {
    quantities.clear();
    _itemById.clear();
    store.value = null;
  }

  /// Build the order payload from the current cart — one entry per line with
  /// the variant's inventory id + variant id, quantity and prices.
  Map<String, dynamic> _buildPayload() {
    return {
      'items': lines.map((item) {
        final v = _variantOf(item);
        return {
          'inventory': v?.inventoryId ?? '',
          'productVariant': v?.id ?? '',
          'quantity': qty(idOf(item)),
          'mrp': mrpOf(item),
          'sellingPrice': sellingPriceOf(item),
        };
      }).toList(),
      'deliveryType': 'self-pickup',
      'discount': 0,
    };
  }

  /// Place the order, clear the path back to the home shell, then open the
  /// chat with the seller.
  Future<void> placeOrder() async {
    final seller = store.value;
    if (isEmpty || seller == null || isPlacingOrder.value) return;
    try {
      isPlacingOrder.value = true;
      AppLoader.show();

      final response =
          await _repo.placeProductOrderRepo(params: _buildPayload());

      if (!response.isSuccess) {
        AppLoader.hide();
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      AppLoader.hide();

      // Capture the order summary before clearing the cart.
      final summary =
          lines.map((e) => '${nameOf(e)} x${qty(idOf(e))}').join(', ');
      final total = totalPrice;

      clear();

      // Clear the navigation path back to the bottom nav so the store /
      // cart screens are gone — backing out of the chat lands the user on
      // the home shell, not the (now-ordered) store details.
      Get.until((route) =>
          route.settings.name == RouteConstant.BottomNavigationBarScreen);

      // Open the chat with the seller so the buyer can coordinate pickup /
      // delivery — same lane the store's chat icon opens.
      final chatViewController = getOrPut(() => ChatViewController());
      chatViewController.checkChatConnectionAndOpenChat(
        userId: seller.userId ?? '',
        name: seller.serviceName,
        profile: seller.serviceLogo,
        route: AppConstants.route_discover,
        prefilledMessage:
            'Hi! I just placed an order: $summary. Total ${AppConstants.rupeeSymbol}${total.toStringAsFixed(0)}.',
      );
    } catch (e) {
      AppLoader.hide();
      log('Error placing home product order: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isPlacingOrder.value = false;
    }
  }
}
