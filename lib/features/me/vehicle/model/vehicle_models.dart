/// Domain models for the BlueEra vehicle service
/// (`vehicle-service/...` endpoints).
///
/// Mirrors `lib/docs/FLUTTER_INTEGRATION_GUIDE.md` § 2 — every model
/// exposes `fromJson`, `toJson` / `toCreateJson` and only emits
/// non-null fields when serialising for create/update calls so the
/// server can apply partial updates without nulling existing values.
library;

// ─────────────────────────────────────────────────────────────────────
// Common building blocks
// ─────────────────────────────────────────────────────────────────────

class VehicleLocation {
  final double? lat;
  final double? lon;
  final String? address;
  final String? city;
  final String? state;
  final int? pincode;

  VehicleLocation({
    this.lat,
    this.lon,
    this.address,
    this.city,
    this.state,
    this.pincode,
  });

  factory VehicleLocation.fromJson(Map<String, dynamic> j) => VehicleLocation(
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        address: j['address'] as String?,
        city: j['city'] as String?,
        state: j['state'] as String?,
        pincode: (j['pincode'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
      };
}

class VehiclePhoneNumber {
  final int? pre; // country code, default 91
  final String? number;

  VehiclePhoneNumber({this.pre, this.number});

  factory VehiclePhoneNumber.fromJson(Map<String, dynamic> j) =>
      VehiclePhoneNumber(
        pre: (j['pre'] as num?)?.toInt(),
        number: j['number'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (pre != null) 'pre': pre,
        if (number != null) 'number': number,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Vehicle
// ─────────────────────────────────────────────────────────────────────

enum VehicleFuelType { petrol, diesel, electric, cng, hybrid, other }

enum VehicleTransmission { manual, automatic, amt, cvt }

extension VehicleFuelTypeWire on VehicleFuelType {
  String get wire => name.toUpperCase();
  static VehicleFuelType? parse(String? s) {
    if (s == null) return null;
    return VehicleFuelType.values.firstWhere(
      (e) => e.wire == s.toUpperCase(),
      orElse: () => VehicleFuelType.other,
    );
  }
}

extension VehicleTransmissionWire on VehicleTransmission {
  String get wire => name.toUpperCase();
  static VehicleTransmission? parse(String? s) {
    if (s == null) return null;
    try {
      return VehicleTransmission.values
          .firstWhere((e) => e.wire == s.toUpperCase());
    } catch (_) {
      return null;
    }
  }
}

class Vehicle {
  final String? id;
  final String? userId;
  final String? businessId;
  final String name;
  final String? description;
  final String? category; // e.g. CAR / BIKE / TRUCK
  final String? subCategory; // e.g. SUV / Sedan
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? registrationNo;
  final VehicleFuelType? fuelType;
  final VehicleTransmission? transmission;
  final int? seatingCapacity;
  final String? mileage;
  final double? price;
  final String? currency;
  final VehicleLocation? location;
  final String? coverImage;
  final List<String> images;
  final bool? isActive;
  final bool? isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Owner profile when hydrated by the server (gRPC enrichment).
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? business;

  Vehicle({
    this.id,
    this.userId,
    this.businessId,
    required this.name,
    this.description,
    this.category,
    this.subCategory,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.registrationNo,
    this.fuelType,
    this.transmission,
    this.seatingCapacity,
    this.mileage,
    this.price,
    this.currency,
    this.location,
    this.coverImage,
    this.images = const [],
    this.isActive,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.business,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        category: j['category'] as String?,
        subCategory: j['sub_category'] as String?,
        brand: j['brand'] as String?,
        model: j['model'] as String?,
        year: (j['year'] as num?)?.toInt(),
        color: j['color'] as String?,
        registrationNo: j['registration_no'] as String?,
        fuelType: VehicleFuelTypeWire.parse(j['fuel_type'] as String?),
        transmission:
            VehicleTransmissionWire.parse(j['transmission'] as String?),
        seatingCapacity: (j['seating_capacity'] as num?)?.toInt(),
        mileage: j['mileage'] as String?,
        price: (j['price'] as num?)?.toDouble(),
        currency: j['currency'] as String?,
        location: j['location'] is Map<String, dynamic>
            ? VehicleLocation.fromJson(
                Map<String, dynamic>.from(j['location'] as Map))
            : null,
        coverImage: j['cover_image'] as String?,
        images:
            ((j['images'] as List?) ?? const []).whereType<String>().toList(),
        isActive: j['is_active'] as bool?,
        isVerified: j['is_verified'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
        user: j['user'] is Map
            ? Map<String, dynamic>.from(j['user'] as Map)
            : null,
        business: j['business'] is Map
            ? Map<String, dynamic>.from(j['business'] as Map)
            : null,
      );

  /// Wire payload for create / update — only sends provided keys.
  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (subCategory != null) 'sub_category': subCategory,
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
        if (year != null) 'year': year,
        if (color != null) 'color': color,
        if (registrationNo != null) 'registration_no': registrationNo,
        if (fuelType != null) 'fuel_type': fuelType!.wire,
        if (transmission != null) 'transmission': transmission!.wire,
        if (seatingCapacity != null) 'seating_capacity': seatingCapacity,
        if (mileage != null) 'mileage': mileage,
        if (price != null) 'price': price,
        if (currency != null) 'currency': currency,
        if (location != null) 'location': location!.toJson(),
        if (coverImage != null) 'cover_image': coverImage,
        if (images.isNotEmpty) 'images': images,
        if (businessId != null) 'business_id': businessId,
      };
}

class PaginatedVehicles {
  final List<Vehicle> vehicles;
  final int page;
  final int limit;
  final int total;

  PaginatedVehicles({
    required this.vehicles,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PaginatedVehicles.fromJson(Map<String, dynamic> j) =>
      PaginatedVehicles(
        vehicles: ((j['vehicles'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => Vehicle.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        page: (j['page'] as num?)?.toInt() ?? 1,
        limit: (j['limit'] as num?)?.toInt() ?? 20,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );

  bool get hasMore => vehicles.length + ((page - 1) * limit) < total;
}

// ─────────────────────────────────────────────────────────────────────
// Facility
// ─────────────────────────────────────────────────────────────────────

class VehicleFacility {
  final String? id;
  final String? userId;
  final String? businessId;
  final String name;
  final String? description;
  final String? icon;
  final String? image;
  final String? type;
  final bool? isActive;
  final int? sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleFacility({
    this.id,
    this.userId,
    this.businessId,
    required this.name,
    this.description,
    this.icon,
    this.image,
    this.type,
    this.isActive,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleFacility.fromJson(Map<String, dynamic> j) => VehicleFacility(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        icon: j['icon'] as String?,
        image: j['image'] as String?,
        type: j['type'] as String?,
        isActive: j['is_active'] as bool?,
        sortOrder: (j['sort_order'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (image != null) 'image': image,
        if (type != null) 'type': type,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Live photo
// ─────────────────────────────────────────────────────────────────────

class VehicleLivePhotoLocation {
  final double? lat;
  final double? lon;

  VehicleLivePhotoLocation({this.lat, this.lon});

  factory VehicleLivePhotoLocation.fromJson(Map<String, dynamic> j) =>
      VehicleLivePhotoLocation(
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };
}

class VehicleLivePhoto {
  final String? id;
  final String? userId;
  final String? businessId;
  final String imageUrl;
  final String? caption;
  final DateTime? capturedAt;
  final VehicleLivePhotoLocation? location;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleLivePhoto({
    this.id,
    this.userId,
    this.businessId,
    required this.imageUrl,
    this.caption,
    this.capturedAt,
    this.location,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleLivePhoto.fromJson(Map<String, dynamic> j) => VehicleLivePhoto(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        imageUrl: (j['image_url'] ?? '') as String,
        caption: j['caption'] as String?,
        capturedAt: DateTime.tryParse(j['captured_at']?.toString() ?? ''),
        location: j['location'] is Map
            ? VehicleLivePhotoLocation.fromJson(
                Map<String, dynamic>.from(j['location'] as Map))
            : null,
        isActive: j['is_active'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'image_url': imageUrl,
        if (caption != null) 'caption': caption,
        if (capturedAt != null)
          'captured_at': capturedAt!.toUtc().toIso8601String(),
        if (location != null) 'location': location!.toJson(),
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Gallery item
// ─────────────────────────────────────────────────────────────────────

enum VehicleMediaType { image, video }

extension VehicleMediaTypeWire on VehicleMediaType {
  String get wire => name.toUpperCase();
  static VehicleMediaType parse(String? s) {
    if (s?.toUpperCase() == 'VIDEO') return VehicleMediaType.video;
    return VehicleMediaType.image;
  }
}

class VehicleGalleryItem {
  final String? id;
  final String? userId;
  final String? businessId;
  final String? album; // default "default"
  final String? title;
  final String? description;
  final VehicleMediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int? sortOrder;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleGalleryItem({
    this.id,
    this.userId,
    this.businessId,
    this.album,
    this.title,
    this.description,
    this.mediaType = VehicleMediaType.image,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.sortOrder,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleGalleryItem.fromJson(Map<String, dynamic> j) =>
      VehicleGalleryItem(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        album: j['album'] as String?,
        title: j['title'] as String?,
        description: j['description'] as String?,
        mediaType: VehicleMediaTypeWire.parse(j['media_type'] as String?),
        mediaUrl: (j['media_url'] ?? '') as String,
        thumbnailUrl: j['thumbnail_url'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt(),
        isActive: j['is_active'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'media_url': mediaUrl,
        'media_type': mediaType.wire,
        if (album != null) 'album': album,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Testimonial
// ─────────────────────────────────────────────────────────────────────

class VehicleTestimonial {
  final String? id;
  final String toUser;
  final String? fromUser;
  final String? businessId;
  final String title;
  final String description;
  final double? rating; // 0..5
  final String? image;
  final bool? isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Hydrated by server on read endpoints.
  final Map<String, dynamic>? from;
  final Map<String, dynamic>? fromBusiness;

  VehicleTestimonial({
    this.id,
    required this.toUser,
    this.fromUser,
    this.businessId,
    required this.title,
    required this.description,
    this.rating,
    this.image,
    this.isVisible,
    this.createdAt,
    this.updatedAt,
    this.from,
    this.fromBusiness,
  });

  factory VehicleTestimonial.fromJson(Map<String, dynamic> j) =>
      VehicleTestimonial(
        id: j['_id'] as String?,
        toUser: (j['toUser'] ?? '') as String,
        fromUser: j['fromUser'] as String?,
        businessId: j['business_id'] as String?,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        rating: (j['rating'] as num?)?.toDouble(),
        image: j['image'] as String?,
        isVisible: j['is_visible'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
        from: j['from'] is Map
            ? Map<String, dynamic>.from(j['from'] as Map)
            : null,
        fromBusiness: j['from_business'] is Map
            ? Map<String, dynamic>.from(j['from_business'] as Map)
            : null,
      );

  Map<String, dynamic> toCreateJson() => {
        'toUser': toUser,
        'title': title,
        'description': description,
        if (rating != null) 'rating': rating,
        if (image != null) 'image': image,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Contact us
// ─────────────────────────────────────────────────────────────────────

class VehicleContact {
  final String? id;
  final String? userId;
  final String? businessId;
  final String locationName;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final int? pincode;
  final double? lat;
  final double? lon;
  final VehiclePhoneNumber? phoneNumber;
  final VehiclePhoneNumber? alternatePhoneNumber;
  final String? email;
  final String? website;
  final String? openingHours;
  final String? mapLink;
  final bool? isPrimary;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleContact({
    this.id,
    this.userId,
    this.businessId,
    required this.locationName,
    this.address,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.lat,
    this.lon,
    this.phoneNumber,
    this.alternatePhoneNumber,
    this.email,
    this.website,
    this.openingHours,
    this.mapLink,
    this.isPrimary,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleContact.fromJson(Map<String, dynamic> j) => VehicleContact(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        locationName: (j['location_name'] ?? '') as String,
        address: j['address'] as String?,
        city: j['city'] as String?,
        state: j['state'] as String?,
        country: j['country'] as String?,
        pincode: (j['pincode'] as num?)?.toInt(),
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        phoneNumber: j['phone_number'] is Map
            ? VehiclePhoneNumber.fromJson(
                Map<String, dynamic>.from(j['phone_number'] as Map))
            : null,
        alternatePhoneNumber: j['alternate_phone_number'] is Map
            ? VehiclePhoneNumber.fromJson(
                Map<String, dynamic>.from(j['alternate_phone_number'] as Map))
            : null,
        email: j['email'] as String?,
        website: j['website'] as String?,
        openingHours: j['opening_hours'] as String?,
        mapLink: j['map_link'] as String?,
        isPrimary: j['is_primary'] as bool?,
        isActive: j['is_active'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'location_name': locationName,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (pincode != null) 'pincode': pincode,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        if (phoneNumber != null) 'phone_number': phoneNumber!.toJson(),
        if (alternatePhoneNumber != null)
          'alternate_phone_number': alternatePhoneNumber!.toJson(),
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (openingHours != null) 'opening_hours': openingHours,
        if (mapLink != null) 'map_link': mapLink,
        if (isPrimary != null) 'is_primary': isPrimary,
        if (isActive != null) 'is_active': isActive,
        if (businessId != null) 'business_id': businessId,
      };
}

// ─────────────────────────────────────────────────────────────────────
// S3 presigned upload
// ─────────────────────────────────────────────────────────────────────

class VehicleUploadInit {
  final String uploadUrl; // S3 presigned PUT URL — 30 min validity
  final String publicUrl; // public URL to persist on the entity
  final String fileKey; // S3 object key

  VehicleUploadInit({
    required this.uploadUrl,
    required this.publicUrl,
    required this.fileKey,
  });

  factory VehicleUploadInit.fromJson(Map<String, dynamic> j) =>
      VehicleUploadInit(
        uploadUrl: (j['uploadUrl'] ?? '') as String,
        publicUrl: (j['publicUrl'] ?? '') as String,
        fileKey: (j['fileKey'] ?? '') as String,
      );
}
