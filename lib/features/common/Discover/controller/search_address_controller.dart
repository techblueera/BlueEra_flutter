import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/features/common/Discover/model/favorite_location_model.dart';
import 'package:BlueEra/features/common/Discover/repo/favorite_location_repo.dart';
import 'package:BlueEra/features/common/Discover/service/favourite_location_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backs the "Pickup from / Drop at" search (SearchAddressScreen): place
/// autocomplete, the saved favourites and the recent searches kept on device.
///
/// Scoped to that screen's route by SearchAddressBinding. The screen keeps the
/// text field, navigation and snackbars.
class SearchAddressController extends GetxController {
  SearchAddressController({
    PlaceRepo? placeRepo,
    FavoriteLocationRepo? favoriteRepo,
  })  : _placeRepo = placeRepo ?? PlaceRepo(),
        _favoriteRepo = favoriteRepo ?? FavoriteLocationRepo();

  final PlaceRepo _placeRepo;
  final FavoriteLocationRepo _favoriteRepo;

  static const String recentSearchesKey = 'recent_transport_searches';
  static const int maxRecentSearches = 10;
  static const Duration searchDebounce = Duration(milliseconds: 350);

  final RxString searchQuery = ''.obs;
  final RxBool isLoadingPredictions = false.obs;
  final RxList<PlacePrediction> predictions = <PlacePrediction>[].obs;

  /// `place_id` currently being resolved by a row tap, or null. Drives the row
  /// spinner and blocks a second tap while a lookup is in flight.
  final RxnString resolvingPlaceId = RxnString();

  final RxList<Map<String, dynamic>> recentSearches =
      <Map<String, dynamic>>[].obs;
  final RxList<FavoriteLocation> favourites = <FavoriteLocation>[].obs;
  final RxBool isLoadingFavourites = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
    loadFavourites();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // ─── Data loaders ───────────────────────────────────────────────────────

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(recentSearchesKey) ?? [];
    recentSearches
        .assignAll(stored.map((e) => jsonDecode(e) as Map<String, dynamic>));
  }

  Future<void> saveRecentSearch(double lat, double lng, String address) async {
    if (address.isEmpty) return;
    final entry = {'lat': lat, 'lng': lng, 'address': address};
    recentSearches.removeWhere((e) => e['address'] == address);
    recentSearches.insert(0, entry);
    if (recentSearches.length > maxRecentSearches) {
      recentSearches.removeRange(maxRecentSearches, recentSearches.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      recentSearchesKey,
      recentSearches.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> loadFavourites() async {
    isLoadingFavourites.value = true;
    try {
      final res = await _favoriteRepo.listFavorites();
      if (res.isSuccess) {
        final data = res.response?.data;
        final list = (data is Map ? data['favorites'] as List? : null) ?? [];
        favourites.assignAll(list.map((e) =>
            FavoriteLocation.fromJson(Map<String, dynamic>.from(e as Map))));
      }
    } catch (e) {
      log('listFavorites error: $e');
    } finally {
      isLoadingFavourites.value = false;
    }
  }

  // ─── Search ─────────────────────────────────────────────────────────────

  /// Debounced: runs the search once typing pauses.
  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      final trimmed = query.trim();
      searchQuery.value = trimmed;
      if (trimmed.isEmpty) {
        predictions.clear();
      } else {
        fetchPredictions(trimmed);
      }
    });
  }

  void clearSearch() {
    searchQuery.value = '';
    predictions.clear();
  }

  Future<void> fetchPredictions(String query) async {
    isLoadingPredictions.value = true;
    try {
      final responseModel = await _placeRepo.autoCompleteSearch(query: query);
      if (responseModel.statusCode == 200) {
        final data = responseModel.response?.data;
        final predictionsJson = (data['predictions'] as List?) ?? [];
        // Render the predictions as they arrive and resolve NOTHING here.
        //
        // This used to loop over every prediction calling Place Details, to fill
        // in lat/lng and a "x km away" label — 5 billed lookups per keystroke
        // burst, for a list the user takes one row from. Coordinates are now
        // fetched in the tap handler (see [selectPrediction]) and the ordering
        // that the distance label used to convey comes from the location bias on
        // the autocomplete request itself, which is free.
        // See docs/GOOGLE_MAPS_COST_GUIDE.md §3.1.
        predictions.assignAll(PlacePrediction.fromList(predictionsJson));
      } else {
        predictions.clear();
      }
    } catch (e) {
      log('Autocomplete error: $e');
      predictions.clear();
    } finally {
      isLoadingPredictions.value = false;
    }
  }

  /// Fill in [p]'s coordinates if it has none yet. [PlaceRepo.resolvePlace]
  /// caches per `place_id` for the session, so favouriting and then picking
  /// the same row costs one lookup. Returns false when it can't be resolved.
  Future<bool> resolveCoordinates(PlacePrediction p) async {
    if ((p.lat ?? 0.0) != 0.0 || (p.lng ?? 0.0) != 0.0) return true;
    final resolved = await _placeRepo.resolvePlace(p.placeId);
    if (resolved == null) return false;
    p.lat = resolved.lat;
    p.lng = resolved.lng;
    return true;
  }

  /// Resolve the tapped prediction's coordinates — the one Place Details call
  /// this screen makes. Returns false when it can't be resolved, and ignores a
  /// second tap while a lookup is in flight (returning null).
  Future<bool?> selectPrediction(PlacePrediction p) async {
    if (resolvingPlaceId.value != null) return null;
    resolvingPlaceId.value = p.placeId;
    try {
      // Cached back onto the prediction, so the favourite button on this row
      // doesn't have to look it up again.
      return await resolveCoordinates(p);
    } finally {
      resolvingPlaceId.value = null;
    }
  }

  // ─── Favourites ─────────────────────────────────────────────────────────

  bool isFavourited(String address) =>
      favourites.any((f) => f.address == address);

  FavoriteLocation? findFavourite(String address) =>
      favourites.firstWhereOrNull((f) => f.address == address);

  /// Removes [existing] from the saved favourites. Returns null on success, or
  /// the server's message ('' when it gave none) on failure.
  Future<String?> removeFavourite(FavoriteLocation existing) async {
    try {
      final res = await _favoriteRepo.deleteFavorite(existing.id);
      if (!res.isSuccess) return res.message ?? '';
      favourites.removeWhere((f) => f.id == existing.id);
      return null;
    } catch (e) {
      log('deleteFavorite error: $e');
      return '';
    }
  }

  /// Saves a favourite and adds it to the list. Returns the saved favourite,
  /// or throws [FavouriteSaveError] with the server's message.
  Future<FavoriteLocation> addFavourite({
    required String address,
    required double latitude,
    required double longitude,
    required String tag,
    required bool isCustomTag,
  }) async {
    final created = await FavouriteLocationService(repo: _favoriteRepo).add(
      address: address,
      latitude: latitude,
      longitude: longitude,
      tag: tag,
      isCustomTag: isCustomTag,
    );
    favourites.insert(0, created);
    return created;
  }
}
