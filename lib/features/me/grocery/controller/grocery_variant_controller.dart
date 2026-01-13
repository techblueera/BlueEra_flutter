import 'package:flutter/material.dart';
import 'package:get/get.dart';
class GroceryVariantController extends GetxController {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final mrpController = TextEditingController();
  final priceController = TextEditingController();

  var isFormValid = false.obs;

  void validate() {
    isFormValid.value = nameController.text.trim().isNotEmpty &&
        quantityController.text.trim().isNotEmpty &&
        mrpController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  void validateVariantPrice() {
    isFormValid.value =
        mrpController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  @override
  void onClose() {
    // Only dispose if they haven't been disposed already
    nameController.dispose();
    quantityController.dispose();
    mrpController.dispose();
    priceController.dispose();
    super.onClose();
  }


  clearAllField(){
    nameController.clear();
    quantityController.clear();
    mrpController.clear();
    priceController.clear();
    isFormValid = false.obs;
  }
}
