import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/repo/vehicle_v3_repo.dart';
import 'package:get/get.dart';

/// Buyer-side state for the rebuilt vehicle service (v3).
///
/// Kept apart from [VehicleV3Controller] because the two ask the service
/// completely different questions: a seller reads `/inventory/my` (their own
/// rows, live or not), a buyer reads `/products/user/search` and
/// `/inventory/browse` (live rows near them, rolled up to trim cards). Sharing
/// one controller would mean one list meaning two things.
///
/// Discovery is location-scoped by contract — §6 requires **one of** pincode
/// or lat+lng+range on the buyer search — so every read here goes through
/// [_locationParams], and a missing location is surfaced as such rather than
/// silently returning nothing.
class VehicleBuyerControllerV3 extends GetxController {
  final VehicleV3Repo _repo = VehicleV3Repo();

  /// Default radius in km for the lat/lng form of the search.
  static const num defaultRangeKm = 25;

  /// Hive key for the level-0 strip. Level 1 is keyed per parent — see
  /// [fetchSubCategories].
  static const String _level0CacheKey = 'vehicleLevel0';

  // ───── Discovery ──────────────────────────────────────────────────

  /// Trim cards from `/products/user/search`, each carrying `listingCount`
  /// and `priceFrom` — the rollup the buyer browses, not raw listings.
  final RxList<VehicleTrimV3> trims = <VehicleTrimV3>[].obs;
  final Rx<Status> trimsStatus = Status.INITIAL.obs;
  final RxBool isLoadingMore = false.obs;

  /// The catalog tree pruned to branches that actually have stock — the
  /// category strip. A buyer should never be offered a filter that leads to
  /// an empty list.
  final RxList<VehicleCategoryV3> categories = <VehicleCategoryV3>[].obs;

  /// Null = every type. Otherwise a root category id.
  final RxnString selectedCategoryId = RxnString();

  /// Level-1 nodes — brands — under [selectedCategoryId], or the whole
  /// level-1 row when no type is picked. This is the second, smaller strip.
  final RxList<VehicleCategoryV3> subCategories = <VehicleCategoryV3>[].obs;

  /// Null = every brand under the selected type. Otherwise a level-1 id.
  final RxnString selectedSubCategoryId = RxnString();

  /// What the search actually filters on. `categoryId` resolves to the whole
  /// subtree, so the *deepest* selection wins: a brand narrows to that brand,
  /// and clearing it falls back to the type.
  String? get _effectiveCategoryId =>
      selectedSubCategoryId.value ?? selectedCategoryId.value;

  /// Null = both. Otherwise NEW / USED — this is what the Discover tile's
  /// new-vs-old split maps onto.
  final RxnString conditionFilter = RxnString();

  /// True when neither a pincode nor coordinates are available, so the
  /// screen can prompt for location instead of showing "no results".
  final RxBool locationMissing = false.obs;

  VehiclePaginationV3 _trimsPage = const VehiclePaginationV3();
  final FetchCache _trimsCache = FetchCache();

  String get _signature =>
      'vehicleBuyer|${_effectiveCategoryId}|${conditionFilter.value}|'
      '${LocationService.lat.toStringAsFixed(2)}|'
      '${LocationService.lng.toStringAsFixed(2)}';

  // ───── Listings for one trim ──────────────────────────────────────

  final RxList<VehicleListingV3> trimListings = <VehicleListingV3>[].obs;
  final Rx<Status> trimListingsStatus = Status.INITIAL.obs;

  // ───── Reads ──────────────────────────────────────────────────────

  Future<void> loadDiscoverIfNeeded() async {
    if (_trimsCache.isFresh(_signature, hasData: trims.isNotEmpty)) return;
    await loadDiscover();
  }

  /// [force] bypasses the category cache — pull-to-refresh means "go ask the
  /// server", so it must not be answered out of Hive.
  Future<void> loadDiscover({bool force = false}) async {
    await Future.wait([
      fetchTrims(),
      fetchCategories(force: force),
      fetchSubCategories(force: force),
    ]);
  }

  /// The main buyer search. Rolls live listings up to trim cards.
  Future<void> fetchTrims() async {
    final location = _locationParams();
    if (location == null) {
      // Without pincode or lat/lng the endpoint 400s, so don't spend the call.
      locationMissing.value = true;
      trimsStatus.value = Status.COMPLETE;
      trims.clear();
      return;
    }
    locationMissing.value = false;
    trimsStatus.value = Status.LOADING;
    try {
      final res = await _searchTrims(page: 1, location: location);
      if (!res.isSuccess) {
        trimsStatus.value = Status.ERROR;
        return;
      }
      final body = res.response?.data;
      trims.assignAll(VehicleTrimV3.listFrom(body));
      _trimsPage = VehiclePaginationV3.of(body);
      trimsStatus.value = Status.COMPLETE;
      _trimsCache.mark(_signature);
    } catch (e) {
      logs('VEHICLE_V3_BUYER: fetchTrims failed — $e');
      trimsStatus.value = Status.ERROR;
    }
  }

  Future<void> loadMoreTrims() async {
    if (isLoadingMore.value || !_trimsPage.hasMore) return;
    final location = _locationParams();
    if (location == null) return;
    isLoadingMore.value = true;
    try {
      final res =
          await _searchTrims(page: _trimsPage.page + 1, location: location);
      if (!res.isSuccess) return;
      final body = res.response?.data;
      trims.addAll(VehicleTrimV3.listFrom(body));
      _trimsPage = VehiclePaginationV3.of(body);
    } catch (e) {
      logs('VEHICLE_V3_BUYER: loadMoreTrims failed — $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// `/products/user/search` with the current filters folded in.
  Future<ResponseModel> _searchTrims({
    required int page,
    required Map<String, dynamic> location,
  }) {
    return _repo.searchBuyerTrims(
      categoryId: _effectiveCategoryId,
      condition: conditionFilter.value,
      page: page,
      location: location,
    );
  }

  /// The category strip: the vehicle catalog's own level-0 categories —
  /// `GET vehicle-service/categories?level=0`, the SAME read the seller's add
  /// flow makes for its rails and "More" drill-down
  /// ([VehicleV3Controller.fetchRootCategories]).
  ///
  /// One catalog for both sides is the point. These ids are what a listing is
  /// actually filed under, so they are the ids `/products/user/search` filters
  /// on — a tab here narrows the results instead of matching nothing.
  ///
  /// Two earlier sources were wrong for this strip and are worth naming so
  /// neither comes back:
  ///
  ///  * `/categories/nested/with-inventory` — right ids, but pruned to
  ///    branches holding stock, so a buyer with little nearby inventory got a
  ///    strip containing nothing but "All".
  ///  * `automotive-service/api/categories/nested` — a DIFFERENT service's
  ///    catalog. That is the right source for the auto-parts discover screen,
  ///    which sells automotive-service products; vehicles for sale live in the
  ///    vehicle service, and its ids mean nothing to this search.
  /// Hive-first, per [HiveServices.categoryCacheTtl]: a warm cache paints the
  /// strip and the endpoint is not called at all. The catalog is the same for
  /// every buyer and changes on the order of weeks, so re-reading it on every
  /// screen open was a call that could never return anything new.
  Future<void> fetchCategories({bool force = false}) async {
    const key = _level0CacheKey;
    final cached = HiveServices().getVehicleCategoriesRaw(key);
    if (cached != null && cached.isNotEmpty) {
      categories.assignAll(VehicleCategoryV3.listFrom(cached));
      if (!force && HiveServices().isVehicleCategoriesFresh(key)) return;
    }
    try {
      final res = await _repo.getCategories(level: 0);
      if (!res.isSuccess) return;
      final raw = VehicleV3Envelope.list(res.response?.data);
      // An empty response must not evict a good cache — treat it as "nothing
      // new", not as "the catalog is now empty".
      if (raw.isEmpty) return;
      await HiveServices().saveVehicleCategoriesRaw(key, raw);
      categories.assignAll(VehicleCategoryV3.listFrom(raw));
    } catch (e) {
      logs('VEHICLE_V3_BUYER: fetchCategories failed — $e');
    }
  }

  /// The second strip: level-1 of the same catalog — brands.
  ///
  /// Scoped to the selected type when there is one (`parentId`), otherwise the
  /// flat level-1 row across every type, which is what "All …" should offer.
  /// These ids are ordinary category ids, so selecting one just narrows
  /// `/products/user/search` a level deeper — see [_effectiveCategoryId].
  /// Cached per parent, so switching back to a type already visited this week
  /// paints its brands with no call — same discipline as [fetchCategories].
  Future<void> fetchSubCategories({bool force = false}) async {
    final key = 'vehicleLevel1_${selectedCategoryId.value ?? 'all'}';
    final cached = HiveServices().getVehicleCategoriesRaw(key);
    if (cached != null && cached.isNotEmpty) {
      subCategories.assignAll(VehicleCategoryV3.listFrom(cached));
      _dropStaleSubCategorySelection();
      if (!force && HiveServices().isVehicleCategoriesFresh(key)) return;
    }
    try {
      final res = await _repo.getCategories(
        level: 1,
        parentId: selectedCategoryId.value,
      );
      if (!res.isSuccess) return;
      final raw = VehicleV3Envelope.list(res.response?.data);
      // A type with no brands is a real answer here (unlike level 0), so an
      // empty list is applied — but only the cache write is skipped, to avoid
      // storing an empty strip that would then be served for a whole TTL.
      subCategories.assignAll(VehicleCategoryV3.listFrom(raw));
      if (raw.isNotEmpty) {
        await HiveServices().saveVehicleCategoriesRaw(key, raw);
      }
      _dropStaleSubCategorySelection();
    } catch (e) {
      logs('VEHICLE_V3_BUYER: fetchSubCategories failed — $e');
    }
  }

  /// A brand that is no longer in the strip must not keep filtering the
  /// search — it would be an invisible filter the buyer can't clear.
  void _dropStaleSubCategorySelection() {
    if (selectedSubCategoryId.value != null &&
        !subCategories.any((c) => c.id == selectedSubCategoryId.value)) {
      selectedSubCategoryId.value = null;
    }
  }

  /// Every live listing for one trim, newest filter state applied.
  Future<void> fetchListingsForTrim(String productId) async {
    trimListingsStatus.value = Status.LOADING;
    try {
      final location = _locationParams() ?? const {};
      final res = await _repo.browseListings(
        productId: productId,
        condition: conditionFilter.value,
        pincode: location['pincode'] as String?,
        lat: location['lat'] as double?,
        lng: location['lng'] as double?,
        range: location['range'] as num?,
      );
      if (!res.isSuccess) {
        trimListingsStatus.value = Status.ERROR;
        return;
      }
      trimListings.assignAll(VehicleListingV3.listFrom(res.response?.data));
      trimListingsStatus.value = Status.COMPLETE;
    } catch (e) {
      logs('VEHICLE_V3_BUYER: fetchListingsForTrim failed — $e');
      trimListingsStatus.value = Status.ERROR;
    }
  }

  /// One listing, fully enriched. Null on failure.
  Future<VehicleListingV3?> fetchListing(String id) async {
    try {
      final res = await _repo.getListing(id);
      if (!res.isSuccess) return null;
      final json = VehicleV3Envelope.object(res.response?.data);
      return json == null ? null : VehicleListingV3.fromJson(json);
    } catch (e) {
      logs('VEHICLE_V3_BUYER: fetchListing failed — $e');
      return null;
    }
  }

  // ───── Filters ────────────────────────────────────────────────────

  /// Picking a type resets the brand — the old brand belongs to the old type's
  /// subtree, so keeping it would search a branch the buyer just left.
  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId.value = categoryId;
    selectedSubCategoryId.value = null;
    await Future.wait([fetchSubCategories(), fetchTrims()]);
  }

  Future<void> selectSubCategory(String? subCategoryId) async {
    selectedSubCategoryId.value = subCategoryId;
    await fetchTrims();
  }

  Future<void> selectCondition(String? condition) async {
    conditionFilter.value = condition;
    await fetchTrims();
  }

  // ───── Enquiry ────────────────────────────────────────────────────

  /// Sends an enquiry and reports the outcome.
  ///
  /// The three documented failures are all *expected* states rather than
  /// errors, so each gets its own message: 404 the listing went away, 400 it
  /// is your own listing, 409 you already have an open request on it.
  Future<bool> sendEnquiry({
    required String inventoryId,
    required String intent,
    num? offerPrice,
    String? note,
  }) async {
    try {
      final res = await _repo.createEnquiry(
        inventoryId: inventoryId,
        intent: intent,
        offerPrice: offerPrice,
        note: note,
      );
      if (res.isSuccess) {
        commonSnackBar(
            message: 'Enquiry sent. The seller can now chat with you.');
        return true;
      }
      final code = res.response?.statusCode ?? res.statusCode ?? 0;
      final serverMessage = VehicleV3Envelope.errorMessage(res.response?.data);
      switch (code) {
        case 404:
          commonSnackBar(message: 'This vehicle is no longer available.');
          break;
        case 400:
          commonSnackBar(
              message: serverMessage ??
                  'You cannot send an enquiry on your own listing.');
          break;
        case 409:
          commonSnackBar(
              message: 'You already have an open enquiry on this vehicle.');
          break;
        default:
          commonSnackBar(
              message: serverMessage ?? 'Could not send the enquiry.');
      }
      return false;
    } catch (e) {
      logs('VEHICLE_V3_BUYER: sendEnquiry failed — $e');
      commonSnackBar(message: 'Could not send the enquiry.');
      return false;
    }
  }

  // ───── Location ───────────────────────────────────────────────────

  /// Coordinates when we have them, else the resolved pincode, else null.
  /// Coordinates are preferred because they give the server a real radius to
  /// rank by; a pincode is an exact-match fallback.
  Map<String, dynamic>? _locationParams() {
    if (LocationService.hasUsableLocation) {
      return {
        'lat': LocationService.lat,
        'lng': LocationService.lng,
        'range': defaultRangeKm,
      };
    }
    final pincode = LocationService.userCurrentAddress.value.postalCode.trim();
    if (pincode.isNotEmpty) return {'pincode': pincode};
    return null;
  }
}
