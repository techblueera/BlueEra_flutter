import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

class HotelPolicyController extends GetxController {
  var isLoading = false.obs;

  // var userSelections = <String, dynamic>{}.obs;
  var userCheckInSelections = '12:00'.obs;
  var userCheckOutSelections = '11:00'.obs;
  var userFoodTypeSelections = [].obs;

  // Observable fields matching your JSON response keys
  // var checkInTime = "12:00 PM".obs;
  // var checkOutTime = "11:00 AM".obs;
  var is24Hours = false.obs;

  var earlyCheckInAllowed = false.obs;
  var lateCheckOutAllowed = false.obs;
  var marriedCoupleAllowed = false.obs;
  var bachelorStudentAllowed = false.obs;
  var freeCancellation = false.obs;
  var localIdAllowed = false.obs;
  var aadharMandatory = false.obs;
  var smokingDrinkingAllowed = false.obs;

  // Food Restriction logic
  var foodRestrictionsEnabled = false.obs;
  var selectedRestrictions = <String>[].obs;
  List<String> timeSlots =
      List.generate(24, (i) => "${i.toString().padLeft(2, '0')}:00");

  @override
  void onInit() {
    super.onInit();
    loadPolicies();
    // In a real app, call your fetch API here
  }

  // Load data from GET API response
  Future<void> loadPolicies() async {
    try {
      isLoading(true);
      // Simulated GET Response based on your provided JSON
      await Future.delayed(const Duration(seconds: 1));
      ResponseModel response = await HotelServiceRepo().getHotelPoliciesRepo();

      if (response.isSuccess) {
        final Map<String, dynamic> data = response.response?.data['data'];
        // userCheckInSelections.value = data['checkInTime'] ?? "10:00 AM";
        // userCheckOutSelections.value = data['checkOutTime'] ?? "23:00 PM";
        is24Hours.value = data['checkInHours'] == "24 Hours";
        logs("is24Hours.value=== ${is24Hours.value}");

        earlyCheckInAllowed.value = data['earlyCheckInAllowed'] ?? false;
        lateCheckOutAllowed.value = data['lateCheckOutAllowed'] ?? false;
        marriedCoupleAllowed.value = data['marriedCoupleAllowed'] ?? false;
        bachelorStudentAllowed.value = data['bachelorStudentAllowed'] ?? false;
        freeCancellation.value = data['freeCancellation'] ?? false;
        localIdAllowed.value = data['localIdAllowed'] ?? false;
        aadharMandatory.value = data['aadharMandatory'] ?? false;
        smokingDrinkingAllowed.value = data['smokingDrinkingAllowed'] ?? false;

        if (data['foodRestrictions'] != null) {
          foodRestrictionsEnabled.value =
              data['foodRestrictions']['enabled'] ?? false;
          selectedRestrictions.assignAll(List<String>.from(
              data['foodRestrictions']['restrictions'] ?? []));
        }

        // Assign to the observable map and refresh
        // hotelAmenityStatus.assignAll(filteredMap);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message:"Error Failed to load amenities");
    } finally {
      isLoading(false);
    }
  }

  Future<void> submitPolicies() async {
    // Construct POST payload here
    Map<String, dynamic> requestBody = {
      "checkInTime": userCheckInSelections.value,
      "checkOutTime": userCheckOutSelections.value,
      if (is24Hours.value) "checkInHours": "24 Hours",
      "earlyCheckInAllowed": earlyCheckInAllowed.value,
      "lateCheckOutAllowed": lateCheckOutAllowed.value,
      "marriedCoupleAllowed": marriedCoupleAllowed.value,
      "bachelorStudentAllowed": bachelorStudentAllowed.value,
      "freeCancellation": freeCancellation.value,
      "localIdAllowed": localIdAllowed.value,
      "aadharMandatory": aadharMandatory.value,
      "smokingDrinkingAllowed": smokingDrinkingAllowed.value,
      "foodRestrictions": {
        "enabled": foodRestrictionsEnabled.value,
        if (foodRestrictionsEnabled.value)
          "restrictions": userFoodTypeSelections
      }
    };

    try {
      ResponseModel response =
          await HotelServiceRepo().addHotelAmenitiesRepo(reqBody: requestBody);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        loadPolicies();
        try {
          Get.find<HotelDetailController>().loadHotelData();
        } catch (_) {}
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
