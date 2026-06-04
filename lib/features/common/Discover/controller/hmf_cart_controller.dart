import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// Shared cart for the home made food flow. Registered once at the list
/// screen (the flow entry) so the floating cart bar on both the list and the
/// store details screen — plus the cart page — all observe the same instance.
/// A home made food cart belongs to a single kitchen ([store]); placing an
/// order POSTs to `earn-service/homeFoodOrders` then opens the chat.
class HmfCartController extends GetxController {
  final _repo = EarnProfileRepo();

  /// The kitchen the current cart belongs to (set when the first item is
  /// added). Null when the cart is empty.
  final Rxn<EarnProfileModel> store = Rxn<EarnProfileModel>();

  /// food id -> quantity (reactive source of truth).
  final RxMap<String, int> quantities = <String, int>{}.obs;

  /// food id -> model (plain lookup; reactivity is driven by [quantities]).
  final Map<String, FoodItemModel> _itemById = {};

  final RxBool isPlacingOrder = false.obs;

  int qty(String? id) => id == null ? 0 : (quantities[id] ?? 0);

  /// Whether [fromStore] differs from the kitchen the cart already holds.
  bool isDifferentStore(EarnProfileModel fromStore) =>
      quantities.isNotEmpty &&
      store.value != null &&
      store.value!.id != fromStore.id;

  void add(FoodItemModel item, EarnProfileModel fromStore) {
    final id = item.id;
    if (id == null) return;
    store.value = fromStore;
    _itemById[id] = item;
    quantities[id] = (quantities[id] ?? 0) + 1;
  }

  void remove(FoodItemModel item) {
    final id = item.id;
    if (id == null) return;
    final current = quantities[id] ?? 0;
    if (current <= 1) {
      quantities.remove(id);
      _itemById.remove(id);
    } else {
      quantities[id] = current - 1;
    }
    if (quantities.isEmpty) store.value = null;
  }

  List<FoodItemModel> get lines => quantities.keys
      .map((id) => _itemById[id])
      .whereType<FoodItemModel>()
      .toList();

  bool get isEmpty => quantities.isEmpty;

  int get totalItems => quantities.values.fold(0, (sum, q) => sum + q);

  double _num(String value) => double.tryParse(value) ?? 0;

  double get totalPrice {
    double total = 0;
    quantities.forEach((id, q) {
      total += _num(_itemById[id]?.sellingPrice ?? '') * q;
    });
    return total;
  }

  double get totalMrp {
    double total = 0;
    quantities.forEach((id, q) {
      final item = _itemById[id];
      final mrp = _num(item?.mrpPrice ?? '');
      final sp = _num(item?.sellingPrice ?? '');
      total += (mrp > 0 ? mrp : sp) * q;
    });
    return total;
  }

  double get totalSavings {
    final s = totalMrp - totalPrice;
    return s > 0 ? s : 0;
  }

  List<String?> get previewImages =>
      lines.take(3).map((e) => e.imageUrl).toList();

  void clear() {
    quantities.clear();
    _itemById.clear();
    store.value = null;
  }

  /// Build the order payload from the current cart.
  Map<String, dynamic> _buildPayload() {
    return {
      'items': lines
          .map((item) => {
                'homeMadeFood': item.id,
                'quantity': qty(item.id),
              })
          .toList(),
      'deliveryType': 'self-pickup',
      'discount': totalSavings,
    };
  }

  /// Place the order, clear the path back to the home shell, then open the
  /// chat with the kitchen.
  Future<void> placeOrder() async {
    final kitchen = store.value;
    if (isEmpty || kitchen == null || isPlacingOrder.value) return;
    try {
      isPlacingOrder.value = true;
      AppLoader.show();

      final response = await _repo.placeHomeFoodOrder(params: _buildPayload());

      if (!response.isSuccess) {
        AppLoader.hide();
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      AppLoader.hide();

      // Capture the order summary before clearing the cart.
      final summary = lines.map((e) => '${e.foodName} x${qty(e.id)}').join(', ');
      final total = totalPrice;

      clear();

      // Clear the navigation path back to the bottom nav so the store /
      // cart screens are gone — backing out of the chat lands the user on
      // the home shell, not the (now-ordered) store details.
      Get.until((route) =>
          route.settings.name == RouteConstant.BottomNavigationBarScreen);

      // Open the chat with the kitchen so the buyer can coordinate pickup /
      // delivery — same lane the store's chat icon opens.
      final chatViewController = getOrPut(() => ChatViewController());
      chatViewController.checkChatConnectionAndOpenChat(
        userId: kitchen.userId ?? '',
        name: kitchen.serviceName,
        profile: kitchen.serviceLogo,
        route: AppConstants.route_discover,
        prefilledMessage:
            'Hi! I just placed an order: $summary. Total ${AppConstants.rupeeSymbol}${total.toStringAsFixed(0)}.',
      );
    } catch (e) {
      AppLoader.hide();
      log('Error placing home food order: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isPlacingOrder.value = false;
    }
  }
}
