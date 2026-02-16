class ReferralGetBdmDetailsModel {
  final String? id;
  final String? userId;
  final int? v;
  final String? aadharDocumentId;
  final bool? aadharDocumentUploaded;
  final bool? acceptedTerms;
  final String? address;
  final String? addressProofDocumentId;
  final bool? addressProofDocumentUploaded;
  final String? alternatePhoneNumber;
  final String? bankDetailsDocumentId;
  final bool? bankDetailsDocumentUploaded;
  final DateTime? createdAt;
  final DateTime? dob;
  final String? email;
  final String? highestEducationalQualification;
  final bool? isBDMRegistered;
  final bool? isPersonalInfoComplete;
  final bool? isReferralCodeSaved;
  final String? name;
  final String? panDocumentId;
  final bool? panDocumentUploaded;
  final String? preferredCity;
  final String? preferredState;
  final DateTime? updatedAt;
  final String? workLocationPinCode;

  ReferralGetBdmDetailsModel({
    this.id,
    this.userId,
    this.v,
    this.aadharDocumentId,
    this.aadharDocumentUploaded,
    this.acceptedTerms,
    this.address,
    this.addressProofDocumentId,
    this.addressProofDocumentUploaded,
    this.alternatePhoneNumber,
    this.bankDetailsDocumentId,
    this.bankDetailsDocumentUploaded,
    this.createdAt,
    this.dob,
    this.email,
    this.highestEducationalQualification,
    this.isBDMRegistered,
    this.isPersonalInfoComplete,
    this.isReferralCodeSaved,
    this.name,
    this.panDocumentId,
    this.panDocumentUploaded,
    this.preferredCity,
    this.preferredState,
    this.updatedAt,
    this.workLocationPinCode,
  });
  ReferralGetBdmDetailsModel copyWith({
    String? id,
    String? userId,
    int? v,
    String? aadharDocumentId,
    bool? aadharDocumentUploaded,
    bool? acceptedTerms,
    String? address,
    String? addressProofDocumentId,
    bool? addressProofDocumentUploaded,
    String? alternatePhoneNumber,
    String? bankDetailsDocumentId,
    bool? bankDetailsDocumentUploaded,
    DateTime? createdAt,
    DateTime? dob,
    String? email,
    String? highestEducationalQualification,
    bool? isBDMRegistered,
    bool? isPersonalInfoComplete,
    bool? isReferralCodeSaved,
    String? name,
    String? panDocumentId,
    bool? panDocumentUploaded,
    String? preferredCity,
    String? preferredState,
    DateTime? updatedAt,
    String? workLocationPinCode,
  }) {
    return ReferralGetBdmDetailsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      v: v ?? this.v,
      aadharDocumentId: aadharDocumentId ?? this.aadharDocumentId,
      aadharDocumentUploaded:
      aadharDocumentUploaded ?? this.aadharDocumentUploaded,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      address: address ?? this.address,
      addressProofDocumentId:
      addressProofDocumentId ?? this.addressProofDocumentId,
      addressProofDocumentUploaded:
      addressProofDocumentUploaded ?? this.addressProofDocumentUploaded,
      alternatePhoneNumber:
      alternatePhoneNumber ?? this.alternatePhoneNumber,
      bankDetailsDocumentId:
      bankDetailsDocumentId ?? this.bankDetailsDocumentId,
      bankDetailsDocumentUploaded:
      bankDetailsDocumentUploaded ?? this.bankDetailsDocumentUploaded,
      createdAt: createdAt ?? this.createdAt,
      dob: dob ?? this.dob,
      email: email ?? this.email,
      highestEducationalQualification:
      highestEducationalQualification ??
          this.highestEducationalQualification,
      isBDMRegistered: isBDMRegistered ?? this.isBDMRegistered,
      isPersonalInfoComplete:
      isPersonalInfoComplete ?? this.isPersonalInfoComplete,
      isReferralCodeSaved:
      isReferralCodeSaved ?? this.isReferralCodeSaved,
      name: name ?? this.name,
      panDocumentId: panDocumentId ?? this.panDocumentId,
      panDocumentUploaded:
      panDocumentUploaded ?? this.panDocumentUploaded,
      preferredCity: preferredCity ?? this.preferredCity,
      preferredState: preferredState ?? this.preferredState,
      updatedAt: updatedAt ?? this.updatedAt,
      workLocationPinCode:
      workLocationPinCode ?? this.workLocationPinCode,
    );
  }
  factory ReferralGetBdmDetailsModel.fromJson(Map<String, dynamic> json) {
    return ReferralGetBdmDetailsModel(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      v: json['__v'] is int
          ? json['__v']
          : int.tryParse(json['__v']?.toString() ?? ''),
      aadharDocumentId: json['aadharDocumentId'] as String?,
      aadharDocumentUploaded:
      (json['aadharDocumentUploaded'] as bool?) ?? false,
      acceptedTerms: (json['acceptedTerms'] as bool?) ?? false,
      address: json['address'] as String?,
      addressProofDocumentId:
      json['addressProofDocumentId'] as String?,
      addressProofDocumentUploaded:
      (json['addressProofDocumentUploaded'] as bool?) ?? false,
      alternatePhoneNumber:
      json['alternatePhoneNumber']?.toString(),
      bankDetailsDocumentId:
      json['bankDetailsDocumentId'] as String?,
      bankDetailsDocumentUploaded:
      (json['bankDetailsDocumentUploaded'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      dob: json['dob'] != null
          ? DateTime.tryParse(json['dob'].toString())
          : null,
      email: json['email'] as String?,
      highestEducationalQualification:
      json['highestEducationalQualification'] as String?,
      isBDMRegistered:
      (json['isBDMRegistered'] as bool?) ?? false,
      isPersonalInfoComplete:
      (json['isPersonalInfoComplete'] as bool?) ?? false,
      isReferralCodeSaved:
      (json['isReferralCodeSaved'] as bool?) ?? false,
      name: json['name'] as String?,
      panDocumentId: json['panDocumentId'] as String?,
      panDocumentUploaded:
      (json['panDocumentUploaded'] as bool?) ?? false,
      preferredCity: json['preferredCity'] as String?,
      preferredState: json['preferredState'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      workLocationPinCode:
      json['workLocationPinCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      '__v': v,
      'aadharDocumentId': aadharDocumentId,
      'aadharDocumentUploaded': aadharDocumentUploaded,
      'acceptedTerms': acceptedTerms,
      'address': address,
      'addressProofDocumentId': addressProofDocumentId,
      'addressProofDocumentUploaded': addressProofDocumentUploaded,
      'alternatePhoneNumber': alternatePhoneNumber,
      'bankDetailsDocumentId': bankDetailsDocumentId,
      'bankDetailsDocumentUploaded': bankDetailsDocumentUploaded,
      'createdAt': createdAt?.toIso8601String(),
      'dob': dob?.toIso8601String(),
      'email': email,
      'highestEducationalQualification': highestEducationalQualification,
      'isBDMRegistered': isBDMRegistered,
      'isPersonalInfoComplete': isPersonalInfoComplete,
      'isReferralCodeSaved': isReferralCodeSaved,
      'name': name,
      'panDocumentId': panDocumentId,
      'panDocumentUploaded': panDocumentUploaded,
      'preferredCity': preferredCity,
      'preferredState': preferredState,
      'updatedAt': updatedAt?.toIso8601String(),
      'workLocationPinCode': workLocationPinCode,
    };
  }
}