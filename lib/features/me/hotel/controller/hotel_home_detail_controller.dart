import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

/// Top-level controller for the hotel home/dashboard.
///
/// Holds the merged hotel profile + rooms response and exposes the room-type
/// filter state used by the home & v2 screens.
class HotelDetailController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rxn<HotelDetailsHomeData> hotelData = Rxn<HotelDetailsHomeData>();
  final RxInt selectedRoomIndex = 0.obs;

  /// Currently selected room type tab; starts empty until [loadHotelData]
  /// populates it from the first available type.
  final RxString selectedRoomType = "".obs;

  Future<void> loadHotelData() async {
    try {
      isLoading.value = true;
      final ResponseModel response = await _repo.getHotelHomeRepo();
      if (response.isSuccess) {
        final res = HotelDetailsHomeResModel.fromJson(response.response?.data);
        hotelData.value = res.data;
        final types = dynamicRoomTypes;
        if (types.isNotEmpty) selectedRoomType.value = types.first;
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("HotelDetailController.loadHotelData ERROR $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Uploads a banner/logo to S3 then patches the hotel profile with the URL.
  /// [uploadVia] is the JSON field on the profile to populate (e.g. `logoUrl`).
  Future<void> uploadSchoolLogoOrBannerImage({
    required File uploadFile,
    required String uploadVia,
  }) async {
    try {
      isSaving.value = true;
      final result = await S3UploadService.uploadFile(uploadFile);
      if (!result.isSuccess) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      final name = (hotelData.value?.profile?.name?.isNotEmpty ?? false)
          ? hotelData.value?.profile?.name
          : businessNameGlobal;

      final ResponseModel response = await _repo.updateHotelProfileRepo(reqBody: {
        uploadVia: result.url,
        "name": name,
      });

      if (response.isSuccess) {
        commonSnackBar(message: response.response?.data['message']);
        await loadHotelData();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("HotelDetailController.uploadSchoolLogoOrBannerImage ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  /// Deletes the room with [roomId] and refreshes the hotel data on success.
  Future<void> deleteRoom(String roomId) async {
    if (roomId.isEmpty) return;
    try {
      isSaving.value = true;
      final ResponseModel response = await _repo.deleteHotelRoomRepo(roomId);
      if (response.isSuccess) {
        commonSnackBar(message: response.response?.data['message']);
        await loadHotelData();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("HotelDetailController.deleteRoom ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  /// Unique, non-empty room `type` values from the current hotel data.
  List<String> get dynamicRoomTypes {
    final rooms = hotelData.value?.rooms ?? const <Rooms>[];
    return rooms
        .map((e) => e.type ?? "")
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Rooms matching the active [selectedRoomType] tab.
  List<Rooms> get filteredRooms {
    return hotelData.value?.rooms
            ?.where((room) => room.type == selectedRoomType.value)
            .toList() ??
        const <Rooms>[];
  }
}
