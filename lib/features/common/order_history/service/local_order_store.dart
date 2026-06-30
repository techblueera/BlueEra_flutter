import 'dart:convert';

import 'package:hive/hive.dart';

/// A single line item inside a locally-stored order.
class LocalOrderItem {
  final String name;
  final int quantity;
  final double price; // selling price per unit

  const LocalOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };

  factory LocalOrderItem.fromJson(Map<String, dynamic> j) => LocalOrderItem(
        name: j['name']?.toString() ?? '',
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

/// One order placed from the Discovery section, kept purely on-device. Shop
/// details are denormalised onto every record so the chat-list / thread can
/// render without a network call.
class LocalOrderRecord {
  final String orderId;
  final String shopId;
  final String shopOwnerId;
  final String shopName;
  final String shopImage;
  final String orderType; // 'food' | 'tiffin' | 'product'
  final List<LocalOrderItem> items;
  final double totalPrice;
  final String createdAt; // ISO-8601
  final String status; // 'placed'

  const LocalOrderRecord({
    required this.orderId,
    required this.shopId,
    required this.shopOwnerId,
    required this.shopName,
    required this.shopImage,
    required this.orderType,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    required this.status,
  });

  int get totalQty => items.fold(0, (s, i) => s + i.quantity);

  /// "Idli x2, Dosa x1" — used as the chat-list last-message preview.
  String get summary =>
      items.map((i) => '${i.name} x${i.quantity}').join(', ');

  DateTime? get createdAtDate => DateTime.tryParse(createdAt)?.toLocal();

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'shopId': shopId,
        'shopOwnerId': shopOwnerId,
        'shopName': shopName,
        'shopImage': shopImage,
        'orderType': orderType,
        'items': items.map((e) => e.toJson()).toList(),
        'totalPrice': totalPrice,
        'createdAt': createdAt,
        'status': status,
      };

  factory LocalOrderRecord.fromJson(Map<String, dynamic> j) => LocalOrderRecord(
        orderId: j['orderId']?.toString() ?? '',
        shopId: j['shopId']?.toString() ?? '',
        shopOwnerId: j['shopOwnerId']?.toString() ?? '',
        shopName: j['shopName']?.toString() ?? '',
        shopImage: j['shopImage']?.toString() ?? '',
        orderType: j['orderType']?.toString() ?? '',
        items: (j['items'] is List)
            ? (j['items'] as List)
                .map((e) => LocalOrderItem.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList()
            : <LocalOrderItem>[],
        totalPrice: (j['totalPrice'] as num?)?.toDouble() ?? 0,
        createdAt: j['createdAt']?.toString() ?? '',
        status: j['status']?.toString() ?? 'placed',
      );
}

/// Chat-list summary for one shop the user has ordered from.
class LocalOrderShopSummary {
  final String shopKey;
  final String shopName;
  final String shopImage;
  final String shopOwnerId;
  final int orderCount;
  final LocalOrderRecord lastOrder;

  const LocalOrderShopSummary({
    required this.shopKey,
    required this.shopName,
    required this.shopImage,
    required this.shopOwnerId,
    required this.orderCount,
    required this.lastOrder,
  });
}

/// On-device order history grouped per shop. Backed by a single Hive box keyed
/// by shop (one JSON-encoded list of [LocalOrderRecord] per key) — the same
/// lazy-open / JSON pattern used by `reminder_messages_box`, so no generated
/// adapters or `main.dart` wiring are needed.
class LocalOrderStore {
  static const String _boxName = 'local_order_history_box';

  static Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<String>(_boxName);
    return Hive.openBox<String>(_boxName);
  }

  /// Group key for a record — the shop owner id (so it matches the chat
  /// identity), falling back to the shop id.
  static String _keyFor(LocalOrderRecord r) =>
      r.shopOwnerId.isNotEmpty ? r.shopOwnerId : r.shopId;

  static List<LocalOrderRecord> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) =>
              LocalOrderRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Append a newly-placed order. Same-shop orders accumulate under one key, so
  /// they surface as multiple messages in the same chat thread.
  static Future<void> addOrder(LocalOrderRecord record) async {
    final key = _keyFor(record);
    if (key.isEmpty) return;
    try {
      final box = await _box();
      final list = _decode(box.get(key))..add(record);
      await box.put(key, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  /// One entry per shop, most-recent order first — drives the chat-list.
  static Future<List<LocalOrderShopSummary>> getShops() async {
    try {
      final box = await _box();
      final summaries = <LocalOrderShopSummary>[];
      for (final key in box.keys) {
        final orders = _decode(box.get(key));
        if (orders.isEmpty) continue;
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = orders.first;
        summaries.add(LocalOrderShopSummary(
          shopKey: key.toString(),
          shopName: latest.shopName,
          shopImage: latest.shopImage,
          shopOwnerId: latest.shopOwnerId,
          orderCount: orders.length,
          lastOrder: latest,
        ));
      }
      summaries.sort(
          (a, b) => b.lastOrder.createdAt.compareTo(a.lastOrder.createdAt));
      return summaries;
    } catch (_) {
      return [];
    }
  }

  /// All orders for one shop, oldest first (chat order).
  static Future<List<LocalOrderRecord>> getOrdersForShop(String shopKey) async {
    try {
      final box = await _box();
      final orders = _decode(box.get(shopKey))
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return orders;
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearShop(String shopKey) async {
    try {
      final box = await _box();
      await box.delete(shopKey);
    } catch (_) {}
  }
}
