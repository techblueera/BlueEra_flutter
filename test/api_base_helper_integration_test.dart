import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end tests for [ApiBaseHelper] driven through a real `HttpServer` on
/// loopback, so the whole stack runs: interceptors, `validateStatus`, body
/// normalisation and the failure path.
///
/// Each scenario is one that used to end in an unhandled Dart exception. The
/// assertion is the same every time — **the call returns, it does not throw**
/// — because that is the production bug: `handleError` finished with
/// `throw DioExceptions.fromDioError(e).message!`, a bare String, and the
/// ~1,200 call sites without a `try` crashed on it.
void main() {
  late HttpServer server;
  late String origin;

  /// What the next request should be answered with.
  late void Function(HttpRequest request) respond;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = 'http://${server.address.address}:${server.port}/';
    server.listen((request) async {
      respond(request);
    });
  });

  tearDownAll(() async => server.close(force: true));

  setUp(() {
    // Point the shared Dio at the test server. `baseAPI` is a static built
    // once, so the base URL is swapped rather than the client rebuilt.
    ApiBaseHelper.baseAPI.options.baseUrl = origin;
    ApiBaseHelper.baseAPI.options.connectTimeout = const Duration(seconds: 5);
    ApiBaseHelper.baseAPI.options.receiveTimeout = const Duration(seconds: 5);
    ApiBaseHelper.numberOfReq = 0;
  });

  /// Answers with [body] and [status], under [contentType].
  void serve(int status, String body,
      {String contentType = 'application/json'}) {
    respond = (request) async {
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.parse(contentType);
      request.response.write(body);
      await request.response.close();
    };
  }

  // `showProgress: false` throughout: the progress dialog needs a GetX overlay
  // that does not exist in a plain unit test.

  group('successful responses', () {
    test('a 200 object body parses and reports success', () async {
      serve(200, jsonEncode({'message': 'ok', 'data': {'id': 'a1'}}));

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);

      expect(res.isSuccess, isTrue);
      expect(res.exception, isNull);
      expect(res.statusCode, 200);
      expect(res.message, 'ok');
      expect(res.data, {'id': 'a1'});
    });

    test('nested maps are normalised to Map<String, dynamic> all the way down',
        () async {
      // The old interceptor converted the TOP level only, so
      // `Map<String, dynamic>.from(json['data']['owner'])` one level down threw
      // `type '_Map<dynamic, dynamic>' is not a subtype of type
      // 'Map<String, dynamic>'`.
      serve(
          200,
          jsonEncode({
            'data': {
              'owner': {'name': 'Ana'},
              'items': [
                {'sku': 'x1'}
              ],
            }
          }));

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);
      final data = res.data as Map<String, dynamic>;

      expect(data['owner'], isA<Map<String, dynamic>>());
      expect((data['items'] as List).first, isA<Map<String, dynamic>>());
      // The cast that used to blow up:
      expect(() => Map<String, dynamic>.from(data['owner']), returnsNormally);
    });

    test('a bare array body is delivered without throwing', () async {
      serve(200, jsonEncode([
        {'id': 1}
      ]));

      final res = await ApiBaseHelper().postHTTP('inventory',
          params: {'q': 1}, showProgress: false);

      expect(res.isSuccess, isTrue);
      expect(res.response?.data, isA<List>());
      // Indexing a List with a String is what used to throw here.
      expect(res.data, isNull);
    });
  });

  group('HTTP error statuses return rather than throw', () {
    test('400 carries the server message', () async {
      serve(400, jsonEncode({'message': 'Mobile number already registered'}));

      final res = await ApiBaseHelper()
          .postHTTP('auth-service/sent-otp', showProgress: false);

      expect(res.isSuccess, isFalse);
      expect(res.statusCode, 400);
      expect(res.exception, isA<BadRequestException>());
      expect(res.message, 'Mobile number already registered');
    });

    test('404 with a body that has no message key does not crash', () async {
      serve(404, jsonEncode({'ok': false}));

      // Awaiting directly IS the assertion: a throw here fails the test, and a
      // throw here is exactly what production did.
      final res = await ApiBaseHelper().getHTTP('missing', showProgress: false);

      expect(res.exception, isA<NotFoundException>());
      expect(res.message, isNotEmpty);
    });

    test('404 whose body is a bare array does not crash', () async {
      serve(404, jsonEncode(['nope']));

      final res = await ApiBaseHelper().getHTTP('missing', showProgress: false);

      expect(res.exception, isA<NotFoundException>());
      expect(res.isSuccess, isFalse);
    });

    test('500 is classified and retryable', () async {
      serve(500, jsonEncode({'message': 'boom'}));

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);

      expect(res.exception, isA<InternalServerErrorException>());
      expect(res.isRetryable, isTrue);
    });
  });

  group('corrupted and mislabelled bodies', () {
    test('a 502 HTML page served as application/json does not crash', () async {
      // The headline case: Dio is told the body is JSON, tries to decode an
      // nginx error page, and the FormatException used to surface as
      // `DioExceptionType.unknown` → reported to the user as "No internet
      // connection" or thrown as a raw String.
      serve(
        502,
        '<html><head><title>502 Bad Gateway</title></head>'
        '<body><h1>502 Bad Gateway</h1></body></html>',
        contentType: 'application/json',
      );

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);

      expect(res.isSuccess, isFalse);
      expect(res.exception, isNotNull);
      // Whatever the classification, the user must never see markup.
      expect(res.message, isNot(contains('<html')));
      expect(res.message, isNot(contains('<h1')));
    });

    test('a 200 with a truncated JSON body does not crash', () async {
      serve(200, '{"data": {"id": "a1"');

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);

      expect(res.isSuccess, isFalse);
      expect(res.exception, isNotNull);
      expect(res.message, isNotEmpty);
    });

    test('a 200 with an empty body does not crash', () async {
      serve(200, '');

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);

      expect(res.isSuccess, isTrue);
      expect(res.data, isNull);
    });

    test('a 204 with no body at all does not crash', () async {
      respond = (request) async {
        request.response.statusCode = 204;
        await request.response.close();
      };

      final res =
          await ApiBaseHelper().deleteHTTP('thing', showProgress: false);

      expect(res.isSuccess, isTrue);
      expect(res.statusCode, 204);
    });

    test('JSON sent as text/plain is still usable', () async {
      serve(200, jsonEncode({'message': 'ok'}), contentType: 'text/plain');

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);

      expect(res.isSuccess, isTrue);
      expect(res.message, 'ok');
    });
  });

  group('transport failures return a classified model, never a throw', () {
    test('an unreachable host is reported, not thrown', () async {
      ApiBaseHelper.baseAPI.options.baseUrl =
          'http://127.0.0.1:1/'; // nothing listens on port 1

      final res = await ApiBaseHelper().getHTTP('thing', showProgress: false);

      expect(res.isSuccess, isFalse);
      expect(res.isTransportFailure, isTrue);
      expect(res.exception!.isRetryable, isTrue);
      expect(res.statusCode, isNull);
      // The synthetic body keeps `response!.data['message']` call sites alive.
      expect(res.response, isNotNull);
      expect(res.response!.data['success'], isFalse);
      expect(res.message, isNotEmpty);
    });

    test('a server that sends headers then stalls hits the deadline instead '
        'of hanging forever', () async {
      // This is the case dio does NOT cover. Its IO adapter applies
      // `receiveTimeout` to `request.close()` — waiting for the response
      // HEADERS — and the per-chunk timer in `handleResponseStream` is armed
      // only from inside the stream's data callback. Headers-then-silence is
      // therefore guarded by nothing, and the request hangs as long as the OS
      // keeps the socket alive. Verified against dio 5.9.0: without
      // `ApiBaseHelper.requestDeadline` this test runs until the suite's own
      // 30 s timeout kills it.
      ApiBaseHelper.baseAPI.options.receiveTimeout =
          const Duration(milliseconds: 300);
      ApiBaseHelper.interactiveDeadline = const Duration(seconds: 2);
      addTearDown(() =>
          ApiBaseHelper.interactiveDeadline = const Duration(seconds: 45));

      respond = (request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        // Headers go out; the body never does and the response is never closed.
        await request.response.flush();
      };

      final started = DateTime.now();
      final res = await ApiBaseHelper().getHTTP('slow', showProgress: false);
      final elapsed = DateTime.now().difference(started);

      expect(res.isSuccess, isFalse);
      expect(res.exception, isA<ApiTimeoutException>());
      expect(res.isTransportFailure, isTrue);
      expect(elapsed, lessThan(const Duration(seconds: 10)),
          reason: 'the deadline must bound the wait');
      // The deadline cancels through the request's CancelToken, so the
      // interceptor's error path runs and the in-flight counter drains — that
      // is what takes the progress dialog down.
      expect(ApiBaseHelper.numberOfReq, 0);
    });

    test('a stalled TRANSFER is cancelled by the watchdog, not left hanging',
        () async {
      // Transfers cannot take a wall-clock deadline — a legitimate upload on a
      // slow connection would be killed mid-flight — so they are watched for
      // SILENCE instead. Without this they were opted out of every guard, which
      // left the requests holding the most resources (socket, file handle,
      // progress dialog) as the only unprotected ones.
      ApiBaseHelper.transferStallTimeout = const Duration(seconds: 1);
      addTearDown(() =>
          ApiBaseHelper.transferStallTimeout = const Duration(seconds: 60));

      // Accept the upload, send headers, then never finish the response.
      respond = (request) async {
        await request.drain<void>();
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        await request.response.flush();
      };

      final started = DateTime.now();
      final res = await ApiBaseHelper().postHTTP(
        'upload',
        params: {'field': 'value'},
        isMultipart: true,
        showProgress: false,
      );
      final elapsed = DateTime.now().difference(started);

      expect(res.isSuccess, isFalse);
      // Reclassified: a stall cancels the CancelToken, so dio reports
      // `cancel` — the one kind screens stay silent for. A wedged upload is
      // not a cancellation the user asked for.
      expect(res.exception, isA<ApiTimeoutException>());
      expect(res.exception!.kind, isNot(ApiErrorKind.cancelled));
      expect(res.isTransportFailure, isTrue);
      expect(elapsed, lessThan(const Duration(seconds: 15)));
      expect(ApiBaseHelper.numberOfReq, 0);
    });

    test('a slow transfer inside the stall window still succeeds', () async {
      // The other half of the contract: the watchdog must not turn into a
      // blanket cap on slow work.
      //
      // NOTE the shape of this test. It dribbles for ~1.2s under a 3s window,
      // rather than dribbling past the window and relying on each chunk
      // re-arming the watchdog — because `onReceiveProgress` does NOT arrive
      // per chunk. Probed against dart:io's HttpClient, every receive callback
      // for a 4s dribbled response landed in one burst at ~4020 ms, in all of
      // bare Dio / with receiveTimeout / with an interceptor. Receive progress
      // reports how much arrived, not when, so it cannot carry liveness. The
      // real liveness signal is `onSendProgress`; see [transferStallTimeout].
      ApiBaseHelper.transferStallTimeout = const Duration(seconds: 3);
      addTearDown(() =>
          ApiBaseHelper.transferStallTimeout = const Duration(seconds: 60));

      respond = (request) async {
        await request.drain<void>();
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"message":"');
        await request.response.flush();
        for (var i = 0; i < 4; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          request.response.write('x');
          await request.response.flush();
        }
        request.response.write('"}');
        await request.response.close();
      };

      final res = await ApiBaseHelper().postHTTP(
        'upload',
        params: {'field': 'value'},
        isMultipart: true,
        showProgress: false,
      );

      expect(res.isSuccess, isTrue,
          reason: 'a transfer well inside the window must not be cancelled; '
              'got ${res.exception?.debugDescription}');
      expect(res.message, 'xxxx');
      expect(ApiBaseHelper.numberOfReq, 0);
    });

    test('throwOnError opts in to a TYPED exception — never a String',
        () async {
      ApiBaseHelper.baseAPI.options.baseUrl = 'http://127.0.0.1:1/';

      // The whole point: `on Exception catch` works now. Against the old raw
      // String throw this clause never fired.
      Object? caught;
      try {
        await ApiBaseHelper()
            .getHTTP('thing', showProgress: false, throwOnError: true);
      } on Exception catch (e) {
        caught = e;
      }

      expect(caught, isA<ApiException>());
      expect(caught, isNot(isA<String>()));
      expect((caught as ApiException).isTransport, isTrue);
    });

    test('the legacy onError callback still fires for transport failures',
        () async {
      ApiBaseHelper.baseAPI.options.baseUrl = 'http://127.0.0.1:1/';

      DioExceptions? reported;
      await ApiBaseHelper().getHTTP(
        'thing',
        showProgress: false,
        onError: (e) => reported = e,
        onSuccess: (_) {},
      );

      expect(reported, isNotNull);
      expect(reported!.message, isNotEmpty);
      expect(reported!.isTransport, isTrue);
      expect(reported!.kind, ApiErrorKind.noConnection);
    });

    test('a throwing onSuccess callback cannot take down the caller', () async {
      serve(200, jsonEncode({'message': 'ok'}));

      final res = await ApiBaseHelper().getHTTP(
        'thing',
        showProgress: false,
        onSuccess: (_) => throw StateError('callback blew up'),
        onError: (_) {},
      );
      expect(res.isSuccess, isTrue);
    });
  });

  group('malformed requests fail as values too', () {
    test('a multipart POST with non-Map params is reported, not thrown',
        () async {
      serve(200, jsonEncode({'message': 'ok'}));

      // `params.forEach` on a String raised NoSuchMethodError *before* the
      // request, outside the `on DioException catch` that was the only guard.
      final res = await ApiBaseHelper().postHTTP(
        'upload',
        params: 'not a map',
        isMultipart: true,
        showProgress: false,
      );
      expect(res.isSuccess, isFalse);
      expect(res.exception, isNotNull);
    });
  });

  group('in-flight accounting', () {
    test('the request counter returns to zero after success and failure',
        () async {
      serve(200, jsonEncode({'message': 'ok'}));
      await ApiBaseHelper().getHTTP('thing', showProgress: false);
      expect(ApiBaseHelper.numberOfReq, 0);

      ApiBaseHelper.baseAPI.options.baseUrl = 'http://127.0.0.1:1/';
      await ApiBaseHelper().getHTTP('thing', showProgress: false);
      expect(ApiBaseHelper.numberOfReq, 0);
    });

    test('the counter never goes negative', () async {
      // A single stray decrement used to pin it at -1, after which the
      // `numberOfReq == 0` test never held again and the progress dialog
      // stayed up for the rest of the session.
      ApiBaseHelper.baseAPI.options.baseUrl = 'http://127.0.0.1:1/';
      await Future.wait([
        ApiBaseHelper().getHTTP('a', showProgress: false),
        ApiBaseHelper().getHTTP('b', showProgress: false),
        ApiBaseHelper().getHTTP('c', showProgress: false),
      ]);
      expect(ApiBaseHelper.numberOfReq, greaterThanOrEqualTo(0));
      expect(ApiBaseHelper.numberOfReq, 0);
    });
  });
}
