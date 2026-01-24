class TimingModel {
  String? id;
  String? userId;
  String? businessProfileId;
  DaySchedule? monday;
  DaySchedule? tuesday;
  DaySchedule? wednesday;
  DaySchedule? thursday;
  DaySchedule? friday;
  DaySchedule? saturday;
  DaySchedule? sunday;

  TimingModel({
    this.id,
    this.userId,
    this.businessProfileId,
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });

  factory TimingModel.fromJson(Map<String, dynamic> json) {
    return TimingModel(
      id: json['_id'],
      userId: json['userId'],
      businessProfileId: json['businessProfileId'],
      monday: json['monday'] != null ? DaySchedule.fromJson(json['monday']) : null,
      tuesday: json['tuesday'] != null ? DaySchedule.fromJson(json['tuesday']) : null,
      wednesday: json['wednesday'] != null ? DaySchedule.fromJson(json['wednesday']) : null,
      thursday: json['thursday'] != null ? DaySchedule.fromJson(json['thursday']) : null,
      friday: json['friday'] != null ? DaySchedule.fromJson(json['friday']) : null,
      saturday: json['saturday'] != null ? DaySchedule.fromJson(json['saturday']) : null,
      sunday: json['sunday'] != null ? DaySchedule.fromJson(json['sunday']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (monday != null) data['monday'] = monday!.toJson();
    if (tuesday != null) data['tuesday'] = tuesday!.toJson();
    if (wednesday != null) data['wednesday'] = wednesday!.toJson();
    if (thursday != null) data['thursday'] = thursday!.toJson();
    if (friday != null) data['friday'] = friday!.toJson();
    if (saturday != null) data['saturday'] = saturday!.toJson();
    if (sunday != null) data['sunday'] = sunday!.toJson();
    return data;
  }
}

class DaySchedule {
  bool? isOpen;
  String? openTime;
  String? closeTime;

  DaySchedule({this.isOpen, this.openTime, this.closeTime});

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isOpen: json['isOpen'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }
}
