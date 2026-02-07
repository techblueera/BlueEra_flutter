class SocialEventModel {
  bool? success;
  List<SocialEventData>? data;

  SocialEventModel({this.success, this.data});

  SocialEventModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <SocialEventData>[];
      if (json['data'] is List) {
        json['data'].forEach((v) {
          data!.add(SocialEventData.fromJson(v));
        });
      } else if (json['data'] is Map<String, dynamic>) {
        data!.add(SocialEventData.fromJson(json['data']));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SocialEventData {
  Timing? timing;
  Venue? venue;
  String? sId;
  String? title;
  String? startDate;
  String? endDate;
  String? eventType;
  String? registrationLink;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  SocialEventData(
      {this.timing,
      this.venue,
      this.sId,
      this.title,
      this.startDate,
      this.endDate,
      this.eventType,
      this.registrationLink,
      this.userId,
      this.createdAt,
      this.updatedAt,
      this.iV});

  SocialEventData.fromJson(Map<String, dynamic> json) {
    timing = json['timing'] != null ? Timing.fromJson(json['timing']) : null;
    venue = json['venue'] != null ? Venue.fromJson(json['venue']) : null;
    sId = json['_id'];
    title = json['title'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    eventType = json['eventType'];
    registrationLink = json['registrationLink'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (timing != null) {
      data['timing'] = timing!.toJson();
    }
    if (venue != null) {
      data['venue'] = venue!.toJson();
    }
    data['_id'] = sId;
    data['title'] = title;
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['eventType'] = eventType;
    data['registrationLink'] = registrationLink;
    data['userId'] = userId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class Timing {
  String? from;
  String? to;

  Timing({this.from, this.to});

  Timing.fromJson(Map<String, dynamic> json) {
    from = json['from'];
    to = json['to'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['from'] = from;
    data['to'] = to;
    return data;
  }
}

class Venue {
  EventLocation? location;
  String? name;

  Venue({this.location, this.name});

  Venue.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? EventLocation.fromJson(json['location'])
        : null;
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['name'] = name;
    return data;
  }
}

class EventLocation {
  String? name;
  String? type;
  List<double>? coordinates;

  EventLocation({this.name, this.type, this.coordinates});

  EventLocation.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['type'] = type;
    data['coordinates'] = coordinates;
    return data;
  }
}
