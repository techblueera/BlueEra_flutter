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

  int _page = 1;
  final int _limit = 10;

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

      _mapCategoryToApiType(selectedCategory.value);

      final ResponseModel res = await ApiBaseHelper().getHTTP(
        // "other-service/business-profile/search?distance=5000&limit=$_limit&type=BANKING_SECTOR",
        // "other-service/business-profile/search?distance=5000&limit=$_limit&type=LOANS_SECTOR",
        "other-service/business-profile/search?distance=5000&limit=$_limit&type=finance",
        // "other-service/business-profile/search?distance=5000&limit=$_limit&type=$categoryType",
        onError: (e) {},
        onSuccess: (data) {},
      );

      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final items =
            data.map((e) => FinanceBusinessItem.fromJson(e)).toList();
        if (items.isEmpty) {
          hasMore.value = false;
        } else {
          profiles.addAll(items);
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

  String _mapCategoryToApiType(String slugId) {
    switch (slugId) {
      case 'ADVISORY_SECTOR':
        return 'advisory';
      case 'BANKING_SECTOR':
        return 'banking';
      case 'CAPITAL_MARKET':
        return 'capital_market';
      case 'DATA_SECTOR':
        return 'data';
      case 'INSURANCE_SECTOR':
        return 'insurance';
      case 'LOAN_SECTOR':
        return 'loan';
      default:
        return 'finance';
    }
  }
}
