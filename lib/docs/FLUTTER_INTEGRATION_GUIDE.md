# Flutter Integration Guide — `be_vehicle_service`

A complete, drop-in client for every REST endpoint exposed by this microservice.

- **Base URL (prod)**: `https://be.blueera.ai/api/vehicle-service`
- **Base URL (local)**: `http://localhost:3009`
- **Auth**: `Authorization: Bearer <JWT>` — same JWT issued by `be_user_service`.
- **Upload flow**: app calls `GET /upload/init` → backend returns a presigned S3 PUT URL → app `PUT`s the file binary to S3 → uses the returned `publicUrl` in subsequent create/update calls.
- **Response convention**: every JSON response carries a `status: bool` plus a payload field whose key matches the entity (`vehicle`, `vehicles`, `photo`, `photos`, `item`, `items`, `facility`, `facilities`, `contact`, `contacts`, `testimonial`, `testimonials`).
- **Owner-scoped endpoints** (`/me/...`) require auth. **Public endpoints** (`/public/:userId`, `GET /vehicles`, `GET /vehicles/get/:id`, `GET /contact-us/get/:id`, `GET /testimonials/get/:id`) do not.

---

## 1. Setup

### 1.1 `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  dio: ^5.7.0          # used for streaming uploads with progress
  shared_preferences: ^2.3.0
  image_picker: ^1.1.2 # optional, for picking files to upload
  mime: ^1.0.5         # to derive Content-Type from filename
```

### 1.2 Create `lib/api/api_config.dart`

```dart
class ApiConfig {
  // Switch between prod/staging/local here.
  static const String baseUrl = String.fromEnvironment(
    'VEHICLE_SERVICE_BASE_URL',
    defaultValue: 'https://be.blueera.ai/api/vehicle-service',
  );

  // Connect/read timeouts (multipart uploads bypass these).
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

Run with `--dart-define=VEHICLE_SERVICE_BASE_URL=http://10.0.2.2:3009` to point at a local server (Android emulator → `10.0.2.2`; iOS sim → `localhost`).

### 1.3 Token storage — `lib/api/token_store.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _kJwt = 'auth_jwt';

  static Future<void> save(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kJwt, token);
  }

  static Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kJwt);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kJwt);
  }
}
```

### 1.4 HTTP client — `lib/api/api_client.dart`

A thin wrapper around `package:http` that injects the bearer token and decodes JSON. Throws `ApiException` for non-2xx responses so calling code can `try/catch` cleanly.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'token_store.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;
  ApiException(this.statusCode, this.message, [this.body]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final base = '${ApiConfig.baseUrl}/$clean';
    final uri = Uri.parse(base);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  Future<Map<String, String>> _headers({bool auth = true, bool json = true}) async {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (auth) {
      final token = await TokenStore.read();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      body = res.body;
    }
    if (!ok) {
      final msg = (body is Map && body['message'] is String)
          ? body['message'] as String
          : 'HTTP ${res.statusCode}';
      throw ApiException(res.statusCode, msg, body);
    }
    return body;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final res = await http
        .get(_u(path, query), headers: await _headers(auth: auth, json: false))
        .timeout(ApiConfig.receiveTimeout);
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final res = await http
        .post(_u(path), headers: await _headers(auth: auth), body: body == null ? null : jsonEncode(body))
        .timeout(ApiConfig.receiveTimeout);
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    final res = await http
        .put(_u(path), headers: await _headers(auth: auth), body: body == null ? null : jsonEncode(body))
        .timeout(ApiConfig.receiveTimeout);
    return _decode(res);
  }

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) async {
    final res = await http
        .delete(_u(path), headers: await _headers(auth: auth), body: body == null ? null : jsonEncode(body))
        .timeout(ApiConfig.receiveTimeout);
    return _decode(res);
  }
}
```

---

## 2. Domain models

All models live under `lib/api/models/`. Every model has `fromJson`, `toJson`, and only sends non-null fields when serialising for create/update calls.

### 2.1 `lib/api/models/location.dart`

```dart
class Location {
  final double? lat;
  final double? lon;
  final String? address;
  final String? city;
  final String? state;
  final int? pincode;

  Location({this.lat, this.lon, this.address, this.city, this.state, this.pincode});

  factory Location.fromJson(Map<String, dynamic> j) => Location(
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
```

### 2.2 `lib/api/models/phone_number.dart`

```dart
class PhoneNumber {
  final int? pre;       // country code, default 91
  final String? number;
  PhoneNumber({this.pre, this.number});

  factory PhoneNumber.fromJson(Map<String, dynamic> j) => PhoneNumber(
        pre: (j['pre'] as num?)?.toInt(),
        number: j['number'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (pre != null) 'pre': pre,
        if (number != null) 'number': number,
      };
}
```

### 2.3 `lib/api/models/vehicle.dart`

```dart
import 'location.dart';

enum FuelType { petrol, diesel, electric, cng, hybrid, other }
enum Transmission { manual, automatic, amt, cvt }

extension FuelTypeWire on FuelType {
  String get wire => name.toUpperCase();
  static FuelType? parse(String? s) {
    if (s == null) return null;
    return FuelType.values.firstWhere(
      (e) => e.wire == s.toUpperCase(),
      orElse: () => FuelType.other,
    );
  }
}

extension TransmissionWire on Transmission {
  String get wire => name.toUpperCase();
  static Transmission? parse(String? s) {
    if (s == null) return null;
    try {
      return Transmission.values.firstWhere((e) => e.wire == s.toUpperCase());
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
  final String? category;       // e.g. CAR / BIKE / TRUCK
  final String? subCategory;    // e.g. SUV / Sedan
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? registrationNo;
  final FuelType? fuelType;
  final Transmission? transmission;
  final int? seatingCapacity;
  final String? mileage;
  final double? price;
  final String? currency;
  final Location? location;
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
        fuelType: FuelTypeWire.parse(j['fuel_type'] as String?),
        transmission: TransmissionWire.parse(j['transmission'] as String?),
        seatingCapacity: (j['seating_capacity'] as num?)?.toInt(),
        mileage: j['mileage'] as String?,
        price: (j['price'] as num?)?.toDouble(),
        currency: j['currency'] as String?,
        location: j['location'] is Map<String, dynamic>
            ? Location.fromJson(j['location'])
            : null,
        coverImage: j['cover_image'] as String?,
        images: ((j['images'] as List?) ?? const []).whereType<String>().toList(),
        isActive: j['is_active'] as bool?,
        isVerified: j['is_verified'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
        user: j['user'] as Map<String, dynamic>?,
        business: j['business'] as Map<String, dynamic>?,
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

  factory PaginatedVehicles.fromJson(Map<String, dynamic> j) => PaginatedVehicles(
        vehicles: ((j['vehicles'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Vehicle.fromJson)
            .toList(),
        page: (j['page'] as num?)?.toInt() ?? 1,
        limit: (j['limit'] as num?)?.toInt() ?? 20,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}
```

### 2.4 `lib/api/models/facility.dart`

```dart
class Facility {
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

  Facility({
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

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
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
```

### 2.5 `lib/api/models/live_photo.dart`

```dart
class LivePhotoLocation {
  final double? lat;
  final double? lon;
  LivePhotoLocation({this.lat, this.lon});
  factory LivePhotoLocation.fromJson(Map<String, dynamic> j) => LivePhotoLocation(
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };
}

class LivePhoto {
  final String? id;
  final String? userId;
  final String? businessId;
  final String imageUrl;
  final String? caption;
  final DateTime? capturedAt;
  final LivePhotoLocation? location;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LivePhoto({
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

  factory LivePhoto.fromJson(Map<String, dynamic> j) => LivePhoto(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        imageUrl: (j['image_url'] ?? '') as String,
        caption: j['caption'] as String?,
        capturedAt: DateTime.tryParse(j['captured_at']?.toString() ?? ''),
        location: j['location'] is Map<String, dynamic>
            ? LivePhotoLocation.fromJson(j['location'])
            : null,
        isActive: j['is_active'] as bool?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toCreateJson() => {
        'image_url': imageUrl,
        if (caption != null) 'caption': caption,
        if (capturedAt != null) 'captured_at': capturedAt!.toUtc().toIso8601String(),
        if (location != null) 'location': location!.toJson(),
        if (businessId != null) 'business_id': businessId,
      };
}
```

### 2.6 `lib/api/models/gallery_item.dart`

```dart
enum MediaType { image, video }

extension MediaTypeWire on MediaType {
  String get wire => name.toUpperCase();
  static MediaType parse(String? s) {
    if (s?.toUpperCase() == 'VIDEO') return MediaType.video;
    return MediaType.image;
  }
}

class GalleryItem {
  final String? id;
  final String? userId;
  final String? businessId;
  final String? album;          // default "default"
  final String? title;
  final String? description;
  final MediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int? sortOrder;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GalleryItem({
    this.id,
    this.userId,
    this.businessId,
    this.album,
    this.title,
    this.description,
    this.mediaType = MediaType.image,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.sortOrder,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> j) => GalleryItem(
        id: j['_id'] as String?,
        userId: j['user_id'] as String?,
        businessId: j['business_id'] as String?,
        album: j['album'] as String?,
        title: j['title'] as String?,
        description: j['description'] as String?,
        mediaType: MediaTypeWire.parse(j['media_type'] as String?),
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
```

### 2.7 `lib/api/models/testimonial.dart`

```dart
class Testimonial {
  final String? id;
  final String toUser;
  final String? fromUser;
  final String? businessId;
  final String title;
  final String description;
  final double? rating;          // 0..5
  final String? image;
  final bool? isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Hydrated by server on read endpoints.
  final Map<String, dynamic>? from;
  final Map<String, dynamic>? fromBusiness;

  Testimonial({
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

  factory Testimonial.fromJson(Map<String, dynamic> j) => Testimonial(
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
        from: j['from'] as Map<String, dynamic>?,
        fromBusiness: j['from_business'] as Map<String, dynamic>?,
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
```

### 2.8 `lib/api/models/contact.dart`

```dart
import 'phone_number.dart';

class Contact {
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
  final PhoneNumber? phoneNumber;
  final PhoneNumber? alternatePhoneNumber;
  final String? email;
  final String? website;
  final String? openingHours;
  final String? mapLink;
  final bool? isPrimary;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Contact({
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

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
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
        phoneNumber: j['phone_number'] is Map<String, dynamic>
            ? PhoneNumber.fromJson(j['phone_number'])
            : null,
        alternatePhoneNumber: j['alternate_phone_number'] is Map<String, dynamic>
            ? PhoneNumber.fromJson(j['alternate_phone_number'])
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
```

### 2.9 `lib/api/models/upload_url.dart`

```dart
class UploadInit {
  final String uploadUrl;   // S3 presigned PUT URL — 30 min validity
  final String publicUrl;   // public URL to persist on the entity
  final String fileKey;     // S3 object key

  UploadInit({required this.uploadUrl, required this.publicUrl, required this.fileKey});

  factory UploadInit.fromJson(Map<String, dynamic> j) => UploadInit(
        uploadUrl: j['uploadUrl'] as String,
        publicUrl: j['publicUrl'] as String,
        fileKey: j['fileKey'] as String,
      );
}
```

---

## 3. Upload service (S3 presigned PUT)

`lib/api/upload_service.dart` — handles the two-step flow used by every media field on every entity.

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'api_client.dart';
import 'models/upload_url.dart';

class UploadService {
  final ApiClient _api = ApiClient.instance;
  final Dio _dio = Dio();

  /// Step 1 — ask backend for a presigned URL.
  /// Endpoint: GET /upload/init?fileName=...&fileType=...
  Future<UploadInit> init({required String fileName, required String fileType}) async {
    final j = await _api.get('/upload/init', query: {
      'fileName': fileName,
      'fileType': fileType,
    });
    return UploadInit.fromJson(Map<String, dynamic>.from(j));
  }

  /// Step 2 — PUT the binary body to the presigned URL.
  /// IMPORTANT: do NOT send the Authorization header here; S3 expects only
  /// Content-Type to match what was signed.
  Future<void> putToS3({
    required String uploadUrl,
    required File file,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final length = await file.length();
    final stream = file.openRead();
    await _dio.put(
      uploadUrl,
      data: stream,
      options: Options(
        headers: {
          Headers.contentLengthHeader: length,
          'Content-Type': contentType,
        },
        // Disable extra headers Dio adds by default.
        contentType: contentType,
      ),
      onSendProgress: onProgress,
    );
  }

  /// Convenience — runs both steps and returns the public URL to store.
  Future<String> uploadFile(File file, {String? contentTypeOverride}) async {
    final fileName = file.uri.pathSegments.last;
    final contentType = contentTypeOverride ??
        lookupMimeType(file.path) ??
        'application/octet-stream';

    final init = await this.init(fileName: fileName, fileType: contentType);
    await putToS3(uploadUrl: init.uploadUrl, file: file, contentType: contentType);
    return init.publicUrl;
  }
}
```

Usage:

```dart
final url = await UploadService().uploadFile(
  pickedFile,
  contentTypeOverride: 'image/jpeg',
);
// Now persist `url` as cover_image / images[i] / image_url / media_url etc.
```

---

## 4. Service classes — one per entity

Every service is stateless and uses `ApiClient.instance`. Exact endpoint paths shown above each method.

### 4.1 `lib/api/services/vehicle_service.dart`

```dart
import '../api_client.dart';
import '../models/vehicle.dart';

class VehicleService {
  final ApiClient _api = ApiClient.instance;

  /// GET /vehicles  — public, paginated, filterable.
  /// Query params:
  ///   category, sub_category, pincode, user_id, q, page, limit (max 100)
  Future<PaginatedVehicles> list({
    String? category,
    String? subCategory,
    int? pincode,
    String? userId,
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final j = await _api.get('/vehicles', auth: false, query: {
      if (category != null) 'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      if (pincode != null) 'pincode': pincode,
      if (userId != null) 'user_id': userId,
      if (q != null && q.isNotEmpty) 'q': q,
      'page': page,
      'limit': limit,
    });
    return PaginatedVehicles.fromJson(Map<String, dynamic>.from(j));
  }

  /// GET /vehicles/get/:id — public, owner+business hydrated.
  Future<Vehicle> getById(String id) async {
    final j = await _api.get('/vehicles/get/$id', auth: false);
    return Vehicle.fromJson(Map<String, dynamic>.from(j['vehicle']));
  }

  /// POST /vehicles/create — auth required.
  Future<Vehicle> create(Vehicle v) async {
    final j = await _api.post('/vehicles/create', body: v.toCreateJson());
    return Vehicle.fromJson(Map<String, dynamic>.from(j['vehicle']));
  }

  /// GET /vehicles/me/list — auth required, vehicles owned by caller.
  Future<List<Vehicle>> listMine() async {
    final j = await _api.get('/vehicles/me/list');
    return ((j['vehicles'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList();
  }

  /// PUT /vehicles/update/:id — auth required, must be owner.
  /// Editable fields: name, description, category, sub_category, brand, model,
  /// year, color, registration_no, fuel_type, transmission, seating_capacity,
  /// mileage, price, currency, location, cover_image, images, is_active.
  Future<Vehicle> update(String id, Map<String, dynamic> patch) async {
    final j = await _api.put('/vehicles/update/$id', body: patch);
    return Vehicle.fromJson(Map<String, dynamic>.from(j['vehicle']));
  }

  /// DELETE /vehicles/delete/:id — auth required, must be owner.
  Future<void> delete(String id) async {
    await _api.delete('/vehicles/delete/$id');
  }

  /// POST /vehicles/:id/images — append URLs (already uploaded to S3).
  Future<Vehicle> addImages(String id, List<String> imageUrls) async {
    final j = await _api.post('/vehicles/$id/images', body: {'images': imageUrls});
    return Vehicle.fromJson(Map<String, dynamic>.from(j['vehicle']));
  }

  /// DELETE /vehicles/:id/images — remove a single URL from the array.
  Future<Vehicle> removeImage(String id, String imageUrl) async {
    final j = await _api.delete('/vehicles/$id/images', body: {'image': imageUrl});
    return Vehicle.fromJson(Map<String, dynamic>.from(j['vehicle']));
  }
}
```

### 4.2 `lib/api/services/facility_service.dart`

```dart
import '../api_client.dart';
import '../models/facility.dart';

class FacilityService {
  final ApiClient _api = ApiClient.instance;

  /// POST /facilities/create — auth.
  Future<Facility> create(Facility f) async {
    final j = await _api.post('/facilities/create', body: f.toCreateJson());
    return Facility.fromJson(Map<String, dynamic>.from(j['facility']));
  }

  /// GET /facilities/me/list — auth.
  Future<List<Facility>> listMine() async {
    final j = await _api.get('/facilities/me/list');
    return ((j['facilities'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Facility.fromJson)
        .toList();
  }

  /// GET /facilities/public/:userId — public, only active items.
  Future<List<Facility>> listForUser(String userId) async {
    final j = await _api.get('/facilities/public/$userId', auth: false);
    return ((j['facilities'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Facility.fromJson)
        .toList();
  }

  /// PUT /facilities/update/:id — auth, must be owner.
  /// Editable: name, description, icon, image, type, is_active, sort_order.
  Future<Facility> update(String id, Map<String, dynamic> patch) async {
    final j = await _api.put('/facilities/update/$id', body: patch);
    return Facility.fromJson(Map<String, dynamic>.from(j['facility']));
  }

  /// DELETE /facilities/delete/:id — auth, must be owner.
  Future<void> delete(String id) async {
    await _api.delete('/facilities/delete/$id');
  }
}
```

### 4.3 `lib/api/services/live_photo_service.dart`

```dart
import '../api_client.dart';
import '../models/live_photo.dart';

class LivePhotoService {
  final ApiClient _api = ApiClient.instance;

  /// POST /live-photos/add — auth. Requires `image_url`.
  Future<LivePhoto> add(LivePhoto p) async {
    final j = await _api.post('/live-photos/add', body: p.toCreateJson());
    return LivePhoto.fromJson(Map<String, dynamic>.from(j['photo']));
  }

  /// POST /live-photos/bulk — auth. Body: { "photos": [LivePhotoCreate, ...] }
  Future<List<LivePhoto>> addBulk(List<LivePhoto> photos) async {
    final j = await _api.post('/live-photos/bulk', body: {
      'photos': photos.map((p) => p.toCreateJson()).toList(),
    });
    return ((j['photos'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LivePhoto.fromJson)
        .toList();
  }

  /// GET /live-photos/me/list — auth. Sorted captured_at desc.
  Future<List<LivePhoto>> listMine() async {
    final j = await _api.get('/live-photos/me/list');
    return ((j['photos'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LivePhoto.fromJson)
        .toList();
  }

  /// GET /live-photos/public/:userId — public, only active.
  Future<List<LivePhoto>> listForUser(String userId) async {
    final j = await _api.get('/live-photos/public/$userId', auth: false);
    return ((j['photos'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LivePhoto.fromJson)
        .toList();
  }

  /// DELETE /live-photos/delete/:id — auth, owner only.
  Future<void> delete(String id) async {
    await _api.delete('/live-photos/delete/$id');
  }
}
```

### 4.4 `lib/api/services/gallery_service.dart`

```dart
import '../api_client.dart';
import '../models/gallery_item.dart';

class GalleryService {
  final ApiClient _api = ApiClient.instance;

  /// POST /gallery/add — auth. Requires `media_url`.
  Future<GalleryItem> add(GalleryItem item) async {
    final j = await _api.post('/gallery/add', body: item.toCreateJson());
    return GalleryItem.fromJson(Map<String, dynamic>.from(j['item']));
  }

  /// POST /gallery/bulk — auth. Body: { "items": [GalleryItemCreate, ...] }
  Future<List<GalleryItem>> addBulk(List<GalleryItem> items) async {
    final j = await _api.post('/gallery/bulk', body: {
      'items': items.map((i) => i.toCreateJson()).toList(),
    });
    return ((j['items'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GalleryItem.fromJson)
        .toList();
  }

  /// GET /gallery/me/list — auth. Optional ?album=foo.
  Future<List<GalleryItem>> listMine({String? album}) async {
    final j = await _api.get('/gallery/me/list', query: {
      if (album != null) 'album': album,
    });
    return ((j['items'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GalleryItem.fromJson)
        .toList();
  }

  /// GET /gallery/public/:userId — public. Optional ?album=foo. Active only.
  Future<List<GalleryItem>> listForUser(String userId, {String? album}) async {
    final j = await _api.get(
      '/gallery/public/$userId',
      auth: false,
      query: {if (album != null) 'album': album},
    );
    return ((j['items'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GalleryItem.fromJson)
        .toList();
  }

  /// PUT /gallery/update/:id — auth, owner only.
  /// Editable: album, title, description, media_type, media_url,
  /// thumbnail_url, sort_order, is_active.
  Future<GalleryItem> update(String id, Map<String, dynamic> patch) async {
    final j = await _api.put('/gallery/update/$id', body: patch);
    return GalleryItem.fromJson(Map<String, dynamic>.from(j['item']));
  }

  /// DELETE /gallery/delete/:id — auth, owner only.
  Future<void> delete(String id) async {
    await _api.delete('/gallery/delete/$id');
  }
}
```

### 4.5 `lib/api/services/testimonial_service.dart`

```dart
import '../api_client.dart';
import '../models/testimonial.dart';

class TestimonialFeed {
  final Map<String, dynamic>? to;
  final Map<String, dynamic>? toBusiness;
  final List<Testimonial> testimonials;
  TestimonialFeed({this.to, this.toBusiness, required this.testimonials});
}

class TestimonialService {
  final ApiClient _api = ApiClient.instance;

  /// POST /testimonials/add — auth. Cannot self-testimonial.
  Future<Testimonial> add(Testimonial t) async {
    final j = await _api.post('/testimonials/add', body: t.toCreateJson());
    return Testimonial.fromJson(Map<String, dynamic>.from(j['testimonial']));
  }

  /// GET /testimonials/me/received — auth. Returns testimonials *to* current user.
  Future<List<Testimonial>> listReceived() async {
    final j = await _api.get('/testimonials/me/received');
    return ((j['testimonials'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Testimonial.fromJson)
        .toList();
  }

  /// GET /testimonials/public/:userId — public. Hydrates `to`/`to_business`.
  Future<TestimonialFeed> listForUser(String userId) async {
    final j = await _api.get('/testimonials/public/$userId', auth: false);
    return TestimonialFeed(
      to: j['to'] as Map<String, dynamic>?,
      toBusiness: j['to_business'] as Map<String, dynamic>?,
      testimonials: ((j['testimonials'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Testimonial.fromJson)
          .toList(),
    );
  }

  /// GET /testimonials/get/:id — public.
  Future<Testimonial> getById(String id) async {
    final j = await _api.get('/testimonials/get/$id', auth: false);
    return Testimonial.fromJson(Map<String, dynamic>.from(j['testimonial']));
  }

  /// PUT /testimonials/update/:id — auth, only the author can edit.
  /// Editable: title, description, rating, image, is_visible.
  Future<Testimonial> update(String id, Map<String, dynamic> patch) async {
    final j = await _api.put('/testimonials/update/$id', body: patch);
    return Testimonial.fromJson(Map<String, dynamic>.from(j['testimonial']));
  }

  /// DELETE /testimonials/delete/:id — auth, only the author can delete.
  Future<void> delete(String id) async {
    await _api.delete('/testimonials/delete/$id');
  }
}
```

### 4.6 `lib/api/services/contact_service.dart`

```dart
import '../api_client.dart';
import '../models/contact.dart';

class ContactService {
  final ApiClient _api = ApiClient.instance;

  /// POST /contact-us/create — auth. Requires `location_name`.
  /// If `is_primary: true`, server unsets other primaries for the same user.
  Future<Contact> create(Contact c) async {
    final j = await _api.post('/contact-us/create', body: c.toCreateJson());
    return Contact.fromJson(Map<String, dynamic>.from(j['contact']));
  }

  /// GET /contact-us/me/list — auth. Sorted primary-first, then created desc.
  Future<List<Contact>> listMine() async {
    final j = await _api.get('/contact-us/me/list');
    return ((j['contacts'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Contact.fromJson)
        .toList();
  }

  /// GET /contact-us/public/:userId — public, active only.
  Future<List<Contact>> listForUser(String userId) async {
    final j = await _api.get('/contact-us/public/$userId', auth: false);
    return ((j['contacts'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Contact.fromJson)
        .toList();
  }

  /// GET /contact-us/get/:id — public.
  Future<Contact> getById(String id) async {
    final j = await _api.get('/contact-us/get/$id', auth: false);
    return Contact.fromJson(Map<String, dynamic>.from(j['contact']));
  }

  /// PUT /contact-us/update/:id — auth, owner only.
  /// Editable: location_name, address, city, state, country, pincode,
  /// lat, lon, phone_number, alternate_phone_number, email, website,
  /// opening_hours, map_link, is_primary, is_active.
  Future<Contact> update(String id, Map<String, dynamic> patch) async {
    final j = await _api.put('/contact-us/update/$id', body: patch);
    return Contact.fromJson(Map<String, dynamic>.from(j['contact']));
  }

  /// DELETE /contact-us/delete/:id — auth, owner only.
  Future<void> delete(String id) async {
    await _api.delete('/contact-us/delete/$id');
  }
}
```

---

## 5. Endpoint reference (cheat sheet)

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/vehicles` | ❌ | Filters: `category`, `sub_category`, `pincode`, `user_id`, `q`, `page`, `limit` (max 100). Owners hydrated via gRPC. |
| GET | `/vehicles/get/:id` | ❌ | Returns `{ status, vehicle }` with `user` + `business`. |
| POST | `/vehicles/create` | ✅ | Body = `VehicleCreate`. Owner = JWT user. |
| GET | `/vehicles/me/list` | ✅ | All vehicles owned by caller. |
| PUT | `/vehicles/update/:id` | ✅ | 403 if not owner, 404 if missing. |
| DELETE | `/vehicles/delete/:id` | ✅ | 403 if not owner. |
| POST | `/vehicles/:id/images` | ✅ | Body = `{ images: string[] }`. Appends + dedupes. |
| DELETE | `/vehicles/:id/images` | ✅ | Body = `{ image: string }`. Removes one URL. |
| POST | `/facilities/create` | ✅ | `name` required. |
| GET | `/facilities/me/list` | ✅ | |
| GET | `/facilities/public/:userId` | ❌ | Active only. |
| PUT | `/facilities/update/:id` | ✅ | |
| DELETE | `/facilities/delete/:id` | ✅ | |
| POST | `/live-photos/add` | ✅ | `image_url` required. |
| POST | `/live-photos/bulk` | ✅ | Body `{ photos: [...] }`. |
| GET | `/live-photos/me/list` | ✅ | |
| GET | `/live-photos/public/:userId` | ❌ | Active only. |
| DELETE | `/live-photos/delete/:id` | ✅ | |
| POST | `/gallery/add` | ✅ | `media_url` required. |
| POST | `/gallery/bulk` | ✅ | Body `{ items: [...] }`. |
| GET | `/gallery/me/list` | ✅ | Optional `?album=`. |
| GET | `/gallery/public/:userId` | ❌ | Optional `?album=`. Active only. |
| PUT | `/gallery/update/:id` | ✅ | |
| DELETE | `/gallery/delete/:id` | ✅ | |
| POST | `/testimonials/add` | ✅ | `toUser`, `title`, `description` required. Self-target rejected. |
| GET | `/testimonials/me/received` | ✅ | `from`/`from_business` hydrated. |
| GET | `/testimonials/public/:userId` | ❌ | Visible only. Includes `to`/`to_business`. |
| GET | `/testimonials/get/:id` | ❌ | Single, hydrated. |
| PUT | `/testimonials/update/:id` | ✅ | Author-only. |
| DELETE | `/testimonials/delete/:id` | ✅ | Author-only. |
| POST | `/contact-us/create` | ✅ | `location_name` required. |
| GET | `/contact-us/me/list` | ✅ | Primary first. |
| GET | `/contact-us/public/:userId` | ❌ | Active only. |
| GET | `/contact-us/get/:id` | ❌ | |
| PUT | `/contact-us/update/:id` | ✅ | Setting `is_primary:true` unsets siblings. |
| DELETE | `/contact-us/delete/:id` | ✅ | |
| GET | `/upload/init` | ✅ | `?fileName=&fileType=`. Returns `{ uploadUrl, publicUrl, fileKey }`. |
| GET | `/health` | ❌ | `{ status: "ok" }`. Useful for connectivity checks. |

---

## 6. Worked examples

### 6.1 Sign in once → store token

The JWT comes from `be_user_service` (login flow). Once you have it:

```dart
await TokenStore.save(jwtFromUserService);
// every subsequent ApiClient call attaches it automatically.
```

### 6.2 Create a vehicle with one cover image and three gallery images

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'lib/api/upload_service.dart';
import 'lib/api/services/vehicle_service.dart';
import 'lib/api/models/vehicle.dart';
import 'lib/api/models/location.dart';

Future<Vehicle> createInnova(File cover, List<File> photos) async {
  final upload = UploadService();
  final vehicles = VehicleService();

  // 1) upload all images in parallel, get back public S3 URLs
  final urls = await Future.wait([
    upload.uploadFile(cover),
    ...photos.map(upload.uploadFile),
  ]);
  final coverUrl = urls.first;
  final imageUrls = urls.sublist(1);

  // 2) create the vehicle with the URLs
  final draft = Vehicle(
    name: 'Toyota Innova Crysta',
    description: '7-seater diesel automatic',
    category: 'CAR',
    subCategory: 'SUV',
    brand: 'Toyota',
    model: 'Innova Crysta',
    year: 2022,
    fuelType: FuelType.diesel,
    transmission: Transmission.automatic,
    seatingCapacity: 7,
    price: 1850000,
    currency: 'INR',
    location: Location(
      lat: 28.6139, lon: 77.2090,
      address: 'Connaught Place', city: 'New Delhi',
      state: 'Delhi', pincode: 110001,
    ),
    coverImage: coverUrl,
    images: imageUrls,
  );
  return vehicles.create(draft);
}
```

### 6.3 Browse public vehicles with filters and infinite scroll

```dart
final svc = VehicleService();

Future<void> loadPage(int page) async {
  final res = await svc.list(
    category: 'CAR',
    pincode: 110001,
    q: 'innova',
    page: page,
    limit: 20,
  );
  print('page $page / total ${res.total}');
  for (final v in res.vehicles) {
    print('${v.name} • ${v.user?['name'] ?? 'unknown owner'}');
  }
}
```

### 6.4 Add and remove a vehicle image after the fact

```dart
final svc = VehicleService();
final upload = UploadService();

// add one
final newUrl = await upload.uploadFile(File('/tmp/extra.jpg'));
await svc.addImages(vehicleId, [newUrl]);

// remove one
await svc.removeImage(vehicleId, oldUrl);
```

### 6.5 Write a testimonial about another user

```dart
await TestimonialService().add(Testimonial(
  toUser: '64f...targetUserId',
  title: 'Excellent service',
  description: 'Fast pickup and clean cab.',
  rating: 4.5,
));
```

### 6.6 Manage business contacts (set one as primary)

```dart
final svc = ContactService();

final hq = await svc.create(Contact(
  locationName: 'HQ — Connaught Place',
  address: 'Block A, CP', city: 'New Delhi', state: 'Delhi',
  country: 'India', pincode: 110001,
  phoneNumber: PhoneNumber(pre: 91, number: '9876543210'),
  email: 'hq@example.com',
  isPrimary: true, // server unsets siblings' is_primary
));

await svc.update(hq.id!, {'opening_hours': 'Mon–Sat 9–7'});
```

### 6.7 Bulk-add a gallery album

```dart
final upload = UploadService();
final svc = GalleryService();

final urls = await Future.wait(localFiles.map(upload.uploadFile));
final items = urls.asMap().entries.map((e) => GalleryItem(
  album: 'showroom-2026',
  title: 'Showroom #${e.key + 1}',
  mediaType: MediaType.image,
  mediaUrl: e.value,
  sortOrder: e.key,
)).toList();

final saved = await svc.addBulk(items);
print('Stored ${saved.length} gallery items');
```

### 6.8 Live photo with capture coordinates

```dart
await LivePhotoService().add(LivePhoto(
  imageUrl: await UploadService().uploadFile(camFile),
  caption: 'Workshop — fresh delivery',
  capturedAt: DateTime.now().toUtc(),
  location: LivePhotoLocation(lat: 28.5, lon: 77.2),
));
```

---

## 7. Error handling & edge cases

| Case | Status | Body shape |
|---|---|---|
| Missing `Authorization` on protected endpoint | 400 | `{ "message": "No token provided" }` |
| Invalid / expired JWT | 401 | `{ "message": "Unauthorized User!", "error": "..." }` |
| Body validation failure | 400 | `{ "status": false, "message": "<field> required" }` |
| Resource does not exist | 404 | `{ "status": false, "message": "... not found" }` |
| Acting on a record you don't own | 403 | `{ "status": false, "message": "Not allowed" }` |
| Self-testimonial attempt | 400 | `{ "status": false, "message": "Cannot write testimonial for yourself" }` |
| Server fault | 500 | `{ "status": false, "message": "Server error" }` |
| Rate limit (1000 req/min/IP) | 429 | `Too many requests, please try again later.` |

`ApiClient` raises `ApiException` for any non-2xx — wrap calls to surface them in UI:

```dart
try {
  final v = await VehicleService().getById(id);
  // ...
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    await TokenStore.clear();
    // navigate to login
  } else {
    showSnack(e.message);
  }
}
```

---

## 8. Wiring it into a Riverpod / Provider app

The services are stateless singletons — register them once and inject as needed.

```dart
// Riverpod
final vehicleServiceProvider = Provider((_) => VehicleService());
final uploadServiceProvider = Provider((_) => UploadService());

final myVehiclesProvider = FutureProvider((ref) =>
    ref.read(vehicleServiceProvider).listMine());
```

```dart
// Provider package
MultiProvider(
  providers: [
    Provider(create: (_) => VehicleService()),
    Provider(create: (_) => GalleryService()),
    Provider(create: (_) => ContactService()),
    Provider(create: (_) => LivePhotoService()),
    Provider(create: (_) => TestimonialService()),
    Provider(create: (_) => FacilityService()),
    Provider(create: (_) => UploadService()),
  ],
  child: MyApp(),
);
```

---

## 9. Local development tips

- **Android emulator**: backend at `http://10.0.2.2:3009`. Set `network_security_config.xml` to allow cleartext to `10.0.2.2` in debug builds.
- **iOS simulator**: backend at `http://localhost:3009`. Add `NSAppTransportSecurity → NSAllowsLocalNetworking = true` in `Info.plist` for debug only.
- The interactive Swagger UI is at `<base>/api-docs/` and the raw OpenAPI JSON is at `<base>/swagger.json` — handy for `Dio` interceptors and code generators if you ever want to regenerate the client with `openapi-generator-cli`.
- Health check: `GET /health` → `{ "status": "ok", "service": "be_vehicle_service" }`.

---

## 10. Recommended folder layout

```
lib/
└── api/
    ├── api_client.dart
    ├── api_config.dart
    ├── token_store.dart
    ├── upload_service.dart
    ├── models/
    │   ├── contact.dart
    │   ├── facility.dart
    │   ├── gallery_item.dart
    │   ├── live_photo.dart
    │   ├── location.dart
    │   ├── phone_number.dart
    │   ├── testimonial.dart
    │   ├── upload_url.dart
    │   └── vehicle.dart
    └── services/
        ├── contact_service.dart
        ├── facility_service.dart
        ├── gallery_service.dart
        ├── live_photo_service.dart
        ├── testimonial_service.dart
        └── vehicle_service.dart
```

Drop these files in, set the JWT once on login, and every endpoint in this microservice is one method call away.
