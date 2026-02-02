import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/admin_video_model_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;
  void onChangeIndex(int index) => currentIndex.value = index;
  List<AdminVideoData> adminVideos = [];

Future<void> fetchAllAdminVideoApi() async {
  try {

    final cachedVideos = await HiveServices().getAllSavedAdminVideos();
    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      adminVideos.assignAll(cachedVideos);
    } else {
      adminVideos.clear();
    }

    final savedLangCode = LocalizationService.box.get('selectedLanguage', defaultValue: 'en');

    Map<String, dynamic> queryParams = {
      ApiKeys.language: savedLangCode,
      ApiKeys.type: 'App Video'
    };
    final res = await ChannelRepo().fetchAllAdminVideoRepo(queryParams: queryParams);
    if (res.isSuccess) {
      final adminVideoModelResponse = AdminVideoModelResponse.fromJson(res.response?.data);
      adminVideos.assignAll(adminVideoModelResponse.data ?? []);
      await HiveServices().saveAllAdminVideos(adminVideos);
    }
    commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
  } catch (e, s) {
    log('stack trace: $s');
  }
}

// List<CategoryData> businessCategoriesList = [];
// Future<void> getAllCategories() async {
//
//   businessCategoriesList = await HiveServices().getAllCategories() ?? await _fetchFromApi();
//   log('[getAllCategories]  ${businessCategoriesList.length} items');
//
//   // single pass – Add Category Data
//   for (final api in businessCategoriesList) {
//     final list = _selectList(api.type);
//     if (list == null) continue;
//
//     final idx = list.indexWhere((c) => c.slugId.toLowerCase() == (api.name ?? '').toLowerCase());
//     if (idx != -1) {
//       log('[slug] ${api.name}  ${list[idx].slugId} → ${api.id}');
//       list[idx] = list[idx].copyWith(categoryData: api);
//     }
//   }
//   log('[getAllCategories] slug update complete');
// }

  // List<CategoryData> businessCategoriesList = [];
  //
  // Future<void> getAllCategories() async {
  //
  //   businessCategoriesList = await HiveServices().getAllCategories() ?? await _fetchFromApi();
  //   log('[getAllCategories]  ${businessCategoriesList.length} items');
  //
  //   // single pass – Add Category Data
  //   for (final api in businessCategoriesList) {
  //     final list = _selectList(api.type);
  //     if (list == null) continue;
  //
  //     final idx = list.indexWhere((c) => c.slugId.toLowerCase() == (api.name ?? '').toLowerCase());
  //     if (idx != -1) {
  //       log('[slug] ${api.name}  ${list[idx].slugId} → ${api.id}');
  //       list[idx] = list[idx].copyWith(categoryData: api);
  //     }
  //   }
  //   log('[getAllCategories] slug update complete');
  // }
  //
  // Future<List<CategoryData>> _fetchFromApi() async {
  //   try {
  //     final res = await AuthRepo().getBusinessCategoriesRepo();
  //     if (res.isSuccess) {
  //       final data = CategoryModel.fromJson(res.response?.data).data ?? [];
  //       await HiveServices().saveCategoryList(data);
  //       return data;
  //     }
  //     commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
  //   } catch (e) {
  //     log('[getAllCategories] $e');
  //   }
  //   return [];
  // }
  //
  // List<BusinessProfileCategory>? _selectList(String? type) {
  //   switch (type) {
  //     case AppConstants.service: return businessServicesCategories;
  //     case AppConstants.food:    return businessFoodsCategories;
  //     case AppConstants.product: return businessProductsCategories;
  //     default:                   return null;
  //   }
  // }
}