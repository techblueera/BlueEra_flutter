import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Manages the boolean amenity flags for a single room.
///
/// Mirrors [HotelAmenityController] but talks to the per-room amenity endpoint.
class RoomAmenityController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// The room currently being edited. Set via [loadForRoom] before fetching
  /// so the amenity toggles reflect (and write back to) that specific room.
  String roomId = '';

  /// `{amenityKey: enabled}` — only boolean entries from the API response.
  final RxMap<String, bool> roomAmenityStatus = <String, bool>{}.obs;

  /// Point the controller at [roomId] and (re)load its saved amenities.
  /// Called by [RoomAmenitiesScreen] each time it opens for a given room.
  Future<void> loadForRoom(String roomId) async {
    this.roomId = roomId;
    roomAmenityStatus.clear();
    await fetchAmenities();
  }

  Future<void> fetchAmenities() async {
    if (roomId.isEmpty) return;
    try {
      isLoading.value = true;
      final ResponseModel response =
          await _repo.getHotelRoomAmenitiesRepo(roomId: roomId);
      if (response.isSuccess) {
        final data = response.response?.data['data'] as Map<String, dynamic>?;
        roomAmenityStatus.assignAll(_filterBooleans(data));
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
    roomAmenityStatus[key] = value;
    roomAmenityStatus.refresh();
  }

  Future submitAPI() async {
    try {
      isSaving.value = true;
      final body = <String, dynamic>{
        "roomId": roomId,
        ...roomAmenityStatus,
      };
      final ResponseModel response =
          await _repo.addHotelRoomAmenitiesRepo(reqBody: body);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, bool> _filterBooleans(Map<String, dynamic>? source) {
    final result = <String, bool>{};
    source?.forEach((key, value) {
      if (value is bool) result[key] = value;
    });
    return result;
  }
}
