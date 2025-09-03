import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'product_details_screen_controller.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});

  // Helper method to create widget lists
  List<Widget> _generateWidgets(int count, Widget Function(int) builder) {
    return List.generate(count, builder).cast<Widget>();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductDetailsScreenController>(
      init: ProductDetailsScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header Section with Search Bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fillColor,
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.black,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 45,
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.greyE5,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: AppColors.grey9B,
                                size: 20,
                              ),
                              SizedBox(width: SizeConfig.size8),
                              Expanded(
                                child: TextField(
                                  controller: controller.searchController,
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 14,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'iphone 16...',
                                    hintStyle: TextStyle(
                                      color: AppColors.grey9B,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image Section
                        _buildProductImageSection(controller),
                        
                        SizedBox(height: SizeConfig.size16),

                        // Product Details Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Name
                              CustomText(
                                controller.productDetails['name'],
                                fontSize: SizeConfig.medium15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                              
                              SizedBox(height: SizeConfig.size12),
                              
                              // Price Section
                              Row(
                                children: [
                                  CustomText(
                                    controller.productDetails['currentPrice'],
                                    fontSize: SizeConfig.large18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                  SizedBox(width: SizeConfig.size8),
                                  CustomText(
                                    '${controller.productDetails['discount']} ${controller.productDetails['originalPrice']}',
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.grey9B,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: SizeConfig.size8),
                              
                              // Rating Section
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: SizeConfig.size4),
                                  CustomText(
                                    controller.productDetails['rating'],
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black,
                                  ),
                                  SizedBox(width: SizeConfig.size4),
                                  CustomText(
                                    controller.productDetails['reviews'],
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.grey9B,
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: SizeConfig.size20),

                              // Available Colors Section
                              _buildAvailableColorsSection(controller),
                              
                              SizedBox(height: SizeConfig.size20),

                              // Storage Options Section
                              _buildStorageOptionsSection(controller),
                              
                              SizedBox(height: SizeConfig.size20),

                              // Delivery Address Section
                              _buildDeliveryAddressSection(controller),
                              
                              SizedBox(height: SizeConfig.size20),

                              // About Shop Section
                              _buildAboutShopSection(controller),
                              
                              SizedBox(height: SizeConfig.size16),

                              // Product Highlights Section
                              _buildProductHighlightsSection(controller),
                              
                              SizedBox(height: SizeConfig.size16),

                              // Other Details Section
                              _buildOtherDetailsSection(controller),
                              
                              SizedBox(height: SizeConfig.size20),

                              // Ratings & Reviews Section
                              _buildRatingsAndReviewsSection(controller),
                              
                              SizedBox(height: SizeConfig.size20),

                              // Similar Products Section
                              _buildSimilarProductsSection(controller),
                              
                              SizedBox(height: SizeConfig.size20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                _buildBottomActionBar(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImageSection(ProductDetailsScreenController controller) {
    return Container(
      height: 300,
      child: Stack(
        children: [
          // Main Product Image
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.fillColor,
            ),
            child: Obx(() => PageView.builder(
              itemCount: controller.productImages.length,
              onPageChanged: controller.changeImage,
              itemBuilder: (context, index) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: controller.productImages[index] != null 
                        ? Colors.transparent 
                        : Colors.grey[200],
                  ),
                  child: controller.productImages[index] != null
                      ? Image.asset(
                          controller.productImages[index],
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          Icons.phone_android,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                );
              },
            )),
          ),
          
          // Wishlist Icon Overlay
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: controller.toggleWishlist,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() => Icon(
                  controller.isWishlisted.value 
                      ? Icons.favorite 
                      : Icons.favorite_border,
                  color: controller.isWishlisted.value 
                      ? Colors.red 
                      : AppColors.black,
                  size: 18,
                )),
              ),
            ),
          ),
          
          // Image Carousel Dots
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _generateWidgets(
                controller.productImages.length,
                (index) => Obx(() => Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.currentImageIndex.value == index
                        ? AppColors.black
                        : AppColors.grey9B,
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableColorsSection(ProductDetailsScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Available Colors:',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size12),
        Wrap(
          spacing: SizeConfig.size12,
          children: controller.availableColors.map((color) => GestureDetector(
            onTap: () => controller.selectColor(color['name']),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size8,
              ),
              decoration: BoxDecoration(
                color: color['isSelected'] ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color['isSelected'] ? AppColors.primaryColor : AppColors.greyE5,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    color['name'],
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: color['isSelected'] ? AppColors.primaryColor : AppColors.black,
                  ),
                ],
              ),
            ),
          )).toList().cast<Widget>(),
        ),
      ],
    );
  }

  Widget _buildStorageOptionsSection(ProductDetailsScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Storage Options:',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size12),
        Wrap(
          spacing: SizeConfig.size12,
          children: controller.storageOptions.map((storage) => GestureDetector(
            onTap: () => controller.selectStorage(storage['capacity']),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size8,
              ),
              decoration: BoxDecoration(
                color: storage['isSelected'] ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: storage['isSelected'] ? AppColors.primaryColor : AppColors.greyE5,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  CustomText(
                    storage['capacity'],
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: storage['isSelected'] ? AppColors.primaryColor : AppColors.black,
                  ),
                  CustomText(
                    storage['price'],
                    fontSize: SizeConfig.small,
                    color: storage['isSelected'] ? AppColors.primaryColor : AppColors.grey9B,
                  ),
                ],
              ),
            ),
          )).toList().cast<Widget>(),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(ProductDetailsScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'Delivery Address',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            GestureDetector(
              onTap: controller.editDeliveryAddress,
              child: Icon(
                Icons.edit,
                size: 20,
                color: AppColors.grey9B,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              size: 20,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    controller.deliveryAddress['name'],
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  CustomText(
                    controller.deliveryAddress['address'],
                    fontSize: SizeConfig.medium,
                    color: AppColors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutShopSection(ProductDetailsScreenController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'About Shop',
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size12),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                'Pervez Mobile Shop',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            'Tech Galaxy is a trusted mobile store offers genuine smartphones and accessories. We ensure original pr...',
            fontSize: SizeConfig.small,
            color: AppColors.grey9B,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SizeConfig.size8),
          GestureDetector(
            onTap: () {
              // Handle read more action

            },
            child: CustomText(
              'Read more',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHighlightsSection(ProductDetailsScreenController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Product Highlights:',
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size12),
          Column(
            children: [
              _buildHighlightItem('6.1" Super Retina XDR Display'),
              _buildHighlightItem('Dual 12MP Rear Cameras'),
              _buildHighlightItem('A15 Bionic Chip with 5-core GPU'),
              _buildHighlightItem('All-day Battery Life'),
              _buildHighlightItem('Crash Detection & Emergency SOS'),
              _buildHighlightItem('5G Connectivity'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherDetailsSection(ProductDetailsScreenController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Other Details:',
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size12),
          Column(
            children: [
              _buildDetailItem('In the Box: iPhone 14, USB-C to Lightning Cable, Documentation'),
              _buildDetailItem('Material: Aerospace-grade aluminum edges, Ceramic Shield front'),
              _buildDetailItem('Dimensions: 146.7 x 71.5 x 7.8 mm'),
              _buildDetailItem('Weight: 172 grams'),
              _buildDetailItem('SIM Type: Dual SIM (nano + eSIM)'),
              _buildDetailItem('Charging: MagSafe & Qi wireless charging supported'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.small,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.small,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsAndReviewsSection(ProductDetailsScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Ratings & Reviews',
          fontSize: SizeConfig.medium15,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size16),

        // Media Carousel
        _buildReviewMediaCarousel(controller),
        SizedBox(height: SizeConfig.size20),

        // Individual Reviews
        _buildIndividualReviews(controller),
      ],
    );
  }

  Widget _buildReviewMediaCarousel(ProductDetailsScreenController controller) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.reviewMedia.length,
        itemBuilder: (context, index) {
          final media = controller.reviewMedia[index];
          return Container(
            width: 100,
            margin: EdgeInsets.only(right: SizeConfig.size12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: media['type'] == 'video'
                      ? Container(
                          color: Colors.black,
                          child: Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Image.asset(
                          media['url'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                ),
                if (media['type'] == 'video')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CustomText(
                        'VIDEO',
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndividualReviews(ProductDetailsScreenController controller) {
    return Column(
      children: controller.reviews.map((review) => _buildReviewItem(review)).toList().cast<Widget>(),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating and Title
          Row(
            children: [
              // Star Rating
              Row(
                children: _generateWidgets(5, (index) {
                  if (index < review['rating'].floor()) {
                    return const Icon(Icons.star, size: 16, color: Colors.amber);
                  } else if (index == review['rating'].floor() && review['rating'] % 1 > 0) {
                    return const Icon(Icons.star_half, size: 16, color: Colors.amber);
                  } else {
                    return const Icon(Icons.star_border, size: 16, color: Colors.amber);
                  }
                }),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                review['rating'].toString(),
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),

          // Review Title
          CustomText(
            review['title'],
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size8),

          // Review Comment
          CustomText(
            review['comment'],
            fontSize: SizeConfig.small,
            color: AppColors.black,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SizeConfig.size12),

          // Review Images
          if (review['images'] != null && review['images'].isNotEmpty)
            Row(
              children: review['images'].take(3).map((image) => Container(
                width: 60,
                height: 60,
                margin: EdgeInsets.only(right: SizeConfig.size8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              )).toList().cast<Widget>(),
            ),
          SizedBox(height: SizeConfig.size12),

          // Reviewer Info
          Row(
            children: [
              CustomText(
                review['userName'],
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                ', ${review['location']} ${review['date']}',
                fontSize: SizeConfig.small,
                color: AppColors.grey9B,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductsSection(ProductDetailsScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "See all" button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Similar Products',
                fontSize: SizeConfig.medium15,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              GestureDetector(
                onTap: () {
                  // Handle "See all" action

                },
                child: CustomText(
                  'See all',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size16),

        // Similar Products Horizontal List
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            itemCount: controller.similarProducts.length,
            itemBuilder: (context, index) {
              final product = controller.similarProducts[index];
              return Container(
                width: 160,
                margin: EdgeInsets.only(right: SizeConfig.size12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: product['imageColor'] ?? Colors.grey[200],
                        ),
                        child: product['image'] != null
                            ? Image.asset(
                                product['image'],
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.phone_android,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                      ),
                    ),

                    // Product Details
                    Padding(
                      padding: EdgeInsets.all(SizeConfig.size12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          CustomText(
                            product['name'] ?? 'Product Name',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: SizeConfig.size4),

                          // Current Price
                          CustomText(
                            product['currentPrice'] ?? '₹0',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),

                          SizedBox(height: SizeConfig.size2),

                          // Discount and Original Price
                          Row(
                            children: [
                              CustomText(
                                '${product['discount'] ?? '0%'} Off ',
                                fontSize: SizeConfig.small,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                              CustomText(
                                product['originalPrice'] ?? '₹0',
                                fontSize: SizeConfig.small,
                                color: AppColors.grey9B,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ],
                          ),

                          SizedBox(height: SizeConfig.size8),

                          // Seller Info
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              SizedBox(width: SizeConfig.size4),
                              Expanded(
                                child: CustomText(
                                  product['seller'] ?? 'Seller Name',
                                  fontSize: SizeConfig.small,
                                  color: AppColors.grey9B,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: SizeConfig.size4),

                          // Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber,
                              ),
                              SizedBox(width: SizeConfig.size2),
                              CustomText(
                                '${product['rating'] ?? '0.0'} (${product['reviews'] ?? '0'} reviews)',
                                fontSize: SizeConfig.small,
                                color: AppColors.grey9B,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(ProductDetailsScreenController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Add to Wishlist Button
          Expanded(
            child: GestureDetector(
              onTap: controller.toggleWishlist,
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Obx(() => CustomText(
                    controller.isWishlisted.value ? 'Remove from Wishlist' : 'Add to Wishlist',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  )),
                ),
              ),
            ),
          ),

          SizedBox(width: SizeConfig.size12),

          // Chat Now Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Handle chat action

              },
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomText(
                    'Chat Now',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 