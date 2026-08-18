import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_basket_entry_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/repo/vehicle_v3_repo.dart';
import 'package:BlueEra/features/me/vehicle/v3/service/vehicle_local_store.dart';
import 'package:get/get.dart';

/// Owner-side state for the rebuilt vehicle service (v3).
///
/// Scoped to the merchant dashboard: the seller's own listings, their
/// summary counters, and the catalog reads the add flow walks. Buyer-side
/// browsing has its own call sites and doesn't share this state.
///
/// Mirrors how [GroceryController] is used by the grocery merchant home —
/// registered by the home screen, kept for the session, and refreshed through
/// `*IfNeeded` guards so returning to the tab doesn't refire the same GETs.
class VehicleV3Controller extends GetxController {
  final VehicleV3Repo _repo = VehicleV3Repo();

  // ───── Listings ───────────────────────────────────────────────────

  final RxList<VehicleListingV3> myListings = <VehicleListingV3>[].obs;
  final Rxn<VehicleListingSummaryV3> summary = Rxn<VehicleListingSummaryV3>();

  /// INITIAL until the first listings fetch settles — the tab renders a
  /// skeleton off this rather than an empty state, so a slow network doesn't
  /// read as "you have no vehicles".
  final Rx<Status> listingsStatus = Status.INITIAL.obs;

  final RxBool isSubmitting = false.obs;

  VehiclePaginationV3 _listingsPage = const VehiclePaginationV3();
  final RxBool isLoadingMore = false.obs;

  bool get hasMoreListings => _listingsPage.hasMore;

  /// Freshness guard for the dashboard's fetch-on-tab-entry. Keyed by seller
  /// so a different account's data is never mistaken for fresh.
  final FetchCache _listingsCache = FetchCache();
  String _listingsSignature = '';

  /// Set by the add flow on a successful publish so the dashboard knows to
  /// reload instead of showing a list the new vehicle is missing from.
  bool listingsNeedRefresh = false;

  /// How many listings the dashboard rail previews before "View all".
  static const int listingsPreviewLimit = 10;

  // ───── Catalog ────────────────────────────────────────────────────

  /// Level-0 nodes (`4 Wheeler`, `2 Wheeler`, …) — the **add flow's** first
  /// picker. Deliberately NOT the dashboard's category rail: that shows what
  /// this shop stocks, see [myStockedCategories].
  final RxList<VehicleCategoryV3> rootCategories = <VehicleCategoryV3>[].obs;
  final Rx<Status> rootCategoriesStatus = Status.INITIAL.obs;
  final FetchCache _rootCategoriesCache = FetchCache();

  /// The catalog tree pruned to branches this seller actually has live stock
  /// in — `GET /categories/nested/with-inventory?businessId=`.
  ///
  /// This is the vehicle analogue of grocery's `categories/with-inventory`,
  /// and it is what "Manage via categories" must render. The rail used to be
  /// built from [rootCategories] (level 0 of the whole catalog), which showed
  /// a showroom every vehicle type in existence rather than the ones it
  /// sells — the opposite of "manage".
  final RxList<VehicleCategoryV3> myStockedCategories =
      <VehicleCategoryV3>[].obs;
  final Rx<Status> stockedCategoriesStatus = Status.INITIAL.obs;

  // ───── Add flow: "Quick Upload" rails + selection cart ────────────

  /// One rail per root category, each holding trims —
  /// `GET /products/by-root-category`. Drives the add screen exactly the way
  /// grocery's by-root-category rails drive its add screen.
  final RxList<VehicleRootCategorySectionV3> rootCategorySections =
      <VehicleRootCategorySectionV3>[].obs;
  final Rx<Status> rootSectionsStatus = Status.INITIAL.obs;
  final FetchCache _rootSectionsCache = FetchCache();

  /// The basket: one entry per vehicle the merchant is about to list.
  ///
  /// A vehicle can't be added by trim alone — `productVariant` (the colour) is
  /// required on create, and `condition` decides which fields the server
  /// expects — so an entry is only complete once both are chosen. That is why
  /// tapping "+" on a rail card opens the colour + condition sheet rather than
  /// dropping the trim straight into the basket like grocery does.
  final RxList<VehicleBasketEntryV3> basket = <VehicleBasketEntryV3>[].obs;

  /// Matches grocery's cap on one publish batch.
  static const int basketMaxItems = 10;

  bool get isBasketFull => basket.length >= basketMaxItems;

  bool isInBasket(String productVariantId) =>
      basket.any((e) => e.colour.id == productVariantId);

  /// Adds a colour+condition pair, or removes it when it's already there.
  void toggleBasketEntry(VehicleBasketEntryV3 entry) {
    final index =
        basket.indexWhere((e) => e.colour.id == entry.colour.id);
    if (index != -1) {
      basket.removeAt(index);
      return;
    }
    if (isBasketFull) {
      commonSnackBar(
          message: 'You can add up to $basketMaxItems vehicles at a time.');
      return;
    }
    basket.add(entry);
  }

  void removeFromBasket(String productVariantId) =>
      basket.removeWhere((e) => e.colour.id == productVariantId);

  void clearBasket() => basket.clear();

  /// Rails, skipped while still fresh — same TTL guard grocery's add screen
  /// uses so re-entering doesn't refetch.
  Future<void> fetchRootSectionsIfNeeded() async {
    if (_rootSectionsCache.isFresh('vehicleV3|rootSections',
        hasData: rootCategorySections.isNotEmpty)) {
      return;
    }
    await fetchRootSections();
  }

  Future<void> fetchRootSections() async {
    rootSectionsStatus.value = Status.LOADING;
    try {
      final res = await _repo.getProductsByRootCategory();
      if (!res.isSuccess) {
        rootSectionsStatus.value = Status.ERROR;
        return;
      }
      rootCategorySections
          .assignAll(VehicleRootCategorySectionV3.listFrom(res.response?.data));
      rootSectionsStatus.value = Status.COMPLETE;
      _rootSectionsCache.mark('vehicleV3|rootSections');
    } catch (e) {
      logs('VEHICLE_V3: fetchRootSections failed — $e');
      rootSectionsStatus.value = Status.ERROR;
    }
  }

  /// Publishes every basket entry.
  ///
  /// One POST per entry, not one batched call: §5 of the integration guide
  /// documents `POST /inventory` as taking a SINGLE listing
  /// (`{productVariant, condition, …}`) — unlike grocery and medical, whose
  /// endpoints accept an array. Sent sequentially so a multipart upload for a
  /// used vehicle doesn't contend with the others.
  ///
  /// Returns the number published. Partial success is reported rather than
  /// rolled back — the rows that landed are real listings.
  Future<int> publishBasket() async {
    if (basket.isEmpty) return 0;

    // Validate everything up front: a photo-heavy upload shouldn't start and
    // then fail on the last row for a missing price.
    for (final entry in basket) {
      final problem = entry.toDraft().validate();
      if (problem != null) {
        commonSnackBar(message: '${entry.trim.name}: $problem');
        return 0;
      }
    }

    isSubmitting.value = true;
    var published = 0;
    try {
      for (final entry in basket) {
        final res = await _repo.createListing(entry.toDraft());
        if (res.isSuccess) {
          published++;
        } else {
          commonSnackBar(
            message: VehicleV3Envelope.errorMessage(res.response?.data) ??
                'Could not publish ${entry.trim.name}.',
          );
        }
      }
      if (published > 0) {
        listingsNeedRefresh = true;
        _listingsCache.invalidate();
        basket.clear();
      }
      return published;
    } catch (e) {
      logs('VEHICLE_V3: publishBasket failed — $e');
      commonSnackBar(message: 'Could not publish these vehicles.');
      return published;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ───── Listings: reads ────────────────────────────────────────────

  /// Loads the dashboard data for [sellerId], skipping the network when the
  /// same seller's data is already on screen and still fresh.
  Future<void> loadDashboardIfNeeded(String sellerId) async {
    final signature = 'vehicleV3|$sellerId';
    final hasData =
        myListings.isNotEmpty || myStockedCategories.isNotEmpty;
    if (_listingsCache.isFresh(signature, hasData: hasData)) return;
    await loadDashboard(sellerId);
  }

  /// Unconditional reload — pull-to-refresh and post-publish.
  ///
  /// The same two-call shape grocery's Products tab uses: the seller's own
  /// stock, plus the categories that stock falls under. The level-0 catalog
  /// read is NOT part of this — that belongs to the add flow, which fetches it
  /// when the picker opens.
  Future<void> loadDashboard(String sellerId) async {
    _listingsSignature = 'vehicleV3|$sellerId';
    await Future.wait([
      fetchMyListings(),
      fetchSummary(),
      fetchMyStockedCategories(sellerId),
    ]);
  }

  Future<void> fetchMyListings({String? condition}) async {
    listingsStatus.value = Status.LOADING;
    try {
      final res = await _repo.getMyListings(condition: condition);
      if (!res.isSuccess) {
        listingsStatus.value = Status.ERROR;
        _reportIfMessage(res);
        return;
      }
      final body = res.response?.data;
      myListings.assignAll(VehicleListingV3.listFrom(body));
      _listingsPage = VehiclePaginationV3.of(body);
      listingsStatus.value = Status.COMPLETE;
      if (_listingsSignature.isNotEmpty) {
        _listingsCache.mark(_listingsSignature);
      }
    } catch (e) {
      logs('VEHICLE_V3: fetchMyListings failed — $e');
      listingsStatus.value = Status.ERROR;
    }
  }

  /// Appends the next page. No-op while one is in flight or when the last
  /// response said there is nothing after it.
  Future<void> loadMoreListings({String? condition}) async {
    if (isLoadingMore.value || !hasMoreListings) return;
    isLoadingMore.value = true;
    try {
      final res = await _repo.getMyListings(
        page: _listingsPage.page + 1,
        limit: _listingsPage.limit,
        condition: condition,
      );
      if (!res.isSuccess) return;
      final body = res.response?.data;
      myListings.addAll(VehicleListingV3.listFrom(body));
      _listingsPage = VehiclePaginationV3.of(body);
    } catch (e) {
      logs('VEHICLE_V3: loadMoreListings failed — $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchSummary() async {
    try {
      final res = await _repo.getMySummary();
      if (!res.isSuccess) return;
      final json = VehicleV3Envelope.object(res.response?.data);
      if (json != null) {
        summary.value = VehicleListingSummaryV3.fromJson(json);
      }
    } catch (e) {
      logs('VEHICLE_V3: fetchSummary failed — $e');
    }
  }

  // ───── Catalog: reads ─────────────────────────────────────────────

  /// Three layers, cheapest first:
  /// 1. [_rootCategoriesCache] — loaded < 5 min ago, still in memory.
  /// 2. [VehicleLocalStore] — the saved list. **If there is one and it is
  ///    inside [VehicleLocalStore.catalogTtl], that is the answer and no
  ///    request is made.**
  /// 3. The network.
  ///
  /// The memory guard alone died with the app, so a cold start re-asked for a
  /// catalogue that changes on the order of weeks. Age is the only refresh
  /// trigger it can have — nothing the seller does from this device changes the
  /// platform's category tree.
  Future<void> fetchRootCategories() async {
    if (_rootCategoriesCache.isFresh('vehicleV3|roots',
        hasData: rootCategories.isNotEmpty)) {
      return;
    }
    rootCategoriesStatus.value = Status.LOADING;
    try {
      final entry = await VehicleLocalStore.readCatalogRoots();
      if (entry != null && !entry.isEmpty) {
        final cached = VehicleCategoryV3.listFrom(entry.items);
        if (cached.isNotEmpty) {
          rootCategories.assignAll(cached);
          rootCategoriesStatus.value = Status.COMPLETE;
          if (!entry.isOlderThan(VehicleLocalStore.catalogTtl)) {
            _rootCategoriesCache.mark('vehicleV3|roots');
            return;
          }
        }
      }

      final res = await _repo.getCategories(level: 0);
      if (!res.isSuccess) {
        // A failed refresh must not wipe a list restored from disk.
        if (rootCategories.isEmpty) rootCategoriesStatus.value = Status.ERROR;
        return;
      }
      // The unwrapped list is what gets cached, so the next open rebuilds it
      // through this same `listFrom` — the envelope helper takes a bare array.
      final raw = VehicleV3Envelope.list(res.response?.data);
      rootCategories.assignAll(VehicleCategoryV3.listFrom(raw));
      rootCategoriesStatus.value = Status.COMPLETE;
      _rootCategoriesCache.mark('vehicleV3|roots');
      if (raw.isNotEmpty) await VehicleLocalStore.writeCatalogRoots(raw);
    } catch (e) {
      logs('VEHICLE_V3: fetchRootCategories failed — $e');
      if (rootCategories.isEmpty) rootCategoriesStatus.value = Status.ERROR;
    }
  }

  /// The seller's own stocked categories — what the dashboard's category rail
  /// renders. Scoped with `businessId` so the tree comes back pruned to
  /// branches this showroom has live listings in.
  Future<void> fetchMyStockedCategories(String sellerId) async {
    stockedCategoriesStatus.value = Status.LOADING;
    try {
      final res = await _repo.getNestedCategoriesWithInventory(
        businessId: sellerId,
      );
      if (!res.isSuccess) {
        stockedCategoriesStatus.value = Status.ERROR;
        return;
      }
      myStockedCategories
          .assignAll(VehicleCategoryV3.listFrom(res.response?.data));
      stockedCategoriesStatus.value = Status.COMPLETE;
    } catch (e) {
      logs('VEHICLE_V3: fetchMyStockedCategories failed — $e');
      stockedCategoriesStatus.value = Status.ERROR;
    }
  }

  /// Every category id at or beneath [node].
  ///
  /// `/inventory/my` takes only `page`, `limit` and `condition` — there is no
  /// category filter on it — so drilling into a category rail tile filters the
  /// already-loaded listings client-side, matching a listing's
  /// `modelCategory` (a leaf) against the tapped branch's whole subtree.
  Set<String> descendantCategoryIds(VehicleCategoryV3 node) {
    final ids = <String>{};
    void walk(VehicleCategoryV3 current) {
      if (current.id.isNotEmpty) ids.add(current.id);
      for (final child in current.children) {
        walk(child);
      }
    }

    walk(node);
    return ids;
  }

  /// Children of [parentId] at [level] — the add flow's brand (1) and model
  /// (2) steps. Returns the list rather than parking it in controller state:
  /// the picker screen is transient and owns its own page state, so keeping a
  /// copy here would just go stale.
  /// Cache-first, one entry per `parentId|level`. Both belong in the key: the
  /// endpoint takes both, and the same parent answers differently per level.
  ///
  /// This is the branch the picker walks on every add — root → brand → model,
  /// then back up and down again to correct a wrong turn — and it had no cache
  /// of any kind, so each of those taps was a request.
  Future<List<VehicleCategoryV3>> fetchChildCategories({
    required String parentId,
    required int level,
  }) async {
    final cacheKey = '$parentId|$level';
    try {
      final entry = await VehicleLocalStore.readCatalogChild(cacheKey);
      final hasCache = entry != null && !entry.isEmpty;
      if (hasCache && !entry.isOlderThan(VehicleLocalStore.catalogTtl)) {
        final cached = VehicleCategoryV3.listFrom(entry.items);
        if (cached.isNotEmpty) return cached;
      }

      final res = await _repo.getCategories(level: level, parentId: parentId);
      if (!res.isSuccess) {
        // A stale saved branch beats an empty picker when the network says no.
        if (hasCache) {
          final cached = VehicleCategoryV3.listFrom(entry.items);
          if (cached.isNotEmpty) return cached;
        }
        _reportIfMessage(res);
        return const [];
      }
      final raw = VehicleV3Envelope.list(res.response?.data);
      if (raw.isNotEmpty) {
        unawaited(VehicleLocalStore.writeCatalogChild(cacheKey, raw));
      }
      return VehicleCategoryV3.listFrom(raw);
    } catch (e) {
      logs('VEHICLE_V3: fetchChildCategories failed — $e');
      return const [];
    }
  }

  /// Trims under a model (or any ancestor — `categoryId` resolves to the
  /// whole subtree).
  Future<List<VehicleTrimV3>> fetchTrims({
    required String categoryId,
    String? searchTerm,
    int page = 1,
  }) async {
    try {
      final res = await _repo.searchTrims(
        categoryId: categoryId,
        searchTerm: searchTerm,
        page: page,
      );
      if (!res.isSuccess) {
        _reportIfMessage(res);
        return const [];
      }
      return VehicleTrimV3.listFrom(res.response?.data);
    } catch (e) {
      logs('VEHICLE_V3: fetchTrims failed — $e');
      return const [];
    }
  }

  /// A trim with its colours. Null on failure — the caller can't proceed to
  /// the form without it, so there is nothing to degrade to.
  Future<VehicleTrimV3?> fetchTrimDetail(String productId) async {
    try {
      final res = await _repo.getTrim(productId);
      if (!res.isSuccess) {
        _reportIfMessage(res);
        return null;
      }
      final json = VehicleV3Envelope.object(res.response?.data);
      if (json == null) return null;
      return VehicleTrimV3.fromJson(json);
    } catch (e) {
      logs('VEHICLE_V3: fetchTrimDetail failed — $e');
      return null;
    }
  }

  // ───── Listings: writes ───────────────────────────────────────────

  /// Publishes [draft]. Returns true on success.
  ///
  /// Validation runs client-side first so an obviously incomplete form
  /// doesn't cost an upload — particularly worth it here, where a USED
  /// listing can be carrying a dozen photos.
  Future<bool> publishListing(VehicleListingDraftV3 draft) async {
    final problem = draft.validate();
    if (problem != null) {
      commonSnackBar(message: problem);
      return false;
    }

    isSubmitting.value = true;
    try {
      final res = await _repo.createListing(draft);
      if (!res.isSuccess) {
        commonSnackBar(
          message: VehicleV3Envelope.errorMessage(res.response?.data) ??
              'Could not publish this listing. Please try again.',
        );
        return false;
      }
      // The dashboard reloads on the way back rather than inserting the
      // response row here: the create response isn't enriched with the joined
      // catalog the cards render from.
      listingsNeedRefresh = true;
      _listingsCache.invalidate();
      return true;
    } catch (e) {
      logs('VEHICLE_V3: publishListing failed — $e');
      commonSnackBar(message: 'Could not publish this listing. Please try again.');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Flips a listing's active flag, updating the row in place on success.
  Future<void> toggleListingActive(VehicleListingV3 listing) async {
    final next = !listing.isActive;
    try {
      final res = await _repo.toggleListing(listing.id, isActive: next);
      if (!res.isSuccess) {
        commonSnackBar(
          message: VehicleV3Envelope.errorMessage(res.response?.data) ??
              'Could not update this listing.',
        );
        return;
      }
      final index = myListings.indexWhere((l) => l.id == listing.id);
      if (index != -1) {
        // No copyWith on the model — re-read is cheap and keeps the row
        // consistent with whatever else the server changed.
        await fetchMyListings();
      }
      await fetchSummary();
    } catch (e) {
      logs('VEHICLE_V3: toggleListingActive failed — $e');
    }
  }

  /// Soft-deletes a listing and drops it from the list optimistically.
  Future<bool> deleteListing(VehicleListingV3 listing) async {
    try {
      final res = await _repo.deleteListing(listing.id);
      if (!res.isSuccess) {
        commonSnackBar(
          message: VehicleV3Envelope.errorMessage(res.response?.data) ??
              'Could not delete this listing.',
        );
        return false;
      }
      myListings.removeWhere((l) => l.id == listing.id);
      await fetchSummary();
      return true;
    } catch (e) {
      logs('VEHICLE_V3: deleteListing failed — $e');
      return false;
    }
  }

  /// Surfaces a server-provided message, and only that — a failure with no
  /// message stays silent rather than inventing one for a background read.
  void _reportIfMessage(ResponseModel res) {
    final message = VehicleV3Envelope.errorMessage(res.response?.data);
    if (message != null) commonSnackBar(message: message);
  }
}
