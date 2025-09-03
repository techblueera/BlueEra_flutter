import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductItem {
  final String id;
  final String name;
  final String description;
  final String color;
  final String price;
  final String size;
  final String imageUrl;
  bool isSelected;
  bool showSellingPrice;
  String sellingPrice;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.price,
    required this.size,
    required this.imageUrl,
    this.isSelected = false,
    this.showSellingPrice = false,
    this.sellingPrice = '',
  });
}

class AddProductScreenController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  final RxBool isLoading = false.obs;
  final RxBool showErrorBanner = false.obs;
  final RxList<ProductItem> allProducts = <ProductItem>[].obs;
  final RxList<ProductItem> filteredProducts = <ProductItem>[].obs;
  final RxList<ProductItem> selectedProducts = <ProductItem>[].obs;

  final int maxSelectionLimit = 10;

  @override
  void onInit() {
    super.onInit();
    _initializeProducts();
    _setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _initializeProducts() {
    // Initialize with sample products
    allProducts.value = [
      ProductItem(
        id: '1',
        name: 'Wireless Earbuds',
        description: 'Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit inte.....',
        color: 'Red',
        price: '₹500/-',
        size: '12UK',
        imageUrl: 'assets/images/headphones.png',
      ),
      ProductItem(
        id: '2',
        name: 'Sneakers',
        description: 'Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit inte.....',
        color: 'Red',
        price: '₹500/-',
        size: '12UK',
        imageUrl: 'assets/images/sneakers.png',
      ),
      ProductItem(
        id: '3',
        name: 'Smart Watch',
        description: 'Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit inte.....',
        color: 'Red',
        price: '₹500/-',
        size: '12UK',
        imageUrl: 'assets/images/watch.png',
      ),
      ProductItem(
        id: '4',
        name: 'Laptop',
        description: 'Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit inte.....',
        color: 'Red',
        price: '₹500/-',
        size: '12UK',
        imageUrl: 'assets/images/laptop.png',
      ),
      ProductItem(
        id: '5',
        name: 'Mobile Phone',
        description: 'Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit inte.....',
        color: 'Red',
        price: '₹500/-',
        size: '12UK',
        imageUrl: 'assets/images/phone.png',
      ),
      ProductItem(
        id: '6',
        name: 'Boat Airdopes',
        description: 'Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit inte.....',
        color: 'Red',
        price: '₹500/-',
        size: '12UK',
        imageUrl: 'assets/images/airpods.png',
      ),
      ProductItem(
        id: '7',
        name: 'Bluetooth Speaker',
        description: 'Norem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit inte.....',
        color: 'Red',
        price: '₹500/-',
        size: '12UK',
        imageUrl: 'assets/images/speaker.png',
      ),
    ];
    filteredProducts.value = allProducts;
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      filterProducts();
    });
  }

  void filterProducts() {
    final query = searchController.text.toLowerCase().trim();
    print('Searching for: "$query"');
    
    if (query.isEmpty) {
      filteredProducts.value = allProducts;
      print('Showing all products: ${allProducts.length}');
    } else {
      final filtered = allProducts
          .where((product) => product.name.toLowerCase().contains(query))
          .toList();
      filteredProducts.value = filtered;
      print('Filtered products: ${filtered.length}');
    }
  }

  void toggleProductSelection(ProductItem product) {
    if (product.isSelected) {
      // Deselect product
      product.isSelected = false;
      product.showSellingPrice = false;
      product.sellingPrice = '';
      selectedProducts.remove(product);
      showErrorBanner.value = false;
    } else {
      // Try to select product
      if (selectedProducts.length >= maxSelectionLimit) {
        showErrorBanner.value = true;
        return;
      }
      
      product.isSelected = true;
      product.showSellingPrice = true;
      selectedProducts.add(product);
      showErrorBanner.value = false;
    }
    
    // Update the lists
    final index = allProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      allProducts[index] = product;
    }
    
    final filteredIndex = filteredProducts.indexWhere((p) => p.id == product.id);
    if (filteredIndex != -1) {
      filteredProducts[filteredIndex] = product;
    }
    
    update();
  }

  void updateSellingPrice(ProductItem product, String price) {
    product.sellingPrice = price;
    
    // Update the lists
    final index = allProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      allProducts[index] = product;
    }
    
    final filteredIndex = filteredProducts.indexWhere((p) => p.id == product.id);
    if (filteredIndex != -1) {
      filteredProducts[filteredIndex] = product;
    }
    
    update();
  }

  void removeProduct(ProductItem product) {
    product.isSelected = false;
    product.showSellingPrice = false;
    product.sellingPrice = '';
    selectedProducts.remove(product);
    showErrorBanner.value = false;
    
    // Update the lists
    final index = allProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      allProducts[index] = product;
    }
    
    final filteredIndex = filteredProducts.indexWhere((p) => p.id == product.id);
    if (filteredIndex != -1) {
      filteredProducts[filteredIndex] = product;
    }
    
    update();
  }

  void saveAsDraft() {
    // TODO: Implement save as draft functionality
    print('Saving as draft...');
  }

  void postProduct() {
    if (selectedProducts.isEmpty) {
      // Show error or validation
      return;
    }
    
    isLoading.value = true;
    
    // TODO: Implement post product functionality
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;
      Get.back();
    });
  }

  void dismissErrorBanner() {
    showErrorBanner.value = false;
  }
} 