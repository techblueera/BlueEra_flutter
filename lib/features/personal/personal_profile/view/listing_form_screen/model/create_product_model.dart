class CreateProductModel {
  bool? success;
  String? message;
  Data? data;

  CreateProductModel({this.success, this.message, this.data});

  factory CreateProductModel.fromJson(Map<String, dynamic> json) {
    return CreateProductModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['success'] = success;
    map['message'] = message;
    if (data != null) map['data'] = data!.toJson();
    return map;
  }
}

class Data {
  String? name;
  String? type;
  String? symbol;
  String? brand;
  List<String>? media;
  List<String>? videoUrl;
  String? categoryId;
  bool? isReturnable;
  int? returningDay;
  bool? isPublished;
  ExpiryTime? expiryTime;
  List<String>? tags;
  bool? addedByAdmin;
  String? approvalStatus;
  String? sId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Data({
    this.name,
    this.type,
    this.symbol,
    this.brand,
    this.media,
    this.videoUrl,
    this.categoryId,
    this.isReturnable,
    this.returningDay,
    this.isPublished,
    this.expiryTime,
    this.tags,
    this.addedByAdmin,
    this.approvalStatus,
    this.sId,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      name: json['name'],
      type: json['type'],
      symbol: json['symbol'],
      brand: json['brand'],
      media: (json['media'] as List?)?.map((e) => e.toString()).toList(),
      videoUrl: (json['video_url'] as List?)?.map((e) => e.toString()).toList(),
      categoryId: json['category_id'],
      isReturnable: json['is_returnable'],
      returningDay: json['returning_day'],
      isPublished: json['is_published'],
      expiryTime:
      json['expiry_time'] != null ? ExpiryTime.fromJson(json['expiry_time']) : null,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      addedByAdmin: json['addedByAdmin'],
      approvalStatus: json['approval_status'],
      sId: json['_id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      iV: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['name'] = name;
    map['type'] = type;
    map['symbol'] = symbol;
    map['brand'] = brand;
    map['media'] = media;
    map['video_url'] = videoUrl;
    map['category_id'] = categoryId;
    map['is_returnable'] = isReturnable;
    map['returning_day'] = returningDay;
    map['is_published'] = isPublished;
    if (expiryTime != null) map['expiry_time'] = expiryTime!.toJson();
    map['tags'] = tags;
    map['addedByAdmin'] = addedByAdmin;
    map['approval_status'] = approvalStatus;
    map['_id'] = sId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = iV;
    return map;
  }
}

class ExpiryTime {
  int? day;
  int? week;
  int? month;
  num? year; // could be int or double (since you had 0.5 steps)
  bool? lifetime;

  ExpiryTime({this.day, this.week, this.month, this.year, this.lifetime});

  factory ExpiryTime.fromJson(Map<String, dynamic> json) {
    return ExpiryTime(
      day: json['day'],
      week: json['week'],
      month: json['month'],
      year: json['year'],
      lifetime: json['lifetime'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (day != null) map['day'] = day;
    if (week != null) map['week'] = week;
    if (month != null) map['month'] = month;
    if (year != null) map['year'] = year;
    if (lifetime != null) map['lifetime'] = lifetime;
    return map;
  }
}
