import 'package:BlueEra/core/constants/app_enum.dart';

class ConsumerTiffinResponseModel {
  final bool success;
  final ConsumerTiffinPagination? pagination;
  final List<ConsumerTiffinItem> items;

  const ConsumerTiffinResponseModel({
    this.success = false,
    this.pagination,
    this.items = const [],
  });

  factory ConsumerTiffinResponseModel.fromJson(Map<String, dynamic> json) {
    return ConsumerTiffinResponseModel(
      success: json['success'] ?? false,
      pagination: json['pagination'] != null
          ? ConsumerTiffinPagination.fromJson(json['pagination'])
          : null,
      items: (json['data'] as List? ?? [])
          .map((e) => ConsumerTiffinItem.fromJson(e))
          .toList(),
    );
  }
}

class ConsumerTiffinPagination {
  final int totalCount;
  final int page;
  final int limit;
  final int totalPages;

  const ConsumerTiffinPagination({
    this.totalCount = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory ConsumerTiffinPagination.fromJson(Map<String, dynamic> json) {
    return ConsumerTiffinPagination(
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class ConsumerTiffinItem {
  final String? id;
  final String? userId;
  final MealType mealType;
  final String tiffinName;
  final String centerName;
  final String mrpPrice;
  final String sellingPrice;
  final String foodType;
  final String cookingMethod;
  final List<String> images;
  final String startTime;
  final String endTime;
  final bool isActive;
  final double? lat;
  final double? lng;
  final String? createdAt;

  /// Store/kitchen details — sourced from the nested `earnProfile` object.
  final String storeName;
  final String address;
  final String? storeLogo;
  final bool homeDelivery;
  final bool monthlyPayment;
  final double? storeLat;
  final double? storeLng;

  const ConsumerTiffinItem({
    this.id,
    this.userId,
    required this.mealType,
    this.tiffinName = '',
    this.centerName = '',
    this.mrpPrice = '',
    this.sellingPrice = '',
    this.foodType = '',
    this.cookingMethod = '',
    this.images = const [],
    this.startTime = '',
    this.endTime = '',
    this.isActive = false,
    this.lat,
    this.lng,
    this.createdAt,
    this.storeName = '',
    this.address = '',
    this.storeLogo,
    this.homeDelivery = false,
    this.monthlyPayment = false,
    this.storeLat,
    this.storeLng,
  });

  String? get imageUrl => images.isNotEmpty ? images.first : null;

  factory ConsumerTiffinItem.fromJson(Map<String, dynamic> json) {
    final coords = json['location']?['coordinates'] as List?;

    // Store/kitchen info lives in the nested `earnProfile` object.
    final earnProfile = json['earnProfile'] as Map<String, dynamic>?;
    final storeCoords = earnProfile?['location']?['coordinates'] as List?;
    final serviceName = earnProfile?['serviceName'] ?? json['centerName'] ?? '';

    return ConsumerTiffinItem(
      id: json['_id'],
      userId: json['userId'],
      mealType: MealType.fromKey(json['tiffinKey']),
      tiffinName: json['tiffinName'] ?? '',
      centerName: serviceName,
      mrpPrice: '${json['mrp'] ?? ''}',
      sellingPrice: '${json['sellingPrice'] ?? ''}',
      foodType: json['foodType'] ?? '',
      cookingMethod: json['cookingMethod'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      startTime: json['tiffinTiming']?['start'] ?? '',
      endTime: json['tiffinTiming']?['end'] ?? '',
      isActive: json['isActive'] ?? false,
      lng: coords != null && coords.length > 0
          ? (coords[0] as num?)?.toDouble()
          : null,
      lat: coords != null && coords.length > 1
          ? (coords[1] as num?)?.toDouble()
          : null,
      createdAt: json['createdAt'],
      storeName: serviceName,
      address: earnProfile?['address'] ?? '',
      storeLogo: earnProfile?['serviceLogo'],
      homeDelivery: earnProfile?['homeDelivery'] ?? false,
      monthlyPayment: earnProfile?['monthlyPayment'] ?? false,
      storeLng: storeCoords != null && storeCoords.isNotEmpty
          ? (storeCoords[0] as num?)?.toDouble()
          : null,
      storeLat: storeCoords != null && storeCoords.length > 1
          ? (storeCoords[1] as num?)?.toDouble()
          : null,
    );
  }
}
