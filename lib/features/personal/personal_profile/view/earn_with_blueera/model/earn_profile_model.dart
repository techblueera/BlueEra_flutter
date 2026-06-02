/// Top-level response for GET `/earn-service/earn-profiles/user/{userId}`.
///
/// Shape:
/// ```json
/// {
///   "success": true,
///   "data": { ... EarnProfileModel ... },
///   "uploadUrls": { "serviceLogo": ..., "coverImage": ..., "galleryImages": [...] }
/// }
/// ```
class EarnProfileResponse {
  final bool success;
  final EarnProfileModel? data;
  final EarnProfileUploadUrls? uploadUrls;

  const EarnProfileResponse({
    this.success = false,
    this.data,
    this.uploadUrls,
  });

  factory EarnProfileResponse.fromJson(Map<String, dynamic> json) {
    return EarnProfileResponse(
      success: json['success'] ?? false,
      data: json['data'] is Map<String, dynamic>
          ? EarnProfileModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      uploadUrls: json['uploadUrls'] is Map<String, dynamic>
          ? EarnProfileUploadUrls.fromJson(
              json['uploadUrls'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Response for `GET earn-service/earn-profiles?profileType=...` — a flat list
/// of earn-profile objects (the store/kitchen/provider profiles) plus
/// pagination. Used by the Discover home-made-food / product / service lists.
class EarnProfilesListResponse {
  final bool success;
  final List<EarnProfileModel> data;
  final EarnProfilePagination? pagination;

  const EarnProfilesListResponse({
    this.success = false,
    this.data = const [],
    this.pagination,
  });

  factory EarnProfilesListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    return EarnProfilesListResponse(
      success: json['success'] ?? false,
      data: rawList is List
          ? rawList
              .whereType<Map<String, dynamic>>()
              .map(EarnProfileModel.fromJson)
              .toList()
          : const [],
      pagination: json['pagination'] is Map<String, dynamic>
          ? EarnProfilePagination.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pagination metadata for earn-profile / home-food list responses.
class EarnProfilePagination {
  final int totalCount;
  final int page;
  final int limit;
  final int totalPages;

  const EarnProfilePagination({
    this.totalCount = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory EarnProfilePagination.fromJson(Map<String, dynamic> json) {
    return EarnProfilePagination(
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class EarnProfileUploadUrls {
  final String? serviceLogo;
  final String? coverImage;
  final List<String> galleryImages;

  const EarnProfileUploadUrls({
    this.serviceLogo,
    this.coverImage,
    this.galleryImages = const [],
  });

  factory EarnProfileUploadUrls.fromJson(Map<String, dynamic> json) {
    return EarnProfileUploadUrls(
      serviceLogo: json['serviceLogo']?.toString(),
      coverImage: json['coverImage']?.toString(),
      galleryImages: (json['galleryImages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class EarnProfileModel {
  final String? id;
  final String? userId;
  final String? serviceName;
  final String? foodType;
  final String? profileType;
  final String? address;
  final String? houseNumber;
  final String? alternatePhoneNumber;
  final String? email;
  final String? website;
  final bool homeDelivery;
  final bool monthlyPayment;
  final String? serviceLogo;
  final String? coverImage;
  final List<String> galleryImages;
  final bool isActive;

  /// GeoJSON location — server sends `{ type: "Point", coordinates: [lng, lat] }`.
  /// Index 0 = longitude, index 1 = latitude.
  final List<double> coordinates;
  final String? locationType;

  double? get longitude =>
      coordinates.isNotEmpty ? coordinates[0] : null;
  double? get latitude =>
      coordinates.length > 1 ? coordinates[1] : null;

  final String? createdAt;
  final String? updatedAt;
  final int version;

  // Optional counters (not in current API, default 0 so UI doesn't break).
  final int totalViews;
  final int totalInquiries;
  final int totalFollowers;
  final int totalFollowing;

  const EarnProfileModel({
    this.id,
    this.userId,
    this.serviceName,
    this.foodType,
    this.profileType,
    this.address,
    this.houseNumber,
    this.alternatePhoneNumber,
    this.email,
    this.website,
    this.homeDelivery = false,
    this.monthlyPayment = false,
    this.serviceLogo,
    this.coverImage,
    this.galleryImages = const [],
    this.isActive = true,
    this.coordinates = const [],
    this.locationType,
    this.createdAt,
    this.updatedAt,
    this.version = 0,
    this.totalViews = 0,
    this.totalInquiries = 0,
    this.totalFollowers = 0,
    this.totalFollowing = 0,
  });

  factory EarnProfileModel.fromJson(Map<String, dynamic> json) {
    // GeoJSON "Point" — coordinates are stored as [longitude, latitude].
    String? locationType;
    List<double> coordinates = const [];
    final loc = json['location'];
    if (loc is Map) {
      locationType = loc['type']?.toString();
      final coords = loc['coordinates'];
      if (coords is List) {
        coordinates = coords
            .map((e) => (e as num?)?.toDouble())
            .whereType<double>()
            .toList();
      }
    }

    return EarnProfileModel(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString(),
      serviceName: json['serviceName']?.toString(),
      foodType: json['foodType']?.toString(),
      profileType: json['profileType']?.toString(),
      address: json['address']?.toString(),
      houseNumber: json['houseNumber']?.toString(),
      alternatePhoneNumber: json['alternatePhoneNumber']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      homeDelivery: json['homeDelivery'] ?? false,
      monthlyPayment: json['monthlyPayment'] ?? false,
      serviceLogo: json['serviceLogo']?.toString(),
      coverImage: json['coverImage']?.toString(),
      galleryImages: (json['galleryImages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isActive: json['isActive'] ?? true,
      coordinates: coordinates,
      locationType: locationType,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      version: (json['__v'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      totalInquiries: (json['totalInquiries'] as num?)?.toInt() ?? 0,
      totalFollowers: (json['totalFollowers'] as num?)?.toInt() ?? 0,
      totalFollowing: (json['totalFollowing'] as num?)?.toInt() ?? 0,
    );
  }
}
