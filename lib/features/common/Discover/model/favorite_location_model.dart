/// Mirrors the FavoriteLocation response from the rider service.
///
/// `location.coordinates` from the API is `[longitude, latitude]`
/// (GeoJSON). We swap to UI-friendly `(latitude, longitude)` here so
/// the rest of the app never has to think about it.
class FavoriteLocation {
  final String id;
  final String? label;
  final String address;
  final double latitude;
  final double longitude;
  final String tag;
  final bool isCustomTag;

  FavoriteLocation({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.tag,
    required this.isCustomTag,
    this.label,
  });

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    final coords = (json['location']?['coordinates'] as List?) ?? const [];
    final lng = coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
    final lat = coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;
    return FavoriteLocation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      label: json['label'] as String?,
      address: (json['address'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
      tag: (json['tag'] ?? '').toString(),
      isCustomTag: (json['isCustomTag'] as bool?) ?? false,
    );
  }

  /// Title shown in the list — `label` if present, otherwise the
  /// human-friendly version of the tag.
  String get displayTitle {
    final l = label?.trim() ?? '';
    if (l.isNotEmpty) return l;
    if (tag.isEmpty) return 'Saved place';
    return tag
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }
}
