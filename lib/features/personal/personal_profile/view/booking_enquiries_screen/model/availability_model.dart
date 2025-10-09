
class AvailabilityResponse {
  final bool? success;
  final String? message;
  final AvailabilityModel? data;

  AvailabilityResponse({
    this.success,
    this.message,
    this.data,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return AvailabilityResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? AvailabilityModel.fromJson(json['data'])
          : null,
    );
  }
}


class AvailabilityModel {
  final String? id;
  final String? availableForType;
  final String? availableForId;
  final String? bookingType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? durationInMinutes;
  final int? fee;
  final String? instructions;
  final Location? location;
  final List<Schedule>? schedule;
  final List<SpecialOverride>? specialOverrides;
  final String? timezone;
  final int? v;

  AvailabilityModel({
    this.id,
    this.availableForType,
    this.availableForId,
    this.bookingType,
    this.createdAt,
    this.updatedAt,
    this.durationInMinutes,
    this.fee,
    this.instructions,
    this.location,
    this.schedule,
    this.specialOverrides,
    this.timezone,
    this.v,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) =>
      AvailabilityModel(
        id: json["_id"],
        availableForType: json["availableForType"],
        availableForId: json["availableForId"],
        bookingType: json["bookingType"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        durationInMinutes: json["durationInMinutes"],
        fee: json["fee"],
        instructions: json["instructions"],
        location: json["location"] == null
            ? null
            : Location.fromJson(json["location"]),
        schedule: json["schedule"] == null
            ? []
            : List<Schedule>.from(
            json["schedule"].map((x) => Schedule.fromJson(x))),
        specialOverrides: json["specialOverrides"] == null
            ? []
            : List<SpecialOverride>.from(
            json["specialOverrides"].map((x) => SpecialOverride.fromJson(x))),
        timezone: json["timezone"],
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "availableForType": availableForType,
    "availableForId": availableForId,
    "bookingType": bookingType,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "durationInMinutes": durationInMinutes,
    "fee": fee,
    "instructions": instructions,
    "location": location?.toJson(),
    "schedule": schedule == null
        ? []
        : List<dynamic>.from(schedule!.map((x) => x.toJson())),
    "specialOverrides": specialOverrides == null
        ? []
        : List<dynamic>.from(specialOverrides!.map((x) => x.toJson())),
    "timezone": timezone,
    "__v": v,
  };

  AvailabilityModel copyWith({
    String? id,
    String? availableForType,
    String? availableForId,
    String? bookingType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? durationInMinutes,
    int? fee,
    String? instructions,
    Location? location,
    List<Schedule>? schedule,
    List<SpecialOverride>? specialOverrides,
    String? timezone,
    int? v,
  }) =>
      AvailabilityModel(
        id: id ?? this.id,
        availableForType: availableForType ?? this.availableForType,
        availableForId: availableForId ?? this.availableForId,
        bookingType: bookingType ?? this.bookingType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        durationInMinutes: durationInMinutes ?? this.durationInMinutes,
        fee: fee ?? this.fee,
        instructions: instructions ?? this.instructions,
        location: location ?? this.location,
        schedule: schedule ?? this.schedule,
        specialOverrides: specialOverrides ?? this.specialOverrides,
        timezone: timezone ?? this.timezone,
        v: v ?? this.v,
      );
}

class Location {
  final String? landmark;
  final String? address;
  final String? latitude;
  final String? longitude;

  Location({
    this.landmark,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    landmark: json["landmark"],
    address: json["address"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    // latitude: (json["latitude"] is int)
    //     ? (json["latitude"] as int).toDouble()
    //     : json["latitude"],
    // longitude: (json["longitude"] is int)
    //     ? (json["longitude"] as int).toDouble()
    //     : json["longitude"],
  );

  Map<String, dynamic> toJson() => {
    "landmark": landmark,
    "address": address,
    "latitude": latitude,
    "longitude": longitude,
  };

  Location copyWith({
    String? landmark,
    String? address,
    String? latitude,
    String? longitude,
  }) =>
      Location(
        landmark: landmark ?? this.landmark,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}

class Schedule {
  final String? day;
  final bool? isOpen;
  final List<TimeSlot>? timeSlots;

  Schedule({
    this.day,
    this.isOpen,
    this.timeSlots,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    day: json["day"],
    isOpen: json["isOpen"],
    timeSlots: json["timeSlots"] == null
        ? []
        : List<TimeSlot>.from(
        json["timeSlots"].map((x) => TimeSlot.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "day": day,
    "isOpen": isOpen,
    "timeSlots": timeSlots == null
        ? []
        : List<dynamic>.from(timeSlots!.map((x) => x.toJson())),
  };

  Schedule copyWith({
    String? day,
    bool? isOpen,
    List<TimeSlot>? timeSlots,
  }) =>
      Schedule(
        day: day ?? this.day,
        isOpen: isOpen ?? this.isOpen,
        timeSlots: timeSlots ?? this.timeSlots,
      );
}

class TimeSlot {
  final String? startTime;
  final String? endTime;

  TimeSlot({
    this.startTime,
    this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    startTime: json["startTime"],
    endTime: json["endTime"],
  );

  Map<String, dynamic> toJson() => {
    "startTime": startTime,
    "endTime": endTime,
  };

  TimeSlot copyWith({
    String? startTime,
    String? endTime,
  }) =>
      TimeSlot(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );
}

class SpecialOverride {
  final DateTime? date;
  final bool? isOpen;
  final List<TimeSlot>? timeSlots;

  SpecialOverride({
    this.date,
    this.isOpen,
    this.timeSlots,
  });

  factory SpecialOverride.fromJson(Map<String, dynamic> json) =>
      SpecialOverride(
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
        isOpen: json["isOpen"],
        timeSlots: json["timeSlots"] == null
            ? []
            : List<TimeSlot>.from(
            json["timeSlots"].map((x) => TimeSlot.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "date": date?.toIso8601String(),
    "isOpen": isOpen,
    "timeSlots": timeSlots == null
        ? []
        : List<dynamic>.from(timeSlots!.map((x) => x.toJson())),
  };

  SpecialOverride copyWith({
    DateTime? date,
    bool? isOpen,
    List<TimeSlot>? timeSlots,
  }) =>
      SpecialOverride(
        date: date ?? this.date,
        isOpen: isOpen ?? this.isOpen,
        timeSlots: timeSlots ?? this.timeSlots,
      );
}
