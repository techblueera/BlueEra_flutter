import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:hive/hive.dart';

class HiveServices{
  static const String _savedPosts = 'savedPosts';
  static const String _savedVideos = 'savedVideos';

  /// Initialize Hive boxes
  static Future<void> init() async {
    await Hive.openBox(_savedPosts);
    await Hive.openBox(_savedVideos);
  }

  bool isPostSaved(String id) {
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_$id';
    return box.containsKey(key);
  }

  Future<bool> savePostJson(Post post) async {
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_${post.id ?? ''}';
    await box.put(key, post.toJson());
    return true;
  }

  List<Post> getAllSavedPosts() {
    final box = Hive.box(_savedPosts);
    final List<Post> posts = [];
    for (final dynamic key in box.keys) {
      if (key is String && key.startsWith('$userId\_')) {
        final dynamic value = box.get(key);
        if (value is Map) {
          try {
            posts.add(Post.fromJson(Map<String, dynamic>.from(value)));
          } catch (e, st) {
            print("Hive -> Failed to parse Post: $st");
          }
        }
      }
    }
    return posts;
  }

  Post? getPostById(String postId) {
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_$postId';
    final dynamic value = box.get(key);
    if (value is Map) {
      try {
        return Post.fromJson(Map<String, dynamic>.from(value));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deletePostById(String postId) async {
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_$postId';
    await box.delete(key);
  }


  bool isVideoSaved(String id) {
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_$id';
    return box.containsKey(key);
  }

  Future<bool> saveVideoJson(ShortFeedItem shortFeedItem) async {
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_${shortFeedItem.videoId ?? shortFeedItem.video?.id ?? ''}';
    await box.put(key, shortFeedItem.toJson());
    return true;
  }

  List<ShortFeedItem> getAllSavedVideos() {
    final box = Hive.box(_savedVideos);
    final List<ShortFeedItem> videos = [];
    for (final dynamic key in box.keys) {
      if (key is String && key.startsWith('$userId\_')) {
        final dynamic value = box.get(key);
        if (value is Map) {
          try {
            videos.add(ShortFeedItem.fromJson(Map<String, dynamic>.from(value)));
          } catch (_) {}
        }
      }
    }
    return videos;
  }

  ShortFeedItem? getVideoById(String videoId) {
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_$videoId';
    final dynamic value = box.get(key);
    if (value is Map) {
      try {
        return ShortFeedItem.fromJson(Map<String, dynamic>.from(value));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteVideoById(String videoId) async {
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_$videoId';
    await box.delete(key);
  }

  // /// Conversation regarding Database
  // final box = Hive.box<GetHiveChatConversation>('conversations');
  //
  // Future<void> saveConversation(String userId, GetHiveChatConversation convo) async {
  //   await box.put('${userId}_${convo.conversationId}', convo);
  // }
  //
  // List<GetHiveChatConversation> getUserConversations(String userId) {
  //   return box.values
  //       .where((convo) =>
  //       (box.keyAt(box.values.toList().indexOf(convo)) as String)
  //           .startsWith('${userId}_'))
  //       .toList();
  // }
  //
  // Future<void> deleteConversation(String userId, String convoId) async {
  //   await box.delete('${userId}_$convoId');
  // }

}