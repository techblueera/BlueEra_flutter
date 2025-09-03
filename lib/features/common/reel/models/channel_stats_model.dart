class ChannelStatsModel {
  final bool success;
  final String message;
  final ChannelStats? data;

  ChannelStatsModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory ChannelStatsModel.fromJson(Map<String, dynamic> json) {
    return ChannelStatsModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? ChannelStats.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class ChannelStats {
  final String id;
  final String channel;
  final int posts;
  final int followers;
  final int following;

  ChannelStats({
    required this.id,
    required this.channel,
    required this.posts,
    required this.followers,
    required this.following,
  });

  factory ChannelStats.fromJson(Map<String, dynamic> json) {
    return ChannelStats(
      id: json['id'] ?? '',
      channel: json['channel'] ?? '',
      posts: json['posts'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel': channel,
      'posts': posts,
      'followers': followers,
      'following': following,
    };
  }
}
