/// A delivery/drop address the user saved locally for ride requests. Stored
/// device-only via [SavedAddressController].
class SavedAddress {
  final String id;

  /// Short label, e.g. "Home", "Work", or a custom name.
  final String label;

  /// Full address text — typically picked from Google place suggestions.
  final String address;

  /// House / flat / building number entered manually by the user.
  final String houseNo;

  /// Optional landmark to help the rider locate the spot.
  final String landmark;

  /// Coordinates of the picked place (when chosen from a Google suggestion).
  final double? lat;
  final double? lng;

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    this.houseNo = '',
    this.landmark = '',
    this.lat,
    this.lng,
  });

  /// Single-line address combining the manual house no, the picked address and
  /// the optional landmark — convenient for display and for sending in chat.
  String get fullAddress {
    final parts = <String>[
      if (houseNo.isNotEmpty) houseNo,
      if (address.isNotEmpty) address,
      if (landmark.isNotEmpty) 'Landmark: $landmark',
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'house_no': houseNo,
        'landmark': landmark,
        'lat': lat,
        'lng': lng,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        houseNo: json['house_no']?.toString() ?? '',
        landmark: json['landmark']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );
}
