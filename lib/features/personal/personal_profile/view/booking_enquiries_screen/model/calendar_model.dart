

import 'dart:convert';

// CalendarResponse model for the complete API response
class CalendarResponse {
  bool? success;
  List<String>? data;
  String? fee;
  String? durationInMinutes;
  String? bookingType;
  String? location;

  CalendarResponse({
    this.success,
    this.data,
    this.fee,
    this.durationInMinutes,
    this.bookingType,
    this.location,
  });

  factory CalendarResponse.fromJson(Map<String, dynamic> json) => CalendarResponse(
    success: json["success"],
    data: json["data"] != null 
        ? List<String>.from(json["data"])
        : null,
    fee: json["fee"]?.toString(),
    durationInMinutes: json["durationInMinutes"]?.toString(),
    bookingType: json["bookingType"],
    location: json["location"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data,
    "fee": fee,
    "durationInMinutes": durationInMinutes,
    "bookingType": bookingType,
    "location": location,
  };
}

// Legacy model for backward compatibility
CalendarModel calendarModelFromJson(String str) => CalendarModel.fromJson(json.decode(str));
String calendarModelToJson(CalendarModel data) => json.encode(data.toJson());

// Simple CalendarModel for individual dates (if needed)
class CalendarModel {
  String? date;

  CalendarModel({
    this.date,
  });

  factory CalendarModel.fromJson(Map<String, dynamic> json) => CalendarModel(
    date: json["date"],
  );

  Map<String, dynamic> toJson() => {
    "date": date,
  };
}
