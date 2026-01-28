import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

class RoomAmenityController extends GetxController {
  var isLoading = false.obs;

  // This map holds the true/false status for each key from your API
  var roomAmenityStatus = <String, bool>{}.obs;

  @override
  void onInit() {
    fetchAmenities();
    super.onInit();
  }

  // GET API Call
  Future<void> fetchAmenities() async {
    try {
      isLoading(true);
      // Simulated GET Response based on your provided JSON
      await Future.delayed(const Duration(seconds: 1));
      ResponseModel response = await HotelServiceRepo()
          .getHotelRoomAmenitiesRepo(roomId: "");

      if (response.isSuccess) {
        final Map<String, dynamic> allData = response.response?.data['data'];

        // Filter the map: only keep entries where the value is a boolean
        final Map<String, bool> filteredMap = {};
        allData.forEach((key, value) {
          if (value is bool) {
            filteredMap[key] = value;
          }
        });

        // Assign to the observable map and refresh
        roomAmenityStatus.assignAll(filteredMap);
        // Get.back();
        // commonSnackBar(message: response.response?.data['message']);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load amenities");
    } finally {
      isLoading(false);
    }
  }

  // POST/PUT API Call (Update Toggle)
  Future<void> updateAmenity(String key, bool value) async {
    // Update local UI immediately for better UX
    roomAmenityStatus[key] = value;

    try {
      roomAmenityStatus.refresh();
    } catch (e) {
      // Revert if API fails
      roomAmenityStatus[key] = !value;
      commonSnackBar(message: "Error Update failed");
    }
  }

  ///SUBMIT ROOM AMENITIES....
  submitAPI() async {
    try {
      Map<String, dynamic> requestBody = {
        "roomId": "",
        ...roomAmenityStatus,
      };
      ResponseModel response = await HotelServiceRepo()
          .addHotelRoomAmenitiesRepo(reqBody: requestBody);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
