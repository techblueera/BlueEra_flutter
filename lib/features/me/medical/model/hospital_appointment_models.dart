/// Snapshot of the hospital the customer is booking with. Denormalised
/// so the sheet header and (later) the in-chat card render without
/// re-fetching the source listing.
class HospitalAppointmentListing {
  final String hospitalId;
  final String ownerId;
  final String ownerName;
  final String hospitalName;
  final String? coverImage;
  final String? location;

  const HospitalAppointmentListing({
    required this.hospitalId,
    required this.ownerId,
    required this.ownerName,
    required this.hospitalName,
    this.coverImage,
    this.location,
  });
}

/// One selectable doctor in the appointment sheet — slim projection of
/// [OpdDoctor] so this widget doesn't couple to the OPD model.
///
/// The doc §1 requires `opd_id`; everything else on the card (doctor
/// name, department, fees, image) is snapshotted server-side from the
/// OPD record — no need to send them.
class HospitalAppointmentDoctorOption {
  final String id;
  final String name;
  final String? department;
  final int? fees;
  final String? image;
  final String? timing;
  final String? position;

  const HospitalAppointmentDoctorOption({
    required this.id,
    required this.name,
    this.department,
    this.fees,
    this.image,
    this.timing,
    this.position,
  });
}
