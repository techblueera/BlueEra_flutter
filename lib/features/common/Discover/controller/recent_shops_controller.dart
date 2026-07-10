import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/common/Discover/model/recent_shops_models.dart';
import 'package:BlueEra/features/common/Discover/repo/recent_shops_repo.dart';
import 'package:get/get.dart';

/// Backs the "Recently Visited Stores" section. Fetches the recent-shops
/// endpoint across the grocery, product and food services, merges them into one
/// most-recent-first list, and exposes loading state. A failing vertical is
/// dropped, not fatal (mirrors the guide's `fetchAll`).
class RecentShopsController extends GetxController {
  final RecentShopsRepo _repo = RecentShopsRepo();

  final RxList<RecentShop> shops = <RecentShop>[].obs;
  final RxBool isLoading = false.obs;

  /// True once at least one fetch attempt has completed (so the UI can tell
  /// "still loading" from "loaded, but empty").
  final RxBool loaded = false.obs;

  final FetchCache _cache = FetchCache();

  /// Which verticals to compile the "recently visited" rail from.
  static const List<GroceryVertical> _verticals = [
    GroceryVertical.grocery,
    GroceryVertical.product,
    GroceryVertical.food,
  ];

  /// Fetch only when not already loaded & fresh. Safe to call on every section
  /// build / screen (re)entry — the overview tab renders this section twice
  /// (tabs 1 & 3), so the in-flight guard stops duplicate calls.
  Future<void> fetchIfNeeded() async {
    if (isLoading.value) return;
    if (_cache.isFresh('recent-shops', hasData: shops.isNotEmpty)) return;
    await fetch();
  }

  Future<void> fetch() async {
    // In-flight guard — a second concurrent caller (the two section instances
    // mount together) must not fire the endpoints again.
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final results = await Future.wait(
        _verticals.map((v) => _repo.getRecentShops(v).then<List<RecentShop>>(
              (res) => _parse(res, v),
            ).catchError((_) => <RecentShop>[])),
      );

      final merged = results.expand((e) => e).toList()
        ..sort((a, b) {
          final da = a.lastOrderedAt?.millisecondsSinceEpoch ?? 0;
          final db = b.lastOrderedAt?.millisecondsSinceEpoch ?? 0;
          return db.compareTo(da); // most recent first
        });

      shops.assignAll(merged);
      _cache.mark('recent-shops');
    } finally {
      loaded.value = true;
      isLoading.value = false;
    }
  }

  List<RecentShop> _parse(ResponseModel res, GroceryVertical vertical) {
    if (!res.isSuccess) return const [];
    final body = res.response?.data;
    if (body is! Map) return const [];
    final parsed =
        RecentShopsResponse.fromJson(Map<String, dynamic>.from(body));
    // Tag each shop with the vertical it came from (the response doesn't carry
    // it) so the card can route to the right store type on tap.
    return parsed.shops.map((s) => s.copyWith(vertical: vertical)).toList();
  }
}
