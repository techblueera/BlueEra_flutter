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

  factory ReferralGetBdmDetailsModel.fromJson(Map<String, dynamic> json) {
    return ReferralGetBdmDetailsModel(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      v: json['__v'] is int ? json['__v'] : int.tryParse(json['__v']?.toString() ?? ''),
      aadharDocumentId: json['aadharDocumentId'] as String?,
      aadharDocumentUploaded: json['aadharDocumentUploaded'] as bool?,
      acceptedTerms: json['acceptedTerms'] as bool?,
      address: json['address'] as String?,
      addressProofDocumentId: json['addressProofDocumentId'] as String?,
      addressProofDocumentUploaded: json['addressProofDocumentUploaded'] as bool?,
      alternatePhoneNumber: json['alternatePhoneNumber']?.toString(),
      bankDetailsDocumentId: json['bankDetailsDocumentId'] as String?,
      bankDetailsDocumentUploaded: json['bankDetailsDocumentUploaded'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      dob: json['dob'] != null
          ? DateTime.tryParse(json['dob'].toString())
          : null,
      email: json['email'] as String?,
      highestEducationalQualification:
      json['highestEducationalQualification'] as String?,
      isBDMRegistered: json['isBDMRegistered'] as bool?,
      isPersonalInfoComplete: json['isPersonalInfoComplete'] as bool?,
      isReferralCodeSaved: json['isReferralCodeSaved'] as bool?,
      name: json['name'] as String?,
      panDocumentId: json['panDocumentId'] as String?,
      panDocumentUploaded: json['panDocumentUploaded'] as bool?,
      preferredCity: json['preferredCity'] as String?,
      preferredState: json['preferredState'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      workLocationPinCode: json['workLocationPinCode']?.toString(),
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