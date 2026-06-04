import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:get/get.dart';

class HmpStoreDetailsController extends GetxController {
  final ProductRepo _repo = ProductRepo();

  /// The owning user's id whose products we list.
  final String userId;

  HmpStoreDetailsController({required this.userId});

  static const int _pageLimit = 20;

  final RxList<GetProductData> products = <GetProductData>[].obs;
  final RxBool isFirstLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  int _page = 1;
  bool _hasMore = true;

  /// True once a fetch has completed and no products were found.
  bool get hasNoProducts => products.isEmpty;

  @override
  void onInit() {
    super.onInit();
    fetchProducts(reset: true);
  }

  void onScrollEnd() {
    if (isLoadingMore.value || isFirstLoading.value || !_hasMore) return;
    _page++;
    fetchProducts(reset: false);
  }

  Future<void> fetchProducts({required bool reset}) async {
    try {
      if (reset) {
        _page = 1;
        _hasMore = true;
        isFirstLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      final response = await _repo.fetchProductsRepo(queryParams: {
        ApiKeys.ownerType: ProviderType.user.title,
        ApiKeys.businessId: userId,
        ApiKeys.page: _page,
        ApiKeys.limit: _pageLimit,
      });

      if (!response.isSuccess || response.response?.data == null) return;

      final parsed = GetProductModel.fromJson(response.response!.data);
      final newItems = parsed.data;
      _hasMore = newItems.length >= _pageLimit;

      if (reset) {
        products.assignAll(newItems);
      } else {
        products.addAll(newItems);
      }
    } catch (e, s) {
      log('Error fetching store products: $e\n$s');
      if (!reset) _page--; // roll back failed page bump
    } finally {
      isFirstLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}
