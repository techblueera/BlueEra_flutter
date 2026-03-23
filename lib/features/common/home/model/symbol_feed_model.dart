class SymbolFeedResponse {
  bool? status;
  String? message;
  SymbolFeedData? data;

  SymbolFeedResponse({this.status, this.message, this.data});

  factory SymbolFeedResponse.fromJson(Map<String, dynamic> json) {
    return SymbolFeedResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? SymbolFeedData.fromJson(json['data'])
          : null,
    );
  }
}

class SymbolFeedData {
  List<SymbolFeedItem>? symbols;
  SymbolPagination? pagination;

  SymbolFeedData({this.symbols, this.pagination});

  factory SymbolFeedData.fromJson(Map<String, dynamic> json) {
    return SymbolFeedData(
      symbols: json['symbols'] != null
          ? (json['symbols'] as List)
              .map((e) => SymbolFeedItem.fromJson(e))
              .toList()
          : [],
      pagination: json['pagination'] != null
          ? SymbolPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class SymbolFeedItem {
  String? id;
  String? userId;
  String? type;
  String? content;
  String? caption;
  String? backgroundColor;
  DateTime? expiresAt;
  String? visibility;
  List<String>? hiddenFrom;
  List<String>? taggedUsers;
  int? likesCount;
  int? commentsCount;
  int? seenCount;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool? hasSeen;
  SymbolFeedUser? user;

  SymbolFeedItem({
    this.id,
    this.userId,
    this.type,
    this.content,
    this.caption,
    this.backgroundColor,
    this.expiresAt,
    this.visibility,
    this.hiddenFrom,
    this.taggedUsers,
    this.likesCount,
    this.commentsCount,
    this.seenCount,
    this.createdAt,
    this.updatedAt,
    this.hasSeen,
    this.user,
  });

  factory SymbolFeedItem.fromJson(Map<String, dynamic> json) {
    return SymbolFeedItem(
      id: json['_id'],
      userId: json['user_id'] is String
          ? json['user_id']
          : (json['user_id'] is Map ? json['user_id']['_id'] : null),
      type: json['type'],
      content: json['content'],
      caption: json['caption'],
      backgroundColor: json['backgroundColor'],
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      visibility: json['visibility'],
      hiddenFrom: json['hidden_from'] != null
          ? List<String>.from(json['hidden_from'])
          : [],
      taggedUsers: json['tagged_users'] != null
          ? List<String>.from(json['tagged_users'])
          : [],
      likesCount: json['likes_count'],
      commentsCount: json['comments_count'],
      seenCount: json['seen_count'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      hasSeen: json['has_seen'],
      user: json['user'] is Map
          ? SymbolFeedUser.fromJson(json['user'])
          : null,
    );
  }
}

class SymbolFeedUser {
  String? id;
  String? name;
  String? profileImage;
  String? username;

  SymbolFeedUser({this.id, this.name, this.profileImage, this.username});

  factory SymbolFeedUser.fromJson(Map<String, dynamic> json) {
    return SymbolFeedUser(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      profileImage: json['profile_image'],
      username: json['username'],
    );
  }
}

class SymbolPagination {
  int? page;
  int? limit;
  int? total;
  int? totalPages;
  bool? hasNextPage;
  bool? hasPrevPage;

  SymbolPagination({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
    this.hasNextPage,
    this.hasPrevPage,
  });

  factory SymbolPagination.fromJson(Map<String, dynamic> json) {
    return SymbolPagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
      hasNextPage: json['hasNextPage'],
      hasPrevPage: json['hasPrevPage'],
    );
  }
}
