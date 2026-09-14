import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_exceptions.dart';
import 'package:BlueEra/core/api/apiService/api_result.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the networking layer's failure paths.
///
/// Each group pins one of the production crash signatures that came out of
/// `ApiBaseHelper`. They are written against the response/exception shapes
/// rather than a live socket, so they run without a device or a server.
void main() {
  RequestOptions optionsFor(String path) =>
      RequestOptions(path: path, baseUrl: 'https://api.example.com/');

  Response<dynamic> responseWith(int? status, dynamic body, {String path = 'x'}) =>
      Response<dynamic>(
        requestOptions: optionsFor(path),
        statusCode: status,
        data: body,
      );

  group('classification by transport failure', () {
    test('connection timeout is a timeout, not "no internet"', () {
      final error = DioException(
        requestOptions: optionsFor('feed'),
        type: DioExceptionType.connectionTimeout,
      );
      final exception = ApiException.from(error);

      expect(exception, isA<ApiTimeoutException>());
      expect(exception.kind, ApiErrorKind.timeout);
      expect(exception.isTransport, isTrue);
      expect(exception.isRetryable, isTrue);
      expect(exception.statusCode, isNull);
    });

    test('send timeout is classified — the old switch could never match it', () {
      // The previous implementation wrote `case DioException.sendTimeout:`
      // (the factory constructor) instead of `DioExceptionType.sendTimeout`.
      // That is a valid constant pattern, so it compiled and silently never
      // matched: every send timeout was reported as "Something went wrong".
      final exception = ApiException.from(DioException(
        requestOptions: optionsFor('upload'),
        type: DioExceptionType.sendTimeout,
      ));

      expect(exception, isA<ApiTimeoutException>());
      expect(exception.message, isNot(contains('Something went wrong')));
    });

    test('connectionError and wrapped SocketException are no-connection', () {
      expect(
        ApiException.from(DioException(
          requestOptions: optionsFor('feed'),
          type: DioExceptionType.connectionError,
        )),
        isA<FetchDataException>(),
      );

      expect(
        ApiException.from(DioException(
          requestOptions: optionsFor('feed'),
          type: DioExceptionType.unknown,
          error: const SocketException('Failed host lookup: api.example.com'),
        )),
        isA<FetchDataException>(),
      );
    });

    test('a bare SocketException from outside Dio is still classified', () {
      final exception =
          ApiException.from(const SocketException('Network is unreachable'));
      expect(exception, isA<FetchDataException>());
      expect(exception.isTransport, isTrue);
    });

    test('dart:async TimeoutException maps to the timeout kind', () {
      final exception = ApiException.from(TimeoutException('too slow'));
      expect(exception, isA<ApiTimeoutException>());
    });

    test('cancellation is not treated as a user-facing failure to retry', () {
      final exception = ApiException.from(DioException(
        requestOptions: optionsFor('feed'),
        type: DioExceptionType.cancel,
      ));
      expect(exception, isA<RequestCancelledException>());
      expect(exception.isTransport, isFalse);
      expect(exception.isRetryable, isFalse);
    });

    test('a DioExceptionType.unknown wrapping a FormatException is a format '
        'error, not "No internet connection"', () {
      // The old mapping labelled every `unknown` as "No internet connection".
      // Dio also lands there when its transformer fails to decode a body — a
      // gateway serving an HTML 502 as application/json — so users were told
      // their wifi was off while the gateway was down.
      final exception = ApiException.from(DioException(
        requestOptions: optionsFor('feed'),
        type: DioExceptionType.unknown,
        error: const FormatException('Unexpected character'),
      ));

      expect(exception, isA<ResponseFormatException>());
      expect(exception.kind, ApiErrorKind.format);
    });
  });

  group('classification by status code', () {
    test('400 / 401 / 403 / 404 / 409 / 429 / 500 each map to their type', () {
      expect(ApiException.fromResponse(responseWith(400, {})),
          isA<BadRequestException>());
      expect(ApiException.fromResponse(responseWith(401, {})),
          isA<UnauthorisedException>());
      expect(ApiException.fromResponse(responseWith(403, {})),
          isA<ForbiddenException>());
      expect(ApiException.fromResponse(responseWith(404, {})),
          isA<NotFoundException>());
      expect(ApiException.fromResponse(responseWith(409, {})),
          isA<ConflictException>());
      expect(ApiException.fromResponse(responseWith(429, {})),
          isA<TooManyRequestsException>());
      expect(ApiException.fromResponse(responseWith(500, {})),
          isA<InternalServerErrorException>());
      expect(ApiException.fromResponse(responseWith(503, {})),
          isA<InternalServerErrorException>());
    });

    test('401 tears down the session but 403 must not', () {
      expect(ApiException.fromResponse(responseWith(401, {})).isAuthFailure,
          isTrue);
      // 403 here means "not your order/business". Logging out on it ejects a
      // perfectly valid session.
      expect(ApiException.fromResponse(responseWith(403, {})).isAuthFailure,
          isFalse);
    });

    test('the server message wins over the generic line when present', () {
      final exception = ApiException.fromResponse(
          responseWith(400, {'message': 'Mobile number already registered'}));
      expect(exception.message, 'Mobile number already registered');
    });

    test('a machine-readable code is lifted from nested shapes', () {
      expect(
        ApiException.fromResponse(
                responseWith(409, {'error': {'code': 'ORDER_TERMINAL'}}))
            .code,
        'ORDER_TERMINAL',
      );
    });
  });

  group('safe parsing of bodies that are not a JSON object', () {
    test('a 404 whose body is a bare array does not throw', () {
      // `POST medical-service/inventory` answers with a bare array. The old
      // handler did `return error["message"]` unguarded: indexing a List with
      // a String threw `type 'String' is not a subtype of type 'int'` from
      // inside the error handler itself.
      late ApiException exception;
      expect(
        () => exception =
            ApiException.fromResponse(responseWith(404, [1, 2, 3])),
        returnsNormally,
      );
      expect(exception, isA<NotFoundException>());
      expect(exception.message, isNotEmpty);
    });

    test('a 404 with no message key falls back instead of returning null', () {
      // The old `_handleResponseError` returned `error["message"]` — null when
      // the key was absent — into a non-nullable String, and the caller then
      // did `.message!`, which null-asserted and crashed.
      final exception =
          ApiException.fromResponse(responseWith(404, {'status': 'nope'}));
      expect(exception.message, isNotEmpty);
    });

    test('a 502 HTML gateway page never leaks markup into the UI', () {
      const html = '<html><head><title>502 Bad Gateway</title></head>'
          '<body><h1>502 Bad Gateway</h1><hr>nginx</body></html>';
      final exception = ApiException.fromResponse(responseWith(502, html));

      expect(exception, isA<InternalServerErrorException>());
      expect(exception.message, isNot(contains('<')));
      expect(exception.message, contains('temporarily unavailable'));
    });

    test('a null body is handled', () {
      expect(() => ApiException.fromResponse(responseWith(500, null)),
          returnsNormally);
      expect(ApiException.fromResponse(responseWith(500, null)).message,
          isNotEmpty);
    });

    test('a response with a null status code does not crash the mapping', () {
      // `response.statusCode!` was asserted in the interceptor.
      expect(() => ApiException.fromResponse(responseWith(null, {})),
          returnsNormally);
    });

    test('validation errors arriving as a list of strings are joined', () {
      final exception = ApiException.fromResponse(responseWith(422, {
        'message': ['Name is required', 'Pincode must be 6 digits'],
      }));
      expect(exception.message, contains('Name is required'));
      expect(exception.message, contains('Pincode must be 6 digits'));
    });

    test('a JSON body that arrived undecoded as a String is still read', () {
      final exception = ApiException.fromResponse(
          responseWith(400, jsonEncode({'message': 'Bad payload'})));
      expect(exception.message, 'Bad payload');
    });
  });

  group('tryDecodeJson never throws', () {
    test('returns null for HTML, empty and truncated payloads', () {
      expect(ApiException.tryDecodeJson('<html>502</html>'), isNull);
      expect(ApiException.tryDecodeJson(''), isNull);
      expect(ApiException.tryDecodeJson('   '), isNull);
      expect(ApiException.tryDecodeJson('{"a": 1'), isNull); // truncated
      expect(ApiException.tryDecodeJson('not json at all'), isNull);
    });

    test('decodes well-formed payloads', () {
      expect(ApiException.tryDecodeJson('{"a":1}'), {'a': 1});
      expect(ApiException.tryDecodeJson('[1,2]'), [1, 2]);
    });
  });

  group('ResponseModel failure contract', () {
    test('a transport failure reports not-success and a usable message', () {
      const failure = FetchDataException('No internet connection.');
      final model = ResponseModel(response: null, exception: failure);

      expect(model.isSuccess, isFalse);
      expect(model.isTransportFailure, isTrue);
      expect(model.isRetryable, isTrue);
      // The pervasive `response.message ?? somethingWentWrong` call site now
      // shows the real reason rather than the generic fallback.
      expect(model.message, 'No internet connection.');
    });

    test('a 2xx response with no exception is success', () {
      final model = ResponseModel(
        statusCode: 200,
        response: responseWith(200, {'message': 'ok', 'data': [1]}),
      );
      expect(model.isSuccess, isTrue);
      expect(model.message, 'ok');
      expect(model.data, [1]);
    });

    test('data on an array body yields null rather than throwing', () {
      final model =
          ResponseModel(statusCode: 200, response: responseWith(200, [1, 2]));
      expect(model.data, isNull);
      expect(model.isSuccess, isTrue);
    });

    test('an exception forces isSuccess false even on a 2xx status', () {
      final model = ResponseModel(
        statusCode: 200,
        response: responseWith(200, {}),
        exception: const ResponseFormatException('bad body'),
      );
      expect(model.isSuccess, isFalse);
    });
  });

  group('ApiResult', () {
    test('guard converts a throwing body into a failure', () async {
      final result = await ApiResult.guard<int>(
        () async => throw const SocketException('down'),
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<FetchDataException>());
    });

    test('guard passes a value through', () async {
      final result = await ApiResult.guard<int>(() async => 7);
      expect(result.dataOrNull, 7);
    });

    test('map turns a throwing fromJson into a failure, not a crash', () {
      // The `_Map<dynamic, dynamic> is not a subtype of Map<String, dynamic>`
      // family of TypeErrors used to escape straight out of a controller's
      // success path.
      final result = const ApiSuccess<Map<String, dynamic>>({'id': 'abc'})
          .map<int>((body) => body['id'] as int);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ResponseFormatException>());
    });

    test('fold collapses both branches', () {
      expect(const ApiSuccess<int>(2).fold((d) => 'ok $d', (e) => 'err'), 'ok 2');
      expect(
        const ApiFailure<int>(NotFoundException('gone'))
            .fold((d) => 'ok', (e) => 'err ${e.message}'),
        'err gone',
      );
    });

    test('toResult bridges a ResponseModel and guards the parse', () {
      final ok = ResponseModel(
        statusCode: 200,
        response: responseWith(200, {'name': 'Cafe Aroma'}),
      ).toResult<String>((body) => body['name'] as String);
      expect(ok.dataOrNull, 'Cafe Aroma');

      final parseFailure = ResponseModel(
        statusCode: 200,
        response: responseWith(200, {'name': 42}),
      ).toResult<String>((body) => body['name'] as String);
      expect(parseFailure.errorOrNull, isA<ResponseFormatException>());

      final transportFailure = ResponseModel(
        exception: const ApiTimeoutException('slow'),
      ).toResult<String>((body) => body['name'] as String);
      expect(transportFailure.errorOrNull, isA<ApiTimeoutException>());
    });
  });

  group('what user-facing code sees', () {
    test('toString is the display message, never a type dump', () {
      // Call sites do `commonSnackBar(message: e.toString())` in many places.
      final exception = ApiException.from(DioException(
        requestOptions: optionsFor('feed'),
        type: DioExceptionType.connectionError,
      ));
      expect(exception.toString(), exception.message);
      expect(exception.toString(), isNot(contains('Instance of')));
      expect(exception.toString(), isNot(contains('DioException')));
    });

    test('every classified failure has a non-empty message', () {
      for (final type in DioExceptionType.values) {
        final exception = ApiException.from(DioException(
          requestOptions: optionsFor('feed'),
          type: type,
          response: type == DioExceptionType.badResponse
              ? responseWith(500, null)
              : null,
        ));
        expect(exception.message.trim(), isNotEmpty,
            reason: 'empty message for $type');
      }
    });

    test('debugDescription carries the detail toString withholds', () {
      final exception =
          ApiException.fromResponse(responseWith(404, {}), endpoint: 'GET /x');
      expect(exception.debugDescription, contains('404'));
      expect(exception.debugDescription, contains('GET /x'));
    });
  });

  // The worked examples from docs/API_ERROR_HANDLING_GUIDE.md, compiled and
  // executed so the guide cannot drift from the API it documents.
  group('the documented consumption patterns', () {
    // A stand-in for a model whose `fromJson` is strict about its payload.
    Map<String, dynamic> parseProfile(dynamic body) {
      final map = body as Map<String, dynamic>;
      return {'name': map['name'] as String};
    }

    test('pattern A — branch on isSuccess, read message and kind', () {
      final failure = ResponseModel(
        exception: ApiException.from(DioException(
          requestOptions: optionsFor('profile'),
          type: DioExceptionType.connectionError,
        )),
      );

      String rendered;
      if (failure.isSuccess) {
        rendered = 'loaded';
      } else if (failure.isTransportFailure) {
        rendered = 'retry: ${failure.message}';
      } else {
        rendered = failure.message;
      }

      expect(rendered, startsWith('retry: '));
      expect(rendered, contains('No internet'));
    });

    test('pattern B — the switch is exhaustive and the parse is guarded', () {
      String render(ApiResult<Map<String, dynamic>> result) {
        // Omitting either arm is a compile error — that is the guarantee.
        switch (result) {
          case ApiSuccess(:final data):
            return 'hello ${data['name']}';
          case ApiFailure(:final error):
            return error.kind == ApiErrorKind.cancelled
                ? '<silent>'
                : error.message;
        }
      }

      final ok = ResponseModel(
        statusCode: 200,
        response: responseWith(200, {'name': 'Ana'}),
      ).toResult<Map<String, dynamic>>(parseProfile);
      expect(render(ok), 'hello Ana');

      // A payload the model does not expect: a failure, not a TypeError
      // escaping into the controller's success path.
      final malformed = ResponseModel(
        statusCode: 200,
        response: responseWith(200, {'name': 42}),
      ).toResult<Map<String, dynamic>>(parseProfile);
      expect(malformed.errorOrNull, isA<ResponseFormatException>());
      expect(render(malformed), isNotEmpty);

      // A cancelled request renders silently.
      expect(
        render(const ApiFailure(RequestCancelledException('Request cancelled.'))),
        '<silent>',
      );
    });

    test('pattern C — typed catches, ordered specific to general', () async {
      Future<String> classify(ApiException thrown) async {
        try {
          throw thrown;
        } on UnauthorisedException {
          return 'logout';
        } on ApiTimeoutException {
          return 'retry?';
        } on FetchDataException {
          return 'offline';
        } on ApiException catch (e) {
          return 'generic:${e.statusCode}';
        }
      }

      expect(await classify(const UnauthorisedException('x')), 'logout');
      expect(await classify(const ApiTimeoutException('x')), 'retry?');
      expect(await classify(const FetchDataException('x')), 'offline');
      expect(
        await classify(const NotFoundException('x', statusCode: 404)),
        'generic:404',
      );
    });

    test('fold, getOrElse and map behave as documented', () {
      final result = const ApiSuccess<Map<String, dynamic>>({'name': 'Ana'});

      expect(result.fold((d) => 'ok', (e) => e.message), 'ok');
      expect(
        const ApiFailure<int>(NotFoundException('gone')).getOrElse((_) => -1),
        -1,
      );
      expect(result.map((d) => (d['name'] as String).length).dataOrNull, 3);
    });
  });
}
