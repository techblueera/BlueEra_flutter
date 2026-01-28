import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:get/get.dart';

class RestaurantController extends GetxController {
  // Observables
  var isLoading = true.obs;
  var restaurantData = Rxn<FoodData>();
  var allFoodItems = <Items>[].obs;

  @override
  void onInit() {
    fetchHomeData();
    super.onInit();
  }

  void fetchHomeData() async {
    try {
      isLoading(true);
      // Replace with your actual API provider call
      // String jsonString = ... from your API
      // var response = foodHomeResModelFromJson(jsonString);

      // Simulating data assignment from your model
      // if (response.success == true) {
      //   restaurantData.value = response.data;
      //   _flattenItems();
      // }

      // call repo
      ResponseModel responseModel = await FoodRepo()
          .getHomeFoodByIdRepo(businessProfile: "696f13baead58417505a8851");

      if (responseModel.isSuccess) {
          restaurantData.value = FoodHomeResModel.fromJson(responseModel.response?.data).data;

        _flattenItems();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } finally {
      isLoading(false);
    }
  }

  void _flattenItems() {
    if (restaurantData.value?.foodMenu != null) {
      var items = <Items>[];
      for (var menu in restaurantData.value!.foodMenu!) {
        for (var sub in menu.subCategories ?? []) {
          if (sub.items != null) items.addAll(sub.items!);
        }
      }
      allFoodItems.value = items;
    }
  }
}