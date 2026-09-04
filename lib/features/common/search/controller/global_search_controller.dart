import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/core/services/analytics_service.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/search/model/search_category.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/model/store_match_model.dart';
import 'package:BlueEra/features/common/search/repo/search_repo.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Size of the server's candidate pool for the current query — not a match
  /// count. Render [totalLabel] rather than this.
  final RxInt total = 0.obs;

  /// Display form of [total]: `"100+"` once the pool ceiling is hit, since the
  /// true number of matches isn't available past it.
  final RxString totalLabel = ''.obs;
  final RxString appliedFiltersText = ''.obs;

  /// Active entity-type facet filter (`null` = All). Drives the type tabs.
  final RxnString activeType = RxnString();

  /// Vertical the search is scoped to, picked from the chips under the search
  /// field *before* the query is committed. [SearchCategory.all] is the
  /// "no filter" state and is not sent on the wire — it's the server default.
  final Rx<SearchCategory> selectedCategory = SearchCategory.all.obs;

  /// True while a real vertical is selected — drives the "clear" affordance.
  bool get hasCategoryFilter => selectedCategory.value != SearchCategory.all;

  /// Active sort of the results list. `null` = relevance (server order);
  /// `'price_asc'` / `'price_desc'` sort the loaded results client-side.
  /// Applied on every page so paginated appends stay ordered.
  final RxnString sortKey = RxnString();

  // ── Recent searches (locally persisted) ─────────────────────────────
  /// Most-recent-first list of committed query terms, shown on the search
  /// landing (empty-query) screen. Persisted across app launches via
  /// SharedPreferences so it survives the controller being disposed on exit.
  static const String _recentSearchesKey = 'global_recent_searches';
  static const int _maxRecentSearches = 12;
  final RxList<String> recentSearches = <String>[].obs;

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

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches.assignAll(prefs.getStringList(_recentSearchesKey) ?? const []);
    } catch (_) {
      // Non-fatal: recents are a convenience, an empty list is a fine fallback.
    }
  }

  Future<void> _persistRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, recentSearches.toList());
    } catch (_) {}
  }

  /// Push a committed [query] to the front of the recents (de-duped,
  /// case-insensitively) and cap the list length. Persisted immediately.
  void _addRecentSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    recentSearches.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    recentSearches.insert(0, q);
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches.value = recentSearches.sublist(0, _maxRecentSearches);
    }
    _persistRecentSearches();
  }

  /// Remove a single recent term (from the ✕ on a recent chip).
  void removeRecentSearch(String query) {
    recentSearches.remove(query);
    _persistRecentSearches();
  }

  /// Clear the whole recents list ("Clear all" on the landing screen).
  void clearRecentSearches() {
    recentSearches.clear();
    _persistRecentSearches();
  }

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

  /// Searcher position for `/search` and `/suggest`, or null when the app has
  /// no usable fix. Both coordinates travel together — the repo drops them if
  /// either is missing, since a lone coordinate (or `0,0`) is a `400`.
  double? get _geoLat =>
      LocationService.hasUsableLocation ? LocationService.lat : null;

  double? get _geoLng =>
      LocationService.hasUsableLocation ? LocationService.lng : null;

  Future<void> _fetchSuggest(String q) async {
    final seq = ++_suggestSeq;
    try {
      // Scoped server-side, never filtered here: the row cap is applied inside
      // the query, so trimming the response would leave a near-empty dropdown.
      final s = await _repo.suggest(
        q,
        category: selectedCategory.value,
        lat: _geoLat,
        lng: _geoLng,
      );
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
    _addRecentSearch(q);
    // GA4's recommended `search` event — logged on COMMIT only. The debounced
    // suggest path fires per keystroke and would bury the real intent under
    // partial terms.
    AnalyticsService.I.logSearch(q);
    activeType.value = null;
    sortKey.value = null; // fresh query starts at relevance
    suggestions.clear();
    showSuggestions.value = false;
    focusNode.unfocus();
    _runSearch(reset: true);
  }

  /// Change the results sort. Relevance can't be reconstructed once the list
  /// is reordered, so switching back to it re-runs the search; the price sorts
  /// reorder the already-loaded results in place.
  void applySort(String? key) {
    if (sortKey.value == key) return;
    sortKey.value = key;
    if (key == null) {
      _runSearch(reset: true);
    } else {
      _sortInPlace();
    }
  }

  void _sortInPlace() {
    final k = sortKey.value;
    if (k == null) return;
    final list = results.toList();
    if (k == 'price_asc') {
      list.sort((a, b) =>
          (a.price ?? double.infinity).compareTo(b.price ?? double.infinity));
    } else if (k == 'price_desc') {
      list.sort((a, b) =>
          (b.price ?? double.negativeInfinity)
              .compareTo(a.price ?? double.negativeInfinity));
    }
    results.assignAll(list);
  }

  /// Pick the vertical the search runs against (the chips under the field).
  ///
  /// Takes effect immediately: with a query already committed the search re-runs
  /// in the new scope; while the user is still typing the suggestion dropdown
  /// is re-fetched in the new scope instead (`/suggest` takes the same
  /// `category`). The entity-type facet filter is dropped because `type` is only
  /// legal *within* a category — carrying `grocery_shop` over into
  /// `category=food` is a `400`.
  void selectCategory(SearchCategory category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    activeType.value = null;
    facets.clear();
    if (showSuggestions.value) {
      final q = queryController.text.trim();
      if (q.isNotEmpty) {
        _debounce?.cancel();
        _fetchSuggest(q);
      }
      return;
    }
    if (_committedQuery.isNotEmpty) _runSearch(reset: true);
  }

  /// Drop the category filter and go back to searching everything.
  void clearCategory() => selectCategory(SearchCategory.all);

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
        category: selectedCategory.value,
        type: activeType.value,
        page: _page,
        limit: _limit,
        lat: _geoLat,
        lng: _geoLng,
      );
      if (seq != _searchSeq) return; // superseded by a newer search

      if (reset) {
        results.assignAll(res.results);
        facets.assignAll(res.facets);
        total.value = res.total;
        totalLabel.value = res.totalLabel;
        appliedFiltersText.value = res.appliedFiltersText;
      } else {
        results.addAll(res.results);
      }
      _hasMore = res.hasMore;
      if (res.results.isNotEmpty) _page++;
      // Keep any active price sort applied across paginated appends.
      _sortInPlace();
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

  // ── Opening a result's profile ──────────────────────────────────────
  /// Entity types that are a **person**. All are owned by `be_user_service`,
  /// so the id on the row resolves against [NewVisitProfileScreen].
  static const Set<String> peopleEntityTypes = {
    'user',
    'professional',
    'home_food_center',
    'home_product_seller',
    'home_service_provider',
  };

  /// Entity types that are a **business / shop**, whatever the vertical —
  /// their `sourceId` is the business id in `be_user_service`.
  ///
  /// Deliberately excludes `hospital`, `hotel`, `home_stay`, `school`,
  /// `course`, `rental` and `job`: those ids belong to their own services, so
  /// the business profile would open on an id it cannot fetch. Those rows keep
  /// the existing no-op until a screen is wired for them.
  static const Set<String> businessEntityTypes = {
    'business',
    'grocery_shop',
    'food_business',
    'retail_business',
    'service_business',
    'healthcare_business',
    'hotel_business',
    'education_business',
    'finance_business',
    'automotive_business',
  };

  /// The profile screen behind a result row, or null when the row isn't a
  /// profile (a product, a job listing, a course…).
  ///
  /// Routes on `sourceId` — the id in the owning service. `_id` is the
  /// search-index document id and resolves to nothing anywhere in the app.
  static Widget? profileScreenFor(SearchResultItem item) {
    final sourceId = item.sourceId?.trim() ?? '';
    final ownerId = item.ownerUserId?.trim() ?? '';
    final type = item.entityType;

    if (peopleEntityTypes.contains(type)) {
      // A `user` row *is* the person, so its own id wins. A provider row
      // (professional / home-*) is a listing owned by someone, so the owner id
      // is the profile to open and the listing id is only the fallback.
      final userId = type == 'user'
          ? (sourceId.isNotEmpty ? sourceId : ownerId)
          : (ownerId.isNotEmpty ? ownerId : sourceId);
      if (userId.isEmpty) return null;
      return NewVisitProfileScreen(
        authorId: userId,
        screenFromName: AppConstants.feedScreen,
      );
    }

    if (businessEntityTypes.contains(type)) {
      final businessId = sourceId.isNotEmpty ? sourceId : (item.businessId ?? '');
      if (businessId.isEmpty) return null;
      return VisitBusinessProfileNew(
        businessId: businessId,
        screenName: AppConstants.feedScreen,
      );
    }

    return null;
  }

  /// Open the profile behind a tapped result card — a person's visiting
  /// profile for people rows, the business profile for shop/business rows.
  /// Rows with no profile behind them fall back to the previous no-op toast.
  void openProfile(SearchResultItem item) {
    final screen = profileScreenFor(item);
    if (screen == null) {
      commonSnackBar(message: item.title);
      return;
    }
    // The search field can still hold focus behind the results list; leaving
    // it focused pops the keyboard back up on return from the profile.
    focusNode.unfocus();
    Get.to(() => screen);
  }

  /// Fetch the nearby stores that stock a product (grocery Search-Order flow,
  /// step 2 — `search-by-product`). Scopes to the user's current pincode/city
  /// when known; the backend broadens gracefully when neither is sent. Returns
  /// the parsed [StoreMatch] list (cheapest first). Throws on network failure so
  /// the caller can show a retry state.
  Future<List<StoreMatch>> fetchStoresForProduct(SearchResultItem item) async {
    final productId = item.sourceId ?? '';
    if (productId.isEmpty) return const [];

    final addr = LocationService.userCurrentAddress.value;
    final pincode = addr.postalCode.trim();
    final city = addr.city.trim();

    // No `inStock` key on purpose. It's an optional server-side *filter*, so
    // sending it at all narrows the result set — `true` drops stores the
    // backend thinks are empty, `false` drops the rest. Omitting it returns
    // every store that carries the product, which is what this sheet lists.
    final res = await GroceryRepo().searchInventoryByProductRepo(params: {
      'productId': productId,
      // if (pincode.isNotEmpty) 'pincode': pincode,
      if (pincode.isEmpty && city.isNotEmpty) 'cityName': city,
      'sortBy': 'price_low_to_high',
      'page': 1,
      'limit': 20,
    });

    final raw = res.response?.data;
    if (res.isSuccess && raw is Map) {
      final list = (raw['data'] as List?) ?? const [];
      return list
          .map((e) => StoreMatch.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw (raw is Map ? raw['message'] : null) ?? 'Could not load stores';
  }

  /// Fetch the full product behind a search result, for the fields the search
  /// index doesn't carry — `description` above all, plus country of origin and
  /// the veg flag (`GET grocery-service/api/products/{id}`).
  ///
  /// Returns null (never throws) when the id doesn't resolve — a non-grocery
  /// product, or a failed call — so the detail sheet simply omits those
  /// sections instead of showing an error for an enrichment.
  Future<GroceryProductData?> fetchProductDetail(SearchResultItem item) async {
    final productId = item.sourceId ?? '';
    if (productId.isEmpty) return null;
    try {
      final res = await GroceryRepo().fetchGroceryProductByIdRepo(productId);
      final raw = res.response?.data;
      if (!res.isSuccess || raw is! Map) return null;

      // Endpoint returns either the bare product or a `{ data: {...} }` envelope.
      final m = Map<String, dynamic>.from(raw);
      final payload =
          m['data'] is Map ? Map<String, dynamic>.from(m['data'] as Map) : m;
      final product = GroceryProductData.fromJson(payload);
      // A success envelope with no product in it parses to an empty shell.
      return product.sId == null ? null : product;
    } catch (_) {
      return null;
    }
  }

  /// Open the existing self-pickup order flow for a product result.
  ///
  /// Mirrors the grocery share deep-link "Buy Now": fetch the full grocery
  /// product by its [SearchResultItem.sourceId], drop the first priced variant
  /// into the shared [GrocerySelfPickupConsumerController] cart, then land on
  /// [GrocerySelfPickUpCartScreen] where the user reviews and places the real
  /// order (`placeBulkGroceryOrderApi`). Reuses the shipped flow end-to-end
  /// rather than a bespoke checkout.
  ///
  /// When [store] is given (the user picked a specific store from the
  /// "Available at N stores" list — grocery Search-Order flow, step 3), the line
  /// is grouped under that store and pinned to its inventory row, so the order
  /// is placed against the chosen seller rather than the product's default one.
  ///
  /// [variantId] pins the pack the user picked in the detail sheet (e.g. the
  /// 500 g tin rather than the 1 kg one); without it the store's first
  /// orderable line is used.
  Future<void> openProductOrder(SearchResultItem item,
      {StoreMatch? store, String? variantId}) async {
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

      // When a store was picked, honour its inventory line for the chosen pack
      // and pin that store's inventoryId. Otherwise fall back to the first
      // priced variant (else the first overall).
      final storeLine = store?.orderLineFor(variantId);
      final wantedVariantId = (storeLine?.productVariantId.isNotEmpty ?? false)
          ? storeLine!.productVariantId
          : (variantId ?? '');
      final variant = variants.firstWhere(
        (v) => wantedVariantId.isNotEmpty && v.sId == wantedVariantId,
        orElse: () => variants.firstWhere(
          (v) => (v.pricing?.isNotEmpty ?? false),
          orElse: () => variants.first,
        ),
      );

      final cart = getOrPut<GrocerySelfPickupConsumerController>(
          () => GrocerySelfPickupConsumerController());

      final storeName = store?.businessName?.trim();

      // Avoid double-adding if the user re-opens the same product.
      if (cart.getQuantity(variant.sId) == 0) {
        cart.addToCart(
          variant,
          productId: product.sId,
          inventoryId: storeLine?.inventoryId ??
              variant.inventory?.inventoryId ??
              variant.sId,
          // Group the line under the chosen store when one was picked; otherwise
          // fall back to the product's own context (the order body keys off
          // inventory + variant ids, not businessId).
          businessId: store?.businessId ?? item.businessId ?? product.sId,
          businessName: (storeName?.isNotEmpty ?? false)
              ? storeName
              : (item.subtitle?.trim().isNotEmpty ?? false)
                  ? item.subtitle
                  : (product.brand ?? product.name),
          businessLogo: store?.businessLogo ?? item.imageUrl,
          businessAddress: store?.locationLine ?? item.city,
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
