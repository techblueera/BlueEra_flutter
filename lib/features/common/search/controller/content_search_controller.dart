import 'dart:async';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/deeplink_network_resources.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/repo/search_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the inline type-ahead attached to the Connect (chat/feed) header
/// search field.
///
/// Scope is deliberately narrow: **content** (posts + videos) via
/// `search-service/search/content`, plus **people** (users + businesses)
/// picked out of the unscoped `/suggest` response. Catalogue entities
/// (products, grocery, food, hospitals…) are never shown here — that's what
/// the Discover global search is for.
///
/// Tapping a row goes straight to the thing itself: post → post detail,
/// video → the video/short player, user/business → that profile. There is no
/// intermediate results screen.
class ContentSearchController extends GetxController {
  final SearchRepo _repo = SearchRepo();

  final TextEditingController queryController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  /// Rows rendered in the dropdown — capped at [maxSuggestions].
  final RxList<SearchResultItem> suggestions = <SearchResultItem>[].obs;

  /// True while a debounced fetch for the current query is in flight.
  final RxBool isLoading = false.obs;

  /// True once a fetch for the current query has settled, so the panel can
  /// tell "still typing/loading" apart from "genuinely nothing matched".
  final RxBool hasSearched = false.obs;

  /// Mirrors the field text so the panel (recents vs suggestions) and the
  /// clear button react without the field rebuilding the whole header.
  final RxString query = ''.obs;

  /// True while the dropdown is open. The chat screen reads this to keep its
  /// collapsing header pinned while the user is searching.
  final RxBool isPanelOpen = false.obs;

  /// Max rows in the dropdown, and how many of them people may take.
  static const int maxSuggestions = 5;
  static const int _maxPeople = 2;

  // ── Recent searches (locally persisted) ─────────────────────────────
  /// Own key, separate from the Discover global search recents — this list
  /// only ever holds content/people terms, so mixing in product searches
  /// would surface rows that can't be opened from here.
  static const String _recentSearchesKey = 'connect_content_recent_searches';
  static const int _maxRecentSearches = 8;
  final RxList<String> recentSearches = <String>[].obs;

  Timer? _debounce;

  /// Bumped per fetch; responses that don't match the latest value are dropped
  /// so a slow early keystroke can't overwrite a fast later one.
  int _seq = 0;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches
          .assignAll(prefs.getStringList(_recentSearchesKey) ?? const []);
    } catch (_) {
      // Non-fatal: recents are a convenience, an empty list is fine.
    }
  }

  Future<void> _persistRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, recentSearches.toList());
    } catch (_) {}
  }

  void _addRecentSearch(String term) {
    final q = term.trim();
    if (q.isEmpty) return;
    recentSearches.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    recentSearches.insert(0, q);
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches.value = recentSearches.sublist(0, _maxRecentSearches);
    }
    _persistRecentSearches();
  }

  void removeRecentSearch(String term) {
    recentSearches.remove(term);
    _persistRecentSearches();
  }

  void clearRecentSearches() {
    recentSearches.clear();
    _persistRecentSearches();
  }

  // ── Typing ──────────────────────────────────────────────────────────

  /// Called on every keystroke. Debounced by 280 ms — the backend caches
  /// identical queries for 60 s, but firing per keystroke is still wasteful.
  void onQueryChanged(String text) {
    query.value = text;
    final q = text.trim();
    _debounce?.cancel();
    if (q.isEmpty) {
      _seq++; // invalidate anything in flight
      suggestions.clear();
      isLoading.value = false;
      hasSearched.value = false;
      return;
    }
    isLoading.value = true;
    _debounce = Timer(const Duration(milliseconds: 280), () => _fetch(q));
  }

  /// Re-run for a tapped recent term (fills the field, keeps focus).
  void applyRecentSearch(String term) {
    queryController.text = term;
    queryController.selection =
        TextSelection.collapsed(offset: queryController.text.length);
    onQueryChanged(term);
  }

  void clearQuery() {
    _debounce?.cancel();
    _seq++;
    queryController.clear();
    query.value = '';
    suggestions.clear();
    isLoading.value = false;
    hasSearched.value = false;
  }

  /// Fires the content search and the people lookup together and merges them.
  ///
  /// Two calls because there is no single endpoint that covers both:
  /// `/search/content` is fixed to posts+videos server-side, and people only
  /// come back from the unscoped `/suggest`. They race in parallel, and either
  /// one failing still lets the other render.
  Future<void> _fetch(String q) async {
    final seq = ++_seq;

    final contentFuture = _repo
        .searchContent(q, limit: maxSuggestions)
        .then<List<SearchResultItem>>((r) => r.results)
        .catchError((_) => <SearchResultItem>[]);

    // Called WITHOUT a category on purpose — `user` belongs to no category, so
    // scoping this call to `content` would drop the very rows it exists to
    // find. Hence the wider limit and the client-side people filter here, which
    // is the one case the "always scope /suggest" rule doesn't cover.
    final peopleFuture = _repo
        .suggest(q, limit: 10)
        .then<List<SearchResultItem>>((list) => list
            .where((s) => _isPerson(s.entityType))
            .map(_personToItem)
            .toList())
        .catchError((_) => <SearchResultItem>[]);

    final both = await Future.wait([contentFuture, peopleFuture]);
    if (seq != _seq) return; // superseded by a newer keystroke

    final people = both[1];
    final content = both[0];

    // A name match is usually what someone means when they type a person's
    // name, so people lead — but capped at two so content still gets room.
    final merged = <SearchResultItem>[
      ...people.take(_maxPeople),
      ...content,
      ...people.skip(_maxPeople),
    ];

    // De-dupe on entityType+id: the same row can arrive from both calls.
    final seen = <String>{};
    final deduped = <SearchResultItem>[];
    for (final item in merged) {
      final key = '${item.entityType}:${item.sourceId ?? item.id}';
      if (seen.add(key)) deduped.add(item);
      if (deduped.length == maxSuggestions) break;
    }

    suggestions.assignAll(deduped);
    isLoading.value = false;
    hasSearched.value = true;
  }

  static bool _isPerson(String entityType) =>
      entityType == 'user' || entityType == 'business';

  static SearchResultItem _personToItem(Suggestion s) => SearchResultItem(
        id: s.sourceId ?? '',
        entityType: s.entityType,
        sourceId: s.sourceId,
        title: s.title,
        subtitle: s.subtitle,
        imageUrl: s.imageUrl,
        deepLink: s.deepLink,
      );

  // ── Opening a result ────────────────────────────────────────────────

  /// Navigate to the tapped result and remember the query that found it.
  ///
  /// Ids come from `sourceId` (the id in the origin service) — `_id` is the
  /// search-index row id and is not routable.
  Future<void> openResult(SearchResultItem item) async {
    final id = (item.sourceId ?? '').trim();
    if (id.isEmpty) {
      commonSnackBar(message: 'Could not open this result');
      return;
    }

    _addRecentSearch(query.value);
    focusNode.unfocus();
    isPanelOpen.value = false;

    // Reset the field before navigating, so coming back from the post/profile
    // lands on an empty search showing recents rather than a stale query with
    // a stale result list behind it. The term itself is kept in recents above.
    clearQuery();

    switch (item.entityType) {
      case 'post':
        Get.to(() => PostDeatilPage(), arguments: {"postId": id});
        break;
      case 'video':
        // Long vs short isn't known from the search row, so this fetches the
        // video first and lands on the right player — same path deep links use.
        await deepLinkNetworkResources.navigateToVideoDetail(id);
        break;
      case 'user':
        Get.to(() => NewVisitProfileScreen(
              authorId: id,
              screenFromName: AppConstants.feedScreen,
            ));
        break;
      case 'business':
        Get.to(() => VisitBusinessProfileNew(
              businessId: id,
              screenName: AppConstants.feedScreen,
            ));
        break;
      default:
        commonSnackBar(message: item.title);
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    queryController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
