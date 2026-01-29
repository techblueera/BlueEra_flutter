import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';

class HealthCareAskAiModel extends BaseAiChatModel {
  List<String>? suggestions;
  Data? data;

  HealthCareAskAiModel(
      {
        super.conversationId,
        super.role,
        super.timestamp,
        super.message,
        this.suggestions,
        this.data,
        });

  HealthCareAskAiModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    message = json['reply'] ?? json['content'];
    conversationId = json['conversationId'];
    suggestions = json['suggestions'] != null
        ? List<String>.from(json['suggestions'])
        : null;
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['reply'] = this.message;
    data['conversationId'] = this.conversationId;
    data['suggestions'] = this.suggestions;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['timestamp'] = this.timestamp;
    return data;
  }
}

class Data {
  bool? success;
  List<HealthCareData>? healthCareData;

  Data({this.success, this.healthCareData});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      healthCareData = <HealthCareData>[];
      json['data'].forEach((v) {
        healthCareData!.add(new HealthCareData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.healthCareData != null) {
      data['data'] = this.healthCareData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HealthCareData {
  String? sId;
  String? businessId;
  String? departmentId;
  String? name;
  String? specialization;
  String? qualification;
  String? photo;
  String? availability;
  int? fees;
  bool? isOnLeave;
  String? createdAt;
  String? updatedAt;
  int? iV;
  HospitalInfo? hospitalInfo;

  HealthCareData(
      {this.sId,
        this.businessId,
        this.departmentId,
        this.name,
        this.specialization,
        this.qualification,
        this.photo,
        this.availability,
        this.fees,
        this.isOnLeave,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.hospitalInfo});

  HealthCareData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessId = json['businessId'];
    departmentId = json['departmentId'];
    name = json['name'];
    specialization = json['specialization'];
    qualification = json['qualification'];
    photo = json['photo'];
    availability = json['availability'];
    fees = json['fees'];
    isOnLeave = json['isOnLeave'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    hospitalInfo = json['hospitalInfo'] != null
        ? new HospitalInfo.fromJson(json['hospitalInfo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['departmentId'] = this.departmentId;
    data['name'] = this.name;
    data['specialization'] = this.specialization;
    data['qualification'] = this.qualification;
    data['photo'] = this.photo;
    data['availability'] = this.availability;
    data['fees'] = this.fees;
    data['isOnLeave'] = this.isOnLeave;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.hospitalInfo != null) {
      data['hospitalInfo'] = this.hospitalInfo!.toJson();
    }
    return data;
  }
}

class HospitalInfo {
  String? hospitalName;
  String? address;
  String? email;

  HospitalInfo({this.hospitalName, this.address, this.email});

  HospitalInfo.fromJson(Map<String, dynamic> json) {
    hospitalName = json['hospitalName'];
    address = json['address'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['hospitalName'] = this.hospitalName;
    data['address'] = this.address;
    data['email'] = this.email;
    return data;
  }
}
