import 'dart:convert';
GstVerifyModel gstVerifyModelFromJson(String str) => GstVerifyModel.fromJson(json.decode(str));
String gstVerifyModelToJson(GstVerifyModel data) => json.encode(data.toJson());
class GstVerifyModel {
  GstVerifyModel({
      this.success, 
      this.isVerified, 
      this.data,});

  GstVerifyModel.fromJson(dynamic json) {
    success = json['success'];
    isVerified = json['is_verified'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  bool? success;
  bool? isVerified;
  Data? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['is_verified'] = isVerified;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.gstin, 
      this.legalName, 
      this.tradeName, 
      this.status, 
      this.registrationDate, 
      this.businessType, 
      this.address,});

  Data.fromJson(dynamic json) {
    gstin = json['gstin'];
    legalName = json['legalName'];
    tradeName = json['tradeName'];
    status = json['status'];
    registrationDate = json['registrationDate'];
    businessType = json['businessType'];
    address = json['address'] != null ? Address.fromJson(json['address']) : null;
  }
  String? gstin;
  String? legalName;
  String? tradeName;
  String? status;
  String? registrationDate;
  String? businessType;
  Address? address;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['gstin'] = gstin;
    map['legalName'] = legalName;
    map['tradeName'] = tradeName;
    map['status'] = status;
    map['registrationDate'] = registrationDate;
    map['businessType'] = businessType;
    if (address != null) {
      map['address'] = address?.toJson();
    }
    return map;
  }

}

Address addressFromJson(String str) => Address.fromJson(json.decode(str));
String addressToJson(Address data) => json.encode(data.toJson());
class Address {
  Address({
      this.bnm, 
      this.loc, 
      this.st, 
      this.bno, 
      this.dst, 
      this.lt, 
      this.locality, 
      this.pncd, 
      this.landMark, 
      this.stcd, 
      this.geocodelvl, 
      this.flno, 
      this.lg,});

  Address.fromJson(dynamic json) {
    bnm = json['bnm'];
    loc = json['loc'];
    st = json['st'];
    bno = json['bno'];
    dst = json['dst'];
    lt = json['lt'];
    locality = json['locality'];
    pncd = json['pncd'];
    landMark = json['landMark'];
    stcd = json['stcd'];
    geocodelvl = json['geocodelvl'];
    flno = json['flno'];
    lg = json['lg'];
  }
  String? bnm;
  String? loc;
  String? st;
  String? bno;
  String? dst;
  String? lt;
  String? locality;
  String? pncd;
  String? landMark;
  String? stcd;
  String? geocodelvl;
  String? flno;
  String? lg;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bnm'] = bnm;
    map['loc'] = loc;
    map['st'] = st;
    map['bno'] = bno;
    map['dst'] = dst;
    map['lt'] = lt;
    map['locality'] = locality;
    map['pncd'] = pncd;
    map['landMark'] = landMark;
    map['stcd'] = stcd;
    map['geocodelvl'] = geocodelvl;
    map['flno'] = flno;
    map['lg'] = lg;
    return map;
  }

}