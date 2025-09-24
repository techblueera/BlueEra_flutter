import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/detail_item.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/generate_ai_product_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMoreDetailsController extends GetxController {
  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

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
    detailController.dispose();
    super.onClose();
  }

  // Validation Methods
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    return null;
  }

  String? validateDetail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Detail is required';
    }
    if (value.trim().length < 3) {
      return 'Detail must be at least 3 characters';
    }
    return null;
  }

  // Save Details
  Future<void> saveDetails({required String fromScreen}) async {
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
        'detail': detailController.text.trim(),
      };

      final detailItem = DetailItem(
        title: titleController.text.trim(),
        details: detailController.text.trim(),
      );

      clearForm();

      print('Saving details: $details');

      if(fromScreen == RouteConstant.listingFormScreen) {
        final detailItem = AddMoreDetail(
          title: titleController.text.trim(),
          details: detailController.text.trim(),
        );
        Get.find<ManualListingScreenController>().addDetail(detailItem);
      }else if(fromScreen == RouteConstant.addServicesScreen){
        final detailItem = DetailItem(
          title: titleController.text.trim(),
          details: detailController.text.trim(),
        );
        Get.find<AddServiceController>().addDetail(detailItem);
      }

      Get.back();
      
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
    detailController.clear();
  }
} 