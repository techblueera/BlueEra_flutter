import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/reel/service/video_actions.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _response(int status, Map<String, dynamic> data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakeChannelRepo extends ChannelRepo {
  _FakeChannelRepo(this.status);
  final int status;
  String? deleted;

  @override
  Future<ResponseModel> deleteVideo({required String videoId}) async {
    deleted = videoId;
    return _response(status, {'message': 'Deleted'});
  }
}

class _FakeAuthRepo extends AuthRepo {
  _FakeAuthRepo(this.status);
  final int status;
  Map<String, dynamic>? blockParams;
  Map<String, dynamic>? reportParams;

  @override
  Future<ResponseModel> blockUser({required Map<String, dynamic> params}) async {
    blockParams = params;
    return _response(status, {
      'success': status == 200,
      'message': 'Blocked',
      'data': <String, dynamic>{},
    });
  }

  @override
  Future<ResponseModel> report({required Map<String, dynamic> params}) async {
    reportParams = params;
    return _response(status, {'message': 'Reported'});
  }
}

ShortFeedItem _video(String id, String userId) => ShortFeedItem.fromJson({
      'video': {'_id': id, 'userId': userId},
    });

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('VideoActions', () {
    test('deletes, blocks and reports without any controller registered',
        () async {
      final channel = _FakeChannelRepo(200);
      final auth = _FakeAuthRepo(200);
      final actions = VideoActions(channelRepo: channel, authRepo: auth);

      expect(await actions.deleteVideo('v1'), isTrue);
      expect(channel.deleted, 'v1');
      expect(await actions.blockUser('u1'), isTrue);
      expect(auth.blockParams?[ApiKeys.blockedTo], 'u1');
      expect(await actions.reportPost({'reason': 'spam'}), isTrue);
      expect(auth.reportParams, {'reason': 'spam'});
      expect(Get.isRegistered<VideoController>(), isFalse);
    });

    test('reports failures', () async {
      final actions = VideoActions(
          channelRepo: _FakeChannelRepo(400), authRepo: _FakeAuthRepo(400));

      expect(await actions.deleteVideo('v1'), isFalse);
      expect(await actions.blockUser('u1'), isFalse);
      expect(await actions.reportPost({}), isFalse);
    });
  });

  group('VideoController', () {
    VideoController playerWith(int status) {
      final c = Get.put(VideoController(
          actions: VideoActions(
              channelRepo: _FakeChannelRepo(status),
              authRepo: _FakeAuthRepo(status))));
      c.videoFeedPosts.assignAll([
        _video('v1', 'u1'),
        _video('v2', 'u2'),
        _video('v3', 'u1'),
      ]);
      return c;
    }

    List<String?> ids(VideoController c) =>
        c.videoFeedPosts.map((v) => v.video?.id).toList();

    test('drops a deleted video from its list', () async {
      final c = playerWith(200);
      expect(
          await c.videoDelete(video: VideoType.videoFeed, videoId: 'v2'), isTrue);
      expect(ids(c), ['v1', 'v3']);
    });

    test('drops every video by a blocked author', () async {
      final c = playerWith(200);
      expect(
          await c.userBlocked(
              videoType: VideoType.videoFeed, otherUserId: 'u1'),
          isTrue);
      expect(ids(c), ['v2']);
    });

    test('drops a reported video', () async {
      final c = playerWith(200);
      expect(
          await c.videoPostReport(
              videoType: VideoType.videoFeed, videoId: 'v1', params: {}),
          isTrue);
      expect(ids(c), ['v2', 'v3']);
    });

    test('keeps the list when the action fails', () async {
      final c = playerWith(400);
      expect(
          await c.videoDelete(video: VideoType.videoFeed, videoId: 'v2'),
          isFalse);
      expect(ids(c), ['v1', 'v2', 'v3']);
    });
  });
}
