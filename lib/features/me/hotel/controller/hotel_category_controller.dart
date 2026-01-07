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
    fetchAllHotelServiceCategories();
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
    hotelServiceSubCategoryList[index].isActive = value;
    hotelServiceSubCategoryList.refresh(); // Notify UI of change inside the list
  }

  // Final list of selected data on submit
  void submitData() {
    List<Map<String, dynamic>> selectedRooms = hotelServiceSubCategoryList
        .where((room) => (room.isActive??false))
        .map((room) => {"id": room.id, "name": room.name})
        .toList();

    print("Final Selected List: $selectedRooms");
    commonSnackBar(message: "Success ${selectedRooms.length} rooms selected for submission");
  }
}
