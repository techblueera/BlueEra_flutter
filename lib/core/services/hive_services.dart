import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/feed/hive_model/post_hive_model.dart';
import 'package:BlueEra/features/common/feed/hive_model/video_hive_model.dart';
import 'package:hive/hive.dart';

class HiveServices{

  /// local db for saving posts
  bool isPostSaved(String id) {
    final box = Hive.box<PostHiveModel>('savedPosts');
    final String key = '${userId}_$id';
    return box.containsKey(key);
  }

  Future<bool> savePost(PostHiveModel post) async {
    final box = Hive.box<PostHiveModel>('savedPosts');
    final String key = '${userId}_${post.id}';
    await box.put(key , post); // Using post ID as unique key
    return true;
  }

  List<PostHiveModel> getAllSavedPosts() {
    final box = Hive.box<PostHiveModel>('savedPosts');
    return box.values
        .where((post) => (box.keyAt(box.values.toList().indexOf(post)) as String)
        .startsWith('$userId\_'))
        .toList();
  }

  PostHiveModel? getPostById(String postId) {
    final box = Hive.box<PostHiveModel>('savedPosts');
    final String key = '${userId}_$postId';
    return box.get(key);
  }

  Future<void> deletePostById(String postId) async {
    final box = Hive.box<PostHiveModel>('savedPosts');
    final String key = '${userId}_$postId';
    await box.delete(key);
  }


  /// local db for saving videos and shorts
  bool isVideoSaved(String id) {
    final box = Hive.box<VideoFeedItemHive>('savedVideos');
    final String key = '${userId}_$id';
    return box.containsKey(key);
  }

  Future<bool> saveVideo(VideoFeedItemHive videoData) async {
    final box = Hive.box<VideoFeedItemHive>('savedVideos');
    final String key = '${userId}_${videoData.videoId}';
    await box.put(key , videoData); // Using post ID as unique key
    return true;
  }

  List<VideoFeedItemHive> getAllSavedVideos() {
    final box = Hive.box<VideoFeedItemHive>('savedVideos');
    return box.values
        .where((post) => (box.keyAt(box.values.toList().indexOf(post)) as String)
        .startsWith('$userId\_'))
        .toList();
  }

  VideoFeedItemHive? getVideoById(String videoId) {
    final box = Hive.box<VideoFeedItemHive>('savedVideos');
    final String key = '${userId}_$videoId';
    return box.get(key);
  }

  Future<void> deleteVideoById(String videoId) async {
    final box = Hive.box<VideoFeedItemHive>('savedVideos');
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