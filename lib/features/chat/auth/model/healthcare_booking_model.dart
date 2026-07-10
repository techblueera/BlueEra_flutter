/// Payload carried by a `messageType: "healthcare_booking"` chat message.
///
/// Mirrors the shape settled in
/// `lib/docs/healthcare-appointment-ui-integration.md` §3 (booking / OPD
/// appointment) — one hospital, one doctor, one date, optionally linked
/// back to a prior enquiry via [enquiryId] (enquiry-first flow, §0).
///
/// Doctor snapshot fields ([opdId] / [doctorName] / [department] /
/// [fees] / [doctorImage]) are populated **server-side** from the OPD
/// record when the booking is created — the client only sends `opd_id`.
/// A small listing snapshot ([listingName] / [listingImage] /
/// [location]) is embedded so the in-chat card renders without
/// re-fetching the hospital. `fees` is **display only** — nothing is
/// charged.
class HealthcareBookingModel {
  String? appointmentId;
  String? hospitalId;
  String? ownerId;
  String? customerId;

  /// `HOSPITAL` for hospital-appointment bookings; `LABORATORY` for
  /// lab test bookings (`laboratory-booking-ui-integration.md`). Both
  /// share the `healthcare_booking` message type — the chat card
  /// branches on this value to pick lab vs hospital labels/tiles and
  /// to route accept/decline/cancel to the correct service.
  String? category;

  // Doctor snapshot (server-derived from the OPD record) — hospital
  // bookings only. Empty for lab bookings.
  String? opdId;
  String? doctorName;
  String? department;
  num? fees;
  String? doctorImage;

  // Test snapshot (server-derived from the PathologyTest record) —
  // lab bookings only. Per doc §3 the server denormalizes these onto
  // the booking so the chat card renders standalone.
  String? testId;
  String? testName;
  num? price;
  num? estimatedReportHours;

  // Lab collection preferences (doc §1): `HOME` requires [address];
  // `AT_LAB` hides it. Both are absent for hospital bookings.
  String? collectionMode;
  String? address;

  /// ISO-8601 timestamp (day precision — server enforces today-or-later).
  String? appointmentDate;

  /// Free-text preferred window, e.g. `"10:00 – 11:00 AM"`.
  String? preferredTime;

  String? patientName;

  /// Set only when this booking was raised via the enquiry-first flow
  /// (customer sent `enquiry_id` linking back to their prior enquiry).
  String? enquiryId;

  String? note;
  List<String>? photos;

  // Listing snapshot.
  String? listingName;
  String? listingImage;
  String? location;

  /// 'pending' | 'accepted' | 'declined' | 'cancelled' (buyer-cancel).
  String? status;

  String? createdAt;
  String? updatedAt;

  HealthcareBookingModel({
    this.appointmentId,
    this.hospitalId,
    this.ownerId,
    this.customerId,
    this.category,
    this.opdId,
    this.doctorName,
    this.department,
    this.fees,
    this.doctorImage,
    this.testId,
    this.testName,
    this.price,
    this.estimatedReportHours,
    this.collectionMode,
    this.address,
    this.appointmentDate,
    this.preferredTime,
    this.patientName,
    this.enquiryId,
    this.note,
    this.photos,
    this.listingName,
    this.listingImage,
    this.location,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  static List<String>? _stringList(dynamic v) => v is List
      ? List<String>.from(v.map((e) => e.toString()))
      : null;

  static num? _num(dynamic v) {
    if (v is num) return v;
    if (v is String && v.trim().isNotEmpty) return num.tryParse(v);
    return null;
  }

  factory HealthcareBookingModel.fromJson(Map<String, dynamic> json) {
    // Doctor object may be nested (`doctor: {...}`) — the doc's chat-card
    // schema in §4 uses that shape — or flattened onto the top level
    // when the REST list endpoint returns the raw document (§3). Accept
    // both so the socket + REST paths share this parser.
    final Map<String, dynamic>? doctor = (json['doctor'] is Map)
        ? Map<String, dynamic>.from(json['doctor'] as Map)
        : null;
    dynamic pick(String flat, String nested) =>
        json[flat] ?? doctor?[nested] ?? doctor?[flat];

    return HealthcareBookingModel(
      appointmentId: (json['appointmentId'] ??
              json['_id'] ??
              json['id'])
          ?.toString(),
      hospitalId:
          (json['hospitalId'] ?? json['hospital_id'])?.toString(),
      ownerId: (json['ownerId'] ?? json['owner_id'])?.toString(),
      customerId:
          (json['customerId'] ?? json['customer_id'])?.toString(),
      category: json['category']?.toString(),
      opdId: pick('opdId', 'opdId')?.toString() ??
          (json['opd_id'] ?? doctor?['_id'] ?? doctor?['id'])?.toString(),
      doctorName: pick('doctorName', 'name')?.toString(),
      department: pick('department', 'department')?.toString(),
      fees: _num(pick('fees', 'fees')),
      doctorImage:
          pick('doctorImage', 'image')?.toString() ??
              pick('doctorImage', 'imageUrl')?.toString(),
      // Lab test snapshot — flat or nested (`test: {...}`), same
      // dual-shape treatment as the doctor snapshot above.
      testId: (json['testId'] ?? json['test_id'])?.toString(),
      testName: (json['testName'] ?? json['test_name'])?.toString(),
      price: _num(json['price']),
      estimatedReportHours: _num(json['estimatedReportHours'] ??
          json['estimated_report_hours'] ??
          json['reportHours']),
      collectionMode:
          (json['collectionMode'] ?? json['collection_mode'])?.toString(),
      address: json['address']?.toString(),
      appointmentDate: (json['appointmentDate'] ??
              json['appointment_date'])
          ?.toString(),
      preferredTime: (json['preferredTime'] ??
              json['preferred_time'])
          ?.toString(),
      patientName:
          (json['patientName'] ?? json['patient_name'])?.toString(),
      enquiryId: (json['enquiryId'] ?? json['enquiry_id'])?.toString(),
      note: json['note']?.toString(),
      photos: _stringList(json['photos']),
      listingName:
          (json['hospitalName'] ?? json['listingName'])?.toString(),
      listingImage: (json['hospitalImage'] ??
              json['listingImage'] ??
              json['listing_image'])
          ?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString(),
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'hospitalId': hospitalId,
      'ownerId': ownerId,
      'customerId': customerId,
      'category': category,
      'opdId': opdId,
      'doctorName': doctorName,
      'department': department,
      'fees': fees,
      'doctorImage': doctorImage,
      'testId': testId,
      'testName': testName,
      'price': price,
      'estimatedReportHours': estimatedReportHours,
      'collectionMode': collectionMode,
      'address': address,
      'appointmentDate': appointmentDate,
      'preferredTime': preferredTime,
      'patientName': patientName,
      'enquiryId': enquiryId,
      'note': note,
      'photos': photos,
      'listingName': listingName,
      'listingImage': listingImage,
      'location': location,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
