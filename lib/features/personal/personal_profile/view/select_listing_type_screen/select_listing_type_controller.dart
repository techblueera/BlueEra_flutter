import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectListingTypeController extends GetxController {
  // Selected listing type index (0: Bulk Listing, 1: Single Product, 2: Manual)
  RxInt selectedIndex = 0.obs;

  // Listing type options
  final List<Map<String, dynamic>> listingTypes = [
    {
      'title': 'Bulk Listing',
      'description': 'Search and select multiple products to list at once with pre-filled details.',
      'icon': Icons.inventory_2,
    },
    {
      'title': 'Single Product Listing',
      'description': 'Search and select one product to auto-fill its details and list quickly.',
      'icon': Icons.inventory,
    },
    {
      'title': 'Create New Listing Manually',
      'description': 'Open the full manual form to add detailed information section by section.',
      'icon': Icons.edit,
    },
  ];

  @override
  void onInit() {
    super.onInit();
  }

  // Select listing type
  void selectListingType(int index) {
    selectedIndex.value = index;
  }

  // Start listing based on selected type
  void startListing() {
    print('SelectListingTypeController: Starting listing with index ${selectedIndex.value}');
    switch (selectedIndex.value) {
      case 0:
        // Navigate to Bulk Product Listing
        print('SelectListingTypeController: Navigating to Bulk Product Listing');
        // Get.toNamed(RouteHelper.getProductListingScreenRoute(), arguments: {
        //   'listingType': 'Bulk Product Listing',
        // });
        break;
      case 1:
        // Navigate to Single Product Listing
        print('SelectListingTypeController: Navigating to Single Product Listing');
        // Get.toNamed(RouteHelper.getProductListingScreenRoute(), arguments: {
        //   'listingType': 'Single Product Listing',
        // });
        break;
      case 2:
        // Navigate to Manual Listing Form
        print('SelectListingTypeController: Navigating to Manual Listing');
        // Get.to(() => ListingFormScreen());
        break;
    }
  }
} 