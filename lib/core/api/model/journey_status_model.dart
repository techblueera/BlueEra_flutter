import 'dart:convert';
JourneyStatusModel journeyStatusModelFromJson(String str) => JourneyStatusModel.fromJson(json.decode(str));
String journeyStatusModelToJson(JourneyStatusModel data) => json.encode(data.toJson());
class JourneyStatusModel {
  JourneyStatusModel({
      this.success, 
      this.journeyId, 
      this.isEnded, 
      this.message,});

  JourneyStatusModel.fromJson(dynamic json) {
    success = json['success'];
    journeyId = json['journey_id'];
    isEnded = json['is_ended'];
    message = json['message'];
  }
  bool? success;
  String? journeyId;
  bool? isEnded;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['journey_id'] = journeyId;
    map['is_ended'] = isEnded;
    map['message'] = message;
    return map;
  }

}