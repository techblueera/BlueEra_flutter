import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/repo/search_repo.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Drives the global search screen: debounced type-ahead suggestions while the
/// user types, and a full paginated hybrid search once they commit (tap a
/// suggestion / press search). Self-contained — used only by the search screen
/// launched from Discover, so it can't affect any existing flow.
class GlobalSearchController extends GetxController {
  final SearchRepo _repo = SearchRepo();

  final TextEditingController queryController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  // ── Type-ahead suggestions ──────────────────────────────────────────
  final RxList<Suggestion> suggestions = <Suggestion>[].obs;

  /// When true the suggestion list is shown; when false the results list is.
  /// Flips to false the moment a search is committed, back to true on edit.
  final RxBool showSuggestions = true.obs;

  // ── Search results ──────────────────────────────────────────────────
  final RxList<SearchResultItem> results = <SearchResultItem>[].obs;
  final Rx<Status> status = Status.INITIAL.obs;
  final RxBool isLoadingMore = false.obs;
  final RxMap<String, int> facets = <String, int>{}.obs;
  final RxInt total = 0.obs;
  final RxString appliedFiltersText = ''.obs;

  /// Active entity-type facet filter (`null` = All). Drives the type tabs.
  final RxnString activeType = RxnString();

  String _committedQuery = '';
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;

  // Debounce + out-of-order guards. Suggest/search responses can return out of
  // order; each call bumps a sequence and stale responses are dropped.
  Timer? _debounce;
  int _suggestSeq = 0;
  int _searchSeq = 0;

  String get committedQuery => _committedQuery;

  /// Called on every keystroke. Debounces the suggest call and switches the
  /// view back to suggestions (results are stale until re-committed).
  void onQueryChanged(String text) {
    showSuggestions.value = true;
    final q = text.trim();
    _debounce?.cancel();
    if (q.isEmpty) {
      _suggestSeq++; // invalidate any in-flight suggest
      suggestions.clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _fetchSuggest(q));
  }

  Future<void> _fetchSuggest(String q) async {
    final seq = ++_suggestSeq;
    try {
      final s = await _repo.suggest(q);
      if (seq != _suggestSeq) return; // superseded
      suggestions.assignAll(s);
    } catch (_) {
      if (seq != _suggestSeq) return;
      suggestions.clear();
    }
  }

  /// Commit a full search for [query] (from the keyboard action or a tapped
  /// suggestion). Resets the type filter and pagination.
  void submitSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    _suggestSeq++; // drop any pending suggest
    if (queryController.text != q) queryController.text = q;
    _committedQuery = q;
    activeType.value = null;
    suggestions.clear();
    showSuggestions.value = false;
    focusNode.unfocus();
    _runSearch(reset: true);
  }

  /// Tap a facet tab to scope results to one entity type (`null` = All).
  void selectType(String? type) {
    if (activeType.value == type) return;
    activeType.value = type;
    _runSearch(reset: true);
  }

  /// Infinite-scroll trigger — load the next page of the current query/type.
  void loadMore() {
    if (!_hasMore || isLoadingMore.value || status.value == Status.LOADING) {
      return;
    }
    _runSearch(reset: false);
  }

  Future<void> _runSearch({required bool reset}) async {
    if (_committedQuery.isEmpty) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
      status.value = Status.LOADING;
    } else {
      isLoadingMore.value = true;
    }

    final seq = ++_searchSeq;
    try {
      final res = await _repo.search(
        _committedQuery,
        type: activeType.value,
        page: _page,
        limit: _limit,
      );
      if (seq != _searchSeq) return; // superseded by a newer search

      if (reset) {
        results.assignAll(res.results);
        facets.assignAll(res.facets);
        total.value = res.total;
        appliedFiltersText.value = res.appliedFiltersText;
      } else {
        results.addAll(res.results);
      }
      _hasMore = res.hasMore;
      if (res.results.isNotEmpty) _page++;
      status.value = Status.COMPLETE;
    } catch (_) {
      if (seq != _searchSeq) return;
      if (reset) {
        results.clear();
        status.value = Status.ERROR;
      }
      // On a load-more failure keep existing results; user can retry by scroll.
    } finally {
      if (seq == _searchSeq) isLoadingMore.value = false;
    }
  }

  /// Re-run the last committed search (used by the error-state retry button).
  void retry() {
    if (_committedQuery.isNotEmpty) _runSearch(reset: true);
  }

  /// Open the existing self-pickup order flow for a product result.
  ///
  /// Mirrors the grocery share deep-link "Buy Now": fetch the full grocery
  /// product by its [SearchResultItem.sourceId], drop the first priced variant
  /// into the shared [GrocerySelfPickupConsumerController] cart, then land on
  /// [GrocerySelfPickUpCartScreen] where the user reviews and places the real
  /// order (`placeBulkGroceryOrderApi`). Reuses the shipped flow end-to-end
  /// rather than a bespoke checkout.
  Future<void> openProductOrder(SearchResultItem item) async {
    final productId = item.sourceId ?? '';
    if (productId.isEmpty) {
      commonSnackBar(message: 'Unable to open this product');
      return;
    }
    try {
      AppLoader.show();
      final res = await GroceryRepo().fetchGroceryProductByIdRepo(productId);

      // Endpoint returns either the bare product or a `{ data: {...} }` envelope.
      final raw = res.response?.data;
      Map<String, dynamic>? payload;
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        payload = m['data'] is Map
            ? Map<String, dynamic>.from(m['data'] as Map)
            : m;
      }
      if (!res.isSuccess || payload == null) {
        AppLoader.hide();
        commonSnackBar(message: 'This product is not available for ordering');
        return;
      }

      final product = GroceryProductData.fromJson(payload);
      final variants = product.variants ?? [];
      if (variants.isEmpty) {
        AppLoader.hide();
        commonSnackBar(message: 'No purchasable option for this product');
        return;
      }
      // First variant with pricing wins, else the first overall.
      final variant = variants.firstWhere(
        (v) => (v.pricing?.isNotEmpty ?? false),
        orElse: () => variants.first,
      );

      final cart = getOrPut<GrocerySelfPickupConsumerController>(
          () => GrocerySelfPickupConsumerController());

      // Avoid double-adding if the user re-opens the same product.
      if (cart.getQuantity(variant.sId) == 0) {
        cart.addToCart(
          variant,
          productId: product.sId,
          inventoryId: variant.inventory?.inventoryId ?? variant.sId,
          // Search carries no seller profile — group the item under a store
          // card using the product's own context so the cart renders it (the
          // order body itself keys off inventory + variant ids, not businessId).
          businessId: item.businessId ?? product.sId,
          businessName: (item.subtitle?.trim().isNotEmpty ?? false)
              ? item.subtitle
              : (product.brand ?? product.name),
          businessLogo: item.imageUrl,
          businessAddress: item.city,
          productImage: (product.images?.isNotEmpty ?? false)
              ? product.images!.first.url
              : item.imageUrl,
        );
      }
      AppLoader.hide();
      Get.to(() => const GrocerySelfPickUpCartScreen());
    } catch (_) {
      AppLoader.hide();
      commonSnackBar(message: 'Could not open the order. Please try again.');
    }
  }

  bool get hasMore => _hasMore;

  @override
  void onClose() {
    _debounce?.cancel();
    queryController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
