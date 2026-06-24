class AvailabilityResponse {
  bool? success;
  AvailabilityData? data;

  AvailabilityResponse({this.success, this.data});

  AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new AvailabilityData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class AvailabilityData {
  String? sId;
  String? availableForType;
  String? availableForId;
  int? iV;
  String? bookingType;
  String? createdAt;
  int? durationInMinutes;
  int? fee;
  Location? location;
  List<Schedule>? schedule;
  List<SpecialOverrides>? specialOverrides;
  String? timezone;
  String? updatedAt;
  FeeDetails? feeDetails;
  String? instructions;
  LiveState? liveState;

  AvailabilityData(
      {this.sId,
        this.availableForType,
        this.availableForId,
        this.iV,
        this.bookingType,
        this.createdAt,
        this.durationInMinutes,
        this.fee,
        this.location,
        this.schedule,
        this.specialOverrides,
        this.timezone,
        this.updatedAt,
        this.feeDetails,
        this.instructions,
        this.liveState});

  AvailabilityData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    availableForType = json['availableForType'];
    availableForId = json['availableForId'];
    iV = json['__v'];
    bookingType = json['bookingType'];
    createdAt = json['createdAt'];
    durationInMinutes = json['durationInMinutes'];
    fee = json['fee'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    if (json['schedule'] != null) {
      schedule = <Schedule>[];
      json['schedule'].forEach((v) {
        schedule!.add(new Schedule.fromJson(v));
      });
    }
    if (json['specialOverrides'] != null) {
      specialOverrides = <SpecialOverrides>[];
      json['specialOverrides'].forEach((v) {
        specialOverrides!.add(new SpecialOverrides.fromJson(v));
      });
    }
    timezone = json['timezone'];
    updatedAt = json['updatedAt'];
    feeDetails = json['feeDetails'] != null
        ? new FeeDetails.fromJson(json['feeDetails'])
        : null;
    instructions = json['instructions'];
    liveState =
        json['liveState'] != null ? LiveState.fromJson(json['liveState']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['availableForType'] = this.availableForType;
    data['availableForId'] = this.availableForId;
    data['__v'] = this.iV;
    data['bookingType'] = this.bookingType;
    data['createdAt'] = this.createdAt;
    data['durationInMinutes'] = this.durationInMinutes;
    data['fee'] = this.fee;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    if (this.schedule != null) {
      data['schedule'] = this.schedule!.map((v) => v.toJson()).toList();
    }
    if (this.specialOverrides != null) {
      data['specialOverrides'] =
          this.specialOverrides!.map((v) => v.toJson()).toList();
    }
    data['timezone'] = this.timezone;
    data['updatedAt'] = this.updatedAt;
    if (this.feeDetails != null) {
      data['feeDetails'] = this.feeDetails!.toJson();
    }
    data['instructions'] = this.instructions;
    if (this.liveState != null) {
      data['liveState'] = this.liveState!.toJson();
    }
    return data;
  }
}

class Location {
  String? landmark;
  String? latitude;
  String? longitude;
  String? address;

  Location({this.landmark, this.latitude, this.longitude, this.address});

  Location.fromJson(Map<String, dynamic> json) {
    landmark = json['landmark'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['landmark'] = this.landmark;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['address'] = this.address;
    return data;
  }
}

class Schedule {
  String? day;
  bool? isOpen;
  String? shopOpenTime; // "HH:MM" — explicit open time for the day
  String? shopCloseTime; // "HH:MM" — explicit close time for the day
  List<TimeSlots>? timeSlots;

  Schedule(
      {this.day,
      this.isOpen,
      this.shopOpenTime,
      this.shopCloseTime,
      this.timeSlots});

  Schedule.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    isOpen = json['isOpen'];
    shopOpenTime = json['shopOpenTime'];
    shopCloseTime = json['shopCloseTime'];
    if (json['timeSlots'] != null) {
      timeSlots = <TimeSlots>[];
      json['timeSlots'].forEach((v) {
        timeSlots!.add(new TimeSlots.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['day'] = this.day;
    data['isOpen'] = this.isOpen;
    // Open/close times are only meaningful (and required by the backend)
    // for open days; emit them additively without breaking existing
    // consumers that still rely on timeSlots.
    if (this.shopOpenTime != null) data['shopOpenTime'] = this.shopOpenTime;
    if (this.shopCloseTime != null) data['shopCloseTime'] = this.shopCloseTime;
    if (this.timeSlots != null) {
      data['timeSlots'] = this.timeSlots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// Per-day go-live state mirrored onto the availability document. The flag
/// is per calendar day — confirm [liveDate] equals today before trusting
/// [isLive].
class LiveState {
  bool? isLive;
  String? wentLiveAt; // ISO date-time
  String? liveDate; // "YYYY-MM-DD"
  String? reminderSentForDate;

  LiveState(
      {this.isLive, this.wentLiveAt, this.liveDate, this.reminderSentForDate});

  factory LiveState.fromJson(Map<String, dynamic> json) => LiveState(
        isLive: json['isLive'] ?? false,
        wentLiveAt: json['wentLiveAt'],
        liveDate: json['liveDate'],
        reminderSentForDate: json['reminderSentForDate'],
      );

  Map<String, dynamic> toJson() => {
        'isLive': isLive,
        'wentLiveAt': wentLiveAt,
        'liveDate': liveDate,
        'reminderSentForDate': reminderSentForDate,
      };
}

class TimeSlots {
  String? startTime;
  String? endTime;

  TimeSlots({this.startTime, this.endTime});

  TimeSlots.fromJson(Map<String, dynamic> json) {
    startTime = json['startTime'];
    endTime = json['endTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['startTime'] = this.startTime;
    data['endTime'] = this.endTime;
    return data;
  }
}

class SpecialOverrides {
  String? date;
  String? dateKey; // "YYYY-MM-DD" key the override is stored under
  bool? isOpen;
  String? shopOpenTime; // "HH:MM"
  String? shopCloseTime; // "HH:MM"
  List<TimeSlots>? timeSlots;

  SpecialOverrides(
      {this.date,
      this.dateKey,
      this.isOpen,
      this.shopOpenTime,
      this.shopCloseTime,
      this.timeSlots});

  SpecialOverrides.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    dateKey = json['dateKey'];
    isOpen = json['isOpen'];
    shopOpenTime = json['shopOpenTime'];
    shopCloseTime = json['shopCloseTime'];
    if (json['timeSlots'] != null) {
      timeSlots = <TimeSlots>[];
      json['timeSlots'].forEach((v) {
        timeSlots!.add(new TimeSlots.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    if (this.dateKey != null) data['dateKey'] = this.dateKey;
    data['isOpen'] = this.isOpen;
    if (this.shopOpenTime != null) data['shopOpenTime'] = this.shopOpenTime;
    if (this.shopCloseTime != null) data['shopCloseTime'] = this.shopCloseTime;
    if (this.timeSlots != null) {
      data['timeSlots'] = this.timeSlots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FeeDetails {
  int? minFee;
  int? maxFee;
  String? feeType;

  FeeDetails({this.minFee, this.maxFee, this.feeType});

  FeeDetails.fromJson(Map<String, dynamic> json) {
    minFee = json['minFee'];
    maxFee = json['maxFee'];
    feeType = json['feeType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['minFee'] = this.minFee;
    data['maxFee'] = this.maxFee;
    data['feeType'] = this.feeType;
    return data;
  }
}