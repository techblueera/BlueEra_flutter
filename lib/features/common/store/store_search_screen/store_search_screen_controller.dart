import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Update the constructor to accept initialQuery
class StoreSearchScreenController extends GetxController {
  final String? initialQuery;
  
  StoreSearchScreenController({this.initialQuery});
  
  // Search Controllers
  final TextEditingController searchController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceRangeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  
  // Create a unique GlobalKey for each instance
  late final GlobalKey<FormState> formKey;

  // Reactive Variables
  RxBool isLoading = false.obs;
  RxString selectedCategory = 'All Categories'.obs;
  RxBool isFilterApplied = false.obs;
  RxBool showAdvancedFilters = false.obs;
  
  // Search Results
  RxList<String> searchResults = <String>[].obs;
  RxList<String> filteredResults = <String>[].obs;
  RxList<String> categories = <String>[
    'All Categories',
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Sports',
    'Books',
    'Automotive',
    'Health & Beauty',
    'Toys & Games',
    'Food & Beverages'
  ].obs;
  
  // Filter Variables
  RxDouble minPrice = 0.0.obs;
  RxDouble maxPrice = 10000.0.obs;
  RxString selectedLocation = 'Any Location'.obs;
  RxBool inStockOnly = false.obs;
  RxBool freeShipping = false.obs;
  
  // Search History
  RxList<String> searchHistory = <String>[].obs;
  
  // Pagination
  RxInt currentPage = 1.obs;
  RxBool hasMoreData = true.obs;
  final int itemsPerPage = 20;

  // Products Data
  RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[
    {
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50',
      'seller': 'Pervez Mobile Shop',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.pink[100],
    },
    {
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50',
      'seller': 'Pervez Mobile Shop',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.teal[100],
    },
    {
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50',
      'seller': 'Pervez Mobile Shop',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.blue[100],
    },
    {
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50',
      'seller': 'Pervez Mobile Shop',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.grey[100],
    },
  ].obs;

  // Stores Data
  RxList<Map<String, dynamic>> stores = <Map<String, dynamic>>[
    {
      'name': 'iTech@',
      'tag': 'Mobile Store',
      'rating': '4.8',
      'reviews': '6.2K',
      'status': 'Open - Closes 9:30 pm',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.grey[200],
    },
    {
      'name': 'iTech@',
      'tag': 'Mobile Store',
      'rating': '4.8',
      'reviews': '6.2K',
      'status': 'Open - Closes 9:30 pm',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.grey[200],
    },
    {
      'name': 'iTech@',
      'tag': 'Mobile Store',
      'rating': '4.8',
      'reviews': '6.2K',
      'status': 'Open - Closes 9:30 pm',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.grey[200],
    },
    {
      'name': 'iTech@',
      'tag': 'Mobile Store',
      'rating': '4.8',
      'reviews': '6.2K',
      'status': 'Open - Closes 9:30 pm',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.grey[200],
    },
  ].obs;

  // Services Data
  RxList<Map<String, dynamic>> services = <Map<String, dynamic>>[
    {
      'name': 'Michel John',
      'tag': 'Plumber',
      'rating': '4.8',
      'reviews': '6.2K',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.blue[100],
    },
    {
      'name': 'Michel John',
      'tag': 'Farmer',
      'rating': '4.8',
      'reviews': '6.2K',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.green[100],
    },
    {
      'name': 'Michel John',
      'tag': 'Electrician',
      'rating': '4.8',
      'reviews': '6.2K',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.orange[100],
    },
    {
      'name': 'Michel John',
      'tag': 'Carpenter',
      'rating': '4.8',
      'reviews': '6.2K',
      'address': 'Ground Floor, Sahu Theatre Building Uttar Pradesh 226001',
      'image': 'assets/icons/phone_banner.png',
      'imageColor': Colors.brown[100],
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    // Create a unique GlobalKey for this instance
    formKey = GlobalKey<FormState>();
    
    // Set initial query if provided
    if (initialQuery != null && initialQuery!.isNotEmpty) {
      searchController.text = initialQuery!;
      // Perform search with initial query
      performSearch();
    }
    
    // Load initial data
    // loadInitialData();
    
    // Listen to search changes
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    categoryController.dispose();
    priceRangeController.dispose();
    locationController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    if (searchController.text.length >= 2) {
      performSearch();
    } else {
      filteredResults.clear();
    }
  }

  // Load initial data


  // Search Methods
  void performSearch() {
    if (searchController.text.isEmpty) {
      filteredResults.assignAll(searchResults);
      return;
    }

    final query = searchController.text.toLowerCase();
    final results = searchResults.where((item) => 
      item.toLowerCase().contains(query)
    ).toList();
    
    filteredResults.assignAll(results);
    
    // Add to search history if not empty
    if (query.isNotEmpty && !searchHistory.contains(query)) {
      searchHistory.add(query);
      if (searchHistory.length > 10) {
        searchHistory.removeAt(0);
      }
    }
  }

  void clearSearch() {
    searchController.clear();
    filteredResults.assignAll(searchResults);
  }

  // Category Selection
  void selectCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  // Filter Methods
  void applyFilters() {
    isLoading.value = true;
    
    // Simulate filter application
    Future.delayed(const Duration(milliseconds: 500), () {
      List<String> results = searchResults;
      
      // Apply category filter
      if (selectedCategory.value != 'All Categories') {
        // In real implementation, filter by actual category
        results = results.where((item) => 
          item.toLowerCase().contains(selectedCategory.value.toLowerCase())
        ).toList();
      }
      
      // Apply price filter
      if (minPrice.value > 0 || maxPrice.value < 10000) {
        // In real implementation, filter by actual price
        results = results.where((item) => true).toList(); // Placeholder
      }
      
      // Apply location filter
      if (selectedLocation.value != 'Any Location') {
        // In real implementation, filter by actual location
        results = results.where((item) => true).toList(); // Placeholder
      }
      
      filteredResults.assignAll(results);
      isFilterApplied.value = true;
      isLoading.value = false;
    });
  }

  void clearFilters() {
    selectedCategory.value = 'All Categories';
    minPrice.value = 0.0;
    maxPrice.value = 10000.0;
    selectedLocation.value = 'Any Location';
    inStockOnly.value = false;
    freeShipping.value = false;
    isFilterApplied.value = false;
    
    filteredResults.assignAll(searchResults);
  }

  void toggleAdvancedFilters() {
    showAdvancedFilters.value = !showAdvancedFilters.value;
  }

  // Price Range Methods
  void updateMinPrice(double value) {
    minPrice.value = value;
  }

  void updateMaxPrice(double value) {
    maxPrice.value = value;
  }

  // Location Methods
  void selectLocation(String location) {
    selectedLocation.value = location;
  }

  // Toggle Methods
  void toggleInStockOnly() {
    inStockOnly.value = !inStockOnly.value;
  }

  void toggleFreeShipping() {
    freeShipping.value = !freeShipping.value;
  }

  // Search History Methods
  void clearSearchHistory() {
    searchHistory.clear();
  }

  void removeFromHistory(String query) {
    searchHistory.remove(query);
  }

  void useHistoryItem(String query) {
    searchController.text = query;
    performSearch();
  }

  // Pagination Methods
  void loadMoreData() {
    if (!hasMoreData.value || isLoading.value) return;
    
    isLoading.value = true;
    currentPage.value++;
    
    // Simulate loading more data
    Future.delayed(const Duration(seconds: 1), () {
      // In real implementation, load more data from API
      hasMoreData.value = currentPage.value < 5; // Simulate 5 pages
      isLoading.value = false;
    });
  }

  // void refreshData() {
  //   currentPage.value = 1;
  //   hasMoreData.value = true;
  //   loadInitialData();
  // }

  // Validation Methods
  String? validateSearch(String? value) {
    if (value == null || value.isEmpty) {
      return 'Search query is required';
    }
    if (value.length < 2) {
      return 'Search query must be at least 2 characters';
    }
    return null;
  }

  // Item Selection
  void selectItem(String item) {
    // Handle item selection
    Get.snackbar(
      'Item Selected',
      'You selected: $item',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Sort Methods
  void sortByPrice(bool ascending) {
    // In real implementation, sort by actual price
    filteredResults.sort((a, b) => ascending ? a.compareTo(b) : b.compareTo(a));
  }

  void sortByName(bool ascending) {
    filteredResults.sort((a, b) => ascending ? a.compareTo(b) : b.compareTo(a));
  }

  void sortByPopularity() {
    // In real implementation, sort by popularity/rating
    // For now, just shuffle to simulate different order
    filteredResults.shuffle();
  }
}

void performSearch(String query) {
    // Implement search functionality here
    // This would filter products, stores, and services based on the query

}