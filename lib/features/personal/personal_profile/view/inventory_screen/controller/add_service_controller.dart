import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory_screen/model/detail_item.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory_screen/widget/add_services_screen.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddServiceController extends GetxController{
  final TextEditingController facilitiesCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController serviceNameCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController minPriceCtrl = TextEditingController();
  final TextEditingController maxPriceCtrl = TextEditingController();
  final TextEditingController perUnitCtrl = TextEditingController();
  final TextEditingController minBookingCtrl = TextEditingController();

  // Create a unique GlobalKey for each instance
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxList<String> imageLocalPaths = <String>[].obs;
  final RxList<String> facilities = <String>[].obs;

  RxBool isSpecial = false.obs;
  RxBool isRange = true.obs;

  // Generate 24-hour railway times (00:00 → 23:30)
  final List<String> timeSlots = List.generate(
    48,
        (i) => "${(i ~/ 2).toString().padLeft(2, '0')}:${(i % 2 == 0 ? "00" : "30")}",
  );

  RxString startTime = "".obs;
  RxString endTime = "".obs;

  RxList<DiscountCoupon> coupons = <DiscountCoupon>[].obs;
  RxList<DetailItem> detailsList = <DetailItem>[].obs;

  // Validation method
  String? validateServiceName(String? value) {
    if (value == null || value.isEmpty) return 'Service name is required';
    if (value.length < 3) return 'Product name must be at least 3 characters';
    return null;
  }

  String? validateServiceDescription(String? value) {
    if (value == null || value.isEmpty) return 'Service description is required';
    if (value.length < 600) return 'Service description name must be at least 50 characters';
    return null;
  }

  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';

    // Try parsing the value to a number
    final amount = double.tryParse(value);
    if (amount == null) return 'Enter a valid number';
    if (amount <= 0) return 'Amount must be greater than zero';

    return null;
  }

  String? validateMinPrice(String? value, TextEditingController maxPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return "Min price is required";
    }

    final min = int.tryParse(value);
    if (min == null || min <= 0) {
      return "Enter valid min price";
    }

    final max = int.tryParse(maxPriceCtrl.text);
    if (max != null && min >= max) {
      return "Min must be less than Max";
    }

    return null;
  }

  String? validateMaxPrice(String? value, TextEditingController minPriceCtrl) {
    if (value == null || value.trim().isEmpty) {
      return "Max price is required";
    }

    final max = int.tryParse(value);
    if (max == null || max <= 0) {
      return "Enter valid max price";
    }

    final min = int.tryParse(minPriceCtrl.text);
    if (min != null && max <= min) {
      return "Max must be greater than Min";
    }

    return null;
  }


  Future<void> pickImages(BuildContext context) async {
    try {

      final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
        context,
        'Product Image',
      );

      if (selected != null) {
        if (selected.isEmpty) return;
        final remaining = 5 - imageLocalPaths.length;
        if (remaining <= 0) return;
        final addList = selected.take(remaining).map((i) => i).toList();
        imageLocalPaths.addAll(addList);
      }

    } catch (e) {
      commonSnackBar(message: 'Image pick failed: $e');
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < imageLocalPaths.length) {
      imageLocalPaths.removeAt(index);
    }
  }

  void addFacility() {
    if(facilities.length == 10){
      commonSnackBar(message: 'You can\'t add more than 10 facilities');
      return;
    }

    final text = facilitiesCtrl.text.trim();
    if (text.isNotEmpty) {
      facilities.add(text);
      facilitiesCtrl.clear();
    }
  }

  void removeFacility(String tag) {
    facilities.remove(tag);
  }

  void addCoupon(DiscountCoupon coupon) {
    coupons.add(coupon);
  }

  void removeCoupon(int index) {
    coupons.removeAt(index);
  }

  void addDetail(DetailItem detail) {
    detailsList.add(detail);
  }

  void removeDetail(int index) {
    detailsList.removeAt(index);
  }

}