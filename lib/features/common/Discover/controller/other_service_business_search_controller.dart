import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/model/other_service_business_search_res_model.dart';
import 'package:get/get.dart';

/// Drives the `other-service/business-profile/search` endpoint scoped to a
/// `categoryOfBusiness` (e.g. CONSULTING_BUSINESS_SERVICES). Mirrors the
/// finance discover controller's paging contract: [fetchInitial] resets and
/// loads page 1; [fetchMore] appends the next page when the list scrolls.
class OtherServiceBusinessSearchController extends GetxController {
  final profiles = <OtherServiceBusinessItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = ''.obs;

  /// Current category filter — e.g. `CONSULTING_BUSINESS_SERVICES`.
  final selectedCategory = ''.obs;

  /// Rich `/other-service/business-profile/{id}/full` payload for the
  /// currently-open detail screen. `VisitBusinessHero` prefers fields from
  /// here (business_description, avg_rating, total_ratings, category_details)
  /// over the shared business-profile endpoint.
  final selectedDetail = Rx<OtherServiceBusinessItem?>(null);
  final isDetailLoading = false.obs;
  final detailError = ''.obs;

  int _page = 1;
  final int _limit = 10;
  final int _distance = 5000;

  /// Fetch the rich detail payload from
  /// `other-service/business-profile/{businessId}/full`. Mirrors
  /// [FinanceDiscoverController.fetchDetail] — the two endpoints share the
  /// same wire shape. `businessId` here is the be_user_service
  /// `businesses._id` (same id that keys the ratings endpoint). Suppresses
  /// the global ProgressDialog overlay because the detail screen owns its
  /// own loading state.
  Future<void> fetchDetail(String businessId) async {
    if (businessId.isEmpty) return;
    try {
      isDetailLoading.value = true;
      detailError.value = '';
      final ResponseModel res = await ApiBaseHelper().getHTTP(
        'other-service/business-profile/$businessId/full',
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data is Map) {
          selectedDetail.value = OtherServiceBusinessItem.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
      } else {
        detailError.value = res.message ?? AppStrings.somethingWentWrong;
      }
    } catch (e) {
      detailError.value = e.toString();
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<void> fetchInitial(String categoryOfBusiness) async {
    profiles.clear();
    _page = 1;
    hasMore.value = true;
    selectedCategory.value = categoryOfBusiness;
    await _fetch(_page, isLoadMore: false);
  }

  Future<void> fetchMore() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    _page += 1;
    await _fetch(_page, isLoadMore: true);
  }

  Future<void> _fetch(int page, {required bool isLoadMore}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }
      error.value = '';

      // `showProgress: false` suppresses the global ProgressDialog overlay
      // (see `ApiBaseHelper.addInterceptors` → `CircularIndicator` which
      // renders `ShimmerListView` as a full-screen shimmer for any endpoint
      // outside its allowlist). This screen owns its own initial/pagination
      // states via `isLoading` / `isLoadingMore`, so the global overlay was
      // stacking a shimmer on top during both first load and pagination.
      final ResponseModel res = await ApiBaseHelper().getHTTP(
        'other-service/business-profile/search'
        '?distance=$_distance&limit=$_limit&page=$page'
        '&categoryOfBusiness=${selectedCategory.value}',
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

      if (!res.isSuccess) {
        hasMore.value = false;
        error.value = res.message ?? AppStrings.somethingWentWrong;
        return;
      }

      final List raw = res.response?.data['data'] ?? [];
      final items = raw
          .whereType<Map>()
          .map((m) =>
              OtherServiceBusinessItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();

      if (items.isEmpty) {
        hasMore.value = false;
        return;
      }

      final existingIds = profiles.map((p) => p.id).whereType<String>().toSet();
      final newItems = items
          .where((i) => i.id == null || !existingIds.contains(i.id))
          .toList();

      if (newItems.isEmpty) {
        hasMore.value = false;
      } else {
        profiles.addAll(newItems);
        if (items.length < _limit) hasMore.value = false;
      }
    } catch (e) {
      hasMore.value = false;
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}
