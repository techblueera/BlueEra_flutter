import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Manages the boolean amenity flags for the hotel as a whole (not per-room).
///
/// The API returns a flat map of `{amenityKey: bool}` mixed with non-boolean
/// metadata; we keep only the booleans in [hotelAmenityStatus] so the toggle
/// UI can bind directly.
class HotelAmenityController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// `{amenityKey: enabled}` — only boolean entries from the API response.
  final RxMap<String, bool> hotelAmenityStatus = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAmenities();
  }

  Future<void> fetchAmenities() async {
    try {
      isLoading.value = true;
      final ResponseModel response = await _repo.getHotelAmenitiesRepo();
      if (response.isSuccess) {
        final data = response.response?.data['data'] as Map<String, dynamic>?;
        hotelAmenityStatus.assignAll(_filterBooleans(data));
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.hotelFailedLoadAmenities.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Optimistic local toggle. The actual write happens on [submitAPI].
  void updateAmenity(String key, bool value) {
    hotelAmenityStatus[key] = value;
    hotelAmenityStatus.refresh();
  }

  /// Persists the full amenity map.
  Future<void> submitAPI() async {
    try {
      isSaving.value = true;
      final body = <String, dynamic>{
        "roomId": "",
        ...hotelAmenityStatus,
      };
      final ResponseModel response =
          await _repo.addHotelAmenitiesRepo(reqBody: body);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
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

  /// Keeps only `bool` values from a mixed-type map.
  Map<String, bool> _filterBooleans(Map<String, dynamic>? source) {
    final result = <String, bool>{};
    source?.forEach((key, value) {
      if (value is bool) result[key] = value;
    });
    return result;
  }

  void _refreshHotelHome() {
    try {
      Get.find<HotelDetailController>().loadHotelData();
    } catch (_) {}
  }
}
