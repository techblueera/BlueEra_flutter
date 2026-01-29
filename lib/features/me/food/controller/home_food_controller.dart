import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
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

      // call repo
      ResponseModel responseModel = await FoodRepo()
          .getHomeFoodByIdRepo(businessProfile: userId);
          // .getHomeFoodByIdRepo(businessProfile: "696f13baead58417505a8851");

      if (responseModel.isSuccess) {
        restaurantData.value =
            FoodHomeResModel.fromJson(responseModel.response?.data).data;

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

  // Validation state
  var isFormValid = false.obs;

  // Values to store from location picker
  double? selectedLat;
  double? selectedLng;

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) {
    // Basic validation logic
    bool isValid = branchName.isNotEmpty &&
        website.isURL &&
        address.isNotEmpty &&
        department.isNotEmpty &&
        email.isEmail &&
        phone.length >= 10;

    isFormValid.value = isValid;
  }

  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(
          message: "Please select a valid location from the search.");
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "name": branchName,
        "pageLink": website,
        "department": department,
        "email": email,
        "phone": phone,
        "location": {
          "name": address,
          "type": "Point",
          "coordinates": [selectedLat, selectedLng]
        },
      };

      ResponseModel response =
          await FoodRepo().addFoodContactRepo(reqBody: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Branch details added successfully");
        Get.back();
        fetchHomeData();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
      print("Request Body: $body");
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
}
