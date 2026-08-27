import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_product_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/food/service/food_local_store.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:get/get.dart';

/// What a read of the saved Products-tab snapshot produced.
///
/// [homeOnly] is a real outcome rather than a failure: the menu restored but
/// the Offer Dish rail had no entry of its own, so only that one call is made.
enum _FoodCacheHit { miss, homeOnly, both }

class RestaurantController extends GetxController {
  bool foodDataNeedsRefresh = false;

  Rx<ApiResponse> foodHomeDataResponse = ApiResponse.initial('Initial').obs;

  // Observables
  var isLoading = true.obs;
  var restaurantData = Rxn<FoodData>();
  var foodMenuNestedCategory = <GroceryNestedCategoryModel>[].obs;
  var allFoodItems = <Items>[].obs;
  var restaurantSpecials = <RestaurantSpecial>[].obs;

  /// ─── Discount Products (paginated) ───
  /// Dedicated list for the "Offer Dish (Discount)" horizontal section.
  /// Fed by the `food-service/api/discountProducts` endpoint and paginated
  /// independently of the home API.
  RxList<CategoryFoodProductData> discountFoodItems =
      <CategoryFoodProductData>[].obs;
  RxBool isDiscountProductsLoading = false.obs;
  RxBool isDiscountProductsLoadingMore = false.obs;
  int _discountProductsPage = 1;
  bool _discountProductsHasMore = true;
  static const int _discountProductsLimit = 20;

  bool get discountProductsHasMore => _discountProductsHasMore;

  /// Freshness guard for the store's home data, keyed per business so a
  /// re-entry for the same restaurant skips the network call.
  final FetchCache _homeCache = FetchCache();

  /// Load home + discount data only when it isn't already loaded & fresh for
  /// this [businessId]. Use on screen (re)entry; call [fetchHomeData] /
  /// [fetchDiscountFoodProducts] directly for explicit refreshes.
  /// AWAITS both fetches. Callers that only want them fired (the tab
  /// dispatcher) simply don't await this — but the ones that need to READ the
  /// result afterwards (the go-live catalogue gate, the app-open kickstart)
  /// cannot work unless awaiting this actually means the data has landed. It
  /// used to fire both and return immediately, so those callers always saw an
  /// unresolved response and treated an empty menu as "not loaded".
  ///
  /// Three layers, cheapest first:
  /// 1. [_homeCache] — same restaurant, fetched < 5 min ago, still in memory.
  /// 2. [FoodLocalStore] — the saved snapshot. **If there is one, that is the
  ///    answer and no request is made.**
  /// 3. The network — only when nothing is saved.
  ///
  /// The snapshot is not a head start on a request; it replaces the request.
  /// What keeps it honest is that every write the merchant makes (publish,
  /// price edit, delete, stock toggle, branch details) runs [markMenuChanged],
  /// which refetches and rewrites it — so the only way to be looking at a stale
  /// menu is for it to have changed somewhere other than this device, and
  /// pull-to-refresh on the tab is the escape hatch for that.
  Future<void> fetchHomeAndDiscountIfNeeded({required String businessId}) async {
    final signature = 'foodHome|$businessId';
    if (_homeCache.isFresh(signature, hasData: restaurantData.value != null)) {
      return;
    }

    switch (await _hydrateFoodDataFromCache(businessId)) {
      case _FoodCacheHit.both:
        // Stamped so a tab switch doesn't go back to disk either.
        _homeCache.mark(signature);
        return;
      case _FoodCacheHit.homeOnly:
        // The menu came off disk; only the rail that had no snapshot of its own
        // is fetched. A restaurant with no discounted dish never writes that
        // entry (an empty list is stored as a deletion — "the server had
        // nothing" is re-asked, never pinned), so requiring BOTH sides before
        // hydrating would mean such a restaurant never used the cache at all.
        // Stamped only if that fetch actually landed. Stamping regardless left
        // the offer rail empty for the whole TTL after a dropped request, with
        // every re-entry taking the early return and never retrying it.
        if (await fetchDiscountFoodProducts(businessId: businessId)) {
          _homeCache.mark(signature);
        }
        return;
      case _FoodCacheHit.miss:
        break;
    }

    await Future.wait([
      fetchHomeData(businessId: businessId),
      fetchDiscountFoodProducts(businessId: businessId),
    ]);
  }

  /// Paints the Products tab from the last saved snapshot.
  ///
  /// Deliberately tolerant: a snapshot that fails to parse (a model changed
  /// shape since it was written) counts as a miss, so a bad cache degrades into
  /// a normal fetch rather than an error the user sees.
  ///
  /// Nothing is published unless the HOME payload restores — it is what the
  /// tab's "has the menu loaded?" state is read from, and half a snapshot with
  /// no request coming would leave the screen empty for good.
  Future<_FoodCacheHit> _hydrateFoodDataFromCache(String id) async {
    // Owner scope only. A customer browsing someone else's restaurant has no
    // way to invalidate a snapshot — they can't publish, edit or restock
    // anything — so a cache-first read with no revalidation would freeze that
    // menu on their device indefinitely. Their fetches stay live (in-memory
    // guard only), exactly as before.
    if (!_isOwner(id)) return _FoodCacheHit.miss;

    FoodData? home;
    try {
      final entry = await FoodLocalStore.readHome(id);
      final data = entry?.map;
      if (data != null && data.isNotEmpty) home = FoodData.fromJson(data);
    } catch (e) {
      log('food: home cache hydrate failed — $e');
    }
    if (home == null) return _FoodCacheHit.miss;

    restaurantData.value = home;
    foodMenuNestedCategory.value = home.foodMenu ?? [];
    restaurantSpecials.value = home.restaurantSpecials ?? [];
    foodHomeDataResponse.value = ApiResponse.complete();

    List<CategoryFoodProductData>? discount;
    try {
      final entry = await FoodLocalStore.readDiscount(id);
      if (entry != null && !entry.isEmpty) {
        discount = _mapDiscountRows(entry.items);
      }
    } catch (e) {
      log('food: discount cache hydrate failed — $e');
    }
    if (discount == null || discount.isEmpty) return _FoodCacheHit.homeOnly;

    discountFoodItems.assignAll(discount);
    // The snapshot only ever holds page 1, so "load more" resumes at page 2 —
    // and a short page means the server had nothing after it.
    _discountProductsPage = 2;
    _discountProductsHasMore = discount.length >= _discountProductsLimit;
    return _FoodCacheHit.both;
  }

  /// True when [id] is the logged-in merchant's own restaurant — the only
  /// scope that is cached to disk. See [_hydrateFoodDataFromCache].
  bool _isOwner(String id) => id.isNotEmpty && id == businessId;

  /// Called after any write the merchant just made — publishing dishes, a
  /// variant price edit, a delete, a stock toggle, new branch details.
  ///
  /// The screens already patch their own models in place, so what this fixes is
  /// everything the patch cannot reach: the 5-minute freshness guard that would
  /// otherwise short-circuit the next tab entry, the sibling rail that still
  /// holds the old row, and the disk snapshot, which must never outlive the
  /// change that invalidated it.
  ///
  /// The server is the source of truth for the rewrite: rather than editing the
  /// cached JSON — which would mean re-implementing every mutation against a
  /// second data shape — the snapshot is **deleted** and then rebuilt from a
  /// refetch.
  ///
  /// Deleting first, rather than overwriting when the refetch lands, is what
  /// makes the race safe. The merchant can leave the add-food flow and be back
  /// on the tab before the refetch resolves; with the old snapshot still on
  /// disk, that re-entry would hydrate the pre-mutation menu and stamp it
  /// fresh, hiding the change until the guard expired. With it gone the worst
  /// case is one extra request, and stale is not reachable.
  void markMenuChanged({String? storeId}) {
    foodDataNeedsRefresh = true;
    _homeCache.invalidate();
    foodMenuNestedCategory.refresh();
    discountFoodItems.refresh();

    final id = (storeId == null || storeId.isEmpty) ? businessId : storeId;
    if (id.isEmpty) return;
    // Fire-and-forget: the caller is a sheet closing on a completed write, or a
    // publish screen popping back, and nothing on screen is waiting for this.
    unawaited(FoodLocalStore.clearStore(id).then((_) async {
      await Future.wait([
        fetchHomeData(businessId: id, silent: true),
        fetchDiscountFoodProducts(businessId: id, silent: true),
      ]);
    }));
  }

  /// Returns a Future so callers CAN await the menu; existing call sites that
  /// fire and forget are unaffected.
  ///
  /// [silent] keeps the currently rendered menu on screen while the call runs —
  /// used when the tab was hydrated from disk, or is being refreshed after a
  /// write, so the content never flashes back to a skeleton it has already
  /// moved past.
  Future<void> fetchHomeData({
    required String businessId,
    bool silent = false,
  }) async {
    try {
      if (!silent) foodHomeDataResponse.value = ApiResponse.initial('Initial');

      // call repo
      ResponseModel responseModel =
          await FoodRepo().getHomeFoodByIdRepo(businessProfile: businessId);

      if (responseModel.isSuccess) {
        final raw = responseModel.response?.data;
        restaurantData.value = FoodHomeResModel.fromJson(raw).data;
        foodMenuNestedCategory.value = restaurantData.value?.foodMenu ?? [];
        restaurantSpecials.value =
            restaurantData.value?.restaurantSpecials ?? [];

        foodHomeDataResponse.value = ApiResponse.complete(responseModel);
        _homeCache.mark('foodHome|$businessId');

        // Persist the raw payload, not the parsed model: the next open rebuilds
        // it with this same `fromJson`, so there is one parser to keep right.
        // Owner scope only — see [_hydrateFoodDataFromCache].
        if (_isOwner(businessId) && raw is Map && raw['data'] is Map) {
          unawaited(FoodLocalStore.writeHome(
            businessId,
            data: Map<String, dynamic>.from(raw['data'] as Map),
          ));
        }
      } else {
        // A failed SILENT refresh must not replace what the user is reading
        // with an error — the hydrated menu stays, and the guard was already
        // left un-stamped so the next entry retries. The exception is a status
        // that never resolved; see [_resolveHomeFailure].
        _resolveHomeFailure(silent: silent);

        if (!silent) {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e, s) {
      _resolveHomeFailure(silent: silent);
      log("Stack Trace===== $s");
    }
  }

  /// Records a failed home/menu fetch.
  ///
  /// A silent refresh normally leaves the status alone — that is the point of
  /// `silent`: keep the rendered menu and its COMPLETE state while the
  /// replacement is fetched, so the tab doesn't blink back to a skeleton it has
  /// already moved past. **But a status that has never resolved is not worth
  /// protecting.** [FoodProductsTab] derives `menuResolved` from this, and
  /// renders its loaders until it is COMPLETE or ERROR — so a silent failure
  /// over an unresolved status left the menu section shimmering with nothing
  /// scheduled to stop it.
  ///
  /// Reachable in practice: [markMenuChanged] refetches silently, and it runs
  /// on every publish / price edit / delete / stock toggle. A merchant whose
  /// very first load had not resolved yet when one of those fired — or whose
  /// snapshot was cleared by that same call — got the permanent shimmer. Same
  /// failure this controller's `_fetchProductsTab` counterpart already guards
  /// against for the empty-businessId path.
  void _resolveHomeFailure({required bool silent}) {
    final unresolved = foodHomeDataResponse.value.status == Status.INITIAL;
    if (!silent || unresolved) {
      foodHomeDataResponse.value = ApiResponse.error('error');
    }
  }

  /// Fetch paginated discount food products.
  ///
  /// Pass [isLoadMore] = true to append the next page. When called with
  /// [isLoadMore] = false (default) the list, page counter and
  /// `hasMore` flag are all reset first — use this for initial load /
  /// pull-to-refresh.
  ///
  /// [silent] keeps the rendered rail on screen while the call runs (hydrated
  /// from disk, or refreshed after a write) instead of blinking back to the
  /// loader — see [fetchHomeData].
  /// Returns whether the request SUCCEEDED — not whether it returned rows.
  /// An empty offer rail is a successful answer; a dropped connection is not,
  /// and only the caller that stamps a freshness guard needs to tell them
  /// apart. See the `homeOnly` branch of [fetchHomeAndDiscountIfNeeded].
  Future<bool> fetchDiscountFoodProducts({
    required String businessId,
    bool isLoadMore = false,
    bool silent = false,
  }) async {
    try {
      if (isLoadMore) {
        if (!_discountProductsHasMore ||
            isDiscountProductsLoadingMore.value ||
            isDiscountProductsLoading.value) {
          // Nothing was asked for, so nothing failed — a skipped load-more is
          // not a reason to refuse the caller's freshness stamp.
          return true;
        }
        isDiscountProductsLoadingMore.value = true;
      } else {
        // Paging always restarts, but a silent refresh keeps the rendered rows
        // until the replacements arrive — clearing here is what would make the
        // rail blink on every hydrate and after every write.
        _discountProductsPage = 1;
        _discountProductsHasMore = true;
        if (!silent) {
          isDiscountProductsLoading.value = true;
          discountFoodItems.clear();
        }
      }

      final Map<String, dynamic> queryParams = {
        ApiKeys.page: _discountProductsPage,
        ApiKeys.limit: _discountProductsLimit,
      };

      final ResponseModel response = await FoodRepo()
          .getDiscountFoodProductsRepo(
              businessId: businessId, queryParams: queryParams);

      if (response.isSuccess) {
        final data = response.response?.data;
        final List<dynamic> rawRows =
            (data is Map && data['data'] is List) ? data['data'] as List : const [];
        final List<CategoryFoodProductData> newItems = _mapDiscountRows(rawRows);

        if (newItems.isNotEmpty) {
          if (isLoadMore) {
            discountFoodItems.addAll(newItems);
          } else {
            discountFoodItems.assignAll(newItems);
          }
          _discountProductsPage++;
          // If the server returned fewer than the page size, we've reached
          // the end — no point asking for another page.
          if (newItems.length < _discountProductsLimit) {
            _discountProductsHasMore = false;
          }
        } else {
          _discountProductsHasMore = false;
          if (!isLoadMore && silent) {
            // A silent refresh kept the old rows on screen; the server now says
            // there are none, so drop them rather than leaving a rail of dishes
            // that no longer carry an offer.
            discountFoodItems.clear();
          }
        }

        // Page 1 only — that is exactly what the tab renders, and it keeps the
        // snapshot small however deep the user paged. Owner scope only — see
        // [_hydrateFoodDataFromCache].
        if (!isLoadMore && _isOwner(businessId)) {
          unawaited(FoodLocalStore.writeDiscount(businessId, items: rawRows));
        }
        return true;
      }
      if (!silent) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
      return false;
    } catch (e, s) {
      log('fetchDiscountFoodProducts error: $e\n$s');
      return false;
    } finally {
      if (isLoadMore) {
        isDiscountProductsLoadingMore.value = false;
      } else {
        isDiscountProductsLoading.value = false;
      }
    }
  }

  /// Rebuilds the Offer Dish rows from raw API JSON — the one parser for both
  /// a live response and the saved snapshot, so a cached rail can never drift
  /// from a fetched one.
  ///
  /// Same outer-`inventoryId` → variant copy used by the category listing flow.
  /// The discount API embeds the id at the variant level so the `??=` is
  /// usually a no-op here, but doing the propagation defensively keeps the two
  /// flows in sync.
  List<CategoryFoodProductData> _mapDiscountRows(List<dynamic> rawRows) {
    return rawRows
        .whereType<Map>()
        .map((row) => MyFoodProductData.fromJson(Map<String, dynamic>.from(row)))
        .where((item) => item.productDetails != null)
        .map((item) {
          final pd = item.productDetails!;
          final outerInv = item.inventoryId;
          if (outerInv != null && outerInv.isNotEmpty) {
            for (final v in pd.variants ?? const <FoodVariants>[]) {
              v.inventoryId ??= outerInv;
            }
          }
          return pd;
        })
        .toList();
  }

  // Validation state
  var isFormValid = false.obs;

  // Values to store from location picker
  double? selectedLat;
  double? selectedLng;

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) {
    // Basic validation logic
    bool isValid = branchName.isNotEmpty &&
        website.isURL &&
        address.isNotEmpty &&
        department.isNotEmpty &&
        email.isEmail &&
        phone.length >= 10;

    isFormValid.value = isValid;
  }

  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(message: AppStrings.foodSelectValidLocation.tr);
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "name": branchName,
        "pageLink": website,
        "department": department,
        "email": email,
        "phone": phone,
        "location": {
          "name": address,
          "type": "Point",
          "coordinates": [selectedLat, selectedLng]
        },
      };

      ResponseModel response =
          await FoodRepo().addFoodContactRepo(reqBody: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.foodBranchDetailsAdded.tr);
        Get.back();
        // Contact/branch details are part of the cached home payload, so this
        // goes through the invalidate hook rather than a bare refetch — the
        // snapshot on disk must not outlive the change.
        markMenuChanged();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
      print("Request Body: $body");
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
}
