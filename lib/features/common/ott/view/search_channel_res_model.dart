class ChannelSearchResponse {
  bool? success;
  String? message;
  List<ChannelSearchData>? data;
  Pagination? pagination;

  ChannelSearchResponse({this.success, this.message, this.data, this.pagination});

  ChannelSearchResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ChannelSearchData>[];
      json['data'].forEach((v) {
        data!.add(ChannelSearchData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }
}

class ChannelSearchData {
  String? sId;
  String? name;
  String? username;
  String? bio;
  String? logoUrl;
  bool? isFollowing;

  ChannelSearchData(
      {this.sId,
        this.name,
        this.username,
        this.bio,
        this.logoUrl,
        this.isFollowing});

  ChannelSearchData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    username = json['username'];
    bio = json['bio'];
    logoUrl = json['logoUrl'];
    isFollowing = json['isFollowing'];
  }
}

class Pagination {
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  Pagination({this.page, this.limit, this.total, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    limit = json['limit'];
    total = json['total'];
    totalPages = json['totalPages'];
  }
}