import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

/// One order this device knows about, because this device placed it.
class LocalOrderRef {
  final String orderId;
  final String service;
  final String? orderNumber;
  final String? businessId;
  final String? businessName;
  final num? grandTotal;
  final int? itemCount;
  final DateTime placedAt;

  /// True when this device was the SHOP for the order, false when it was the
  /// customer. Seeds the tracker's role guess until `/track` says `actor`.
  final bool isOwner;

  const LocalOrderRef({
    required this.orderId,
    required this.service,
    required this.placedAt,
    this.orderNumber,
    this.businessId,
    this.businessName,
    this.grandTotal,
    this.itemCount,
    this.isOwner = false,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'service': service,
        'orderNumber': orderNumber,
        'businessId': businessId,
        'businessName': businessName,
        'grandTotal': grandTotal,
        'itemCount': itemCount,
        'placedAt': placedAt.millisecondsSinceEpoch,
        'isOwner': isOwner,
      };

  static LocalOrderRef? fromJson(Map<String, dynamic> json) {
    final id = json['orderId']?.toString() ?? '';
    if (id.isEmpty) return null;
    final stamp = json['placedAt'];
    return LocalOrderRef(
      orderId: id,
      service: json['service']?.toString() ?? 'grocery-service',
      orderNumber: json['orderNumber']?.toString(),
      businessId: json['businessId']?.toString(),
      businessName: json['businessName']?.toString(),
      grandTotal: json['grandTotal'] is num
          ? json['grandTotal'] as num
          : num.tryParse(json['grandTotal']?.toString() ?? ''),
      itemCount: json['itemCount'] is int
          ? json['itemCount'] as int
          : int.tryParse(json['itemCount']?.toString() ?? ''),
      placedAt: stamp is int
          ? DateTime.fromMillisecondsSinceEpoch(stamp)
          : DateTime.fromMillisecondsSinceEpoch(0),
      isOwner: json['isOwner'] == true,
    );
  }
}

/// **The order list the backend does not have.**
///
/// `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` §7 is blunt about it: placing a
/// grocery order creates no conversation and no chat card, the seller's order
/// list excludes self-pickup, and *"there is no server list for either role"*.
/// `/track` works — but only if you already know the order id.
///
/// So the id is kept here, at the moment the order is created, and that is
/// what the tracker is reached from. This is a **pointer store, not a cache**:
/// it holds ids and just enough text to draw a list row, never order state.
/// Every screen that opens from here re-reads `/track`, so nothing in this box
/// can go stale in a way the user sees.
class GroceryOrderLocalStore {
  const GroceryOrderLocalStore._();

  static const String boxName = 'local_order_refs_box';
  static const String _key = 'refs';

  /// Enough for a season of ordering; past that the oldest go. The list is a
  /// convenience, not a permanent record — the server has the orders.
  static const int _maxEntries = 60;

  static Future<Box?> _safeBox() async {
    try {
      return Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
    } catch (e) {
      log('GroceryOrderLocalStore: box unavailable — $e');
      return null;
    }
  }

  /// Newest first.
  static Future<List<LocalOrderRef>> all() async {
    final box = await _safeBox();
    if (box == null) return const [];
    try {
      final raw = box.get(_key);
      if (raw is! String || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final refs = decoded
          .whereType<Map>()
          .map((e) => LocalOrderRef.fromJson(Map<String, dynamic>.from(e)))
          .whereType<LocalOrderRef>()
          .toList();
      refs.sort((a, b) => b.placedAt.compareTo(a.placedAt));
      return refs;
    } catch (e) {
      log('GroceryOrderLocalStore.all error: $e');
      return const [];
    }
  }

  /// Adds (or replaces) one order. Replacing matters: the create response may
  /// carry no order number and a later `/track` will, and the row should
  /// improve rather than duplicate.
  static Future<void> remember(LocalOrderRef ref) async {
    if (ref.orderId.isEmpty) return;
    final existing = await all();
    final merged = <LocalOrderRef>[
      ref,
      ...existing.where((e) => e.orderId != ref.orderId),
    ];
    await _write(merged.take(_maxEntries).toList());
  }

  static Future<void> rememberAll(List<LocalOrderRef> refs) async {
    for (final ref in refs) {
      await remember(ref);
    }
  }

  /// Drops one order — used when `/track` answers 404 and the order really is
  /// gone (S14). A pointer to something that no longer exists is worse than no
  /// pointer.
  static Future<void> forget(String orderId) async {
    final existing = await all();
    if (!existing.any((e) => e.orderId == orderId)) return;
    await _write(existing.where((e) => e.orderId != orderId).toList());
  }

  /// Called from `LogoutHelper.clearAllLocalData()` alongside the other boxes.
  static Future<void> clearAll() async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.clear();
    } catch (e) {
      log('GroceryOrderLocalStore.clearAll error: $e');
    }
  }

  static Future<void> _write(List<LocalOrderRef> refs) async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.put(_key, jsonEncode(refs.map((e) => e.toJson()).toList()));
    } catch (e) {
      log('GroceryOrderLocalStore._write error: $e');
    }
  }

  /// Pulls every order id out of whatever shape the create endpoint answered
  /// with — a bare order, `{data: …}`, or a list of orders for a multi-store
  /// checkout. An id that cannot be found is not an error here; the order was
  /// still placed, it just cannot be tracked from this device.
  static List<Map<String, dynamic>> ordersFromCreateResponse(dynamic body) {
    dynamic payload = body;
    if (payload is Map && payload['data'] != null) payload = payload['data'];
    if (payload is Map && payload['orders'] is List)
      payload = payload['orders'];

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (payload is Map) return [Map<String, dynamic>.from(payload)];
    return const [];
  }

  static String? idOf(Map<String, dynamic> order) {
    final id = (order['_id'] ?? order['id'] ?? order['orderId'])?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }
}
