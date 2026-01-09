// hospital_dynamic_model.dart

class HospitalResponse {
  final bool success;
  final HospitalData? data;

  HospitalResponse({
    required this.success,
    required this.data,
  });

  factory HospitalResponse.fromJson(Map<String, dynamic> json) {
    return HospitalResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? HospitalData.fromJson(json['data'])
          : null,
    );
  }
}

// ------------------------------------------------------------

class HospitalData {
  /// FULL RAW DATA (🔥 MOST IMPORTANT)
  final Map<String, dynamic> rawData;

  HospitalData({
    required this.rawData,
  });

  factory HospitalData.fromJson(Map<String, dynamic> json) {
    return HospitalData(
      rawData: Map<String, dynamic>.from(json),
    );
  }

  // ------------------ OPTIONAL HELPERS ------------------

  /// Safe getter for String
  String getString(String key) => rawData[key]?.toString() ?? '';

  /// Safe getter for Map
  Map<String, dynamic> getMap(String key) =>
      rawData[key] is Map ? Map<String, dynamic>.from(rawData[key]) : {};

  /// Safe getter for List
  List<dynamic> getList(String key) =>
      rawData[key] is List ? List<dynamic>.from(rawData[key]) : [];

  /// Check section exists
  bool hasSection(String key) => rawData.containsKey(key);
}
