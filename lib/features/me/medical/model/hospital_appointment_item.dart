/// One row on the owner's hospital-appointment inbox
/// (`GET /hospital-appointments/owner/me`). Slim projection of the
/// document shape in
/// `lib/docs/healthcare-appointment-ui-integration.md` §3 — only fields
/// the bookings-tab card needs are parsed here.
///
/// Kept as a plain value class (no fromJson/toJson boilerplate on
/// unused fields) so the tab can render without a heavier model tree.
class HospitalAppointmentItem {
  final String id;
  final String status;

  // Doctor snapshot — what the owner-side card actually shows.
  final String doctorName;
  final String? department;
  final int? fees;
  final String? doctorImage;

  // Appointment context.
  final DateTime? appointmentDate;
  final String? preferredTime;
  final String? patientName;
  final String? note;

  const HospitalAppointmentItem({
    required this.id,
    required this.status,
    required this.doctorName,
    this.department,
    this.fees,
    this.doctorImage,
    this.appointmentDate,
    this.preferredTime,
    this.patientName,
    this.note,
  });

  factory HospitalAppointmentItem.fromJson(Map<String, dynamic> json) {
    final rawFees = json['fees'];
    return HospitalAppointmentItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      doctorName: (json['doctorName'] ?? '').toString(),
      department: json['department']?.toString(),
      fees: rawFees is int
          ? rawFees
          : (rawFees is num ? rawFees.toInt() : int.tryParse('$rawFees')),
      doctorImage: json['doctorImage']?.toString(),
      appointmentDate: json['appointmentDate'] is String
          ? DateTime.tryParse(json['appointmentDate'])
          : null,
      preferredTime: json['preferredTime']?.toString(),
      patientName: json['patientName']?.toString(),
      note: json['note']?.toString(),
    );
  }
}
