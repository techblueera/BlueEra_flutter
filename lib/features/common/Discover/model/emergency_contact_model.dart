/// Mirrors the `EmergencyContact` document returned by `emergency-service`
/// (see `lib/docs/EMERGENCY_CONTACTS_FRONTEND_GUIDE.md`).
class EmergencyContactModel {
  final String id;
  final String name;
  final String contactNo;
  final String? relation;
  final int? priority;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.contactNo,
    this.relation,
    this.priority,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      contactNo: (json['contactNo'] ?? '').toString(),
      relation: json['relation']?.toString(),
      priority: json['priority'] is int
          ? json['priority'] as int
          : int.tryParse('${json['priority']}'),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'contactNo': contactNo,
        if (relation != null && relation!.isNotEmpty) 'relation': relation,
        if (priority != null) 'priority': priority,
      };

  /// Display the phone as a 10-digit local number, dropping the `+91` / `91`
  /// country prefix that the server stores. Falls back to the raw value if
  /// the server returns something unexpected.
  String get displayPhone {
    final stripped = contactNo.replaceAll(RegExp(r'\s|-'), '');
    if (stripped.startsWith('+91')) return stripped.substring(3);
    if (stripped.startsWith('91') && stripped.length == 12) {
      return stripped.substring(2);
    }
    return stripped;
  }
}
