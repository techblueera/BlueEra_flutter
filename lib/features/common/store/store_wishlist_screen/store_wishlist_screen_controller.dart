import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreWishlistScreenController extends GetxController {
  // Search Controller
  final TextEditingController searchController = TextEditingController();
  
  // Create a unique GlobalKey for each instance
  late final GlobalKey<FormState> formKey;

  // Reactive Variables
  RxBool isLoading = false.obs;
  RxString searchQuery = ''.obs;
  
  // Wishlist Items
  RxList<Map<String, dynamic>> wishlistItems = <Map<String, dynamic>>[
    {
      'id': '1',
      'name': 'iPhone 16 128 GB: 5G Mobile Phone with...',
      'currentPrice': 'Rs: 61,499/-',
      'originalPrice': '98,000',
      'discount': '50% off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/images/seller_icon.png',
      'rating': '4.8',
      'reviews': '1,432 Ratings',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
      'isInStock': true,
      'isAddedToCart': false,
    },
    {
      'id': '2',
      'name': 'iPhone 16 128 GB: 5G Mobile Phone with...',
      'currentPrice': 'Rs: 61,499/-',
      'originalPrice': '98,000',
      'discount': '50% off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '1,432 Ratings',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
      'isInStock': true,
      'isAddedToCart': false,
    },
    {
      'id': '3',
      'name': 'iPhone 16 128 GB: 5G Mobile Phone with...',
      'currentPrice': 'Rs: 61,499/-',
      'originalPrice': '98,000',
      'discount': '50% off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '1,432 Ratings',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
      'isInStock': true,
      'isAddedToCart': false,
    },
    {
      'id': '4',
      'name': 'iPhone 16 128 GB: 5G Mobile Phone with...',
      'currentPrice': 'Rs: 61,499/-',
      'originalPrice': '98,000',
      'discount': '50% off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '1,432 Ratings',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
      'isInStock': true,
      'isAddedToCart': false,
    },
    {
      'id': '5',
      'name': 'iPhone 16 128 GB: 5G Mobile Phone with...',
      'currentPrice': 'Rs: 61,499/-',
      'originalPrice': '98,000',
      'discount': '50% off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '1,432 Ratings',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
      'isInStock': true,
      'isAddedToCart': false,
    },
    {
      'id': '6',
      'name': 'iPhone 16 128 GB: 5G Mobile Phone with...',
      'currentPrice': 'Rs: 61,499/-',
      'originalPrice': '98,000',
      'discount': '50% off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/images/seller_icon.png',
      'rating': '4.8',
      'reviews': '1,432 Ratings',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
      'isInStock': true,
      'isAddedToCart': false,
    },
  ].obs;

  // Filtered items based on search
  RxList<Map<String, dynamic>> filteredItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Create a unique GlobalKey for this instance
    formKey = GlobalKey<FormState>();
    
    // Initialize filtered items
    filteredItems.assignAll(wishlistItems);
    
    // Listen to search changes
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    performSearch();
  }

  // Search Methods
  void performSearch() {
    if (searchController.text.isEmpty) {
      filteredItems.assignAll(wishlistItems);
      return;
    }

    final query = searchController.text.toLowerCase();
    final results = wishlistItems.where((item) => 
      item['name'].toString().toLowerCase().contains(query) ||
      item['seller'].toString().toLowerCase().contains(query)
    ).toList();
    
    filteredItems.assignAll(results);
  }

  void clearSearch() {
    searchController.clear();
    filteredItems.assignAll(wishlistItems);
  }

  // Wishlist Item Actions
  void removeFromWishlist(String itemId) {
    wishlistItems.removeWhere((item) => item['id'] == itemId);
    performSearch(); // Update filtered items
    Get.snackbar(
      'Removed from Wishlist',
      'Item has been removed from your wishlist',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void addToCart(String itemId) {
    final itemIndex = wishlistItems.indexWhere((item) => item['id'] == itemId);
    if (itemIndex != -1) {
      wishlistItems[itemIndex]['isAddedToCart'] = true;
      Get.snackbar(
        'Added to Cart',
        'Item has been added to your cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void shareItem(String itemId) {
    final item = wishlistItems.firstWhere((item) => item['id'] == itemId);
    Get.snackbar(
      'Share Item',
      'Sharing: ${item['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void viewItemDetails(String itemId) {
    final item = wishlistItems.firstWhere((item) => item['id'] == itemId);
    Get.snackbar(
      'View Details',
      'Viewing details for: ${item['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // Bulk Actions
  void selectAllItems() {
    for (var item in wishlistItems) {
      item['isSelected'] = true;
    }
    wishlistItems.refresh();
  }

  void deselectAllItems() {
    for (var item in wishlistItems) {
      item['isSelected'] = false;
    }
    wishlistItems.refresh();
  }

  void removeSelectedItems() {
    final selectedItems = wishlistItems.where((item) => item['isSelected'] == true).toList();
    for (var item in selectedItems) {
      wishlistItems.remove(item);
    }
    performSearch();
    Get.snackbar(
      'Items Removed',
      '${selectedItems.length} items removed from wishlist',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void addSelectedToCart() {
    final selectedItems = wishlistItems.where((item) => item['isSelected'] == true).toList();
    for (var item in selectedItems) {
      item['isAddedToCart'] = true;
    }
    wishlistItems.refresh();
    Get.snackbar(
      'Added to Cart',
      '${selectedItems.length} items added to cart',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Sort Methods
  void sortByPrice(bool ascending) {
    wishlistItems.sort((a, b) {
      final priceA = double.tryParse(a['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      final priceB = double.tryParse(b['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
    });
    performSearch();
  }

  void sortByName(bool ascending) {
    wishlistItems.sort((a, b) {
      return ascending ? a['name'].compareTo(b['name']) : b['name'].compareTo(a['name']);
    });
    performSearch();
  }

  void sortByRating(bool ascending) {
    wishlistItems.sort((a, b) {
      final ratingA = double.tryParse(a['rating'].toString()) ?? 0;
      final ratingB = double.tryParse(b['rating'].toString()) ?? 0;
      return ascending ? ratingA.compareTo(ratingB) : ratingB.compareTo(ratingA);
    });
    performSearch();
  }

  // Filter Methods
  void filterByPriceRange(double minPrice, double maxPrice) {
    final results = wishlistItems.where((item) {
      final price = double.tryParse(item['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return price >= minPrice && price <= maxPrice;
    }).toList();
    filteredItems.assignAll(results);
  }

  void filterBySeller(String seller) {
    if (seller.isEmpty) {
      filteredItems.assignAll(wishlistItems);
    } else {
      final results = wishlistItems.where((item) => 
        item['seller'].toString().toLowerCase().contains(seller.toLowerCase())
      ).toList();
      filteredItems.assignAll(results);
    }
  }

  // Refresh Data
  void refreshWishlist() {
    isLoading.value = true;
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;
      performSearch();
    });
  }

  // Get Wishlist Statistics
  int get totalItems => wishlistItems.length;
  int get selectedItemsCount => wishlistItems.where((item) => item['isSelected'] == true).length;
  double get totalValue {
    return wishlistItems.fold(0.0, (sum, item) {
      final price = double.tryParse(item['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return sum + price;
    });
  }
}