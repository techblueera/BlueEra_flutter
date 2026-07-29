import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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

  /// Null = both. Otherwise NEW / USED — this is what the Discover tile's
  /// new-vs-old split maps onto.
  final RxnString conditionFilter = RxnString();

  /// True when neither a pincode nor coordinates are available, so the
  /// screen can prompt for location instead of showing "no results".
  final RxBool locationMissing = false.obs;

  VehiclePaginationV3 _trimsPage = const VehiclePaginationV3();
  final FetchCache _trimsCache = FetchCache();

  String get _signature =>
      'vehicleBuyer|${selectedCategoryId.value}|${conditionFilter.value}|'
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

  Future<void> loadDiscover() async {
    await Future.wait([fetchTrims(), fetchCategories()]);
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
      categoryId: selectedCategoryId.value,
      condition: conditionFilter.value,
      page: page,
      location: location,
    );
  }

  /// The category strip — only branches with live stock.
  Future<void> fetchCategories() async {
    try {
      final res = await _repo.getNestedCategoriesWithInventory();
      if (!res.isSuccess) return;
      categories.assignAll(VehicleCategoryV3.listFrom(res.response?.data));
    } catch (e) {
      logs('VEHICLE_V3_BUYER: fetchCategories failed — $e');
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

  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId.value = categoryId;
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
