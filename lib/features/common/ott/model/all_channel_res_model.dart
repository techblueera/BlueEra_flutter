import 'dart:convert';

AllChannelResModel allChannelResModelFromJson(String str) =>
    AllChannelResModel.fromJson(json.decode(str));

String allChannelResModelToJson(AllChannelResModel data) =>
    json.encode(data.toJson());

class AllChannelResModel {
  AllChannelResModel({
    this.success,
    this.message,
    this.data,
    this.pagination,
  });

  AllChannelResModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(AllChannelData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }

  bool? success;
  String? message;
  List<AllChannelData>? data;
  Pagination? pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    return map;
  }
}

Pagination paginationFromJson(String str) =>
    Pagination.fromJson(json.decode(str));

String paginationToJson(Pagination data) => json.encode(data.toJson());

class Pagination {
  Pagination({
    this.totalDocs,
    this.limit,
    this.page,
    this.totalPages,
    this.hasNextPage,
    this.hasPrevPage,
  });

  Pagination.fromJson(dynamic json) {
    totalDocs = json['totalDocs'];
    limit = json['limit'];
    page = json['page'];
    totalPages = json['totalPages'];
    hasNextPage = json['hasNextPage'];
    hasPrevPage = json['hasPrevPage'];
  }

  int? totalDocs;
  int? limit;
  int? page;
  int? totalPages;
  bool? hasNextPage;
  bool? hasPrevPage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['totalDocs'] = totalDocs;
    map['limit'] = limit;
    map['page'] = page;
    map['totalPages'] = totalPages;
    map['hasNextPage'] = hasNextPage;
    map['hasPrevPage'] = hasPrevPage;
    return map;
  }
}

AllChannelData dataFromJson(String str) =>
    AllChannelData.fromJson(json.decode(str));

String dataToJson(AllChannelData data) => json.encode(data.toJson());

class AllChannelData {
  AllChannelData({
    this.ownership,
    this.id,
    this.name,
    this.username,
    this.bio,
    this.logoUrl,
    this.socialLinks,
    this.websites,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.stats,
  });

  AllChannelData.fromJson(dynamic json) {
    ownership = json['ownership'] != null
        ? Ownership.fromJson(json['ownership'])
        : null;
    id = json['_id'];
    name = json['name'];
    username = json['username'];
    bio = json['bio'];
    logoUrl = json['logoUrl'];
    if (json['socialLinks'] != null) {
      socialLinks = [];
      json['socialLinks'].forEach((v) {
        socialLinks?.add(SocialLinks.fromJson(v));
      });
    }
    websites = json['websites'] != null ? json['websites'].cast<String>() : [];

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    stats = json['stats'] != null ? Stats.fromJson(json['stats']) : null;
  }

  Ownership? ownership;
  String? id;
  String? name;
  String? username;
  String? bio;
  String? logoUrl;
  List<SocialLinks>? socialLinks;
  List<String>? websites;

  String? createdAt;
  String? updatedAt;
  int? v;
  Stats? stats;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (ownership != null) {
      map['ownership'] = ownership?.toJson();
    }
    map['_id'] = id;
    map['name'] = name;
    map['username'] = username;
    map['bio'] = bio;
    map['logoUrl'] = logoUrl;
    if (socialLinks != null) {
      map['socialLinks'] = socialLinks?.map((v) => v.toJson()).toList();
    }
    map['websites'] = websites;

    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (stats != null) {
      map['stats'] = stats?.toJson();
    }
    return map;
  }
}

Stats statsFromJson(String str) => Stats.fromJson(json.decode(str));

String statsToJson(Stats data) => json.encode(data.toJson());

class Stats {
  Stats({
    this.id,
    this.posts,
    this.followers,
    this.following,
  });

  Stats.fromJson(dynamic json) {
    id = json['_id'];
    posts = json['posts'];
    followers = json['followers'];
    following = json['following'];
  }

  String? id;
  int? posts;
  int? followers;
  int? following;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['posts'] = posts;
    map['followers'] = followers;
    map['following'] = following;
    return map;
  }
}

SocialLinks socialLinksFromJson(String str) =>
    SocialLinks.fromJson(json.decode(str));

String socialLinksToJson(SocialLinks data) => json.encode(data.toJson());

class SocialLinks {
  SocialLinks({
    this.id,
    this.platform,
    this.url,
  });

  SocialLinks.fromJson(dynamic json) {
    id = json['_id'];
    platform = json['platform'];
    url = json['url'];
  }

  String? id;
  String? platform;
  String? url;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['platform'] = platform;
    map['url'] = url;
    return map;
  }
}

Ownership ownershipFromJson(String str) => Ownership.fromJson(json.decode(str));

String ownershipToJson(Ownership data) => json.encode(data.toJson());

class Ownership {
  Ownership({
    this.claimedBy,
    this.claimedAt,
  });

  Ownership.fromJson(dynamic json) {
    claimedBy = json['claimedBy'];
    claimedAt = json['claimedAt'];
  }

  String? claimedBy;
  String? claimedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['claimedBy'] = claimedBy;
    map['claimedAt'] = claimedAt;
    return map;
  }
}
