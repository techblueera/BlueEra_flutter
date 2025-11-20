import 'dart:developer';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/store/widget/StoreCategory.dart';
import 'package:get/get.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;
  void onChangeIndex(int index) => currentIndex.value = index;

  List<CategoryData> businessCategoriesList = [];

  Future<void> getAllCategories() async {

    businessCategoriesList = await HiveServices().getAllCategories() ?? await _fetchFromApi();
    log('[getAllCategories]  ${businessCategoriesList.length} items');

    // single pass – update slugIds
    for (final api in businessCategoriesList) {
      final list = _selectList(api.type);
      if (list == null) continue;

      final idx = list.indexWhere((c) => c.name.toLowerCase() == (api.name ?? '').toLowerCase());
      if (idx != -1) {
        log('[slug] ${api.name}  ${list[idx].slugId} → ${api.id}');
        list[idx] = list[idx].copyWith(slugId: api.id ?? '');
      }
    }
    log('[getAllCategories] slug update complete');
  }

  Future<List<CategoryData>> _fetchFromApi() async {
    try {
      final res = await AuthRepo().getBusinessCategoriesRepo();
      if (res.isSuccess) {
        final data = CategoryModel.fromJson(res.response?.data).data ?? [];
        await HiveServices().saveCategoryList(data);
        return data;
      }
      commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
    } catch (e) {
      log('[getAllCategories] $e');
    }
    return [];
  }

  List<StoreFeedCategory>? _selectList(String? type) {
    switch (type) {
      case AppConstants.service: return serviceCategories;
      case AppConstants.food:    return foodCategories;
      case AppConstants.product: return productCategories;
      default:                   return null;
    }
  }
}