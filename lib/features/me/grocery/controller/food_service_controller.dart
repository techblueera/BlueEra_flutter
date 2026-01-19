import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/grocery/repo/food_repo.dart';
import 'package:get/get.dart';
import '../../../common/food/model/food_category_res_model.dart';

class FoodServiceController extends GetxController {
  Rx<ApiResponse> getFoodCategoryResponse = ApiResponse.initial('Initial').obs;
  RxList<FoodCategoryData> foodSubCateList = <FoodCategoryData>[].obs;
  RxString selectedFoodTypeID="".obs;
  Future<void> getFoodCategoryController() async {
    getFoodCategoryResponse.value = ApiResponse.initial("Initial");
    ResponseModel response = await FoodRepo().getFoodCategoryRepo();
    if (response.isSuccess) {
      List rawList = response.response?.data['data'];
      foodSubCateList.value =
          rawList.map((e) => FoodCategoryData.fromJson(e)).toList();
      getFoodCategoryResponse.value = ApiResponse.complete(foodSubCateList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getFoodCategoryResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}
