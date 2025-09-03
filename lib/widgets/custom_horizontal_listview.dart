import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CustomHorizontalListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool? primary;
  final ScrollController? controller;
  final double? height;
  final double? itemWidth;
  final double spacing;
  final bool showScrollIndicator;

  const CustomHorizontalListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.primary,
    this.controller,
    this.height,
    this.itemWidth,
    this.spacing = 12.0,
    this.showScrollIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        key: key,
        padding: padding,
        physics: physics ?? const BouncingScrollPhysics(),
        primary: primary,
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) => SizedBox(
          width: itemWidth,
          child: itemBuilder(context, items[index], index),
        ),
        separatorBuilder: (context, index) => SizedBox(width: spacing),
      ),
    );
  }
}

// Specialized version for product cards
class ProductHorizontalListView extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool? primary;
  final ScrollController? controller;
  final double? height;
  final double? itemWidth;
  final double spacing;
  final Function(Map<String, dynamic> product)? onProductTap;

  const ProductHorizontalListView({
    super.key,
    required this.products,
    this.padding,
    this.physics,
    this.primary,
    this.controller,
    this.height = 280,
    this.itemWidth = 160,
    this.spacing = 12.0,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomHorizontalListView<Map<String, dynamic>>(
      key: key,
      items: products,
      height: height,
      itemWidth: itemWidth,
      spacing: spacing,
      padding: padding,
      physics: physics,
      primary: primary,
      controller: controller,
      itemBuilder: (context, product, index) => _buildProductCard(context, product),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => onProductTap?.call(product),
      child: Container(
        width: itemWidth,
        decoration: BoxDecoration(
          color: Colors.white,
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product['name'] ?? 'Product Name',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Current Price
                  Text(
                    product['currentPrice'] ?? '₹0',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Discount Info
                  if (product['originalPrice'] != null)
                    Row(
                      children: [
                        Text(
                          '${product['discount'] ?? 0}% Off ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          product['originalPrice'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Seller Info
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product['seller'] ?? 'Seller Name',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${product['rating'] ?? '0.0'} (${product['reviews'] ?? '0'} reviews)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Specialized version for store cards
class StoreHorizontalListView extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool? primary;
  final ScrollController? controller;
  final double? height;
  final double? itemWidth;
  final double spacing;
  final Function(Map<String, dynamic> store)? onStoreTap;

  const StoreHorizontalListView({
    super.key,
    required this.stores,
    this.padding,
    this.physics,
    this.primary,
    this.controller,
    this.height = 200,
    this.itemWidth = 200,
    this.spacing = 12.0,
    this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomHorizontalListView<Map<String, dynamic>>(
      key: key,
      items: stores,
      height: height,
      itemWidth: itemWidth,
      spacing: spacing,
      padding: padding,
      physics: physics,
      primary: primary,
      controller: controller,
      itemBuilder: (context, store, index) => _buildStoreCard(context, store),
    );
  }

  Widget _buildStoreCard(BuildContext context, Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () => onStoreTap?.call(store),
      child: Container(
        width: itemWidth,
        decoration: BoxDecoration(
          color: Colors.white,
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
            // Store Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: store['imageColor'] ?? Colors.grey[200],
                ),
                child: store['image'] != null
                    ? Image.asset(
                        store['image'],
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.store,
                        size: 40,
                        color: Colors.grey[600],
                      ),
              ),
            ),

            // Store Tag
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),border: Border.all(color: AppColors.primaryColor)
                ),
                child: Text(
                  store['tag'] ?? 'Store',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Store Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Name
                  Text(
                    store['name'] ?? 'Store Name',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // const SizedBox(height: 4),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${store['rating'] ?? '0.0'} (${store['reviews'] ?? '0'})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Status
                  Text(
                    store['status'] ?? 'Status',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Address
                  Text(
                    store['address'] ?? 'Address',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Specialized version for service cards
class ServiceHorizontalListView extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool? primary;
  final ScrollController? controller;
  final double? height;
  final double? itemWidth;
  final double spacing;
  final Function(Map<String, dynamic> service)? onServiceTap;

  const ServiceHorizontalListView({
    super.key,
    required this.services,
    this.padding,
    this.physics,
    this.primary,
    this.controller,
    this.height = 200,
    this.itemWidth = 160,
    this.spacing = 12.0,
    this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomHorizontalListView<Map<String, dynamic>>(
      key: key,
      items: services,
      height: height,
      itemWidth: itemWidth,
      spacing: spacing,
      padding: padding,
      physics: physics,
      primary: primary,
      controller: controller,
      itemBuilder: (context, service, index) => _buildServiceCard(context, service),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => onServiceTap?.call(service),
      child: Container(
        width: itemWidth,
        // margin: const EdgeInsets.only(bottom: 12), // Avoid bottom overflow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // <-- prevent forced full height
          children: [
            // Service Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                color: service['imageColor'] ?? Colors.grey[200],
                child: service['image'] != null
                    ? Image.asset(
                  service['image'],
                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Tag
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['tag'] ?? 'Service',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Service Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Provider Name
                  Text(
                    service['name'] ?? 'Service Provider',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${service['rating'] ?? '0.0'} (${service['reviews'] ?? '0'})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Address
                  Text(
                    service['address'] ?? 'Address',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 