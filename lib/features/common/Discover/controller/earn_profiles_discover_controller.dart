import 'dart:developer';

import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:get/get.dart';

/// Drives a Discover "stores near me" list backed by
/// `GET earn-service/earn-profiles?profileType=...&lat&long`.
///
/// One generic controller for all three earn-service surfaces — registered
/// with a per-[profileType] tag so each screen keeps its own list:
///   • `homeMadeFood`   → Home Made Food kitchens
///   • `homeMadeProduct`→ Home Made Product sellers
///   • `homeService`    → Home Service providers
class EarnProfilesDiscoverController extends GetxController {
  /// `homeMadeFood` | `homeMadeProduct` | `homeService`.
  final String profileType;

  EarnProfilesDiscoverController({required this.profileType});

  final _repo = EarnProfileRepo();

  static const int _pageLimit = 20;

  RxBool isFirstLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxList<EarnProfileModel> stores = <EarnProfileModel>[].obs;

  int _page = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    fetchStores();
  }

  Future<void> fetchStores({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isLoadingMore.value || !_hasMore) return;
      isLoadingMore.value = true;
    } else {
      isFirstLoading.value = true;
      stores.clear();
      _page = 1;
      _hasMore = true;
    }

    try {
      // Ensure usable coordinates first (device GPS, else profile fallback)
      // so the call never goes out with 0,0.
      if (!LocationService.hasUsableLocation) {
        await LocationService.ensureUsableLocation();
      }

      final queryParams = <String, dynamic>{
        'profileType': profileType,
        'lat': LocationService.lat,
        'long': LocationService.lng,
        'page': _page,
        'limit': _pageLimit,
      };

      final response =
          await _repo.fetchEarnProfilesByType(queryParams: queryParams);

      if (response.isSuccess && response.response?.data != null) {
        final parsed =
            EarnProfilesListResponse.fromJson(response.response!.data);
        final newItems = parsed.data;
        if (isLoadMore) {
          stores.addAll(newItems);
        } else {
          stores.assignAll(newItems);
        }
        final pagination = parsed.pagination;
        _hasMore = pagination != null
            ? pagination.page < pagination.totalPages
            : newItems.length >= _pageLimit;
        _page++;
        log('$profileType profiles -- ${stores.length}');
      }
    } catch (e) {
      log('Error fetching $profileType profiles: $e');
    } finally {
      isFirstLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void onScrollEnd() => fetchStores(isLoadMore: true);
}
