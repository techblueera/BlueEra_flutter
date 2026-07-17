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

/// Grouped API response: symbols grouped by user
class SymbolGroupedResponse {
  bool? status;
  String? message;
  SymbolGroupedData? data;

  SymbolGroupedResponse({this.status, this.message, this.data});

  factory SymbolGroupedResponse.fromJson(Map<String, dynamic> json) {
    return SymbolGroupedResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? SymbolGroupedData.fromJson(json['data'])
          : null,
    );
  }
}

class SymbolGroupedData {
  List<SymbolUserGroup>? groups;
  SymbolPagination? pagination;

  SymbolGroupedData({this.groups, this.pagination});

  factory SymbolGroupedData.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'];
    List<SymbolUserGroup> parsedGroups = [];

    if (rawSymbols is List) {
      for (final item in rawSymbols) {
        if (item is Map<String, dynamic>) {
          // Grouped format: each item has user + symbols array
          if (item.containsKey('symbols') && item['symbols'] is List) {
            parsedGroups
                .add(SymbolUserGroup.fromJson(Map<String, dynamic>.from(item)));
          } else {
            // Flat format: individual symbol items — group manually
            final symbol = SymbolFeedItem.fromJson(item);
            final existingIdx = parsedGroups
                .indexWhere((g) => g.user?.id == symbol.userId);
            if (existingIdx != -1) {
              parsedGroups[existingIdx].symbols.add(symbol);
            } else {
              parsedGroups.add(SymbolUserGroup(
                user: symbol.user,
                symbols: [symbol],
              ));
            }
          }
        }
      }
    }

    return SymbolGroupedData(
      groups: parsedGroups,
      pagination: json['pagination'] != null
          ? SymbolPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class SymbolUserGroup {
  SymbolFeedUser? user;
  List<SymbolFeedItem> symbols;

  /// Whether all symbols in this group have been seen
  bool get allSeen => symbols.every((s) => s.hasSeen == true);

  /// Whether any symbol in this group is unseen
  bool get hasUnseen => symbols.any((s) => s.hasSeen != true);

  SymbolUserGroup({this.user, List<SymbolFeedItem>? symbols})
      : symbols = symbols ?? [];

  factory SymbolUserGroup.fromJson(Map<String, dynamic> json) {
    // The grouped API may return user info as 'user', 'user_id' (populated),
    // or '_id' (as a user object). Handle all variants.
    SymbolFeedUser? user;
    final dynamic rawUser = json['user'] ?? json['user_id'];
    if (rawUser is Map) {
      user = SymbolFeedUser.fromJson(Map<String, dynamic>.from(rawUser));
    }

    // Also check if top-level group has _id/name/profile_image directly
    // (some grouped APIs flatten the user fields at group level)
    if (user == null && json['_id'] is Map) {
      user = SymbolFeedUser.fromJson(
          Map<String, dynamic>.from(json['_id'] as Map));
    }
    if (user == null &&
        json['name'] != null &&
        json['profile_image'] != null) {
      user = SymbolFeedUser(
        id: json['_id'] is String ? json['_id'] : null,
        name: json['name'],
        profileImage: json['profile_image'],
        username: json['username'],
      );
    }

    final List<SymbolFeedItem> symbols = [];
    if (json['symbols'] is List) {
      for (final s in json['symbols'] as List) {
        if (s is Map<String, dynamic>) {
          final item = SymbolFeedItem.fromJson(s);
          // Inherit user from group if not set on individual symbol
          item.user ??= user;
          symbols.add(item);
        }
      }
    }

    // If user is still null, try to extract from first symbol
    if (user == null && symbols.isNotEmpty) {
      user = symbols.first.user;
    }

    return SymbolUserGroup(user: user, symbols: symbols);
  }
}

/// Comment model for symbol comments
class SymbolComment {
  String? id;
  String? symbolId;
  String? userId;
  String? comment;
  DateTime? createdAt;
  DateTime? updatedAt;
  SymbolFeedUser? user;

  SymbolComment({
    this.id,
    this.symbolId,
    this.userId,
    this.comment,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory SymbolComment.fromJson(Map<String, dynamic> json) {
    SymbolFeedUser? user;
    String? extractedUserId;

    // Check all possible keys for user data
    final userKeys = ['user_id', 'userId', 'user', 'commented_by', 'commentedBy'];
    for (final key in userKeys) {
      final value = json[key];
      if (value is Map && user == null) {
        user = SymbolFeedUser.fromJson(Map<String, dynamic>.from(value));
        extractedUserId = value['_id'] as String? ?? value['id'] as String?;
      } else if (value is String && extractedUserId == null) {
        extractedUserId = value;
      }
    }

    return SymbolComment(
      id: json['_id'] ?? json['id'],
      symbolId: json['symbol_id'] is String
          ? json['symbol_id']
          : (json['symbol_id'] is Map
              ? json['symbol_id']['_id'] as String?
              : null),
      userId: extractedUserId,
      comment: json['comment'] ?? json['text'] ?? json['content'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null),
      user: user,
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

  /// Video playback length in seconds; 0 for non-video or legacy symbols.
  double mediaDuration;
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
  bool? hasLiked;
  SymbolFeedUser? user;

  /// Whether the backend supplied a usable video length.
  bool get hasKnownDuration => mediaDuration > 0;

  SymbolFeedItem({
    this.id,
    this.userId,
    this.type,
    this.content,
    this.caption,
    this.backgroundColor,
    this.mediaDuration = 0,
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
    this.hasLiked,
    this.user,
  });

  factory SymbolFeedItem.fromJson(Map<String, dynamic> json) {
    // With populate=true, user_id may be a populated user document (Map)
    // instead of a plain string id. Extract id and user data accordingly.
    final dynamic rawUserId = json['user_id'];
    final String? extractedUserId = rawUserId is String
        ? rawUserId
        : (rawUserId is Map ? rawUserId['_id'] as String? : null);

    // Prefer an explicit `user` field if present, otherwise build user from
    // the populated `user_id` map.
    SymbolFeedUser? extractedUser;
    if (json['user'] is Map) {
      extractedUser = SymbolFeedUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map));
    } else if (rawUserId is Map) {
      extractedUser = SymbolFeedUser.fromJson(
          Map<String, dynamic>.from(rawUserId));
    }

    return SymbolFeedItem(
      id: json['_id'],
      userId: extractedUserId,
      type: json['type'],
      content: json['content'],
      caption: json['caption'],
      backgroundColor: json['backgroundColor'],
      mediaDuration: (json['media_duration'] as num?)?.toDouble() ?? 0,
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
      hasLiked: json['has_liked'],
      user: extractedUser,
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
      profileImage: json['profile_image'] ?? json['profileImage'] ?? json['profile_pic'],
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
