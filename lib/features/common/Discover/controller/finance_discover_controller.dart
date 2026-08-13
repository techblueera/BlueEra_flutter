import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:get/get.dart';

class FinanceDiscoverController extends GetxController {
  final profiles = <FinanceBusinessItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = ''.obs;
  final selectedCategory = ''.obs;
  final selectedDetail = Rx<FinanceBusinessItem?>(null);
  final isDetailLoading = false.obs;
  final detailError = ''.obs;

  int _page = 1;
  final int _limit = 10;

  /// Fetch the full business profile (rich detail: profile, management,
  /// staff, gallery, contactUs, etc.) and replace [selectedDetail] with it.
  /// The list screen seeds [selectedDetail] with the lightweight search item
  /// first, so the screen shows immediately and refreshes when this completes.
  Future<void> fetchDetail(String id) async {
    if (id.isEmpty) return;
    try {
      isDetailLoading.value = true;
      detailError.value = '';
      // `showProgress: false` suppresses the global ProgressDialog /
      // ShimmerListView overlay (see [ApiBaseHelper.addInterceptors]) —
      // callers of this controller own their own loading state.
      final ResponseModel res = await ApiBaseHelper().getHTTP(
        "other-service/business-profile/$id/full",
        showProgress: false,
        onError: (e) {},
        onSuccess: (data) {},
      );
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data != null) {
          selectedDetail.value =
              FinanceBusinessItem.fromJson(Map<String, dynamic>.from(data));
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

  Future<void> fetchInitial(String category) async {
    profiles.clear();
    _page = 1;
    hasMore.value = true;
    selectedCategory.value = category;
    await _fetch(_page, isLoadMore: false);
  }

  Future<void> fetchMore() async {
    // Guard against `isLoading` too: the previous version only checked
    // `isLoadingMore`, so an on-layout ScrollNotification (or fast scroll
    // right after the initial fetch resolved) could sneak a page-2 request
    // in parallel with the still-running page-1 request. That resulted in
    // two overlapping fetches whose responses were merged into `profiles`,
    // and if the backend returned the same businesses with fresh `_id`s
    // the dedup below couldn't catch them — each card would then appear
    // twice on screen. Blocking on either loader is enough to serialize.
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
      // `showProgress: false` suppresses the global ProgressDialog /
      // ShimmerListView overlay so pagination doesn't stack a shimmer on
      // top of the list. FinanceListScreen renders its own initial + bottom
      // pagination loaders keyed off `isLoading` / `isLoadingMore`.
      final ResponseModel res = await ApiBaseHelper().getHTTP(
        "other-service/business-profile/search?distance=5000&limit=$_limit&page=$page&sub_type=${selectedCategory.value}",
        showProgress: false,
        onError: (e) {},
        onSuccess: (data) {},
      );

      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final items = data.map((e) => FinanceBusinessItem.fromJson(e)).toList();
        if (items.isEmpty) {
          hasMore.value = false;
        } else {
          // Dedup by ANY stable key — id, userId, or businessId. The
          // previous version only used `id`, and worse, treated a
          // null-id item as automatically new (`i.id == null` always
          // passed the filter). Backends that echo the same businesses
          // on later pages with fresh `_id`s or with `_id` missing were
          // therefore double-added — one row per response — and each
          // card rendered twice. Non-empty owner/business ids give us a
          // safety net when `id` disagrees or drops.
          final existingIds =
              profiles.map((p) => p.id).whereType<String>().toSet();
          final existingUserIds =
              profiles.map((p) => p.userId).whereType<String>().toSet();
          final existingBusinessIds =
              profiles.map((p) => p.businessId).whereType<String>().toSet();
          final newItems = items.where((i) {
            final id = i.id?.trim() ?? '';
            final uid = i.userId?.trim() ?? '';
            final bid = i.businessId?.trim() ?? '';
            if (id.isNotEmpty && existingIds.contains(id)) return false;
            if (uid.isNotEmpty && existingUserIds.contains(uid)) return false;
            if (bid.isNotEmpty && existingBusinessIds.contains(bid)) {
              return false;
            }
            return true;
          }).toList();
          if (newItems.isEmpty) {
            hasMore.value = false;
          } else {
            profiles.addAll(newItems);
            if (items.length < _limit) hasMore.value = false;
          }
        }
      } else {
        hasMore.value = false;
        error.value = res.message ?? AppStrings.somethingWentWrong;
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