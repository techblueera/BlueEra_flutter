import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_room_listing_res_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Drives the multi-step "create room" flow:
///   1. metadata form (count, size, bed type, occupancy, price)
///   2. optional coupons
///   3. exterior / washroom / amenity images
///
/// Also backs the room-listing screen that lists rooms of a given type and
/// supports deletion.
class RoomDetailController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();
  final ImagePicker _picker = ImagePicker();

  // ---- Step 1: metadata form -------------------------------------------------

  final TextEditingController totalRoomsTotal = TextEditingController();
  final TextEditingController roomLength = TextEditingController();
  final TextEditingController roomWidth = TextEditingController();
  final TextEditingController pricePerDay = TextEditingController();

  /// Bed type / occupancy dropdowns.
  final List<BedType> bedTypeList = BedType.values;
  final List<OccupancyType> occupancyList = OccupancyType.values;
  final Rxn<BedType> selectedBedType = Rxn<BedType>();
  final Rxn<OccupancyType> selectedOccupancy = Rxn<OccupancyType>();

  /// Mirrored Rx flag for the "Next" button. Views call [triggerValidation]
  /// after every field change to keep this in sync with [_isFormValid].
  final RxBool isFormValidRx = false.obs;

  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  // ---- Step 2: coupons -------------------------------------------------------

  final TextEditingController couponName = TextEditingController();
  final TextEditingController couponDesc = TextEditingController();
  final TextEditingController couponCode = TextEditingController();
  final TextEditingController totalOff = TextEditingController();

  /// `"In Percentage"` or `"In Rupees"`. Drives validation bounds.
  final RxString offType = "In Percentage".obs;
  final RxBool isCouponValid = false.obs;
  final RxList<Map<String, String>> savedCoupons = <Map<String, String>>[].obs;

  // ---- Step 3: images --------------------------------------------------------

  final RxList<XFile> exteriorImages = <XFile>[].obs;
  final RxList<XFile> washroomImages = <XFile>[].obs;
  final RxList<XFile> amenityImages = <XFile>[].obs;

  final RxList<String> exteriorImagesUrlList = <String>[].obs;
  final RxList<String> washroomImagesUrlList = <String>[].obs;
  final RxList<String> amenityImagesUrlList = <String>[].obs;

  static const int _maxImagesPerCategory = 4;

  // ---- Listing screen --------------------------------------------------------

  final RxList<HotelRoomData> hotelRoomDataList = <HotelRoomData>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // ---- Form-state callbacks --------------------------------------------------

  void onBedTypeChanged(BedType? value) {
    selectedBedType.value = value;
  }

  void onOccupancyChanged(OccupancyType? value) {
    selectedOccupancy.value = value;
    triggerValidation();
  }

  void triggerValidation() {
    isFormValidRx.value = _isFormValid;
    update();
  }

  /// Step-1 form validity (all numeric fields filled + dropdowns picked).
  bool get _isFormValid {
    return totalRoomsTotal.text.isNotEmpty &&
        _numericRegex.hasMatch(totalRoomsTotal.text) &&
        roomLength.text.isNotEmpty &&
        _numericRegex.hasMatch(roomLength.text) &&
        roomWidth.text.isNotEmpty &&
        _numericRegex.hasMatch(roomWidth.text) &&
        selectedBedType.value != null &&
        selectedOccupancy.value != null &&
        pricePerDay.text.isNotEmpty &&
        _numericRegex.hasMatch(pricePerDay.text);
  }

  /// Step-3 minimum-image rule used to gate the create button.
  bool get isCreateHotel =>
      exteriorImages.length >= 2 && washroomImages.length >= 2;

  /// Hard validation for the create flow.
  bool validate() => isCreateHotel;

  // ---- Coupons ---------------------------------------------------------------

  bool isCouponValidMethod() {
    bool ok = couponName.text.trim().length >= 3 &&
        couponDesc.text.trim().length >= 5 &&
        totalOff.text.isNotEmpty &&
        _numericRegex.hasMatch(totalOff.text);

    final off = int.tryParse(totalOff.text);
    if (offType.value == "In Percentage") {
      ok = ok && off != null && off > 0 && off <= 100;
    } else {
      ok = ok && off != null && off > 0;
    }
    isCouponValid.value = ok;
    return ok;
  }

  void addCoupon() {
    savedCoupons.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": couponName.text,
      "desc": couponDesc.text,
      "code":
          couponCode.text.isEmpty ? "NOCODE" : couponCode.text.toUpperCase(),
      "offValue": totalOff.text,
      "offType": offType.value,
    });
    savedCoupons.refresh();
    _clearCouponFields();
    isCouponValid.value = false;
  }

  void removeCoupon(int index) {
    savedCoupons.removeAt(index);
    savedCoupons.refresh();
  }

  void _clearCouponFields() {
    couponName.clear();
    couponDesc.clear();
    couponCode.clear();
    totalOff.clear();
  }

  // ---- Images ----------------------------------------------------------------

  Future<void> pickImage(ImageSource source, RxList<XFile> targetList) async {
    if (targetList.length >= _maxImagesPerCategory) {
      commonSnackBar(message: AppStrings.hotelLimitReached4Images.tr);
      return;
    }
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) targetList.add(picked);
  }

  void removeImage(int index, RxList<XFile> targetList) {
    targetList.removeAt(index);
  }

  // ---- API: list / submit / delete ------------------------------------------

  Future<void> getHotelRoomDetails({required String roomTYPE}) async {
    try {
      isLoading.value = true;
      hotelRoomDataList.clear();
      final ResponseModel response =
          await _repo.getCreatedRoomProfileRepo(roomType: roomTYPE);
      if (response.isSuccess) {
        final res = HotelRoomListingResModel.fromJson(response.response?.data);
        hotelRoomDataList.addAll(res.data ?? []);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("RoomDetailController.getHotelRoomDetails ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitHotelRoom({
    required String name,
    required String type,
  }) async {
    try {
      isSaving.value = true;

      exteriorImagesUrlList.clear();
      washroomImagesUrlList.clear();
      amenityImagesUrlList.clear();

      // Run the three uploads concurrently.
      await Future.wait([
        _uploadCategory(exteriorImages, exteriorImagesUrlList),
        _uploadCategory(washroomImages, washroomImagesUrlList),
        _uploadCategory(amenityImages, amenityImagesUrlList),
      ]);

      final body = <String, dynamic>{
        "name": name,
        "type": type,
        "totalRooms": totalRoomsTotal.text,
        "size": {"length": roomLength.text, "width": roomWidth.text},
        "bedType": selectedBedType.value?.name,
        "maxOccupancy": selectedOccupancy.value?.name,
        "pricePerDay": pricePerDay.text,
        "isActive": true,
        "images": {
          "exteriorImages": exteriorImagesUrlList,
          "washroomImages": washroomImagesUrlList,
          "amenityImages": amenityImagesUrlList,
        },
      };

      final ResponseModel response = await _repo.addHotelRoomRepo(reqBody: body);

      if (response.isSuccess) {
        // Bypass Get.back() — it routes through closeCurrentSnackbar() which
        // crashes with LateInitializationError when the GetX snackbar queue
        // has a stale entry (see progrss_dialog.dart for the same workaround).
        final ctx = Get.context;
        if (ctx != null) {
          final navigator = Navigator.of(ctx);
          if (navigator.canPop()) navigator.pop();
          if (navigator.canPop()) navigator.pop();
        }
        commonSnackBar(message: response.response?.data['message']);
        await getHotelRoomDetails(roomTYPE: type);
        resetForm();
        _refreshHotelHome();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("RoomDetailController.submitHotelRoom ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteHotelRoomController({
    required String hotelRoomType,
    required String hotelRoomId,
  }) async {
    try {
      final ResponseModel response = await _repo.deleteHotelRoomRepo(hotelRoomId);
      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message: response.response?.data['message'] ?? AppStrings.successful);
        await getHotelRoomDetails(roomTYPE: hotelRoomType);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("RoomDetailController.deleteHotelRoom ERROR $e");
    }
  }

  Future<void> _uploadCategory(List<XFile> files, List<String> urlList) async {
    for (final file in files) {
      final result = await S3UploadService.uploadFile(File(file.path));
      if (result.isSuccess) urlList.add(result.url);
    }
  }

  // ---- Reset -----------------------------------------------------------------

  /// Wipes every field of the create-room form so the next entry starts fresh.
  void resetForm() {
    totalRoomsTotal.clear();
    roomLength.clear();
    roomWidth.clear();
    pricePerDay.clear();
    totalOff.clear();

    selectedBedType.value = null;
    selectedOccupancy.value = null;

    exteriorImages.clear();
    washroomImages.clear();
    amenityImages.clear();

    exteriorImagesUrlList.clear();
    washroomImagesUrlList.clear();
    amenityImagesUrlList.clear();

    savedCoupons.clear();
    isFormValidRx.value = false;
    isCouponValid.value = false;
  }

  void _refreshHotelHome() {
    try {
      Get.find<HotelDetailController>().loadHotelData();
    } catch (_) {}
  }

  @override
  void onClose() {
    totalRoomsTotal.dispose();
    roomLength.dispose();
    roomWidth.dispose();
    pricePerDay.dispose();
    couponName.dispose();
    couponDesc.dispose();
    couponCode.dispose();
    totalOff.dispose();
    super.onClose();
  }
}
