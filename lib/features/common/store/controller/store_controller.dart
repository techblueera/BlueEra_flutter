import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/api/model/store_counts_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/models/product_consumer_nested_category_response.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreController extends GetxController{
  Rx<ApiResponse> getAllStoreResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreProductResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllFoodServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfAiMessageResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> followResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> unFollowResponse =
      ApiResponse.initial('Initial').obs;

  final ScrollController scrollController = ScrollController();
  final GlobalKey headerKey = GlobalKey();
  Function(bool isVisible)? onHeaderVisibilityChanged;
  final RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;
  double headerHeight = 0;

  // Search Management
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;
  Timer? debounce;

  String? typeOfBusiness;
  String? businessCategoryId;

  /// Search radius (km) sent with the near-by store request.
  ///
  /// [kmRadius300] is the app-wide default; a screen that needs a different
  /// reach sets this where it sets [typeOfBusiness] and restores the default
  /// when it leaves — this controller is a shared singleton, so an un-restored
  /// value would follow the user into the next store screen. It is part of
  /// [_storeIdentity] as well, so two screens on different radii can never
  /// serve each other's cached list.
  int searchRadiusKm = kmRadius300;

  /// Optional `subCategory` filter for the near-by store search — the
  /// sub-category's `_id`, one level below [businessCategoryId]. Used by the
  /// auto-parts discover screen, whose tabs ARE the sub-categories; null on
  /// screens that filter by category alone, and the param is simply left off
  /// the request then.
  String? businessSubCategoryId;

  /// All Stores data
  RxList<GetAllStoreResModel> allStore = <GetAllStoreResModel>[].obs;
  RxBool isAllStoreLoadingMore = false.obs;
  RxBool isAllStoreFirstLoading = false.obs;
  int allStorePage = 1;
  bool allStoreHasMore = true;

  /// Freshness guard for the shared [allStore] list. Both [getAllStoreNearBy]
  /// (stores / grocery / food — distinguished by [typeOfBusiness]) and
  /// [getServiceBusinessesNearBy] (services) write into [allStore], so each one
  /// stamps this cache with its own identity on success. Re-entering a screen
  /// then reuses the data only when the identity still matches — a grocery
  /// screen never serves a food screen's leftovers, and vice-versa.
  final FetchCache _allStoreCache = FetchCache();

  // ── Store product / category counts ──────────────────────────────────────

  /// Counts by `<catalogue>|<store id>`, for every store seen this session.
  ///
  /// Separate from [allStore] rather than written back onto each model: the
  /// store list is replaced wholesale on every refresh and on every category
  /// switch, and counts merged into it would be thrown away with it and
  /// re-fetched for stores whose numbers had not changed. Keyed by BOTH the
  /// business id and the owner user id — see [StoreCountsModel.lookupKeys].
  ///
  /// The catalogue is part of the key because one business can trade in more
  /// than one of them: a shop selling groceries and cooked food has a grocery
  /// count and a food count, and keying on the id alone would let whichever
  /// screen loaded first answer for the other.
  ///
  /// Observable so a card can paint without counts and fill them in when they
  /// arrive; [countsFor] is what the cards read.
  final RxMap<String, StoreCountsModel> storeCounts =
      <String, StoreCountsModel>{}.obs;

  /// Cache keys with a counts request in flight, so paging back and forth over
  /// the same stores doesn't re-ask for them.
  final Set<String> _countsInFlight = {};

  /// Held rather than constructed per call: [_countsCatalogue] is read from
  /// inside every card's `Obx`, i.e. on every list frame, purely to reach the
  /// three path constants that hang off [BaseService].
  final StoreRepo _countsRepo = StoreRepo();

  /// Which catalogue [typeOfBusiness] maps onto, as `(path, cache prefix)`.
  ///
  /// The three services take an identical request and return an identical
  /// response, so only the URL changes — but they answer for different
  /// inventories, and asking grocery about a restaurant returns a clean,
  /// wrong `0`. Paths are the doc's, per service:
  /// docs/backend/BUSINESS_PRODUCT_STATS_FLUTTER_GUIDE.md.
  ///
  /// Anything not food or grocery (Product, Manufacturing, Automotive, …)
  /// reads the product catalogue, which is where those listings' inventory
  /// lives.
  ({String path, String prefix}) get _countsCatalogue {
    final repo = _countsRepo;
    final type = (typeOfBusiness ?? '').toLowerCase();
    if (type == AppConstants.food.toLowerCase() ||
        type == BusinessType.Food.name.toLowerCase()) {
      return (path: repo.foodBusinessProductStats, prefix: 'food');
    }
    if (type == BusinessType.Grocery.name.toLowerCase()) {
      return (path: repo.groceryBusinessProductStats, prefix: 'grocery');
    }
    if (type == BusinessType.Automotive.name.toLowerCase()) {
      return (path: repo.automotiveBusinessProductStats, prefix: 'automotive');
    }
    return (path: repo.productBusinessProductStats, prefix: 'product');
  }

  String _countsKey(String prefix, String id) => '$prefix|$id';

  /// The counts for a store in the CURRENT screen's catalogue, or null while
  /// they are still unknown.
  ///
  /// Takes both ids because callers have different ones to hand and the server
  /// may have matched on either.
  StoreCountsModel? countsFor({String? businessId, String? userId}) =>
      _countsIn(_countsCatalogue.prefix, businessId: businessId, userId: userId);

  StoreCountsModel? _countsIn(String prefix,
      {String? businessId, String? userId}) {
    if (businessId?.isNotEmpty == true) {
      final hit = storeCounts[_countsKey(prefix, businessId!)];
      if (hit != null) return hit;
    }
    if (userId?.isNotEmpty == true) {
      return storeCounts[_countsKey(prefix, userId!)];
    }
    return null;
  }

  /// Load counts for [stores] — memory, then disk, then the network for
  /// whatever neither could answer.
  ///
  /// Fired AFTER a page of stores is on screen, never before: the whole reason
  /// the backend split this off the listing is that the stores should not wait
  /// on the counts. Failure is silent for the same reason — the cards are
  /// already rendered and complete apart from two figures.
  Future<void> fetchStoreCountsFor(List<GetAllStoreResModel> stores) async {
    if (stores.isEmpty) return;

    final catalogue = _countsCatalogue;
    final prefix = catalogue.prefix;

    // 1. In memory already? A page revisited, or a store that appeared in an
    //    earlier page, costs nothing.
    final pending = <GetAllStoreResModel>[];
    for (final store in stores) {
      final businessId = store.id ?? '';
      final userId = store.userId ?? '';
      if (businessId.isEmpty && userId.isEmpty) continue;
      if (_countsIn(prefix, businessId: businessId, userId: userId) != null) {
        continue;
      }
      if (_countsInFlight.contains(_countsKey(prefix, businessId)) ||
          _countsInFlight.contains(_countsKey(prefix, userId))) {
        continue;
      }
      pending.add(store);
    }
    if (pending.isEmpty) return;

    // 2. Disk — a cold start shows real numbers on the first frame the cards
    //    paint, instead of blanks that fill in a round-trip later.
    final cached = HiveServices().getStoreCounts([
      for (final s in pending) ...[
        if (s.id?.isNotEmpty == true) _countsKey(prefix, s.id!),
        if (s.userId?.isNotEmpty == true) _countsKey(prefix, s.userId!),
      ],
    ]);
    if (cached.isNotEmpty) {
      final hydrated = <String, StoreCountsModel>{};
      for (final row in cached.values) {
        final counts = StoreCountsModel.fromJson(row);
        for (final key in counts.lookupKeys) {
          hydrated[_countsKey(prefix, key)] = counts;
        }
      }
      if (hydrated.isNotEmpty) storeCounts.addAll(hydrated);
      pending.removeWhere(
        (s) => _countsIn(prefix, businessId: s.id, userId: s.userId) != null,
      );
      if (pending.isEmpty) return;
    }

    // 3. Network, for the remainder only.
    final requestKeys = <String>{
      for (final s in pending) ...[
        if (s.id?.isNotEmpty == true) _countsKey(prefix, s.id!),
        if (s.userId?.isNotEmpty == true) _countsKey(prefix, s.userId!),
      ],
    };
    _countsInFlight.addAll(requestKeys);
    try {
      final response = await StoreRepo().getStoreCountsRepo(
        path: catalogue.path,
        businesses: [
          for (final s in pending)
            {
              // Both ids when we have them: the server matches on either, and
              // which one carries the inventory differs per store.
              if (s.id?.isNotEmpty == true) 'businessId': s.id!,
              if (s.userId?.isNotEmpty == true) 'userId': s.userId!,
            },
        ],
      );
      if (!response.isSuccess) return;

      final body = response.response?.data;
      final rows = body is Map ? body['data'] : body;
      if (rows is! List) return;

      final parsed = <String, StoreCountsModel>{};
      final toPersist = <String, Map<String, dynamic>>{};
      for (final row in rows.whereType<Map>()) {
        final counts = StoreCountsModel.fromJson(row);
        for (final key in counts.lookupKeys) {
          parsed[_countsKey(prefix, key)] = counts;
          toPersist[_countsKey(prefix, key)] = counts.toJson();
        }
      }
      if (parsed.isEmpty) return;
      storeCounts.addAll(parsed);
      unawaited(HiveServices().saveStoreCounts(toPersist));
    } catch (e) {
      log('Store counts fetch failed: $e');
    } finally {
      _countsInFlight.removeAll(requestKeys);
    }
  }

  /// `stores|<user>|<type>|<category>|<subCategory>|<radius>` — the dataset
  /// *identity*. Location is no
  /// longer baked into the key; instead it's tracked as a distance delta (see
  /// [_lastStoreFetchLat]/[_lastStoreFetchLng] + [_moveInvalidationMeters]) so
  /// a small walk doesn't refetch but a real relocation does. This is also the
  /// Hive key, so each (user, type, category) gets its own persisted entry.
  String get _storeIdentity =>
      'stores|$userId|${typeOfBusiness ?? ''}|${businessCategoryId ?? ''}'
      '|${businessSubCategoryId ?? ''}|$searchRadiusKm';

  /// `services|<user>|<category>` — service search ignores [typeOfBusiness].
  String get _serviceIdentity => 'services|$userId|${businessCategoryId ?? ''}';

  /// Where the data currently in [allStore] was fetched. Used to detect that
  /// the user has moved far enough to warrant fresh results.
  double? _lastStoreFetchLat;
  double? _lastStoreFetchLng;

  /// A persisted store list older than this triggers a silent background
  /// refresh on re-entry (the cached list is still shown instantly meanwhile).
  static const Duration _persistTtl = Duration(hours: 24);

  /// Moving farther than this (metres) from where the list was fetched marks
  /// the cache stale — the user is effectively shopping a new area.
  static const double _moveInvalidationMeters = 1500;

  /// All Product data
  RxList<GetProductData> productDataList = <GetProductData>[].obs;
  RxBool isProductDataLoadingMore = false.obs;
  RxBool isProductDataFirstLoading = false.obs;
  int productDataPage = 1;
  bool productDataHasMore = true;

  /// Freshness guard for the shared [productDataList].
  final FetchCache _productCache = FetchCache();

  String _productSignature({
    ProviderType? providerType,
    String? productCategory,
    String? query,
  }) =>
      'products|${providerType?.title ?? ''}|${productCategory ?? ''}|'
      '${query ?? ''}|${LocationService.lat.toStringAsFixed(3)}|'
      '${LocationService.lng.toStringAsFixed(3)}';

  /// Store Ai Variables
  TextEditingController sendMessageController = TextEditingController();
  RxBool isTextFieldEmpty = false.obs;
  final ScrollController aiChatScrollController = ScrollController();
  RxBool chatBotReading = false.obs;

  Rx<CategoryData?> selectedGroceryCategoryData = Rx<CategoryData?>(null);

  // RxBool isBannerVisible = false.obs;
  RxBool isBannerVisible = true.obs;

  @override
  void onInit() {
    super.onInit();
    // scrollController.addListener(() {
    //   if (scrollController.offset > 300) {
    //     isBannerVisible.value = true;
    //   } else {
    //     isBannerVisible.value = false;
    //   }
    // });
  }

  @override
  void onClose() {
    debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ── Product Category Tree ─────────────────────────────────

  RxBool isProductCategoryTreeLoading = false.obs;
  RxList<ProductNestedCategory> productCategoryTreeList = <ProductNestedCategory>[].obs;
  Rxn<ProductNestedCategory> selectedProductSubCategory = Rxn<ProductNestedCategory>();

  Future<void> fetchProductCategoryTree({required String group}) async {
    try {
      isProductCategoryTreeLoading.value = true;
      productCategoryTreeList.clear();

      final response = await StoreRepo().getProductCategoryTree(group: group);

      if (response.isSuccess) {
        final data = response.response?.data;
        if (data != null && data is Map<String, dynamic>) {
          final parsed = ProductConsumerNestedCategoryResponse.fromJson(data);
          productCategoryTreeList.value = parsed.data ?? [];
        }
      }
    } catch (e) {
      log('Error fetching product category tree: $e');
    } finally {
      isProductCategoryTreeLoading.value = false;
    }
  }

  /// Fetch the near-by store list only when it isn't already loaded & fresh for
  /// the current request. Use this on screen (re)entry; call [getAllStoreNearBy]
  /// directly for explicit refreshes (pull-to-refresh, category change).
  ///
  /// Three tiers, fastest first:
  ///  1. In-session memory — the list is already loaded for this identity and
  ///     hasn't gone stale (TTL) or far (distance); nothing to do.
  ///  2. Persistent disk cache — hydrate [allStore] instantly so the user sees
  ///     stores with no spinner, then silently revalidate in the background
  ///     only if the saved entry is too old or was fetched too far away.
  ///  3. Network — nothing usable cached; do a normal first-load fetch.
  Future<void> getAllStoreNearByIfNeeded() async {
    // Dropped the in-memory list if the user has relocated since it loaded.
    if (_movedFarFromLastFetch()) _allStoreCache.invalidate();

    // 1) In-session memory cache still fresh.
    if (_allStoreCache.isFresh(_storeIdentity, hasData: allStore.isNotEmpty)) {
      return;
    }

    // 2) Persistent disk cache (cold start / disposed controller / switched
    //    identity). Show instantly, revalidate only when stale.
    final entry =
        HiveServices().getGeoList(boxName: HiveServices.nearByStoreBox, key: _storeIdentity);
    if (entry != null && entry.items.isNotEmpty) {
      final cachedStores = _decodeStores(entry.items);
      if (cachedStores.isNotEmpty) {
        allStore.assignAll(cachedStores);
        getAllStoreResponse.value = ApiResponse.complete();
        _lastStoreFetchLat = entry.lat;
        _lastStoreFetchLng = entry.lng;
        // Reset paging — page 1 is what we persisted; "load more" continues from 2.
        allStorePage = 2;
        allStoreHasMore = true;
        _allStoreCache.mark(_storeIdentity);

        // The cached STORES carry no counts — those live in their own box, so
        // hydrate them for this page too. Reads disk first and only calls the
        // network for stores it can't answer, which on a warm cache is none.
        unawaited(fetchStoreCountsFor(cachedStores));

        final tooOld = DateTime.now().difference(entry.savedAt) > _persistTtl;
        final movedFar =
            LocationService.metersFromCurrent(entry.lat, entry.lng) >
                _moveInvalidationMeters;
        if (tooOld || movedFar) {
          // Stale-while-revalidate: keep the cached list on screen, refresh
          // quietly so it swaps to fresh data without a blocking shimmer.
          unawaited(getAllStoreNearBy(silentRefresh: true));
        }
        return;
      }
    }

    // 3) Nothing usable cached — normal fetch.
    await getAllStoreNearBy();
  }

  /// Whether the device has moved past [_moveInvalidationMeters] from where the
  /// in-memory [allStore] data was last fetched.
  bool _movedFarFromLastFetch() {
    final lat = _lastStoreFetchLat;
    final lng = _lastStoreFetchLng;
    if (lat == null || lng == null) return false;
    return LocationService.metersFromCurrent(lat, lng) > _moveInvalidationMeters;
  }

  /// Maps a raw persisted JSON list into store models, normalising nested map
  /// key types via a JSON round-trip (matches the network parser).
  List<GetAllStoreResModel> _decodeStores(List<dynamic> raw) {
    try {
      return raw
          .map((e) => GetAllStoreResModel.fromJson(
              jsonDecode(jsonEncode(e)) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('store cache decode error: $e');
      return const [];
    }
  }

  ///GET STORES ONLY....
  ///
  /// [silentRefresh] does a fresh page-1 fetch WITHOUT clearing the list or
  /// showing the first-load shimmer — used by the stale-while-revalidate path
  /// so the already-shown cached list swaps to fresh data in place. Pull-to-
  /// refresh / category change pass the default (visible) refresh.
  Future<void>  getAllStoreNearBy({bool isLoadMore = false, bool silentRefresh = false}) async {
    // if(typeOfBusiness == null || businessCategoryId == null){
    //   commonSnackBar(message: 'Business Category id not found');
    //   return;
    // }

    if (isLoadMore) {
      if (isAllStoreLoadingMore.value || !allStoreHasMore) return;
      isAllStoreLoadingMore.value = true;
    } else {
      allStorePage = 1;
      allStoreHasMore = true;
      if (!silentRefresh) {
        isAllStoreFirstLoading.value = true;
        allStore.clear();
      }
    }

    try {

      // `user-service/business/search` params. The old map-service listing
      // spelled these `type` / `category_id`; this endpoint wants
      // `typeOfBusiness` / `category` and ignores anything it doesn't know —
      // an unfiltered list, not an error — so the spellings matter.
      Map<String, dynamic> queryParams = {
        ApiKeys.page: allStorePage,
        ApiKeys.limit: 20,
        ApiKeys.lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "0.0",
        ApiKeys.lng: LocationService.lng != 0.0 ? "${LocationService.lng}" : "0.0",
        ApiKeys.typeOfBusiness: typeOfBusiness,
        ApiKeys.radius: searchRadiusKm
      };
      if (businessCategoryId != null) {
        queryParams[ApiKeys.category] = businessCategoryId;
      }
      if (businessSubCategoryId != null) {
        queryParams[ApiKeys.subCategory] = businessSubCategoryId;
      }

      final response = await StoreRepo().getSpecificStores(
        queryParams: queryParams
      ); // Make sure repo uses params
      if (response.isSuccess) {
        getAllStoreResponse.value = ApiResponse.complete(response);

        final responseData = response.response?.data;

        List<GetAllStoreResModel> newStores = [];

        // Handle both array or wrapped API formats
        if (responseData is List) {
          newStores = responseData
              .map((e) => GetAllStoreResModel.fromJson(e))
              .toList();
        } else if (responseData is Map && responseData['data'] is List) {
          newStores = (responseData['data'] as List)
              .map((e) => GetAllStoreResModel.fromJson(e))
              .toList();
        }

        log("Loaded ${newStores.length} stores");

        // logic for if live photo not available we are not adding in main list
        // newStores = newStores
        //     .where((store) =>
        // (store.livePhotos != null &&
        //     store.livePhotos!.isNotEmpty &&
        //     store.livePhotos!.any((p) => p.trim().isNotEmpty)))
        //     .toList();

        if (newStores.isNotEmpty) {
          if (isLoadMore) {
            allStore.addAll(newStores);
          } else {
            allStore.assignAll(newStores);
            // Stamp the in-memory freshness cache so a re-entry with the same
            // identity skips the network call instead of refetching, record
            // where we fetched (for the move-distance check), and persist
            // page 1 to disk so a cold start shows stores instantly.
            _lastStoreFetchLat = LocationService.lat;
            _lastStoreFetchLng = LocationService.lng;
            _allStoreCache.mark(_storeIdentity);
            unawaited(HiveServices().saveGeoList(
              boxName: HiveServices.nearByStoreBox,
              key: _storeIdentity,
              jsonList: newStores.map((e) => e.toJson()).toList(),
              lat: LocationService.lat,
              lng: LocationService.lng,
            ));
          }

          // Counts come from their own endpoint now — fired here, after the
          // stores are in the list and on screen, and NOT awaited. The listing
          // dropped its gRPC fan-out precisely so it need not wait on these.
          unawaited(fetchStoreCountsFor(newStores));

          allStorePage++;

          // `business/search` reports how many pages exist, so stop at the last
          // one instead of discovering the end by fetching an empty page.
          final pagination =
              responseData is Map ? responseData['pagination'] : null;
          final totalPages = pagination is Map
              ? (pagination['totalPages'] as num?)?.toInt()
              : null;
          if (totalPages != null) allStoreHasMore = allStorePage <= totalPages;
        } else {
          allStoreHasMore = false;
        }

        log("Total: ${allStore.length}");
      } else {

        getAllStoreResponse.value = ApiResponse.error('error');

        log("API failed with status: ${response.statusCode}");
      }
    } catch (e, s) {
      log("Error: $s");
      getAllStoreResponse.value = ApiResponse.error('error');
    }finally{
      if (isLoadMore) {
        isAllStoreLoadingMore.value = false;
      } else {
        isAllStoreFirstLoading.value = false;
      }
    }
  }

  /// GET NEAR-BY SERVICE BUSINESSES
  /// (other-service/business-profile/search)
  ///
  /// Drives the "Services near me" Discover screen. Sends the selected
  /// service category as `categoryOfBusiness` (the category tag id, e.g.
  /// `BEAUTY_FITNESS_PERSONAL_CARE`) and maps each business-profile result
  /// into [GetAllStoreResModel] so the existing store card can render it.
  /// Freshness-guarded variant of [getServiceBusinessesNearBy] for screen entry.
  /// Same three-tier (memory → disk → network) strategy as
  /// [getAllStoreNearByIfNeeded], keyed by the service identity.
  Future<void> getServiceBusinessesNearByIfNeeded() async {
    if (_movedFarFromLastFetch()) _allStoreCache.invalidate();

    if (_allStoreCache.isFresh(_serviceIdentity, hasData: allStore.isNotEmpty)) {
      return;
    }

    final entry = HiveServices()
        .getGeoList(boxName: HiveServices.nearByStoreBox, key: _serviceIdentity);
    if (entry != null && entry.items.isNotEmpty) {
      final cachedStores = _decodeStores(entry.items);
      if (cachedStores.isNotEmpty) {
        allStore.assignAll(cachedStores);
        getAllStoreResponse.value = ApiResponse.complete();
        _lastStoreFetchLat = entry.lat;
        _lastStoreFetchLng = entry.lng;
        allStorePage = 2;
        allStoreHasMore = true;
        _allStoreCache.mark(_serviceIdentity);

        final tooOld = DateTime.now().difference(entry.savedAt) > _persistTtl;
        final movedFar =
            LocationService.metersFromCurrent(entry.lat, entry.lng) >
                _moveInvalidationMeters;
        if (tooOld || movedFar) {
          unawaited(getServiceBusinessesNearBy(silentRefresh: true));
        }
        return;
      }
    }

    await getServiceBusinessesNearBy();
  }

  Future<void> getServiceBusinessesNearBy(
      {bool isLoadMore = false, bool silentRefresh = false}) async {
    if (isLoadMore) {
      if (isAllStoreLoadingMore.value || !allStoreHasMore) return;
      isAllStoreLoadingMore.value = true;
    } else {
      allStorePage = 1;
      allStoreHasMore = true;
      if (!silentRefresh) {
        isAllStoreFirstLoading.value = true;
        allStore.clear();
      }
    }

    try {
      final Map<String, dynamic> queryParams = {
        'distance': kmRadius5000,
        ApiKeys.limit: 10,
        ApiKeys.page: allStorePage,
      };
      if (businessCategoryId != null) {
        queryParams['categoryOfBusiness'] = businessCategoryId;
      }

      final response = await StoreRepo()
          .searchServiceBusinessProfiles(queryParams: queryParams);

      if (response.isSuccess) {
        getAllStoreResponse.value = ApiResponse.complete(response);

        final responseData = response.response?.data;
        List rawList = [];
        if (responseData is Map && responseData['data'] is List) {
          rawList = responseData['data'] as List;
        } else if (responseData is List) {
          rawList = responseData;
        }

        // Dedupe against what's already loaded so a non-paginated response
        // (or a repeated page) can't append the same profiles twice. On a
        // page-1 fetch we REPLACE the list, so don't dedupe against it —
        // otherwise a silent refresh (cached list still on screen) would
        // filter every fresh result out and never update.
        final existingIds =
            isLoadMore ? allStore.map((s) => s.id).toSet() : <String?>{};
        final newStores = rawList
            .whereType<Map>()
            .map((e) =>
                _businessProfileToStore(Map<String, dynamic>.from(e)))
            .where((s) => s.id == null || !existingIds.contains(s.id))
            .toList();

        log("Loaded ${newStores.length} service businesses");

        if (newStores.isNotEmpty) {
          if (isLoadMore) {
            allStore.addAll(newStores);
          } else {
            allStore.assignAll(newStores);
            // Shared list — stamp with the service identity so a store screen
            // re-entry can tell these aren't its results, and persist page 1.
            _lastStoreFetchLat = LocationService.lat;
            _lastStoreFetchLng = LocationService.lng;
            _allStoreCache.mark(_serviceIdentity);
            unawaited(HiveServices().saveGeoList(
              boxName: HiveServices.nearByStoreBox,
              key: _serviceIdentity,
              jsonList: newStores.map((e) => e.toJson()).toList(),
              lat: LocationService.lat,
              lng: LocationService.lng,
            ));
          }
          allStorePage++;
        } else {
          allStoreHasMore = false;
        }
      } else {
        getAllStoreResponse.value = ApiResponse.error('error');
        log("API failed with status: ${response.statusCode}");
      }
    } catch (e, s) {
      log("Error: $s");
      getAllStoreResponse.value = ApiResponse.error('error');
    } finally {
      if (isLoadMore) {
        isAllStoreLoadingMore.value = false;
      } else {
        isAllStoreFirstLoading.value = false;
      }
    }
  }

  /// Maps a single `business-profile/search` item into the store model the
  /// list card consumes. The search API uses camelCase keys and a GeoJSON
  /// `[lng, lat]` coordinate pair, unlike the snake_case store endpoint.
  GetAllStoreResModel _businessProfileToStore(Map<String, dynamic> json) {
    final profile =
        json['profile'] is Map ? Map<String, dynamic>.from(json['profile']) : null;
    dynamic field(String key) => json[key] ?? profile?[key];

    num? lat;
    num? lon;
    String? address;

    // GeoJSON helper: coords are [lng, lat].
    void readGeoJson(dynamic locMap) {
      if (locMap is! Map) return;
      address ??= (locMap['address']?.toString().trim().isNotEmpty ?? false)
          ? locMap['address'].toString()
          : locMap['name']?.toString();
      final coords = locMap['coordinates'];
      if (coords is List && coords.length >= 2) {
        lon ??= coords[0] is num ? coords[0] as num : null;
        lat ??= coords[1] is num ? coords[1] as num : null;
      }
    }

    // 1. Top-level `location` (search API shape).
    readGeoJson(field('location'));

    // 2. Fall back to the first `contactUs[].branch.location` — service
    //    profiles often only carry coordinates on a branch, not at the
    //    profile root.
    if (lat == null || lon == null || (address?.isEmpty ?? true)) {
      final contactUs = field('contactUs');
      if (contactUs is List) {
        for (final c in contactUs) {
          if (c is! Map) continue;
          final branch = c['branch'];
          if (branch is Map) {
            readGeoJson(branch['location']);
          }
          if (lat != null && lon != null && (address?.isNotEmpty ?? false)) {
            break;
          }
        }
      }
    }

    final livePhotos = <String>[];
    final cover = field('coverUrl')?.toString().trim();
    if (cover != null && cover.isNotEmpty) livePhotos.add(cover);
    final gallery = field('gallery');
    if (gallery is List) {
      for (final g in gallery) {
        final urls = g is Map ? g['imageUrls'] : null;
        if (urls is List) {
          livePhotos.addAll(
            urls.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
          );
        }
      }
    }

    final category = field('category')?.toString();
    final type = field('type')?.toString();

    // Re-shape into the snake_case map [GetAllStoreResModel.fromJson] expects
    // so the existing parser builds the model (and avoids referencing the
    // `BusinessLocation` type, whose name is ambiguous in this file).
    return GetAllStoreResModel.fromJson({
      'id': field('_id')?.toString(),
      'user_id': field('userId')?.toString(),
      'business_name': field('profileName')?.toString(),
      'business_description': field('description')?.toString(),
      'logo': field('logoUrl')?.toString().trim(),
      'live_photos': livePhotos,
      'address': address,
      'business_location':
          (lat != null || lon != null) ? {'lat': lat, 'lon': lon} : null,
      'Nature_of_Business': category ?? type,
      'created_at': field('createdAt')?.toString(),
    });
  }

  /// Freshness-guarded variant of [getAllProductNearBy] for screen entry.
  Future<void> getAllProductNearByIfNeeded({
    ProviderType? providerType,
    String? productCategory,
    String? query,
  }) async {
    final signature = _productSignature(
      providerType: providerType,
      productCategory: productCategory,
      query: query,
    );
    if (_productCache.isFresh(signature, hasData: productDataList.isNotEmpty)) {
      return;
    }
    await getAllProductNearBy(
      providerType: providerType,
      productCategory: productCategory,
      query: query,
    );
  }

  ///GET STORE PRODUCT ONLY....
  Future<void> getAllProductNearBy({
    ProviderType? providerType,
    String? productCategory,
    bool isLoadMore = false,
    String? query}
      ) async {
    if (isLoadMore) {
      if (isProductDataLoadingMore.value || !productDataHasMore) return;
      isProductDataLoadingMore.value = true;
    } else {
      isProductDataFirstLoading.value = true;
      productDataPage = 1;
      productDataHasMore = true;
      productDataList.clear();

      // /// fetch local data not for search
      // if(query == null){
      //   final cachedProduct = await HiveServices().getAllStoreProduct(userId);
      //   if (cachedProduct != null && cachedProduct.isNotEmpty) {
      //     productDataList.assignAll(cachedProduct);
      //     isProductDataFirstLoading.value = false;
      //   }
      // }
    }

    try {
      log('lat--> ${LocationService.lat}, lng--> ${LocationService.lng}');

      const int limit = 20;

      // Build query parameters dynamically
      final Map<String, dynamic> queryParams = {
        ApiKeys.page: productDataPage,
        ApiKeys.limit: limit,
        ApiKeys.maxDistance: kmRadius1000,
      };
      double lat =  LocationService.lat != 0.0 ? LocationService.lat : 0.0;
      double long = LocationService.lng != 0.0 ? LocationService.lng : 0.0;

      if ((lat!=0.0) && (long!=0.0)) {
        queryParams[ApiKeys.latitude] = lat;
        queryParams[ApiKeys.longitude] = long;
      }
      if(providerType!=null) queryParams[ApiKeys.ownerType] = providerType.title;
      if(productCategory!=null) queryParams[ApiKeys.key] = productCategory;

      final response;
      if(query != null){
        response = await StoreRepo().productSearchFilterRepo(
            queryParams: queryParams
        );
      }else{
        if(productCategory!=null){
          response = await StoreRepo().productFilterRepo(
              queryParams: queryParams
          );
        }
        else{
          response = await StoreRepo().homePageProductRepo(
              queryParams: queryParams
          );
        }

      }

      if (response.isSuccess) {
        getAllStoreProductResponse.value = ApiResponse.complete(response);
        final getOwnProductModel =
        GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData = getOwnProductModel.data;

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            productDataList.addAll(newData);
          } else {
            productDataList.assignAll(newData);
            _productCache.mark(_productSignature(
              providerType: providerType,
              productCategory: productCategory,
              query: query,
            ));
            log('product data length--> ${productDataList.length}');
            log('loggggg 1--> ${productDataList[0].product.business_name}');

            if(query == null) {
              await HiveServices().saveAllStoreProduct(
                  productDataList, userId);
            }
          }
          productDataPage++;
        }
      } else {
        productDataHasMore = false;
        getAllStoreProductResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getAllStoreProductResponse.value = ApiResponse.error('error');
    } finally{
      if (isLoadMore) {
        isProductDataLoadingMore.value = false;
      } else {
        isProductDataFirstLoading.value = false;
      }
    }
  }

  RxBool aiInventoryLoading = false.obs;

  /// Ask Ai Inventory
  Future<void> askAiInventory({required String message}) async {

    try {
      aiInventoryLoading.value = true;
      final response = await StoreRepo().askAiInventoryRepo(
        params: {
          ApiKeys.query: message
        },
      );

      if (response.isSuccess) {
        getListOfAiMessageResponse.value = ApiResponse.complete(response);
        // final getOwnProductModel =
        // GetProductModel.fromJson(response.response?.data);
        //
        // final List<GetProductData> newData = getOwnProductModel.data;
        //
        // if (newData.isNotEmpty) {
        //   if (isLoadMore) {
        //     storeProductDataList.addAll(newData);
        //   } else {
        //     storeProductDataList.assignAll(newData);
        //     log('product data length--> ${storeProductDataList.length}');
        //     log('loggggg 1--> ${storeProductDataList[0].product.business_name}');
        //
        //     if(query == null) {
        //       await HiveServices().saveAllStoreProduct(
        //           storeProductDataList, userId);
        //     }
        //   }
        //   storeProductDataPage++;
        // }
      } else {
        productDataHasMore = false;
        getListOfAiMessageResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getListOfAiMessageResponse.value = ApiResponse.error('error');
    } finally{
      aiInventoryLoading.value = false;
    }
  }

  /// FOLLOW BUSINESS USER
  Future<void> followBusinessUser({
    required String? businessId,
    required GetAllStoreResModel store,
  }) async {
    try {
      followResponse.value = ApiResponse.initial('Initial');

      final responseModel =
      await UserRepo().followUser(followUserId: businessId);

      if (responseModel.isSuccess) {
        followResponse.value = ApiResponse.complete(responseModel);

        /// Update store locally
        final updatedStore = store.copyWith(
          isFollowed: true,
          followerCount:
          ((int.tryParse(store.followerCount ?? '0') ?? 0) + 1).toString(),
        );

        /// Update both lists
        _updateStoreInLists(updatedStore);
      } else {
        followResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      followResponse.value = ApiResponse.error('error');
    }
  }

  /// UNFOLLOW BUSINESS USER
  Future<void> unFollowBusinessUser({
    required String? businessId,
    required GetAllStoreResModel store,
  }) async {
    try {
      unFollowResponse.value = ApiResponse.initial('Initial');

      final responseModel =
      await UserRepo().unfollowUser(followUserId: businessId);

      if (responseModel.isSuccess) {
        unFollowResponse.value = ApiResponse.complete(responseModel);

        /// Update store locally
        final updatedStore = store.copyWith(
          isFollowed: false,
          followerCount: ((int.tryParse(store.followerCount ?? '0') ?? 0) - 1).toString(),
        );

        /// Update both lists
        _updateStoreInLists(updatedStore);
      } else {
        unFollowResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      unFollowResponse.value = ApiResponse.error('error');
    }
  }

  void _updateStoreInLists(GetAllStoreResModel updatedStore) {
    /// 1️⃣ Update in allStore list
    final index1 = allStore.indexWhere((s) => s.id == updatedStore.id);
    if (index1 != -1) {
      allStore[index1] = updatedStore;
    }

    allStore.refresh();

  }

  void updateStoreRatings(String businessId) {
    ///  Update inside allStore list
    final index1 = allStore.indexWhere((s) => s.id == businessId);
    if (index1 != -1) {
      final store = allStore[index1];
      allStore[index1] = store.copyWith(
        totalRatings: (int.parse(store.totalRatings ?? "0") + 1).toString(),
      );
    }

    /// Refresh reactive lists
    allStore.refresh();

    log('Store rating count updated for businessId: $businessId');
  }

}

/// Counts for [store] in the catalogue the current screen is listing, or null
/// while they are still unknown.
///
/// A free function so every store card reads them the same way without each one
/// repeating the registered check: these cards are also built on screens that
/// never put a [StoreController], where a bare `Get.find` would throw rather
/// than simply show no numbers yet.
///
/// Read inside an `Obx` — [StoreController.storeCounts] is observable, so the
/// two figures fill themselves in when the counts call lands.
StoreCountsModel? storeCountsFor(GetAllStoreResModel store) {
  if (!Get.isRegistered<StoreController>()) return null;
  return Get.find<StoreController>()
      .countsFor(businessId: store.id, userId: store.userId);
}
