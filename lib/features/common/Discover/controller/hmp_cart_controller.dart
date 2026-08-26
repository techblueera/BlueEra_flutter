import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/order_history/service/local_order_store.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/order_checkout_payload.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// Shared **multi-store** cart for the home made product flow (Zomato-style).
///
/// Registered once at the list screen so the floating cart bar (list + store
/// details) and the cart page all observe the same instance. Items added from
/// different sellers stack into separate per-store carts; the user can check
/// out one seller ([placeOrderForStore]) or all of them ([placeAllOrders]).
class HmpCartController extends GetxController {
  final _repo = ProductRepo();

  /// product id -> quantity. Single reactive source of truth across all
  /// stores — every per-store getter derives from this.
  final RxMap<String, int> quantities = <String, int>{}.obs;

  /// product id -> model.
  final Map<String, GetProductData> _itemById = {};

  /// product id -> store key.
  final Map<String, String> _itemStore = {};

  /// store key -> store (insertion order preserved → stable card order).
  final Map<String, EarnProfileModel> _storeById = {};

  /// Store key currently being checked out (per-store button spinner); empty
  /// when idle, [_allKey] while "Checkout All" runs.
  final RxString placingKey = ''.obs;
  final RxBool isPlacingOrder = false.obs;

  static const String _allKey = '__all__';

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

  /// Stable key for a store — its earn-profile id, falling back to userId.
  String storeKeyOf(EarnProfileModel s) => s.id ?? s.userId ?? '';

  int qty(String? id) => id == null ? 0 : (quantities[id] ?? 0);

  void add(GetProductData item, EarnProfileModel fromStore) {
    final id = idOf(item);
    if (id.isEmpty) return;
    final key = storeKeyOf(fromStore);
    if (key.isEmpty) return;
    _storeById[key] = fromStore;
    _itemById[id] = item;
    _itemStore[id] = key;
    quantities[id] = (quantities[id] ?? 0) + 1;
  }

  void remove(GetProductData item) {
    final id = idOf(item);
    if (id.isEmpty) return;
    final current = quantities[id] ?? 0;
    if (current <= 1) {
      quantities.remove(id);
      final key = _itemStore.remove(id);
      _itemById.remove(id);
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

  List<GetProductData> linesOf(String key) => quantities.keys
      .where((id) => _itemStore[id] == key)
      .map((id) => _itemById[id])
      .whereType<GetProductData>()
      .toList();

  int itemCountOf(String key) {
    int c = 0;
    quantities.forEach((id, q) {
      if (_itemStore[id] == key) c += q;
    });
    return c;
  }

  double priceOf(String key) {
    double t = 0;
    quantities.forEach((id, q) {
      final item = _itemById[id];
      if (item != null && _itemStore[id] == key) t += sellingPriceOf(item) * q;
    });
    return t;
  }

  double _storeMrp(String key) {
    double t = 0;
    quantities.forEach((id, q) {
      final item = _itemById[id];
      if (item == null || _itemStore[id] != key) return;
      final mrp = mrpOf(item);
      final sp = sellingPriceOf(item);
      t += (mrp > 0 ? mrp : sp) * q;
    });
    return t;
  }

  double savingsOf(String key) {
    final s = _storeMrp(key) - priceOf(key);
    return s > 0 ? s : 0;
  }

  List<String?> previewImagesOf(String key) =>
      linesOf(key).take(3).map(imageOf).toList();

  // ── Aggregate (all stores) ────────────────────────────────────────────────

  bool get isEmpty => quantities.isEmpty;

  int get totalItems => quantities.values.fold(0, (s, q) => s + q);

  double get totalPrice {
    double t = 0;
    quantities.forEach((id, q) {
      final item = _itemById[id];
      if (item != null) t += sellingPriceOf(item) * q;
    });
    return t;
  }

  List<String?> get previewImages => quantities.keys.take(3).map((id) {
        final it = _itemById[id];
        return it == null ? null : imageOf(it);
      }).toList();

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Remove a single store's cart entirely (the × on a cart card).
  void clearStore(String key) {
    final ids = quantities.keys.where((id) => _itemStore[id] == key).toList();
    for (final id in ids) {
      quantities.remove(id);
      _itemById.remove(id);
      _itemStore.remove(id);
    }
    _storeById.remove(key);
  }

  void clear() {
    quantities.clear();
    _itemById.clear();
    _itemStore.clear();
    _storeById.clear();
  }

  // ── Checkout ──────────────────────────────────────────────────────────────

  /// Snapshot a placed seller order into the on-device order history (chat-list
  /// under "My Orders"). Must run BEFORE the store's cart is cleared. Best-effort.
  Future<void> _saveLocalOrder(String key, EarnProfileModel store) async {
    try {
      final lines = linesOf(key);
      if (lines.isEmpty) return;
      final items = lines
          .map((e) => LocalOrderItem(
                name: nameOf(e),
                quantity: qty(idOf(e)),
                price: sellingPriceOf(e),
              ))
          .toList();
      await LocalOrderStore.addOrder(LocalOrderRecord(
        orderId: DateTime.now().microsecondsSinceEpoch.toString(),
        shopId: store.id ?? '',
        shopOwnerId: store.userId ?? '',
        shopName: store.serviceName ?? '',
        shopImage: store.serviceLogo ?? '',
        orderType: 'product',
        items: items,
        totalPrice: priceOf(key),
        createdAt: DateTime.now().toIso8601String(),
        status: 'placed',
      ));
    } catch (_) {}
  }

  /// One idempotency key **per store**, held until that store's order is
  /// created.
  ///
  /// [placeAllOrders] loops one POST per store. Without a key, a response lost
  /// mid-loop and then retried duplicates every order the loop had already
  /// placed. Keying per store — not per loop — means a retry re-sends each
  /// store's own key and each one resolves to the order it already created.
  final Map<String, CheckoutAttempt> _attempts = {};

  CheckoutAttempt _attemptFor(String key) =>
      _attempts.putIfAbsent(key, () => CheckoutAttempt());

  /// Call when the cart screen opens, so each store starts a fresh attempt.

  /// `cash` (default) or `upi`, chosen in the checkout sheet before each
  /// store's order is placed. These carts are self-pickup only until their
  /// service takes doorstep orders, so the sheet skips the delivery steps.
  final RxString paymentMethod = OrderPaymentMethod.cash.obs;

  void beginCheckoutAttempts() {
    _attempts.clear();
    for (final key in storeKeys) {
      _attemptFor(key).begin();
    }
  }

  /// Called once a store's order is created (201 or 200) — a NEW order needs
  /// a NEW key.
  void _completeAttempt(String key) {
    _attempts.remove(key)?.complete();
  }

  Map<String, dynamic> _payloadFor(String key) => {
        'items': linesOf(key).map((item) {
          final v = _variantOf(item);
          return {
            'inventory': v?.inventoryId ?? '',
            'productVariant': v?.id ?? '',
            'quantity': qty(idOf(item)),
            'mrp': mrpOf(item),
            'sellingPrice': sellingPriceOf(item),
          };
        }).toList(),
        'deliveryType': OrderDeliveryType.selfPickup,
        'discount': 0,
        // Cash is the default and the only method this home-products cart
        // offers today; sending it explicitly keeps the order out of the UPI
        // submit/verify flow rather than relying on a server default.
        'paymentMethod': paymentMethod.value,
        'idempotencyKey': _attemptFor(key).key,
      };

  /// Place the order for one seller, drop its cart, return to the home shell,
  /// then open the chat with that seller.
  Future<void> placeOrderForStore(String key) async {
    final seller = _storeById[key];
    if (seller == null || linesOf(key).isEmpty || isPlacingOrder.value) {
      return;
    }
    try {
      isPlacingOrder.value = true;
      placingKey.value = key;
      AppLoader.show();

      final summary = linesOf(key)
          .map((e) => '${nameOf(e)} x${qty(idOf(e))}')
          .join(', ');
      final total = priceOf(key);

      final response =
          await _repo.placeProductOrderRepo(params: _payloadFor(key));
      AppLoader.hide();

      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      // 201 = created, 200 = already created under this key. Both succeed, and
      // both finish this attempt — a new order needs a new key.
      _completeAttempt(key);

      await _saveLocalOrder(key, seller);
      clearStore(key);

      Get.until((route) =>
          route.settings.name == RouteConstant.BottomNavigationBarScreen);

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
      placingKey.value = '';
    }
  }

  /// Place an order for every seller cart, then return to the home shell.
  Future<void> placeAllOrders() async {
    if (isEmpty || isPlacingOrder.value) return;
    try {
      isPlacingOrder.value = true;
      placingKey.value = _allKey;
      AppLoader.show();

      final keys = storeKeys;
      int placed = 0;
      for (final key in keys) {
        final store = _storeById[key];
        final response =
            await _repo.placeProductOrderRepo(params: _payloadFor(key));
        if (response.isSuccess) {
          placed++;
          _completeAttempt(key);
          // Cart is cleared only after the loop, so lines are still live here.
          if (store != null) await _saveLocalOrder(key, store);
        }
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
      log('Error placing all home product orders: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isPlacingOrder.value = false;
      placingKey.value = '';
    }
  }
}
