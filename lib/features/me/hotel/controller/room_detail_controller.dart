import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_room_listing_res_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RoomDetailController extends GetxController {
  // Text Controllers
  final totalRoomsTotal = TextEditingController();
  final roomLength = TextEditingController();
  final roomWidth = TextEditingController();
  final pricePerDay = TextEditingController();

  // Coupon Modal Controllers
  final couponName = TextEditingController();
  final couponDesc = TextEditingController();
  final couponCode = TextEditingController();
  final totalOff = TextEditingController();
  var discountData = "".obs; // Radio button state
  var offType = "In Percentage".obs; // Radio button state

  // List of saved coupons
  // Dropdown / Complex State
  var selectedCategory = Rxn<String>(); // Example for your CommonDropdown
  final categoryList = ["Standard", "Deluxe", "Suite"].obs;

  // Validation Regex
  final numericRegex = RegExp(r'^[0-9]+$');

  // Computed property to enable/disable the button

  void onCategoryChanged(String? value) {
    selectedCategory.value = value;
    update(); // Triggers UI refresh for validation
  }

  void triggerValidation() {
    update(); // Simple way to refresh the Obx wrapping the button
  }

  // List for dropdown
  final List<BedType> bedTypeList = BedType.values;

  // Selected value
  var selectedBedType = Rxn<BedType>();

  void onBedTypeChanged(BedType? value) {
    selectedBedType.value = value;
    // This updates the TextField controller if you are using one for Bed Type
    // bedTypeController.text = value?.name ?? "";
  }

  // Validation check
  bool get isBedSelected => selectedBedType.value != null;

  // Occupancy State
  final List<OccupancyType> occupancyList = OccupancyType.values;
  var selectedOccupancy = Rxn<OccupancyType>();

  void onOccupancyChanged(OccupancyType? value) {
    selectedOccupancy.value = value;
    triggerValidation(); // Refresh the "Next" button state
  }

  // Update your validation logic to include these dropdowns
  bool get isFormValid {
    return totalRoomsTotal.text.isNotEmpty &&
        roomLength.text.isNotEmpty &&
        roomWidth.text.isNotEmpty &&
        selectedBedType.value != null && // Bed Type must be selected
        selectedOccupancy.value != null && // Occupancy must be selected
        pricePerDay.text.isNotEmpty;
  }

// Validation for Coupon Modal (Code is optional)
  RxBool isCouponValid = false.obs;

  isCouponValidMethod() {
    return isCouponValid.value = couponName.text.isNotEmpty &&
        couponDesc.text.isNotEmpty &&
        totalOff.text.isNotEmpty;
  }

  // Observable list of coupons
  var savedCoupons = <Map<String, String>>[].obs;

  void addCoupon() {
    // Collect data from controllers
    final Map<String, String> newCoupon = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": couponName.text,
      "desc": couponDesc.text,
      "code":
          couponCode.text.isEmpty ? "NOCODE" : couponCode.text.toUpperCase(),
      "offValue": totalOff.text,
      "offType": offType.value, // "In Rupees" or "In Percentage"
    };

    savedCoupons.add(newCoupon);

    // Clear fields for next entry
    _clearCouponFields();
  }

  void removeCoupon(int index) {
    savedCoupons.removeAt(index);
  }

  void _clearCouponFields() {
    couponName.clear();
    couponDesc.clear();
    couponCode.clear();
    totalOff.clear();
  }

  clearRoomFormDetails() {}

  var isLoading = false.obs;
  var roomStatus = <String, bool>{}.obs;

  // Replace with your actual businessId from your auth/session logic
  // final String businessId = "68ccf05f28492e584c365636";

  @override
  void onInit() {
    fetchRoomDetails();
    super.onInit();
  }

  // GET API Logic
  void fetchRoomDetails() async {
    ResponseModel response =
        await HotelServiceRepo().getAllHotelRoomsTypeRepo();
    if (response.isSuccess) {
      Map<String, dynamic> data =
          response.response?.data as Map<String, dynamic>;
      // Filter only booleans for our toggle map
      data.forEach((key, value) {
        if (value is bool) {
          roomStatus[key] = value;
        }
      });
    }
  }

  void toggleRoom(String keyId, bool value) {
    roomStatus[keyId] = value;
    roomStatus.refresh();
  }

  // POST API Logic
  Future<void> submitRoomDetails() async {
    try {
      Map<String, dynamic> requestBody = {
        ...roomStatus,
      };
      ResponseModel response = await HotelServiceRepo()
          .addAllHotelRoomsTypeRepo(reqBODY: requestBody);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    // await getConnect.post('url', requestParams);
  }

  RxList<HotelRoomData> hotelRoomDataList = <HotelRoomData>[].obs;

  ///GET ROOM LISTING
  Future<void> getHotelRoomDetails({
    required String roomTYPE,
  }) async {
    try {
      hotelRoomDataList.clear();
      ResponseModel response = await HotelServiceRepo()
          .getCreatedRoomProfileRepo(roomType: roomTYPE);
      HotelRoomListingResModel hotelRoomListingResModel =
          HotelRoomListingResModel.fromJson(response.response?.data);
      if (response.isSuccess) {
        hotelRoomDataList.addAll(hotelRoomListingResModel.data ?? []);
        // Get.back();
        // commonSnackBar(message: response.response?.data['message']);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    // await getConnect.post('url', requestParams);
  }

  final ImagePicker _picker = ImagePicker();

  // Observable lists for each category
  var exteriorImages = <XFile>[].obs;
  var washroomImages = <XFile>[].obs;
  var amenityImages = <XFile>[].obs;

  var exteriorImagesUrlList = <String>[].obs;
  var washroomImagesUrlList = <String>[].obs;
  var amenityImagesUrlList = <String>[].obs;

  Future<void> pickImage(ImageSource source, RxList<XFile> targetList) async {
    if (targetList.length >= 4) {
      commonSnackBar(
          message: "Limit Reached You can only upload a maximum of 4 images.");
      return;
    }

    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      targetList.add(selected);
    }
  }

  void removeImage(int index, RxList<XFile> targetList) {
    targetList.removeAt(index);
  }

  // RxBool isCreateHotel = false.obs;
  // This getter returns true only if both requirements are met
  bool get isCreateHotel =>
      exteriorImages.length >= 2 && washroomImages.length >= 2;

  // Optional: If you still need a manual validate function for snacks/alerts
  bool validate() {
    if (exteriorImages.length < 2) {
      return false;
    }
    if (washroomImages.length < 2) {
      return false;
    }
    return true;
  }

  Future<void> submitHotelRoom({
    required String name,
    required String type,
  }) async {
    // 1. Show Loader
    isLoading.value = true;

    // Clear previous URLs to avoid duplicates if the user retries

    exteriorImagesUrlList.clear();
    washroomImagesUrlList.clear();
    amenityImagesUrlList.clear();
// 2. Parallel Uploading (Optimization)
    // We create a list of upload tasks and run them concurrently
    await Future.wait([
      _uploadCategory(exteriorImages, exteriorImagesUrlList),
      _uploadCategory(washroomImages, washroomImagesUrlList),
      _uploadCategory(amenityImages, amenityImagesUrlList),
    ]);

    // Construct POST payload here
    Map<String, dynamic> requestBody = {
      "name": name,
      "type": type,
      "totalRooms": totalRoomsTotal.text,
      "size": {"length": roomLength.text, "width": roomWidth.text},
      "bedType": selectedBedType.value?.name,
      "maxOccupancy": selectedOccupancy.value?.name,
      "pricePerDay": pricePerDay.text,
      // "discount": newCoupon[''],
      "isActive": true,
      "images": {
        "exteriorImages": exteriorImagesUrlList,
        "washroomImages": washroomImagesUrlList,
        "amenityImages": amenityImagesUrlList
      },
    };

    try {
      ResponseModel response =
          await HotelServiceRepo().addHotelRoomRepo(reqBody: requestBody);

      if (response.isSuccess) {
        Get.back();
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
        getHotelRoomDetails(roomTYPE: type);
        resetForm();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      // 5. Always hide loader at the end
      isLoading.value = false;
    }
  }

  // Helper method to handle multiple uploads for a category
  Future<void> _uploadCategory(List<XFile> files, List<String> urlList) async {
    for (var file in files) {
      UploadResult? result = await S3UploadService.uploadFile(File(file.path));
      if (result.isSuccess) {
        urlList.add(result.url);
      }
    }
  }

  void resetForm() {
    // 1. Clear Text Controllers
    totalRoomsTotal.clear();
    roomLength.clear();
    roomWidth.clear();
    pricePerDay.clear();
    totalOff.clear(); // If you have this for discount

    // 2. Reset Rxn (Nullable) selections to null
    selectedBedType.value = null;
    selectedOccupancy.value = null;

    // 3. Clear Observable Lists
    exteriorImages.clear();
    washroomImages.clear();
    amenityImages.clear();

    // 4. Reset Validation Booleans
    // isCreateHotel = false;

    // Optional: If you have URL lists for the backend, clear them too
    exteriorImagesUrlList.clear();
    washroomImagesUrlList.clear();
    amenityImagesUrlList.clear();

    savedCoupons.clear();
  }



  ///DELETE NOTICE....
  Future<void> deleteHotelRoomController(
      {required String hotelRoomType,required String hotelRoomId,}) async {
    try {
      ResponseModel response =
      await HotelServiceRepo().deleteHotelRoomRepo(hotelRoomId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
            response.response?.data['message'] ?? AppStrings.successful);
        getHotelRoomDetails(roomTYPE: hotelRoomType);

      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);

      }
    } on Exception catch (e) {
      logs("ERROR ${e}");

    }
  }
}
