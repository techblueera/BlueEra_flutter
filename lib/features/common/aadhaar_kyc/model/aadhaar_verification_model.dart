/// Models for the generic per-user Aadhaar OKYC (OTP) verification flow.
/// Owned by be_user_service. See
/// docs/backend/aadhaar-verification-ui-integration.md.

/// Parsed body of `GET /user/aadhaar/status`.
class AadhaarStatusData {
  final bool isVerified;

  /// null | "OTP_SENT" | "VERIFIED" — an in-progress attempt is treated as
  /// not verified (start fresh).
  final String? attemptStatus;
  final String? aadhaarLast4;
  final String? name;
  final String? verifiedAt;

  AadhaarStatusData({
    required this.isVerified,
    this.attemptStatus,
    this.aadhaarLast4,
    this.name,
    this.verifiedAt,
  });

  factory AadhaarStatusData.fromJson(Map<String, dynamic> json) {
    return AadhaarStatusData(
      isVerified: json['is_verified'] == true,
      attemptStatus: json['attempt_status'] as String?,
      aadhaarLast4: json['aadhaar_last4'] as String?,
      name: json['name'] as String?,
      verifiedAt: json['verified_at'] as String?,
    );
  }
}

/// Parsed `data` of a successful `POST /user/aadhaar/verify-otp`.
class AadhaarVerifiedIdentity {
  final String? name;
  final String? gender;
  final String? dateOfBirth;
  final String? careOf;
  final String? fullAddress;
  final String? aadhaarLast4;

  AadhaarVerifiedIdentity({
    this.name,
    this.gender,
    this.dateOfBirth,
    this.careOf,
    this.fullAddress,
    this.aadhaarLast4,
  });

  factory AadhaarVerifiedIdentity.fromJson(Map<String, dynamic> json) {
    return AadhaarVerifiedIdentity(
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      careOf: json['care_of'] as String?,
      fullAddress: json['full_address'] as String?,
      aadhaarLast4: json['aadhaar_last4'] as String?,
    );
  }
}
