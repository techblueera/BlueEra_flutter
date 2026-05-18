class VehicleEnumResponse {
  List<VehicleEnumItem>? vehicleUsesType;
  List<VehicleEnumItem>? vehicleType;
  List<VehicleEnumItem>? fuelType;
  List<VehicleEnumItem>? registrationType;

  VehicleEnumResponse({
    this.vehicleUsesType,
    this.vehicleType,
    this.fuelType,
    this.registrationType,
  });

  VehicleEnumResponse.fromJson(Map<String, dynamic> json) {
    vehicleUsesType = _parseList(json['vehicleUsesType']);
    vehicleType = _parseList(json['vehicleType']);
    fuelType = _parseList(json['fuelType']);
    registrationType = _parseList(json['registrationType']);
  }

  static List<VehicleEnumItem> _parseList(dynamic raw) {
    if (raw is! List) return <VehicleEnumItem>[];
    return raw
        .map<VehicleEnumItem>((e) {
          if (e is Map<String, dynamic>) return VehicleEnumItem.fromJson(e);
          if (e is Map) return VehicleEnumItem.fromJson(Map<String, dynamic>.from(e));
          // Backward compatibility: server used to return plain strings.
          final v = e?.toString() ?? '';
          return VehicleEnumItem(slugId: v, slugValue: v);
        })
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleUsesType': vehicleUsesType?.map((e) => e.toJson()).toList(),
      'vehicleType': vehicleType?.map((e) => e.toJson()).toList(),
      'fuelType': fuelType?.map((e) => e.toJson()).toList(),
      'registrationType': registrationType?.map((e) => e.toJson()).toList(),
    };
  }
}

class VehicleEnumItem {
  final String slugId;
  final String slugValue;

  VehicleEnumItem({required this.slugId, required this.slugValue});

  factory VehicleEnumItem.fromJson(Map<String, dynamic> json) {
    return VehicleEnumItem(
      slugId: (json['slug_id'] ?? '').toString(),
      slugValue: (json['slug_value'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'slug_id': slugId,
        'slug_value': slugValue,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleEnumItem &&
          runtimeType == other.runtimeType &&
          slugId == other.slugId;

  @override
  int get hashCode => slugId.hashCode;
}
