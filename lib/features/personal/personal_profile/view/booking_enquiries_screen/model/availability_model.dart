class AvailabilityModel {
  final String? bookingType;
  final String? location;
  final String? fee;
  final String? durationInMinutes;
  final List<ScheduleModel>? schedule;
  final String? timezone;

  AvailabilityModel({
    this.bookingType,
    this.location,
    this.fee,
    this.durationInMinutes,
    this.schedule,
    this.timezone,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      bookingType: json['bookingType'],
      location: json['location'],
      fee: json['fee']?.toString(),
      durationInMinutes: json['durationInMinutes']?.toString(),
      timezone: json['timezone'],
      schedule: json['schedule'] != null
          ? List<ScheduleModel>.from(
              json['schedule'].map((x) => ScheduleModel.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingType': bookingType,
      'location': location,
      'fee': fee,
      'durationInMinutes': durationInMinutes,
      'timezone': timezone,
      'schedule': schedule?.map((x) => x.toJson()).toList(),
    };
  }
}

class ScheduleModel {
  final String? day;
  final bool? isOpen;
  final List<TimeSlotModel>? timeSlots;

  ScheduleModel({
    this.day,
    this.isOpen,
    this.timeSlots,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      day: json['day'],
      isOpen: json['isOpen'],
      timeSlots: json['timeSlots'] != null
          ? List<TimeSlotModel>.from(
              json['timeSlots'].map((x) => TimeSlotModel.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isOpen': isOpen,
      'timeSlots': timeSlots?.map((x) => x.toJson()).toList(),
    };
  }
}

class TimeSlotModel {
  final String? startTime;
  final String? endTime;

  TimeSlotModel({
    this.startTime,
    this.endTime,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

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
