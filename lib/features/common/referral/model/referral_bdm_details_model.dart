/// Mirrors the legacy ReferralGetBdmDetailsModel used by the existing
/// referral flow but lives in the new package so the old folder can be
/// deleted without breaking imports here.
class ReferralBdmDetailsModel {
  final bool? success;
  final String? status;
  final BdmData? data;

  ReferralBdmDetailsModel({this.success, this.status, this.data});

  factory ReferralBdmDetailsModel.fromJson(Map<String, dynamic> json) {
    return ReferralBdmDetailsModel(
      success: json['success'],
      status: json['status'],
      data: json['data'] != null ? BdmData.fromJson(json['data']) : null,
    );
  }
}

class BdmData {
  final String? id;
  final String? userId;
  final String? walletId;
  final String? fullName;
  final String? email;
  final String? alternateMobileNo;
  final String? education;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final BdmDob? dob;
  final BdmLocation? location;
  final BdmDocuments? documents;

  BdmData({
    this.id,
    this.userId,
    this.walletId,
    this.fullName,
    this.email,
    this.alternateMobileNo,
    this.education,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.dob,
    this.location,
    this.documents,
  });

  factory BdmData.fromJson(Map<String, dynamic> json) {
    return BdmData(
      id: json['id'],
      userId: json['userId'],
      walletId: json['walletId'],
      fullName: json['fullName'],
      email: json['email'],
      alternateMobileNo: json['alternateMobileNo'],
      education: json['education'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      dob: json['dob'] != null ? BdmDob.fromJson(json['dob']) : null,
      location:
          json['location'] != null ? BdmLocation.fromJson(json['location']) : null,
      documents: json['documents'] != null
          ? BdmDocuments.fromJson(json['documents'])
          : null,
    );
  }
}

class BdmDob {
  final int? day;
  final int? month;
  final int? year;
  BdmDob({this.day, this.month, this.year});
  factory BdmDob.fromJson(Map<String, dynamic> json) => BdmDob(
        day: json['day'],
        month: json['month'],
        year: json['year'],
      );
}

class BdmLocation {
  final String? pincode;
  final String? state;
  final String? city;
  final String? addressString;
  BdmLocation({this.pincode, this.state, this.city, this.addressString});
  factory BdmLocation.fromJson(Map<String, dynamic> json) => BdmLocation(
        pincode: json['pincode'],
        state: json['state'],
        city: json['city'],
        addressString: json['addressString'],
      );
}

/// Per the new spec the `documents` sub-object only contains
/// `bankDetails`. Aadhar/PAN/addressProof are gone from the response
/// schema (Mongoose strips them on read).
class BdmDocuments {
  final String? bankDetails;
  BdmDocuments({this.bankDetails});
  factory BdmDocuments.fromJson(Map<String, dynamic> json) =>
      BdmDocuments(bankDetails: json['bankDetails']);
}
