import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailsScreenController extends GetxController {
  // Search Controller
  final TextEditingController searchController = TextEditingController();
  
  // Create a unique GlobalKey for each instance
  late final GlobalKey<FormState> formKey;

  // Reactive Variables
  RxBool isLoading = false.obs;
  RxString searchQuery = ''.obs;
  RxBool isWishlisted = false.obs;
  RxInt currentImageIndex = 0.obs;
  RxString selectedColor = 'Midnight'.obs;
  RxString selectedStorage = '128GB'.obs;
  
  // Product Details
  RxMap<String, dynamic> productDetails = <String, dynamic>{
    'id': '1',
    'name': 'iPhone 16 128 GB: 5G Mobile Phone with Camera Control, A18 Chip and a Big Boost in Battery Life',
    'currentPrice': '₹61,499',
    'originalPrice': '₹98,000',
    'discount': '50% Off',
    'rating': '4.8',
    'reviews': '1,432 Ratings',
    'description': 'Experience the next generation of iPhone with the iPhone 16. Featuring advanced camera control, the powerful A18 chip, and significantly improved battery life.',
    'brand': 'Apple',
    'model': 'iPhone 16',
    'isInStock': true,
    'isAddedToCart': false,
    'isWishlisted': false,
  }.obs;

  // Product Images
  RxList<String> productImages = <String>[
    'assets/icons/iphone_img.png',
    'assets/icons/iphone_img.png',
    'assets/icons/iphone_img.png',
    'assets/icons/iphone_img.png',
    'assets/icons/iphone_img.png',
  ].obs;

  // Available Colors
  RxList<Map<String, dynamic>> availableColors = <Map<String, dynamic>>[
    {
      'name': 'Midnight',
      'color': Colors.black,
      'isSelected': true,
    },
    {
      'name': 'Starlight',
      'color': Colors.grey[300],
      'isSelected': false,
    },
    {
      'name': 'Blue',
      'color': Colors.blue,
      'isSelected': false,
    },
    {
      'name': 'Purple',
      'color': Colors.purple,
      'isSelected': false,
    },
    {
      'name': '(Product)Red',
      'color': Colors.red,
      'isSelected': false,
    },
  ].obs;

  // Storage Options
  RxList<Map<String, dynamic>> storageOptions = <Map<String, dynamic>>[
    {
      'capacity': '128GB',
      'price': '₹61,499',
      'isSelected': true,
    },
    {
      'capacity': '256GB',
      'price': '₹71,499',
      'isSelected': false,
    },
    {
      'capacity': '512GB',
      'price': '₹91,499',
      'isSelected': false,
    },
  ].obs;

  // Delivery Address
  RxMap<String, dynamic> deliveryAddress = <String, dynamic>{
    'name': 'Neha Singh',
    'address': 'C-102, Galaxy Heights Apartment',
    'city': 'Mumbai',
    'state': 'Maharashtra',
    'pincode': '400001',
    'phone': '+91 98765 43210',
  }.obs;

  // Product Specifications
  RxList<Map<String, String>> specifications = <Map<String, String>>[
    {'key': 'Display', 'value': '6.1-inch Super Retina XDR OLED'},
    {'key': 'Processor', 'value': 'A18 Bionic chip'},
    {'key': 'Storage', 'value': '128GB, 256GB, 512GB'},
    {'key': 'Camera', 'value': '48MP Main + 12MP Ultra Wide'},
    {'key': 'Battery', 'value': 'Up to 20 hours video playback'},
    {'key': 'Operating System', 'value': 'iOS 18'},
    {'key': 'Connectivity', 'value': '5G, Wi-Fi 6E, Bluetooth 5.3'},
    {'key': 'Water Resistance', 'value': 'IP68'},
  ].obs;

  // Reviews
  RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[
    {
      'userName': 'Rishabh Jh',
      'rating': 5.0,
      'title': 'Just Wow!',
      'comment': 'Smooth performance and beautiful display. Just wish the charger came in the box.',
      'date': 'Apr, 2025',
      'location': 'Telangana',
      'isVerified': true,
      'images': [
        'assets/icons/iphone_img.png',
        'assets/icons/iphone_img.png',
        'assets/icons/iphone_img.png',
      ],
    },
    {
      'userName': 'Rishabh Jh',
      'rating': 4.5,
      'title': 'Amazing',
      'comment': 'Absolutely love the camera quality! Low-light photos look amazing. Battery lasts me all day too.',
      'date': 'Apr, 2025',
      'location': 'Telangana',
      'isVerified': true,
      'images': [
        'assets/icons/iphone_img.png',
        'assets/icons/iphone_img.png',
        'assets/icons/iphone_img.png',
      ],
    },
    {
      'userName': 'Rishabh Jh',
      'rating': 4.3,
      'title': 'Amazing',
      'comment': 'Absolutely love the camera quality! Low-light photos look amazing. Battery lasts me all day too.',
      'date': 'Apr, 2025',
      'location': 'Telangana',
      'isVerified': false,
      'images': [
        'assets/icons/iphone_img.png',
        'assets/icons/iphone_img.png',
        'assets/icons/iphone_img.png',
      ],
    },
  ].obs;

  // Review Media (Images and Videos)
  RxList<Map<String, dynamic>> reviewMedia = <Map<String, dynamic>>[
    {
      'type': 'image',
      'url': 'assets/icons/iphone_img.png',
      'thumbnail': 'assets/icons/iphone_img.png',
    },
    {
      'type': 'image',
      'url': 'assets/icons/iphone_img.png',
      'thumbnail': 'assets/icons/iphone_img.png',
    },
    {
      'type': 'video',
      'url': 'assets/icons/iphone_img.png',
      'thumbnail': 'assets/icons/iphone_img.png',
      'duration': '2:30',
    },
    {
      'type': 'image',
      'url': 'assets/icons/iphone_img.png',
      'thumbnail': 'assets/icons/iphone_img.png',
    },
  ].obs;

  // Similar Products
  RxList<Map<String, dynamic>> similarProducts = <Map<String, dynamic>>[
    {
      'id': '1',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50%',
      'seller': 'Pervez Mobile Shop',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.grey[200],
    },
    {
      'id': '2',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50%',
      'seller': 'Pervez Mobile Shop',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.blue[100],
    },
    {
      'id': '3',
      'name': 'Apple iPhone',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50%',
      'seller': 'Pervez Mobile',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.purple[100],
    },
    {
      'id': '4',
      'name': 'Apple iPhone 16',
      'currentPrice': '₹61,499',
      'originalPrice': '₹98,000',
      'discount': '50%',
      'seller': 'Pervez Mobile Shop',
      'rating': '4.8',
      'reviews': '48',
      'image': 'assets/icons/iphone_img.png',
      'imageColor': Colors.teal[100],
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    // Create a unique GlobalKey for this instance
    formKey = GlobalKey<FormState>();
    
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
  }

  // Image Carousel Methods
  void changeImage(int index) {
    currentImageIndex.value = index;
  }

  void nextImage() {
    if (currentImageIndex.value < productImages.length - 1) {
      currentImageIndex.value++;
    }
  }

  void previousImage() {
    if (currentImageIndex.value > 0) {
      currentImageIndex.value--;
    }
  }

  // Color Selection
  void selectColor(String colorName) {
    for (var color in availableColors) {
      color['isSelected'] = color['name'] == colorName;
    }
    selectedColor.value = colorName;
    availableColors.refresh();
  }

  // Storage Selection
  void selectStorage(String capacity) {
    for (var storage in storageOptions) {
      storage['isSelected'] = storage['capacity'] == capacity;
    }
    selectedStorage.value = capacity;
    storageOptions.refresh();
    
    // Update price based on storage
    final selectedStorageOption = storageOptions.firstWhere((storage) => storage['capacity'] == capacity);
    productDetails['currentPrice'] = selectedStorageOption['price'];
    productDetails.refresh();
  }

  // Wishlist Toggle
  void toggleWishlist() {
    isWishlisted.value = !isWishlisted.value;
    productDetails['isWishlisted'] = isWishlisted.value;
    productDetails.refresh();

    commonSnackBar(message: isWishlisted.value ? 'Added to Wishlist' : 'Removed from Wishlist');
  }

  // Add to Cart
  void addToCart() {
    productDetails['isAddedToCart'] = true;
    productDetails.refresh();
    
commonSnackBar(message: "Add to cart");
  }

  // Buy Now
  void buyNow() {
    commonSnackBar(message: "Buy Now");
  }

  // Share Product
  void shareProduct() {
   commonSnackBar(message: "share product");
  }

  // Edit Delivery Address
  void editDeliveryAddress() {
commonSnackBar(message: "edit address");
  }

  // View All Reviews
  void viewAllReviews() {
   commonSnackBar(message: "View all reviews");
  }

  // View Product Images
  void viewProductImages() {
    commonSnackBar(message: "view images");
  }

  // Get Selected Storage Price
  String get selectedStoragePrice {
    final selectedStorageOption = storageOptions.firstWhere((storage) => storage['isSelected'] == true);
    return selectedStorageOption['price'];
  }

  // Get Selected Color
  Map<String, dynamic> get selectedColorOption {
    return availableColors.firstWhere((color) => color['isSelected'] == true);
  }

  // Get Selected Storage
  Map<String, dynamic> get selectedStorageOption {
    return storageOptions.firstWhere((storage) => storage['isSelected'] == true);
  }

  // Calculate Discount Percentage
  double get discountPercentage {
    final currentPrice = double.tryParse(productDetails['currentPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    final originalPrice = double.tryParse(productDetails['originalPrice'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    if (originalPrice > 0) {
      return ((originalPrice - currentPrice) / originalPrice * 100).roundToDouble();
    }
    return 0;
  }

  // Get Average Rating
  double get averageRating {
    if (reviews.isEmpty) return 0;
    final totalRating = reviews.fold(0.0, (sum, review) => sum + review['rating']);
    return (totalRating / reviews.length).roundToDouble();
  }

  // Get Total Reviews Count
  int get totalReviewsCount {
    return reviews.length;
  }
} 