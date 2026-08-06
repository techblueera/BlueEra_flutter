import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:BlueEra/features/common/rental/view/property_details_screen.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/repo/search_repo.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives a category-scoped **store** search: recent searches on the landing
/// state, debounced type-ahead while typing, a paginated `/search` once the
/// query is committed, and the profile push when a result is tapped.
///
/// Every vertical-specific decision — which `category`/`type` to ask for, where
/// recents are stored, which profile screen a result opens — comes from
/// [config], so this class is shared by every store-search entry point rather
/// than copied per vertical.
///
/// Registered under a tag keyed on the config (see `StoreSearchScreen`), so two
/// verticals open at once keep separate state.
class StoreSearchController extends GetxController {
  StoreSearchController(this.config);

  final StoreSearchConfig config;
  final SearchRepo _repo = SearchRepo();

  final TextEditingController queryController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  // ── Type-ahead ───────────────────────────────────────────────────────
  final RxList<Suggestion> suggestions = <Suggestion>[].obs;

  /// True while the field is being edited — the panel shows recents (empty
  /// query) or suggestions. Flips false the moment a search is committed, and
  /// back to true on the next keystroke, because the results behind it are
  /// stale until re-committed.
  final RxBool showSuggestions = true.obs;

  /// Mirrors the field text so the landing/suggestion split can be reactive
  /// without rebuilding on the raw TextEditingController.
  final RxString queryText = ''.obs;

  // ── Results ──────────────────────────────────────────────────────────
  final RxList<SearchResultItem> results = <SearchResultItem>[].obs;
  final Rx<Status> status = Status.INITIAL.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt total = 0.obs;

  // ── Recent searches ──────────────────────────────────────────────────
  static const int _maxRecentSearches = 10;
  final RxList<String> recentSearches = <String>[].obs;

  String _committedQuery = '';
  int _page = 1;
  static const int _limit = 20;
  bool _hasMore = true;

  /// Debounce + out-of-order guards. Suggest/search responses can land out of
  /// order; every call bumps a sequence and stale replies are dropped.
  Timer? _debounce;
  int _suggestSeq = 0;
  int _searchSeq = 0;

  String get committedQuery => _committedQuery;
  bool get hasMore => _hasMore;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
  }

  // ─── Recents ────────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches
          .assignAll(prefs.getStringList(config.recentSearchesKey) ?? const []);
    } catch (_) {
      // Non-fatal: recents are a convenience, an empty list is a fine fallback.
    }
  }

  Future<void> _persistRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          config.recentSearchesKey, recentSearches.toList());
    } catch (_) {}
  }

  /// Push a committed query to the front of the recents (de-duped
  /// case-insensitively) and cap the list.
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

  void removeRecentSearch(String query) {
    recentSearches.remove(query);
    _persistRecentSearches();
  }

  void clearRecentSearches() {
    recentSearches.clear();
    _persistRecentSearches();
  }

  // ─── Typing ─────────────────────────────────────────────────────────

  /// Every keystroke. Debounced at 250 ms per the integration guide, with the
  /// previous suggest invalidated rather than awaited.
  void onQueryChanged(String text) {
    queryText.value = text;
    showSuggestions.value = true;
    final q = text.trim();
    _debounce?.cancel();
    if (q.isEmpty) {
      _suggestSeq++; // invalidate anything in flight
      suggestions.clear();
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 250), () => _fetchSuggest(q));
  }

  Future<void> _fetchSuggest(String q) async {
    final seq = ++_suggestSeq;
    try {
      // Scoped to this screen's vertical server-side. `/suggest` takes the same
      // `category` as `/search`, and the row cap is applied inside the query —
      // so asking unscoped and discarding the off-vertical rows afterwards is
      // what leaves the panel near-empty. It fills all 8 with this vertical.
      final s = await _repo.suggest(q, category: config.searchCategory);
      if (seq != _suggestSeq) return; // superseded
      // A category still pairs catalogue rows with the businesses that sell
      // them, so the ones this screen can actually open lead.
      final wanted = config.entityTypes.toSet();
      final mine = s.where((e) => wanted.contains(e.entityType)).toList();
      final others = s.where((e) => !wanted.contains(e.entityType)).toList();
      suggestions.assignAll([...mine, ...others]);
    } catch (_) {
      if (seq != _suggestSeq) return;
      suggestions.clear();
    }
  }

  /// Clear the field and go back to the recents landing without leaving the
  /// screen.
  void clearQuery() {
    _debounce?.cancel();
    _suggestSeq++;
    _searchSeq++;
    queryController.clear();
    queryText.value = '';
    suggestions.clear();
    results.clear();
    total.value = 0;
    _committedQuery = '';
    status.value = Status.INITIAL;
    showSuggestions.value = true;
    focusNode.requestFocus();
  }

  // ─── Searching ──────────────────────────────────────────────────────

  /// Commit a search (keyboard action, tapped suggestion, tapped recent).
  void submitSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    _suggestSeq++; // drop any pending suggest
    if (queryController.text != q) {
      queryController.text = q;
      queryController.selection =
          TextSelection.fromPosition(TextPosition(offset: q.length));
    }
    queryText.value = q;
    _committedQuery = q;
    _addRecentSearch(q);
    suggestions.clear();
    showSuggestions.value = false;
    focusNode.unfocus();
    _runSearch(reset: true);
  }

  /// Infinite-scroll trigger for the next page of the committed query.
  void loadMore() {
    if (!_hasMore || isLoadingMore.value || status.value == Status.LOADING) {
      return;
    }
    _runSearch(reset: false);
  }

  /// Re-run the committed search (error-state retry).
  void retry() {
    if (_committedQuery.isNotEmpty) _runSearch(reset: true);
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
        category: config.searchCategory,
        type: config.typeParam,
        page: _page,
        limit: _limit,
      );
      if (seq != _searchSeq) return; // superseded by a newer search

      if (reset) {
        results.assignAll(res.results);
        total.value = res.total;
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
      // A load-more failure keeps what's on screen; scrolling retries it.
    } finally {
      if (seq == _searchSeq) isLoadingMore.value = false;
    }
  }

  // ─── Opening a result ───────────────────────────────────────────────

  /// Open what a tapped result points at — a profile for every vertical except
  /// rentals, whose results are listings (see [_openRentalProperty]).
  void openResult(SearchResultItem item) {
    if (config.tapTarget == StoreSearchTapTarget.rentalProperty) {
      _openRentalProperty(item);
      return;
    }
    _openProfile(item);
  }

  /// Fetch a property by its search id and open its detail screen.
  ///
  /// The `rentals` category returns `rental` listings and has no business
  /// entity type, so there is no profile to open — and
  /// [PropertyDetailsScreen] needs a whole [PropertyModel], not an id. Hence
  /// the fetch behind a loader before the push.
  ///
  /// `isOwner: false`: this is the customer-facing view. The screen's owner
  /// controls (edit, mark rented) must not appear on someone else's listing.
  Future<void> _openRentalProperty(SearchResultItem item) async {
    final id = item.sourceId?.trim() ?? '';
    if (id.isEmpty) return;
    try {
      AppLoader.show();
      final res = await PropertyRepo().getPropertyById(id);
      AppLoader.hide();
      final data = res.data;
      if (!res.isSuccess || data is! Map) {
        commonSnackBar(message: 'Could not open this property');
        return;
      }
      Get.to(() => PropertyDetailsScreen(
            property: PropertyModel.fromJson(Map<String, dynamic>.from(data)),
            isOwner: false,
          ));
    } catch (_) {
      AppLoader.hide();
      commonSnackBar(message: 'Could not open this property');
    }
  }

  /// Open the profile behind a result.
  ///
  /// Routed through [openVisitProfile] — the app's single type→screen resolver
  /// — so a store found in search lands on exactly the screen the store list
  /// would have opened, and a new vertical needs no routing code here.
  ///
  /// The two ids are NOT interchangeable and the search index doesn't
  /// guarantee both: the store profile is fetched by business `_id` while its
  /// catalogue is fetched by the owner's user id. `sourceId` is the entity's
  /// real id in its owning service — the business id for a shop — with an
  /// explicit `businessId` preferred when the index carries one, and
  /// [SearchResultItem.ownerUserId] used for the owner. When only one turns up,
  /// [openVisitProfile] falls back to it for both, which still opens the right
  /// screen.
  void _openProfile(SearchResultItem item) {
    final String businessId =
        (item.businessId?.trim().isNotEmpty ?? false) ? item.businessId!.trim()
            : (item.sourceId?.trim() ?? '');
    final String userId = item.ownerUserId?.trim() ?? '';
    if (businessId.isEmpty && userId.isEmpty) return;

    openVisitProfile(
      accountType: config.accountType,
      typeOfBusiness: config.typeOfBusiness,
      // The result's own category first — it is what tells the resolver a
      // Healthcare hit is a pharmacy rather than a hospital. The config's value
      // is the fallback for a payload that carries none.
      categoryOfBusiness: (item.category?.trim().isNotEmpty ?? false)
          ? item.category
          : config.categoryOfBusiness,
      profileType: config.profileType,
      earnProfileTypes: config.earnProfileTypes,
      businessId: businessId,
      userId: userId,
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    queryController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
