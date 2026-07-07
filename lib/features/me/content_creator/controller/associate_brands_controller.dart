import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/model/business_filter_res_model.dart';
import 'package:BlueEra/features/me/content_creator/controller/earn_artist_controller.dart';
import 'package:BlueEra/features/me/content_creator/model/earn_artist_model.dart';
import 'package:BlueEra/features/me/content_creator/repo/earn_artist_repo.dart';
import 'package:get/get.dart';

/// Drives the "Add associate brands" search page. Searches businesses via
/// `GET user-service/business/search` (text + geo, paged) and lets the creator
/// toggle-select which ones appear as their associate brands. On save it hands
/// the full selection to [EarnArtistController.saveBrandCollaborations], which
/// caches display detail locally and PUTs the id list to the artist profile.
class AssociateBrandsController extends GetxController {
  AssociateBrandsController(this._earnCtrl);

  final EarnArtistController _earnCtrl;
  final EarnArtistRepo _repo = EarnArtistRepo();

  // ── Search state ──────────────────────────────────────────────────────────
  final RxString query = ''.obs;
  final RxList<BusinessFilterData> results = <BusinessFilterData>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString error = ''.obs;
  final RxBool didSearch = false.obs;

  int _page = 1;
  final int _limit = 10;
  final int _radiusKm = 25;
  Timer? _debounce;

  // ── Selection state ───────────────────────────────────────────────────────
  /// Ordered ids the user has picked (seeded from the saved profile).
  final RxList<String> selectedIds = <String>[].obs;

  /// id → display detail for everything currently selected. Seeded from the
  /// earn cache so already-saved brands stay resolvable while editing.
  final RxMap<String, ArtistBrand> _selectedDetails = <String, ArtistBrand>{}.obs;

  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    selectedIds.assignAll(_earnCtrl.brandIds);
    _selectedDetails.assignAll({
      for (final id in selectedIds)
        if (_earnCtrl.brandDetails[id] != null) id: _earnCtrl.brandDetails[id]!,
    });
    // Preload nearby businesses so the page opens with pickable results.
    loadInitial();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  int get selectedCount => selectedIds.length;

  bool isSelected(String? id) => id != null && selectedIds.contains(id);

  /// True when the pick set differs from what's already saved — gates the CTA.
  bool get hasChanges {
    final saved = _earnCtrl.brandIds;
    if (saved.length != selectedIds.length) return true;
    return !saved.toSet().containsAll(selectedIds);
  }

  // ── Search ────────────────────────────────────────────────────────────────
  /// Debounced text handler — waits for the user to pause before querying.
  /// First load when the page opens — browse nearby businesses (empty query,
  /// geo-only) so the list is populated immediately instead of an empty prompt.
  Future<void> loadInitial() => search(query.value.trim());

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();
    // Empty field re-runs the nearby browse; a typed query filters it. Both go
    // through [search] after a short debounce.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      search(value.trim());
    });
  }

  Future<void> search(String q) async {
    _debounce?.cancel();
    _page = 1;
    hasMore.value = true;
    error.value = '';
    didSearch.value = true;
    await _fetch(reset: true, q: q);
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value) return;
    _page += 1;
    await _fetch(reset: false, q: query.value.trim());
  }

  Future<void> _fetch({required bool reset, required String q}) async {
    try {
      if (reset) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      // Prefer a device GPS fix; fall back to profile-seeded coords when GPS is
      // off so the geo filter still works instead of centring on (0,0).
      final effLat = LocationService.lat != 0.0
          ? LocationService.lat
          : (LocationService.profileLat ?? 0.0);
      final effLng = LocationService.lng != 0.0
          ? LocationService.lng
          : (LocationService.profileLng ?? 0.0);
      final hasLoc = effLat != 0.0 || effLng != 0.0;
      final res = await _repo.searchBusinesses(
        q: q,
        lat: hasLoc ? effLat : null,
        lng: hasLoc ? effLng : null,
        radius: _radiusKm,
        page: _page,
        limit: _limit,
      );

      if (res.isSuccess) {
        final model = BusinessFilterResModel.fromJson(res.response?.data);
        final page = model.data ?? <BusinessFilterData>[];
        if (reset) results.clear();

        final existing = results.map((e) => e.id).whereType<String>().toSet();
        final fresh =
            page.where((e) => e.id == null || !existing.contains(e.id)).toList();
        results.addAll(fresh);

        final totalPages = model.pagination?.totalPages ?? _page;
        hasMore.value = _page < totalPages && page.isNotEmpty;
      } else {
        if (!reset) _page -= 1;
        hasMore.value = false;
        error.value = res.message ?? 'Something went wrong';
      }
    } catch (e) {
      if (!reset) _page -= 1;
      hasMore.value = false;
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ── Selection ───────────────────────────────────────────────────────────
  void toggle(BusinessFilterData business) {
    final id = business.id;
    if (id == null || id.isEmpty) return;
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      _selectedDetails.remove(id);
    } else {
      selectedIds.add(id);
      _selectedDetails[id] = _toBrand(business);
    }
  }

  /// Maps a search record to the display detail we persist for the strip:
  /// city (or category) becomes the sub-label under the logo.
  ArtistBrand _toBrand(BusinessFilterData b) {
    final sub = [
      b.cityStatePincode,
      b.subCategoryDetails?.name,
      b.categoryDetails?.name,
      b.typeOfBusiness,
    ].firstWhere((s) => s != null && s.trim().isNotEmpty, orElse: () => '') ??
        '';
    return ArtistBrand(
      id: b.id ?? '',
      name: b.businessName ?? '',
      logo: b.logo ?? '',
      subLabel: sub,
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────
  Future<bool> save() async {
    if (_earnCtrl.artistResponse.value.status == Status.LOADING) return false;
    try {
      isSaving.value = true;
      final ok = await _earnCtrl.saveBrandCollaborations(
        ids: selectedIds.toList(),
        details: Map<String, ArtistBrand>.from(_selectedDetails),
      );
      if (ok) {
        commonSnackBar(message: 'Associate brands updated');
        Get.back();
      }
      return ok;
    } finally {
      isSaving.value = false;
    }
  }
}
