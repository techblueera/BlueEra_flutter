import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/categoryinventory_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  
  RxBool isLoading = false.obs;
  RxString selectedFilter = 'Draft'.obs;
  RxList<ProductModel> products = <ProductModel>[].obs;
  RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  RxList<CategoryInventoryModel> categories = <CategoryInventoryModel>[].obs;
  RxList<CategoryInventoryModel> filteredCategories = <CategoryInventoryModel>[].obs;

  RxBool isMenuOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();
    searchController.addListener(_filterData);
    // Ensure search field doesn't auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(Get.context!).unfocus();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void loadProducts() {
    isLoading.value = true;
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      products.value = [
        ProductModel(
          id: '1',
          name: 'Buy Lambard Lightweight Sneake...',
          currentPrice: 500,
          originalPrice: 600,
          discountPercentage: 10,
          imageUrl: 'assets/images/shoes.png',
          status: 'Draft',
          stockStatus: 'In stock',
          sizes: ['7UK', '8UK', '9UK', '10UK', '11UK', '12UK'],
          colors: [Colors.black, Colors.grey, Colors.red, Colors.orange, Colors.blue, Colors.green],
        ),
        ProductModel(
          id: '2',
          name: 'Buy Lambard Lightweight Sneake...',
          currentPrice: 500,
          originalPrice: 600,
          discountPercentage: 10,
          imageUrl: 'assets/images/shoes.png',
          status: 'Draft',
          stockStatus: 'Out of stock',
          sizes: ['7UK', '8UK', '9UK', '10UK', '11UK', '12UK'],
          colors: [Colors.black, Colors.grey, Colors.red, Colors.orange, Colors.blue, Colors.green],
        ),
        ProductModel(
          id: '3',
          name: 'Buy Lambard Lightweight Sneake...',
          currentPrice: 500,
          originalPrice: 600,
          discountPercentage: 10,
          imageUrl: 'assets/images/shoes.png',
          status: 'Draft',
          stockStatus: 'Out of stock',
          sizes: ['7UK', '8UK', '9UK', '10UK', '11UK', '12UK'],
          colors: [Colors.black, Colors.grey, Colors.red, Colors.orange, Colors.blue, Colors.green],
        ),
        ProductModel(
          id: '4',
          name: 'Buy Lambard Lightweight Sneake...',
          currentPrice: 500,
          originalPrice: 600,
          discountPercentage: 10,
          imageUrl: 'assets/images/shoes.png',
          status: 'Draft',
          stockStatus: 'In stock',
          sizes: ['7UK', '8UK', '9UK', '10UK', '11UK', '12UK'],
          colors: [Colors.black, Colors.grey, Colors.red, Colors.orange, Colors.blue, Colors.green],
        ),
        ProductModel(
          id: '5',
          name: 'Buy Lambard Lightweight Sneake...',
          currentPrice: 500,
          originalPrice: 600,
          discountPercentage: 10,
          imageUrl: 'assets/images/shoes.png',
          status: 'Draft',
          stockStatus: 'In stock',
          sizes: ['7UK', '8UK', '9UK', '10UK', '11UK', '12UK'],
          colors: [Colors.grey, Colors.black, Colors.red, Colors.orange, Colors.blue, Colors.green],
        ),
      ];
      filteredProducts.value = products;
      isLoading.value = false;
    });
  }

  void loadCategories() {
    // Simulate API call for categories
    Future.delayed(const Duration(seconds: 1), () {
      categories.value = [
        CategoryInventoryModel(
          id: '1',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 15,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        CategoryInventoryModel(
          id: '2',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 12,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        CategoryInventoryModel(
          id: '3',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 8,
          imageUrl: 'assets/images/shoes.png',
          status: 'Draft',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CategoryInventoryModel(
          id: '4',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 10,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        CategoryInventoryModel(
          id: '5',
          name: 'Electronics',
          description: 'Yorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.',
          productCount: 18,
          imageUrl: 'assets/images/shoes.png',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
      filteredCategories.value = categories;
    });
  }

  void _filterData() {
    final searchQuery = searchController.text.toLowerCase();
    
    if (searchQuery.isEmpty) {
      // Show all items when no search query
      filteredProducts.value = products;
      filteredCategories.value = categories;
    } else {
      // Filter by search query only
      filteredProducts.value = products.where((product) => 
        product.name.toLowerCase().contains(searchQuery)
      ).toList();
      filteredCategories.value = categories.where((category) => 
        category.name.toLowerCase().contains(searchQuery)
      ).toList();
    }
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    // Only apply status filter if no search query is active
    if (searchController.text.isEmpty) {
      if (filter == 'Draft') {
        filteredProducts.value = products.where((product) => product.status == 'Draft').toList();
        filteredCategories.value = categories.where((category) => category.status == 'Draft').toList();
      } else {
        // Show all items for other filters
        filteredProducts.value = products;
        filteredCategories.value = categories;
      }
    }
    // If there's a search query, let _filterData handle it
  }

  void copyListing(String productId) {
    // Implement copy listing functionality

  }

  void addVariant(String productId) {
    // Implement add variant functionality

  }

  void showVariant(String productId) {
    // Implement show variant functionality

  }

  void addProduct() {
    // Navigate to add product screen

  }

  void addCategory() {
    // Navigate to add category screen

  }

  void addToCart(String productId) {
    // Implement add to cart functionality
   commonSnackBar(message: "product added successfully to cart.");
  }

  void handleProductOption(String option, String productId) {
    switch (option) {
      case 'Edit':
        commonSnackBar(message: "Product Edited.");
        break;
      case 'Unpublish':
        commonSnackBar(message: "Product Unpublished.");
        break;
      case 'Copy Listing':
        // copyListing(productId);
        break;
        case 'Out of Stock':
        // copyListing(productId);
        break;
      case 'Delete':
        // Implement delete functionality
        commonSnackBar(message: "Product Deleted.");
        break;
    }
  }

  void handleCategoryOption(String option, String categoryId) {
    switch (option) {
      case 'Edit':
        // Implement edit functionality
        commonSnackBar(message: "Edit Category.");
        break;
      case 'Unpublish':
        // Implement unpublish functionality
        commonSnackBar(message: "Unpublish Category.");
        break;
      case 'Copy Listing':
        copyListing(categoryId);
        break;
      case 'Delete':
        // Implement delete functionality
        commonSnackBar(message: "Category Deleted.");
        break;
    }
  }
}
 