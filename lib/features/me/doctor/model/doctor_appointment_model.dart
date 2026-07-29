/// Status values the doctor-appointment API accepts / returns.
///
/// `accepted` / `declined` are the doctor's to set; `cancelled` is the
/// customer's. Declined and cancelled are terminal.
class DoctorAppointmentStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String declined = 'declined';
  static const String cancelled = 'cancelled';

  static const List<String> all = [
    pending,
    accepted,
    declined,
    cancelled,
  ];
}

/// One appointment request — the shape returned by every
/// `hospital-service/doctor-appointments` list/detail endpoint.
class DoctorAppointment {
  final String? id;
  final String? customerId;

  /// The doctor who owns the listing.
  final String? ownerId;
  final String? businessId;

  /// Null when the doctor booked before completing their profile — the card
  /// must still render.
  final String? doctorProfileId;
  final String? category;
  final String? doctorName;
  final String? specialization;

  /// Display only. Nothing is charged in this flow.
  final num? fees;
  final String? feeType;
  final String? doctorImage;
  final DateTime? appointmentDate;
  final String? preferredTime;
  final String? patientName;
  final String? enquiryId;
  final String? note;
  final List<String> photos;
  final String? listingName;
  final String? listingImage;
  final String? location;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DoctorAppointment({
    this.id,
    this.customerId,
    this.ownerId,
    this.businessId,
    this.doctorProfileId,
    this.category,
    this.doctorName,
    this.specialization,
    this.fees,
    this.feeType,
    this.doctorImage,
    this.appointmentDate,
    this.preferredTime,
    this.patientName,
    this.enquiryId,
    this.note,
    this.photos = const [],
    this.listingName,
    this.listingImage,
    this.location,
    this.status = DoctorAppointmentStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    return DoctorAppointment(
      id: json['_id']?.toString(),
      customerId: json['customerId']?.toString(),
      ownerId: json['ownerId']?.toString(),
      businessId: json['businessId']?.toString(),
      doctorProfileId: json['doctorProfileId']?.toString(),
      category: json['category']?.toString(),
      doctorName: json['doctorName']?.toString(),
      specialization: json['specialization']?.toString(),
      fees: json['fees'] is num
          ? json['fees'] as num
          : num.tryParse(json['fees']?.toString() ?? ''),
      feeType: json['feeType']?.toString(),
      doctorImage: json['doctorImage']?.toString(),
      appointmentDate:
          DateTime.tryParse(json['appointmentDate']?.toString() ?? ''),
      preferredTime: json['preferredTime']?.toString(),
      patientName: json['patientName']?.toString(),
      enquiryId: json['enquiryId']?.toString(),
      note: json['note']?.toString(),
      photos: (json['photos'] is List)
          ? (json['photos'] as List)
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      listingName: json['listingName']?.toString(),
      listingImage: json['listingImage']?.toString(),
      location: json['location']?.toString(),
      status: (json['status']?.toString().toLowerCase().trim().isNotEmpty ??
              false)
          ? json['status'].toString().toLowerCase().trim()
          : DoctorAppointmentStatus.pending,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static List<DoctorAppointment> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DoctorAppointment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  bool get isPending => status == DoctorAppointmentStatus.pending;

  /// Only the doctor may accept/decline, and only from `pending`.
  bool get canOwnerAct => isPending;

  DoctorAppointment copyWithStatus(String next) {
    return DoctorAppointment(
      id: id,
      customerId: customerId,
      ownerId: ownerId,
      businessId: businessId,
      doctorProfileId: doctorProfileId,
      category: category,
      doctorName: doctorName,
      specialization: specialization,
      fees: fees,
      feeType: feeType,
      doctorImage: doctorImage,
      appointmentDate: appointmentDate,
      preferredTime: preferredTime,
      patientName: patientName,
      enquiryId: enquiryId,
      note: note,
      photos: photos,
      listingName: listingName,
      listingImage: listingImage,
      location: location,
      status: next,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// The standard `{ totalCount, page, limit, totalPages }` envelope.
class DoctorPagination {
  final int totalCount;
  final int page;
  final int limit;
  final int totalPages;

  const DoctorPagination({
    this.totalCount = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory DoctorPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorPagination();
    int parse(dynamic v, int fallback) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;
    return DoctorPagination(
      totalCount: parse(json['totalCount'], 0),
      page: parse(json['page'], 1),
      limit: parse(json['limit'], 20),
      totalPages: parse(json['totalPages'], 1),
    );
  }

  bool get hasMore => page < totalPages;
}
