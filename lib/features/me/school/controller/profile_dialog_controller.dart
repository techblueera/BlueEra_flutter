import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileDialogController extends GetxController {
  final searchController = TextEditingController();
  final websiteController = TextEditingController();

  void generateProfile() {
    String school = searchController.text;
    String website = websiteController.text;

    // Logic for AI generation goes here
    print("Generating for: $school, $website");

    Get.back(); // Close dialog after action
  }

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    super.onClose();
  }
}