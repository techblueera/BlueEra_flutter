import 'package:BlueEra/features/me/doctor/model/doctor_certificate_model.dart';

/// The standalone doctor's professional profile — the `data` object of
/// `GET|POST|PUT hospital-service/doctors[/me]`.
///
/// Every field is optional server-side: a doctor may create an empty profile
/// and fill it in later, so nothing here is non-nullable.
class DoctorProfile {
  final String? id;
  final String? userId;
  final List<String> degree;
  final List<String> specialization;
  final List<String> languagesSpoken;
  final List<String> expertise;
  final int? experienceYears;
  final String? registrationNumber;
  final num? consultationFee;
  final String? feeType;
  final String? address;
  final String? description;

  /// Included by `/doctors/me` and `/doctors/full/:userId`; empty on the
  /// create/update responses, which return the profile only.
  final List<DoctorCertificate> certificates;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DoctorProfile({
    this.id,
    this.userId,
    this.degree = const [],
    this.specialization = const [],
    this.languagesSpoken = const [],
    this.expertise = const [],
    this.experienceYears,
    this.registrationNumber,
    this.consultationFee,
    this.feeType,
    this.address,
    this.description,
    this.certificates = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['_id']?.toString(),
      userId: json['userId']?.toString(),
      degree: _stringList(json['degree']),
      specialization: _stringList(json['specialization']),
      languagesSpoken: _stringList(json['languagesSpoken']),
      expertise: _stringList(json['expertise']),
      experienceYears: _toInt(json['experienceYears']),
      registrationNumber: json['registrationNumber']?.toString(),
      consultationFee: json['consultationFee'] is num
          ? json['consultationFee'] as num
          : num.tryParse(json['consultationFee']?.toString() ?? ''),
      feeType: json['feeType']?.toString(),
      address: json['address']?.toString(),
      description: json['description']?.toString(),
      certificates: DoctorCertificate.listFrom(json['certificates']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static int? _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  /// Card/profile subtitle — the guide defines it as `specialization[0]`.
  String get headline =>
      specialization.isNotEmpty ? specialization.first : '';

  // ── Doctor-card completeness (docs/newdrcard.png) ───────────────────
  //
  // The redesigned listing card renders specialization, experience, degree,
  // services and the consultation fee. A card missing any of them reads as
  // broken rather than sparse, so the dashboard collects all five before it
  // will show the profile. Name, photo and rating are NOT listed: they come
  // from the business listing, which every doctor already has.

  /// The card-critical field keys, in the order the gate form renders them.
  static const List<String> cardRequiredKeys = [
    'specialization',
    'experienceYears',
    'degree',
    'expertise',
    'consultationFee',
  ];

  /// Which of [cardRequiredKeys] are still empty.
  ///
  /// `0` counts as empty for both numbers, matching how the rest of the app
  /// already reads them: `DoctorDiscoverSummary.experienceLabel` hides a `0`
  /// because it reads as "no experience" rather than "not filled in", and a
  /// `₹0` fee would advertise a free consultation.
  List<String> get missingCardFields => [
        if (specialization.isEmpty) 'specialization',
        if ((experienceYears ?? 0) <= 0) 'experienceYears',
        if (degree.isEmpty) 'degree',
        if (expertise.isEmpty) 'expertise',
        if ((consultationFee ?? 0) <= 0) 'consultationFee',
      ];

  /// True once the card can be rendered in full.
  bool get hasCardEssentials => missingCardFields.isEmpty;

  /// The `feeType` enum value the app writes for the card's "₹600/Visit"
  /// line. Kept here so the About Me form, the mandatory-details gate and the
  /// card preview all send and render the same one.
  static const String perVisitFeeType = 'Per Visit';

  /// `"₹600/Visit"`. Empty when the fee is unset — a null `consultationFee`
  /// means "not set", and rendering `₹0` would advertise a free consultation.
  String get feeLabel => formatFee(consultationFee, feeType);

  /// [feeLabel] for values that are not on a [DoctorProfile] yet — the gate
  /// form's live preview renders straight from its own inputs.
  static String formatFee(num? fee, String? feeType) {
    if (fee == null) return '';
    final amount = fee % 1 == 0 ? fee.toInt().toString() : fee.toString();
    final type = (feeType ?? '').replaceFirst(RegExp(r'^Per\s+'), '').trim();
    return type.isEmpty ? '₹$amount' : '₹$amount/$type';
  }

  DoctorProfile copyWith({List<DoctorCertificate>? certificates}) {
    return DoctorProfile(
      id: id,
      userId: userId,
      degree: degree,
      specialization: specialization,
      languagesSpoken: languagesSpoken,
      expertise: expertise,
      experienceYears: experienceYears,
      registrationNumber: registrationNumber,
      consultationFee: consultationFee,
      feeType: feeType,
      address: address,
      description: description,
      certificates: certificates ?? this.certificates,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
