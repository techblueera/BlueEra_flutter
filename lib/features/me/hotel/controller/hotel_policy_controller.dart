import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Manages the hotel-wide policies: check-in/out window, allowance flags
/// and food restrictions.
///
/// The API exposes these as a flat record under `data` plus a nested
/// `foodRestrictions: { enabled, restrictions[] }` block; we lift each field
/// to its own observable for direct UI binding.
class HotelPolicyController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final RxString userCheckInSelections = '12:00'.obs;
  final RxString userCheckOutSelections = '11:00'.obs;
  final RxList<String> userFoodTypeSelections = <String>[].obs;

  final RxBool is24Hours = false.obs;
  final RxBool earlyCheckInAllowed = false.obs;
  final RxBool lateCheckOutAllowed = false.obs;
  final RxBool marriedCoupleAllowed = false.obs;
  final RxBool bachelorStudentAllowed = false.obs;
  final RxBool freeCancellation = false.obs;
  final RxBool localIdAllowed = false.obs;
  final RxBool aadharMandatory = false.obs;
  final RxBool smokingDrinkingAllowed = false.obs;

  final RxBool foodRestrictionsEnabled = false.obs;
  final RxList<String> selectedRestrictions = <String>[].obs;

  /// 24 hourly slots (`"00:00"`..`"23:00"`) for the check-in/out dropdowns.
  final List<String> timeSlots =
      List.generate(24, (i) => "${i.toString().padLeft(2, '0')}:00");

  @override
  void onInit() {
    super.onInit();
    loadPolicies();
  }

  Future<void> loadPolicies() async {
    try {
      isLoading.value = true;
      final ResponseModel response = await _repo.getHotelPoliciesRepo();
      if (!response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      final data = response.response?.data['data'] as Map<String, dynamic>?;
      if (data == null) return;

      userCheckInSelections.value = data['checkInTime'] ?? "12:00";
      userCheckOutSelections.value = data['checkOutTime'] ?? "11:00";
      is24Hours.value = data['checkInHours'] == "24 Hours";

      earlyCheckInAllowed.value = data['earlyCheckInAllowed'] ?? false;
      lateCheckOutAllowed.value = data['lateCheckOutAllowed'] ?? false;
      marriedCoupleAllowed.value = data['marriedCoupleAllowed'] ?? false;
      bachelorStudentAllowed.value = data['bachelorStudentAllowed'] ?? false;
      freeCancellation.value = data['freeCancellation'] ?? false;
      localIdAllowed.value = data['localIdAllowed'] ?? false;
      aadharMandatory.value = data['aadharMandatory'] ?? false;
      smokingDrinkingAllowed.value = data['smokingDrinkingAllowed'] ?? false;

      final food = data['foodRestrictions'] as Map<String, dynamic>?;
      if (food != null) {
        foodRestrictionsEnabled.value = food['enabled'] ?? false;
        userFoodTypeSelections
            .assignAll(List<String>.from(food['restrictions'] ?? const []));
      }
    } catch (e) {
      logs("HotelPolicyController.loadPolicies ERROR $e");
      commonSnackBar(message: AppStrings.hotelFailedLoadAmenities.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitPolicies() async {
    final body = <String, dynamic>{
      "checkInTime": userCheckInSelections.value,
      "checkOutTime": userCheckOutSelections.value,
      "checkInHours": is24Hours.value ? "24 Hours" : "12 Hours",
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
        "restrictions":
            foodRestrictionsEnabled.value ? userFoodTypeSelections.toList() : [],
      },
    };

    try {
      isSaving.value = true;
      final ResponseModel response =
          await _repo.addHotelPoliciesRepo(reqBody: body);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        await loadPolicies();
        _refreshHotelHome();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  void _refreshHotelHome() {
    try {
      Get.find<HotelDetailController>().loadHotelData();
    } catch (_) {}
  }
}
