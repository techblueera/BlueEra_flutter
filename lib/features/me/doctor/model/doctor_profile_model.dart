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

  /// `"₹600/Visit"`. Empty when the fee is unset — a null `consultationFee`
  /// means "not set", and rendering `₹0` would advertise a free consultation.
  String get feeLabel {
    if (consultationFee == null) return '';
    final fee = consultationFee!;
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
