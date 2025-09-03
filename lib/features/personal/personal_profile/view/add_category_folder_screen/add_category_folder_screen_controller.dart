import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCategoryFolderScreenController extends GetxController {
  final TextEditingController categoryNameController = TextEditingController();
  final TextEditingController categoryDescriptionController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  final RxBool isLoading = false.obs;
  final RxString selectedImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    categoryNameController.dispose();
    categoryDescriptionController.dispose();
    super.onClose();
  }

  Future<void> uploadImage() async {
    try {
      print('Upload image tapped - opening dialog...');
      
      final String? selected = await SelectProfilePictureDialog.showLogoDialog(
        Get.context!,
        'Upload Category Image',
      );

      print('Dialog result: $selected');

      if (selected?.isNotEmpty ?? false) {
        selectedImagePath.value = selected!;
        update();
        print('Image selected: ${selectedImagePath.value}');
      }
    } catch (e) {
      print('Error in uploadImage: $e');
    }
  }

  void saveCategory() {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      
      // TODO: Implement save functionality
      // This would typically make an API call to save the category
      
      Future.delayed(const Duration(seconds: 1), () {
        isLoading.value = false;
        Get.back();
      });
    }
  }

  void cancel() {
    Get.back();
  }

  String? validateCategoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    if (value.trim().length < 3) {
      return 'Category name must be at least 3 characters';
    }
    return null;
  }

  String? validateCategoryDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category description is required';
    }
    if (value.trim().length < 10) {
      return 'Category description must be at least 10 characters';
    }
    return null;
  }
} 