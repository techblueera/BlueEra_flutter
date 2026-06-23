import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
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

/// Shared **multi-store** cart for the home made food flow (Zomato-style).
///
/// Registered once at the list screen so the floating cart bar (list + store
/// details) and the cart page all observe the same instance. Items added from
/// different kitchens stack into separate per-store carts; the user can check
/// out one kitchen ([placeOrderForStore]) or all of them ([placeAllOrders]).
class HmfCartController extends GetxController {
  final _repo = EarnProfileRepo();

  /// itemId -> quantity. The single reactive source of truth across all
  /// stores — every per-store getter derives from this, so any `Obx` that
  /// reads it (e.g. `quantities.length`) rebuilds on any cart change.
  final RxMap<String, int> quantities = <String, int>{}.obs;

  /// itemId -> model.
  final Map<String, FoodItemModel> _itemById = {};

  /// itemId -> store key.
  final Map<String, String> _itemStore = {};

  /// itemId -> is this a tiffin (vs a home-made-food item). The cart is
  /// single-type: tiffin and food can't be mixed, so every live item shares
  /// the same value — see [cartIsTiffin] / [wouldMix].
  final Map<String, bool> _itemIsTiffin = {};

  /// store key -> store. Insertion order is preserved, so cart cards keep a
  /// stable order (first-added kitchen on top).
  final Map<String, EarnProfileModel> _storeById = {};

  /// Store key currently being checked out (drives the per-store button
  /// spinner); empty when idle, [_allKey] while "Checkout All" runs.
  final RxString placingKey = ''.obs;
  final RxBool isPlacingOrder = false.obs;

  static const String _allKey = '__all__';

  /// Stable key for a store — its earn-profile id, falling back to userId.
  String storeKeyOf(EarnProfileModel s) => s.id ?? s.userId ?? '';

  int qty(String? id) => id == null ? 0 : (quantities[id] ?? 0);

  /// Whether the current cart holds tiffin items. `null` when the cart is
  /// empty (no type yet). Since the cart is single-type, the first live item's
  /// type represents the whole cart.
  bool? get cartIsTiffin {
    if (isEmpty) return null;
    return _itemIsTiffin[quantities.keys.first] ?? false;
  }

  /// True when adding an item of [isTiffin] type would mix with the current
  /// cart (tiffin + food can't be ordered together). False if the cart is
  /// empty or already the same type — the caller should prompt to start a new
  /// cart when this returns true.
  bool wouldMix(bool isTiffin) {
    final current = cartIsTiffin;
    return current != null && current != isTiffin;
  }

  void add(FoodItemModel item, EarnProfileModel fromStore,
      {bool isTiffin = false}) {
    final id = item.id;
    if (id == null) return;
    final key = storeKeyOf(fromStore);
    if (key.isEmpty) return;
    _storeById[key] = fromStore;
    _itemById[id] = item;
    _itemStore[id] = key;
    _itemIsTiffin[id] = isTiffin;
    quantities[id] = (quantities[id] ?? 0) + 1;
  }

  void remove(FoodItemModel item) {
    final id = item.id;
    if (id == null) return;
    final current = quantities[id] ?? 0;
    if (current <= 1) {
      quantities.remove(id);
      final key = _itemStore.remove(id);
      _itemById.remove(id);
      _itemIsTiffin.remove(id);
      // Drop the store once its last item is gone.
      if (key != null && !_itemStore.values.contains(key)) {
        _storeById.remove(key);
      }
    } else {
      quantities[id] = current - 1;
    }
  }

  // ── Per-store views ───────────────────────────────────────────────────────

  /// Store keys that currently hold at least one item, in add order.
  List<String> get storeKeys =>
      _storeById.keys.where((k) => _itemStore.values.contains(k)).toList();

  int get storeCount => storeKeys.length;

  EarnProfileModel? storeOf(String key) => _storeById[key];

  List<FoodItemModel> linesOf(String key) => quantities.keys
      .where((id) => _itemStore[id] == key)
      .map((id) => _itemById[id])
      .whereType<FoodItemModel>()
      .toList();

  int itemCountOf(String key) {
    int c = 0;
    quantities.forEach((id, q) {
      if (_itemStore[id] == key) c += q;
    });
    return c;
  }

  double _num(String value) => double.tryParse(value) ?? 0;

  double priceOf(String key) {
    double t = 0;
    quantities.forEach((id, q) {
      if (_itemStore[id] == key) {
        t += _num(_itemById[id]?.sellingPrice ?? '') * q;
      }
    });
    return t;
  }

  double _mrpOf(String key) {
    double t = 0;
    quantities.forEach((id, q) {
      if (_itemStore[id] != key) return;
      final item = _itemById[id];
      final mrp = _num(item?.mrpPrice ?? '');
      final sp = _num(item?.sellingPrice ?? '');
      t += (mrp > 0 ? mrp : sp) * q;
    });
    return t;
  }

  double savingsOf(String key) {
    final s = _mrpOf(key) - priceOf(key);
    return s > 0 ? s : 0;
  }

  List<String?> previewImagesOf(String key) =>
      linesOf(key).take(3).map((e) => e.imageUrl).toList();

  // ── Aggregate (all stores) ────────────────────────────────────────────────

  bool get isEmpty => quantities.isEmpty;

  int get totalItems => quantities.values.fold(0, (s, q) => s + q);

  double get totalPrice {
    double t = 0;
    quantities.forEach(
        (id, q) => t += _num(_itemById[id]?.sellingPrice ?? '') * q);
    return t;
  }

  List<String?> get previewImages =>
      quantities.keys.take(3).map((id) => _itemById[id]?.imageUrl).toList();

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Remove a single store's cart entirely (the × on a cart card).
  void clearStore(String key) {
    final ids =
        quantities.keys.where((id) => _itemStore[id] == key).toList();
    for (final id in ids) {
      quantities.remove(id);
      _itemById.remove(id);
      _itemStore.remove(id);
      _itemIsTiffin.remove(id);
    }
    _storeById.remove(key);
  }

  void clear() {
    quantities.clear();
    _itemById.clear();
    _itemStore.clear();
    _itemIsTiffin.clear();
    _storeById.clear();
  }

  // ── Checkout ──────────────────────────────────────────────────────────────

  /// Only the item id + `quantity` are sent per line — the backend reads
  /// price, seller and pickup location off the document. The id key differs by
  /// type: `tiffin` for tiffin orders, `homeMadeFood` for food orders.
  Map<String, dynamic> _payloadFor(String key) {
    final tiffin = cartIsTiffin ?? false;
    final idKey = tiffin ? 'tiffin' : 'homeMadeFood';
    return {
      'items': linesOf(key)
          .map((item) => {idKey: item.id, 'quantity': qty(item.id)})
          .toList(),
      'deliveryType': 'self-pickup',
      'discount': 0,
    };
  }

  /// Route a store's order to the correct endpoint based on the cart type.
  Future<ResponseModel> _placeOrder(String key) {
    final params = _payloadFor(key);
    return (cartIsTiffin ?? false)
        ? _repo.placeTiffinOrder(params: params)
        : _repo.placeHomeFoodOrder(params: params);
  }

  /// Place the order for one kitchen, drop its cart, return to the home shell,
  /// then open the chat with that kitchen.
  Future<void> placeOrderForStore(String key) async {
    final kitchen = _storeById[key];
    if (kitchen == null || linesOf(key).isEmpty || isPlacingOrder.value) {
      return;
    }
    try {
      isPlacingOrder.value = true;
      placingKey.value = key;
      AppLoader.show();

      final response = await _placeOrder(key);
      AppLoader.hide();

      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      clearStore(key);

      Get.until((route) =>
          route.settings.name == RouteConstant.BottomNavigationBarScreen);

      final chatViewController = getOrPut(() => ChatViewController());
      chatViewController.checkChatConnectionAndOpenChat(
        userId: kitchen.userId ?? '',
        name: kitchen.serviceName,
        profile: kitchen.serviceLogo,
        route: AppConstants.route_discover,
      );
    } catch (e) {
      AppLoader.hide();
      log('Error placing home food order: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isPlacingOrder.value = false;
      placingKey.value = '';
    }
  }

  /// Place an order for every kitchen cart, then return to the home shell.
  Future<void> placeAllOrders() async {
    if (isEmpty || isPlacingOrder.value) return;
    try {
      isPlacingOrder.value = true;
      placingKey.value = _allKey;
      AppLoader.show();

      final keys = storeKeys;
      int placed = 0;
      for (final key in keys) {
        final response = await _placeOrder(key);
        if (response.isSuccess) placed++;
      }
      AppLoader.hide();

      if (placed == 0) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      clear();
      Get.until((route) =>
          route.settings.name == RouteConstant.BottomNavigationBarScreen);
      commonSnackBar(
        message: placed == keys.length
            ? 'Orders placed successfully'
            : '$placed of ${keys.length} orders placed',
      );
    } catch (e) {
      AppLoader.hide();
      log('Error placing all home food orders: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isPlacingOrder.value = false;
      placingKey.value = '';
    }
  }
}
