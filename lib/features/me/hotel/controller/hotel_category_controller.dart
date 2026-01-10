import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

class HotelCategoryController extends GetxController {
  var hotelServiceCategoryList = <HotelServiceCategoriesData>[].obs;
  var hotelServiceSubCategoryList = <HotelServiceCategoriesData>[].obs;

  Rx<ApiResponse> getAllHotelServiceResponse =
      ApiResponse.initial('Initial').obs;

  @override
  void onInit() {
    super.onInit();
  }

  ///GET ALL CAMPUS CATEGORY...
  Future<void> fetchAllHotelServiceCategories({bool isRefresh = false}) async {
    try {
      hotelServiceCategoryList.clear();
      ResponseModel response =
          await HotelServiceRepo().getHotelServiceCategoryRepo();

      if (response.isSuccess && response.response?.data != null) {
        HotelServiceCategoriesResModel? resModel =
            HotelServiceCategoriesResModel.fromJson(response.response?.data);
        hotelServiceCategoryList.addAll(resModel.data ?? []);
        getAllHotelServiceResponse.value = ApiResponse.complete(resModel);
      } else {
        getAllHotelServiceResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getAllHotelServiceResponse.value = ApiResponse.error(e.toString());
      commonSnackBar(message: "Error: $e");
    }
  }

  // Toggle switch status
  void toggleRoom(int index, bool value) {
    hotelServiceSubCategoryList[index].isEnabled = value;
    hotelServiceSubCategoryList.refresh(); // Notify UI of change inside the list
  }

  /// Call the repository and handle the response
  Future<void> updateHotelBulkStatus() async {
    try {
      final List<Map<String, dynamic>> nodes = hotelServiceSubCategoryList
          .where((room) => room.id != null)
          .map((room) => {
        "catalogNodeId": room.id!,
        "isEnabled": room.isEnabled ?? false,
      })
          .toList();

      final Map<String, dynamic> requestBody = {
        "nodes": nodes,
      };


      // Call your existing repository function
      ResponseModel response = await HotelServiceRepo().updateHotelServiceRepo(reqBody: requestBody);

      if (response.isSuccess == true) {
        // SUCCESS MESSAGE
        commonSnackBar(message:   response.message ?? "Hotel services updated successfully!");

      } else {
        // FAILED MESSAGE FROM API
        commonSnackBar(message: response.message ?? "Failed to update services.");
      }
    } catch (e) {
      // EXCEPTION HANDLING (Network issues, etc.)
      commonSnackBar(message: "Something went wrong. Please try again later.");
    }
  }
}
