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
    if (!hasMore.value || isLoadingMore.value) return;
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
          final existingIds = profiles.map((p) => p.id).toSet();
          final newItems = items
              .where((i) => i.id == null || !existingIds.contains(i.id))
              .toList();
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