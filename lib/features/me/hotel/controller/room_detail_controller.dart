import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomDetailController extends GetxController {
  // Text Controllers
  final totalRoomsTotal = TextEditingController();
  final roomLength = TextEditingController();
  final roomWidth = TextEditingController();
  final bedType = TextEditingController();
  final maxOccupancy = TextEditingController();
  final pricePerDay = TextEditingController();

  // Coupon Modal Controllers
  final couponName = TextEditingController();
  final couponDesc = TextEditingController();
  final couponCode = TextEditingController();
  final totalOff = TextEditingController();
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
        selectedBedType.value != null &&      // Bed Type must be selected
        selectedOccupancy.value != null &&    // Occupancy must be selected
        pricePerDay.text.isNotEmpty;
  }

// Validation for Coupon Modal (Code is optional)
  RxBool isCouponValid=false.obs;
   isCouponValidMethod (){
    return isCouponValid.value= couponName.text.isNotEmpty &&
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
      "code": couponCode.text.isEmpty ? "NOCODE" : couponCode.text.toUpperCase(),
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


  var roomList = <Map<String, dynamic>>[
    {
      "name": "Standard Room",
      "price": "5000",
      "bed": "Super King Bed",
      "occupancy": "Double Occupancy",
      "images": [
        "https://img.freepik.com/free-photo/interior-modern-comfortable-hotel-room_1232-1822.jpg?semt=ais_hybrid&w=740&q=80",
        "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8aG90ZWwlMjByb29tfGVufDB8fDB8fHww"
      ],
    },
    {
      "name": "Standard Room Flex",
      "price": "1000",
      "bed": "Super King Bed",
      "occupancy": "Double Occupancy",
      "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSKo2j4t4WvPnFpYmhSFH4QQw0GilE3QA2tMg&s",

      ],
    },
    {
      "name": "Standard Room 1",
      "price": "8000",
      "bed": "Super King Bed",
      "occupancy": "Double Occupancy",
      "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSA1Yye-lQqFVvhwXEKRrhRZWmLHMnDBVy9Cw&s",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSKo2j4t4WvPnFpYmhSFH4QQw0GilE3QA2tMg&s",
        "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8aG90ZWwlMjByb29tfGVufDB8fDB8fHww"
      ],
    },
    // Add more mock data as needed
  ].obs;
}