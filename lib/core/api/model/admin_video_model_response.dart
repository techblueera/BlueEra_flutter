class AdminVideoModelResponse {
  bool? success;
  List<AdminVideoData>? data;
  Pagination? pagination;

  AdminVideoModelResponse({this.success, this.data, this.pagination});

  AdminVideoModelResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <AdminVideoData>[];
      json['data'].forEach((v) {
        data!.add(new AdminVideoData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class AdminVideoData {
  String? sId;
  String? userId;
  String? title;
  String? description;
  String? thumbnailUrl;
  List<VideoUrls>? videoUrls;
  String? categories;
  String? screenPlacement;
  int? duration;
  String? type;
  String? createdAt;
  String? updatedAt;
  int? iV;

  AdminVideoData(
      {this.sId,
        this.userId,
        this.title,
        this.description,
        this.thumbnailUrl,
        this.videoUrls,
        this.categories,
        this.screenPlacement,
        this.duration,
        this.type,
        this.createdAt,
        this.updatedAt,
        this.iV});

  AdminVideoData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    title = json['title'];
    description = json['description'];
    thumbnailUrl = json['thumbnailUrl'];
    if (json['videoUrls'] != null) {
      videoUrls = <VideoUrls>[];
      json['videoUrls'].forEach((v) {
        videoUrls!.add(new VideoUrls.fromJson(v));
      });
    }
    categories = json['categories'];
    screenPlacement = json['screenPlacement'];
    duration = json['duration'];
    type = json['type'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['title'] = this.title;
    data['description'] = this.description;
    data['thumbnailUrl'] = this.thumbnailUrl;
    if (this.videoUrls != null) {
      data['videoUrls'] = this.videoUrls!.map((v) => v.toJson()).toList();
    }
    data['categories'] = this.categories;
    data['screenPlacement'] = this.screenPlacement;
    data['duration'] = this.duration;
    data['type'] = this.type;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class VideoUrls {
  String? language;
  String? url;
  String? sId;

  VideoUrls({this.language, this.url, this.sId});

  VideoUrls.fromJson(Map<String, dynamic> json) {
    language = json['language'];
    url = json['url'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['language'] = this.language;
    data['url'] = this.url;
    data['_id'] = this.sId;
    return data;
  }
}

class Pagination {
  int? page;
  int? limit;
  int? total;
  int? totalPages;
  bool? hasNext;
  bool? hasPrev;

  Pagination(
      {this.page,
        this.limit,
        this.total,
        this.totalPages,
        this.hasNext,
        this.hasPrev});

  Pagination.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    limit = json['limit'];
    total = json['total'];
    totalPages = json['totalPages'];
    hasNext = json['hasNext'];
    hasPrev = json['hasPrev'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['page'] = this.page;
    data['limit'] = this.limit;
    data['total'] = this.total;
    data['totalPages'] = this.totalPages;
    data['hasNext'] = this.hasNext;
    data['hasPrev'] = this.hasPrev;
    return data;
  }
}