/// _id : "687712b56356e5da0ef2e12d"
/// user_Id : "687712116356e5da0ef2e125"
/// business_Id : "687712116356e5da0ef2e127"
/// business_doc : {"doc_type":"GST","doc_number":"234556323775","status":"PENDING","verifiedAt":null}
/// overall_status : "PENDING"
/// created_at : "2025-07-16T02:47:17.932Z"
/// updated_at : "2025-07-16T02:48:51.048Z"
/// __v : 0

class GetBusinessVerifyViewModel {
  GetBusinessVerifyViewModel({
      this.id, 
      this.userId, 
      this.businessId, 
      this.businessDoc, 
      this.ownerDoc,
      this.overallStatus,
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  GetBusinessVerifyViewModel.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['user_Id'];
    businessId = json['business_Id'];
    businessDoc = json['business_doc'] != null ? BusinessDoc.fromJson(json['business_doc']) : null;
    ownerDoc = json['owner_doc'] != null ? OwnBusinessDoc.fromJson(json['owner_doc']) : null;
    overallStatus = json['overall_status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
  }
  String? id;
  String? userId;
  String? businessId;
  BusinessDoc? businessDoc;
  OwnBusinessDoc? ownerDoc;
  String? overallStatus;
  String? createdAt;
  String? updatedAt;
  num? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['user_Id'] = userId;
    map['business_Id'] = businessId;
    if (businessDoc != null) {
      map['business_doc'] = businessDoc?.toJson();
    }
    map['overall_status'] = overallStatus;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

/// doc_type : "GST"
/// doc_number : "234556323775"
/// status : "PENDING"
/// verifiedAt : null

class BusinessDoc {
  BusinessDoc({
      this.docType, 
      this.docNumber, 
      this.docUrl,
      this.status,
      this.verifiedAt,});

  BusinessDoc.fromJson(dynamic json) {
    docType = json['doc_type'];
    docNumber = json['doc_number'];
    status = json['status'];
    docUrl = json['doc_url'];
    verifiedAt = json['verifiedAt'];
  }
  String? docType;
  String? docNumber;
  String? docUrl;
  String? status;
  dynamic verifiedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['doc_type'] = docType;
    map['doc_number'] = docNumber;
    map['status'] = status;
    map['doc_url'] = docUrl;
    map['verifiedAt'] = verifiedAt;
    return map;
  }

}
class OwnBusinessDoc {
  OwnBusinessDoc({
      this.docType,
    this.docUrl,
    this.status,
      this.verifiedAt,});

  OwnBusinessDoc.fromJson(dynamic json) {
    docType = json['doc_type'];
    status = json['status'];
    docUrl = json['doc_url'];
    verifiedAt = json['verifiedAt'];
  }
  String? docType;
  String? docUrl;
  String? status;
  dynamic verifiedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['doc_type'] = docType;
    map['status'] = status;
    map['doc_url'] = docUrl;
    map['verifiedAt'] = verifiedAt;
    return map;
  }

}