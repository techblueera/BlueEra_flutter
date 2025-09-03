import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductListingController extends GetxController {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController listingTypeController = TextEditingController();
  
  RxString selectedListingType = 'Bulk Product Listing'.obs;
  RxBool isLoading = false.obs;

  // Available listing types
  final List<String> listingTypes = [
    'Bulk Product Listing',
    'Single Product Listing',
    'Manual Listing',
  ];

  @override
  void onInit() {
    super.onInit();
    print('ProductListingController: onInit() called');
    
    // Get the listing type from arguments if passed
    if (Get.arguments != null && Get.arguments['listingType'] != null) {
      selectedListingType.value = Get.arguments['listingType'];
      print('ProductListingController: Setting listing type to ${Get.arguments['listingType']}');
    } else {
      print('ProductListingController: No arguments found, using default');
    }
    
    // Ensure we have a valid listing type
    if (selectedListingType.value.isEmpty) {
      selectedListingType.value = 'Bulk Product Listing';
    }
    print('ProductListingController: Final listing type is ${selectedListingType.value}');
  }

  @override
  void onReady() {
    super.onReady();
    print('ProductListingController: onReady() called');
    // Double-check the listing type after the widget is ready
    if (Get.arguments != null && Get.arguments['listingType'] != null) {
      selectedListingType.value = Get.arguments['listingType'];
      print('ProductListingController: onReady - Updated listing type to ${selectedListingType.value}');
    }
  }

  @override
  void onClose() {
    productNameController.dispose();
    listingTypeController.dispose();
    super.onClose();
  }

  void showListingTypeDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Listing Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...listingTypes.map((type) => ListTile(
              title: Text(type),
              onTap: () {
                selectedListingType.value = type;
                Get.back();
              },
              trailing: selectedListingType.value == type
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void saveAsDraft() {
    if (productNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a product name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Save as draft functionality
    Get.snackbar(
      'Success',
      'Product saved as draft',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void postProduct() {
    if (productNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a product name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Post product functionality
    Get.snackbar(
      'Success',
      'Product posted successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void searchProduct() {
    final productName = productNameController.text.trim();
    if (productName.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a product name to search',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Search product functionality
    Get.snackbar(
      'Searching',
      'Searching for product: $productName',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  // Manual initialization method
  void initializeWithArguments() {
    print('ProductListingController: initializeWithArguments() called');
    if (Get.arguments != null && Get.arguments['listingType'] != null) {
      selectedListingType.value = Get.arguments['listingType'];
      print('ProductListingController: Manual init - Setting listing type to ${Get.arguments['listingType']}');
    }
  }
} 