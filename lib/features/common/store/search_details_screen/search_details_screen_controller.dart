import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchDetailsScreenController extends GetxController {
  // Search Controller
  final TextEditingController searchController = TextEditingController();
  
  // Create a unique GlobalKey for each instance
  late final GlobalKey<FormState> formKey;

  // Reactive Variables
  RxBool isLoading = false.obs;
  RxString searchQuery = ''.obs;
  RxString selectedSortBy = 'Relevance'.obs;
  RxBool showFilters = false.obs;
  
  // Product Grid Items
  RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[
    {
      'id': '1',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.pink[100],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
    {
      'id': '2',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.teal[100],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
    {
      'id': '3',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
    {
      'id': '4',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.grey[100],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
    {
      'id': '5',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.purple[100],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
    {
      'id': '6',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.grey[200],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
    {
      'id': '7',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[200],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
    {
      'id': '8',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50% Off',
      'seller': 'Pervez Mobile Shop',
      'sellerIcon': 'assets/icons/iphone_img.png',
      'rating': '4.8',
      'reviews': '48 reviews',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.indigo[100],
      'isInStock': true,
      'isAddedToCart': false,
      'isWishlisted': false,
    },
  ].obs;

  // Filtered products based on search
  RxList<Map<String, dynamic>> filteredProducts = <Map<String, dynamic>>[].obs;

  // Filter variables
  RxDouble minPrice = 0.0.obs;
  RxDouble maxPrice = 100000.0.obs;
  RxString selectedBrand = 'All Brands'.obs;
  RxString selectedRating = 'All Ratings'.obs;
  RxBool inStockOnly = false.obs;
  RxBool freeShipping = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Create a unique GlobalKey for this instance
    formKey = GlobalKey<FormState>();
    
    // Initialize filtered products
    filteredProducts.assignAll(products);
    
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
      filteredProducts.assignAll(products);
      return;
    }

    final query = searchController.text.toLowerCase();
    final results = products.where((item) => 
      item['name'].toString().toLowerCase().contains(query) ||
      item['seller'].toString().toLowerCase().contains(query)
    ).toList();
    
    filteredProducts.assignAll(results);
  }

  void clearSearch() {
    searchController.clear();
    filteredProducts.assignAll(products);
  }

  // Product Actions
  void addToCart(String productId) {
    final productIndex = products.indexWhere((item) => item['id'] == productId);
    if (productIndex != -1) {
      products[productIndex]['isAddedToCart'] = true;
      Get.snackbar(
        'Added to Cart',
        'Product has been added to your cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void toggleWishlist(String productId) {
    final productIndex = products.indexWhere((item) => item['id'] == productId);
    if (productIndex != -1) {
      products[productIndex]['isWishlisted'] = !products[productIndex]['isWishlisted'];
      products.refresh();
      Get.snackbar(
        products[productIndex]['isWishlisted'] ? 'Added to Wishlist' : 'Removed from Wishlist',
        products[productIndex]['isWishlisted'] ? 'Product added to wishlist' : 'Product removed from wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: products[productIndex]['isWishlisted'] ? Colors.green : Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void viewProductDetails(String productId) {
    final product = products.firstWhere((item) => item['id'] == productId);
    Get.snackbar(
      'View Details',
      'Viewing details for: ${product['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void shareProduct(String productId) {
    final product = products.firstWhere((item) => item['id'] == productId);
    Get.snackbar(
      'Share Product',
      'Sharing: ${product['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.purple,
      colorText: Colors.white,
    );
  }

  // Sort Methods
  void sortByRelevance() {
    selectedSortBy.value = 'Relevance';
    // In real implementation, sort by relevance algorithm
    filteredProducts.refresh();
  }

  void sortByPrice(bool ascending) {
    selectedSortBy.value = ascending ? 'Price: Low to High' : 'Price: High to Low';
    filteredProducts.sort((a, b) {
      final priceA = double.tryParse(a['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      final priceB = double.tryParse(b['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
    });
  }

  void sortByRating(bool ascending) {
    selectedSortBy.value = ascending ? 'Rating: High to Low' : 'Rating: Low to High';
    filteredProducts.sort((a, b) {
      final ratingA = double.tryParse(a['rating'].toString()) ?? 0;
      final ratingB = double.tryParse(b['rating'].toString()) ?? 0;
      return ascending ? ratingB.compareTo(ratingA) : ratingA.compareTo(ratingB);
    });
  }

  void sortByNewest() {
    selectedSortBy.value = 'Newest First';
    // In real implementation, sort by date
    filteredProducts.refresh();
  }

  // Filter Methods
  void applyFilters() {
    var results = products.where((item) {
      // Price filter
      final price = double.tryParse(item['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (price < minPrice.value || price > maxPrice.value) return false;
      
      // Brand filter
      if (selectedBrand.value != 'All Brands' && !item['name'].toString().contains(selectedBrand.value)) {
        return false;
      }
      
      // Rating filter
      if (selectedRating.value != 'All Ratings') {
        final rating = double.tryParse(item['rating'].toString()) ?? 0;
        final requiredRating = double.tryParse(selectedRating.value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        if (rating < requiredRating) return false;
      }
      
      // Stock filter
      if (inStockOnly.value && !item['isInStock']) return false;
      
      return true;
    }).toList();
    
    filteredProducts.assignAll(results);
    showFilters.value = false;
  }

  void clearFilters() {
    minPrice.value = 0.0;
    maxPrice.value = 100000.0;
    selectedBrand.value = 'All Brands';
    selectedRating.value = 'All Ratings';
    inStockOnly.value = false;
    freeShipping.value = false;
    filteredProducts.assignAll(products);
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  // Refresh Data
  void refreshProducts() {
    isLoading.value = true;
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;
      performSearch();
    });
  }

  // Get Statistics
  int get totalProducts => filteredProducts.length;
  int get wishlistedCount => products.where((item) => item['isWishlisted'] == true).length;
  int get cartCount => products.where((item) => item['isAddedToCart'] == true).length;
}