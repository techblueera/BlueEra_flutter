// import 'package:BlueEra/core/api/apiService/api_response.dart';
// import 'package:BlueEra/features/common/food/model/food_category_res_model.dart';
// import 'package:BlueEra/features/common/food/repo/food_ai_repo.dart';
// import 'package:get/get.dart';
//
//
// class FoodCategoryController extends GetxController {
//
//   final RxInt selectedFoodSubTabIndex = 0
//       .obs;
//
//   Rx<ApiResponse> getFoodCategoryResponse = ApiResponse.initial('Initial').obs;
//
//   /// cache: tabName → list of categories
//   Map<String, List<FoodCategoryData>> categoryCache = {};
//
//   /// current tab’s list (used by UI)
//   RxList<FoodCategoryData> foodCategoryDataList = <FoodCategoryData>[].obs;
//
//   Future<void> getFoodCategoryById({required String tabName}) async {
//     try {
//       // 1️⃣ Check cache first
//       if (categoryCache.containsKey(tabName)) {
//         foodCategoryDataList.value = categoryCache[tabName]!;
//         getFoodCategoryResponse.value = ApiResponse.complete("cached");
//         return; // ⛔ Do not call API
//       }
//       final response =
//       await FoodAiRepo().getFoodCategoryDataApi(categoryName: tabName);
//
//       if (response.isSuccess) {
//         final foodCategoryResModel =
//         FoodCategoryResModel.fromJson(response.response?.data);
//
//         final dataList = foodCategoryResModel.data ?? [];
//
//         // 2️⃣ Save in cache
//         categoryCache[tabName] = dataList;
//
//         // 3️⃣ Update UI list
//         foodCategoryDataList.value = dataList;
//
//         getFoodCategoryResponse.value = ApiResponse.complete(response);
//       } else {
//         getFoodCategoryResponse.value =
//             ApiResponse.error('Error loading $tabName');
//       }
//     } catch (e) {
//       getFoodCategoryResponse.value = ApiResponse.error('Exception occurred');
//     }
//   }
//
//   void onChangeFoodSubTab(int index){
//     selectedFoodSubTabIndex.value=index;
//   }
// }
//
//
//
//
