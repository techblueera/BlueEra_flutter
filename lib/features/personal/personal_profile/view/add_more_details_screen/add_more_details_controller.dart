import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMoreDetailsController extends GetxController {
  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController variantController = TextEditingController();

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Loading State
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    titleController.dispose();
    variantController.dispose();
    super.onClose();
  }

  // Validation Methods
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 2) {
      return 'Title must be at least 2 characters';
    }
    return null;
  }

  String? validateVariant(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Variant is required';
    }
    if (value.trim().length < 2) {
      return 'Variant must be at least 2 characters';
    }
    return null;
  }

  // Save Details
  Future<void> saveDetails() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Here you would typically save to backend
      final details = {
        'title': titleController.text.trim(),
        'variant': variantController.text.trim(),
      };
      
      print('Saving details: $details');
      
      // Navigate back with the saved details
      Get.back(result: details);
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save details. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Cancel Action
  void cancel() {
    Get.back();
  }

  // Clear Form
  void clearForm() {
    titleController.clear();
    variantController.clear();
  }
} 