import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/Discover/controller/discovery_video_controller.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// How [DiscoveryVideoController] reads `GET user-service/discovery/video`.
///
/// The clip is shown to GUESTS on the first screen they see, so every
/// malformed-payload path has to end in "no slide" rather than in an exception
/// or an empty black slot on the busiest surface in the app.
class _FakeDiscoverRepo extends DiscoverRepo {
  _FakeDiscoverRepo(this._body, {this.statusCode = 200, this.throws = false});

  final dynamic _body;
  final int statusCode;
  final bool throws;
  int calls = 0;

  @override
  Future<ResponseModel> fetchDiscoveryVideo() async {
    calls++;
    if (throws) throw Exception('network down');
    return ResponseModel(
      response: Response(
        requestOptions: RequestOptions(path: 'user-service/discovery/video'),
        statusCode: statusCode,
        data: _body,
      ),
      statusCode: statusCode,
    );
  }
}

void main() {
  const url =
      'https://blu-user-bck.s3.ap-south-1.amazonaws.com/discovery-video/x.mp4';

  Future<DiscoveryVideoController> load(_FakeDiscoverRepo repo) async {
    final controller = DiscoveryVideoController(repo: repo);
    await controller.ensureLoaded();
    return controller;
  }

  test('reads video_url out of the documented payload', () async {
    final controller = await load(_FakeDiscoverRepo({
      'success': true,
      'data': {'video_url': url},
    }));

    expect(controller.videoUrl.value, url);
  });

  test('trims surrounding whitespace', () async {
    final controller = await load(_FakeDiscoverRepo({
      'data': {'video_url': '  $url  '},
    }));

    expect(controller.videoUrl.value, url);
  });

  test('an empty url yields no clip', () async {
    final controller = await load(_FakeDiscoverRepo({
      'data': {'video_url': '   '},
    }));

    expect(controller.videoUrl.value, isNull);
  });

  test('a missing video_url key yields no clip', () async {
    final controller = await load(_FakeDiscoverRepo({'data': {}}));

    expect(controller.videoUrl.value, isNull);
  });

  test('a non-string video_url yields no clip', () async {
    final controller = await load(_FakeDiscoverRepo({
      'data': {'video_url': 42},
    }));

    expect(controller.videoUrl.value, isNull);
  });

  /// `data` is read defensively because not every endpoint in this app answers
  /// with a JSON object — see the note on [ResponseModel.data].
  test('a non-object data yields no clip', () async {
    final controller = await load(_FakeDiscoverRepo({
      'data': ['not', 'an', 'object'],
    }));

    expect(controller.videoUrl.value, isNull);
  });

  test('an HTTP failure yields no clip', () async {
    final controller = await load(_FakeDiscoverRepo(
      {'message': 'Not Found'},
      statusCode: 404,
    ));

    expect(controller.videoUrl.value, isNull);
  });

  test('a thrown transport error is swallowed, not surfaced', () async {
    final repo = _FakeDiscoverRepo(null, throws: true);
    final controller = DiscoveryVideoController(repo: repo);

    await expectLater(controller.ensureLoaded(), completes);
    expect(controller.videoUrl.value, isNull);
  });

  /// The banner rebuilds on every Discover repaint and calls this each time —
  /// without the guard that is a request per scroll frame.
  test('fetches at most once, however often it is asked', () async {
    final repo = _FakeDiscoverRepo({
      'data': {'video_url': url},
    });
    final controller = DiscoveryVideoController(repo: repo);

    await controller.ensureLoaded();
    await controller.ensureLoaded();
    await controller.ensureLoaded();

    expect(repo.calls, 1);
    expect(controller.videoUrl.value, url);
  });

  test('does not retry after a failure within the same run', () async {
    final repo = _FakeDiscoverRepo({'data': {}}, statusCode: 500);
    final controller = DiscoveryVideoController(repo: repo);

    await controller.ensureLoaded();
    await controller.ensureLoaded();

    expect(repo.calls, 1);
  });
}
