/// A saved address as the `addresses` API speaks it.
///
/// Request/response contract:
/// ```json
/// {
///   "addressLine1": "221B Baker Street",
///   "addressLine2": "Near Regent's Park",
///   "lat": 28.6139,
///   "long": 77.209,
///   "city": "New Delhi",
///   "state": "Delhi",
///   "country": "India",
///   "pincode": "110001",
///   "addressType": "Home"
/// }
/// ```
///
/// Deliberately separate from the older `AddressDetails` model used by the
/// chat order flow — that one is still on the legacy `house_no` / `zip_code`
/// / `lng` / `type` field names and is consumed by screens this module does
/// not own. [UserAddress.fromJson] does read those legacy names as a
/// fallback, so an address cached before this contract landed still parses.
class UserAddress {
  UserAddress({
    this.id,
    this.userId,
    this.addressLine1,
    this.addressLine2,
    this.lat,
    this.long,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.addressType,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  String? id;
  String? userId;
  String? addressLine1;
  String? addressLine2;
  num? lat;
  num? long;
  String? city;
  String? state;
  String? country;
  String? pincode;
  String? addressType;

  /// Read-only: not part of the request contract, kept because the API may
  /// still return it and the local cache sorts on it.
  bool? isDefault;
  String? createdAt;
  String? updatedAt;

  factory UserAddress.fromJson(dynamic json) {
    if (json is! Map) return UserAddress();
    final map = Map<String, dynamic>.from(json);

    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return null;
    }

    num? pickNum(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is num) return value;
        if (value is String && value.trim().isNotEmpty) {
          final parsed = num.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    return UserAddress(
      id: pick(['_id', 'id']),
      userId: pick(['userId', 'user_id']),
      addressLine1: pick(['addressLine1', 'address_line_1', 'house_no']),
      addressLine2: pick(['addressLine2', 'address_line_2', 'street']),
      lat: pickNum(['lat', 'latitude']),
      long: pickNum(['long', 'lng', 'longitude']),
      city: pick(['city']),
      state: pick(['state']),
      country: pick(['country']),
      pincode: pick(['pincode', 'pinCode', 'zip_code', 'zipCode']),
      addressType: pick(['addressType', 'address_type', 'type']),
      isDefault: map['isDefault'] as bool? ?? map['is_default'] as bool?,
      createdAt: pick(['createdAt', 'created_at']),
      updatedAt: pick(['updatedAt', 'updated_at']),
    );
  }

  /// Full object — used for the local Hive cache, so ids survive a restart.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        ...toRequestJson(),
        'isDefault': isDefault,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  /// Exactly the nine keys `POST /addresses` and `PUT /addresses/:id` accept.
  Map<String, dynamic> toRequestJson() => {
        'addressLine1': addressLine1 ?? '',
        'addressLine2': addressLine2 ?? '',
        'lat': lat,
        'long': long,
        'city': city ?? '',
        'state': state ?? '',
        'country': country ?? '',
        'pincode': pincode ?? '',
        'addressType': addressType ?? '',
      };

  /// Pulls the list out of whichever envelope the API used:
  /// a bare array, `{data: [...]}`, or `{data: {addresses: [...]}}`.
  static List<UserAddress> listFrom(dynamic body) {
    dynamic node = body;
    if (node is Map) node = node['data'] ?? node['addresses'];
    if (node is Map) node = node['addresses'] ?? node['data'];
    if (node is! List) return <UserAddress>[];
    return node.map((e) => UserAddress.fromJson(e)).toList();
  }

  /// Pulls a single address out of a `{data: {...}}` / bare-object body.
  static UserAddress? oneFrom(dynamic body) {
    dynamic node = body;
    if (node is Map && node['data'] != null) node = node['data'];
    if (node is! Map) return null;
    final parsed = UserAddress.fromJson(node);
    return parsed.id == null && parsed.addressLine1 == null ? null : parsed;
  }
}
