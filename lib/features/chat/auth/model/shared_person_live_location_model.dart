
class SharedPersonsLiveLocationModel {
  final String? userId;
  final double? longitude;
  final double? latitude;
  final String? availabilityStatus;

  SharedPersonsLiveLocationModel({
    this.userId,
    this.longitude,
    this.latitude,
    this.availabilityStatus,
  });

  factory SharedPersonsLiveLocationModel.fromMap(
      Map<String, dynamic>? map) {
    if (map == null) return SharedPersonsLiveLocationModel();

    return SharedPersonsLiveLocationModel(
      userId: map['userId']?.toString(),
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      availabilityStatus: map['availabilityStatus']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'longitude': longitude,
      'latitude': latitude,
      'availabilityStatus': availabilityStatus,
    };
  }
}
