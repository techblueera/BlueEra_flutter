import 'dart:convert';
ProfessionalsTimingResModel professionalsTimingResModelFromJson(String str) => ProfessionalsTimingResModel.fromJson(json.decode(str));
String professionalsTimingResModelToJson(ProfessionalsTimingResModel data) => json.encode(data.toJson());
class ProfessionalsTimingResModel {
  ProfessionalsTimingResModel({
      this.success, 
      this.data,});

  ProfessionalsTimingResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? ProfessionalsTimingData.fromJson(json['data']) : null;
  }
  bool? success;
  ProfessionalsTimingData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

ProfessionalsTimingData dataFromJson(String str) => ProfessionalsTimingData.fromJson(json.decode(str));
String dataToJson(ProfessionalsTimingData data) => json.encode(data.toJson());
class ProfessionalsTimingData {
  ProfessionalsTimingData({
      this.schedule, 
      this.id, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.updatedAt,});

  ProfessionalsTimingData.fromJson(dynamic json) {
    schedule = json['schedule'] != null ? Schedule.fromJson(json['schedule']) : null;
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  Schedule? schedule;
  String? id;
  String? userId;
  int? v;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (schedule != null) {
      map['schedule'] = schedule?.toJson();
    }
    map['_id'] = id;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

Schedule scheduleFromJson(String str) => Schedule.fromJson(json.decode(str));
String scheduleToJson(Schedule data) => json.encode(data.toJson());
class Schedule {
  Schedule({
      this.monday, 
      this.tuesday, 
      this.wednesday, 
      this.thursday, 
      this.friday, 
      this.saturday, 
      this.sunday,});

  Schedule.fromJson(dynamic json) {
    monday = json['monday'] != null ? ProfessionalDaySchedule.fromJson(json['monday']) : null;
    tuesday = json['tuesday'] != null ? ProfessionalDaySchedule.fromJson(json['tuesday']) : null;
    wednesday = json['wednesday'] != null ? ProfessionalDaySchedule.fromJson(json['wednesday']) : null;
    thursday = json['thursday'] != null ? ProfessionalDaySchedule.fromJson(json['thursday']) : null;
    friday = json['friday'] != null ? ProfessionalDaySchedule.fromJson(json['friday']) : null;
    saturday = json['saturday'] != null ? ProfessionalDaySchedule.fromJson(json['saturday']) : null;
    sunday = json['sunday'] != null ? ProfessionalDaySchedule.fromJson(json['sunday']) : null;
  }
  ProfessionalDaySchedule? monday;
  ProfessionalDaySchedule? tuesday;
  ProfessionalDaySchedule? wednesday;
  ProfessionalDaySchedule? thursday;
  ProfessionalDaySchedule? friday;
  ProfessionalDaySchedule? saturday;
  ProfessionalDaySchedule? sunday;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (monday != null) {
      map['monday'] = monday?.toJson();
    }
    if (tuesday != null) {
      map['tuesday'] = tuesday?.toJson();
    }
    if (wednesday != null) {
      map['wednesday'] = wednesday?.toJson();
    }
    if (thursday != null) {
      map['thursday'] = thursday?.toJson();
    }
    if (friday != null) {
      map['friday'] = friday?.toJson();
    }
    if (saturday != null) {
      map['saturday'] = saturday?.toJson();
    }
    if (sunday != null) {
      map['sunday'] = sunday?.toJson();
    }
    return map;
  }

}

ProfessionalDaySchedule sundayFromJson(String str) => ProfessionalDaySchedule.fromJson(json.decode(str));
String sundayToJson(ProfessionalDaySchedule data) => json.encode(data.toJson());
class ProfessionalDaySchedule {
  ProfessionalDaySchedule({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  ProfessionalDaySchedule.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}
