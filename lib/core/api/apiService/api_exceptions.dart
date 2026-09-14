import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

/// Coarse category of an API failure.
///
/// Callers switch on this instead of on HTTP codes or Dio internals, so a
/// screen can offer "retry" for [noConnection]/[timeout] and "fix your input"
/// for [badRequest] without knowing anything about the transport.
enum ApiErrorKind {
  /// DNS failure, refused connection, airplane mode, captive portal.
  noConnection,

  /// Connect / send / receive / transform timeout.
  timeout,

  /// The request was cancelled (screen disposed, cancel token fired).
  cancelled,

  /// TLS handshake rejected.
  badCertificate,

  /// HTTP 400 and other 4xx without a more specific kind.
  badRequest,

  /// HTTP 401 — credential missing, invalid or expired.
  unauthorised,

  /// HTTP 403 — authenticated but not permitted.
  forbidden,

  /// HTTP 404.
  notFound,

  /// HTTP 409.
  conflict,

  /// HTTP 429.
  tooManyRequests,

  /// HTTP 500..599.
  serverError,

  /// Body could not be decoded: HTML error page, truncated JSON, wrong
  /// content-type, or a shape the parser did not expect.
  format,

  /// Anything not otherwise classified.
  unknown,
}

/// Base type for every failure the networking layer reports.
///
/// Implements [Exception] deliberately. The previous layer ended its error
/// path with `throw DioExceptions.fromDioError(e).message!` — throwing a bare
/// [String]. A raw String is not an [Exception], so `on Exception catch` never
/// caught it, `catch (e)` produced an untyped object whose `toString()` was
/// shown verbatim to users, and any call site without a catch took down the
/// isolate with `Unhandled Exception: Connection timeout with API server`.
/// Everything reported from here is a real typed exception carrying the
/// endpoint, status and original error.
abstract class ApiException implements Exception {
  /// Human-readable, already safe to show in a snackbar.
  final String message;

  /// HTTP status when the failure came from a response; null for transport
  /// failures that never reached the server.
  final int? statusCode;

  /// `METHOD https://host/path` the failure belongs to. Null only when the
  /// request never got as far as having options.
  final String? endpoint;

  /// Machine-readable code lifted from the server body (`code` / `errorCode` /
  /// `error.code`) when it sent one.
  final String? code;

  /// Decoded server body, when there was one and it could be read.
  final dynamic body;

  /// The underlying error ([DioException], [SocketException], ...).
  final Object? cause;

  final StackTrace? stackTrace;

  const ApiException(
    this.message, {
    this.statusCode,
    this.endpoint,
    this.code,
    this.body,
    this.cause,
    this.stackTrace,
  });

  ApiErrorKind get kind;

  /// True when the request never produced a server response, so it is unknown
  /// whether the server acted on it. Non-idempotent calls (payments, order
  /// actions) must surface "retry?" rather than "failed" for these.
  bool get isTransport =>
      kind == ApiErrorKind.noConnection ||
      kind == ApiErrorKind.timeout ||
      kind == ApiErrorKind.badCertificate;

  /// Whether a blind retry is reasonable.
  bool get isRetryable =>
      isTransport ||
      kind == ApiErrorKind.serverError ||
      kind == ApiErrorKind.tooManyRequests;

  /// Whether the session should be torn down. 403 is deliberately excluded —
  /// see [ForbiddenException].
  bool get isAuthFailure => kind == ApiErrorKind.unauthorised;

  /// Returns the message only. Call sites that already do
  /// `commonSnackBar(message: e.toString())` therefore show the friendly text
  /// rather than `Instance of 'DioException'` or a raw dump.
  @override
  String toString() => message;

  /// One-line diagnostic for logs and Crashlytics — carries the detail that
  /// [toString] deliberately keeps away from users.
  String get debugDescription =>
      '$runtimeType(${kind.name}${statusCode == null ? '' : ' $statusCode'}'
      '${code == null ? '' : ' code=$code'}) '
      '${endpoint ?? '<no endpoint>'} :: $message';

  /// Classifies any error thrown anywhere in the request pipeline.
  ///
  /// Accepts [Object] rather than [DioException] on purpose: the pipeline can
  /// also surface a raw [SocketException] (from a non-Dio `HttpClient`), a
  /// [TimeoutException] (from a `.timeout()` wrapper), a [FormatException]
  /// (from `jsonDecode`), or a [TypeError] (from a `fromJson` cast). All of
  /// those previously escaped as unhandled crashes.
  factory ApiException.from(
    Object error, {
    StackTrace? stackTrace,
    String? endpoint,
  }) {
    if (error is ApiException) return error;

    if (error is DioException) {
      return _fromDio(error, stackTrace: stackTrace, endpoint: endpoint);
    }

    if (error is SocketException) {
      return FetchDataException(
        noConnectionMessage,
        endpoint: endpoint,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HandshakeException || error is CertificateException) {
      return BadCertificateException(
        certificateMessage,
        endpoint: endpoint,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return ApiTimeoutException(
        timeoutMessage,
        endpoint: endpoint,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException || error is JsonUnsupportedObjectError) {
      return ResponseFormatException(
        formatMessage,
        endpoint: endpoint,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // TypeError covers the `_Map<dynamic, dynamic> is not a subtype of
    // Map<String, dynamic>` and `type 'String' is not a subtype of type 'int'`
    // family thrown out of model `fromJson` constructors.
    if (error is TypeError || error is NoSuchMethodError) {
      return ResponseFormatException(
        formatMessage,
        endpoint: endpoint,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownApiException(
      genericMessage,
      endpoint: endpoint,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static ApiException _fromDio(
    DioException error, {
    StackTrace? stackTrace,
    String? endpoint,
  }) {
    final where =
        endpoint ?? '${error.requestOptions.method} ${error.requestOptions.uri}';
    final trace = stackTrace ?? error.stackTrace;
    final response = error.response;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // `sendTimeout` was unreachable before: the old switch wrote
        // `case DioException.sendTimeout:` — the factory CONSTRUCTOR, not
        // `DioExceptionType.sendTimeout`. A constructor tear-off is a valid
        // constant pattern, so it compiled cleanly and simply never matched,
        // and every send timeout fell through to "Something went wrong".
        return ApiTimeoutException(
          timeoutMessage,
          endpoint: where,
          cause: error,
          stackTrace: trace,
        );

      case DioExceptionType.cancel:
        return RequestCancelledException(
          'Request cancelled.',
          endpoint: where,
          cause: error,
          stackTrace: trace,
        );

      case DioExceptionType.badCertificate:
        return BadCertificateException(
          certificateMessage,
          endpoint: where,
          cause: error,
          stackTrace: trace,
        );

      case DioExceptionType.connectionError:
        return FetchDataException(
          noConnectionMessage,
          endpoint: where,
          cause: error,
          stackTrace: trace,
        );

      case DioExceptionType.badResponse:
        return ApiException.fromResponse(
          response,
          endpoint: where,
          cause: error,
          stackTrace: trace,
        );

      case DioExceptionType.unknown:
        // `unknown` was previously reported to users as "No internet
        // connection" unconditionally. It is not: Dio also lands here when the
        // response transformer fails to decode a body (an HTML 502 page served
        // as `application/json`), which is a FORMAT error, and when an
        // interceptor throws. Inspect the wrapped error before deciding, so a
        // user is not told their wifi is off while the gateway is down.
        final inner = error.error;
        if (inner is SocketException) {
          return FetchDataException(
            noConnectionMessage,
            endpoint: where,
            cause: error,
            stackTrace: trace,
          );
        }
        if (inner is HandshakeException || inner is CertificateException) {
          return BadCertificateException(
            certificateMessage,
            endpoint: where,
            cause: error,
            stackTrace: trace,
          );
        }
        if (inner is FormatException) {
          return ResponseFormatException(
            formatMessage,
            endpoint: where,
            statusCode: response?.statusCode,
            body: response?.data,
            cause: error,
            stackTrace: trace,
          );
        }
        if (inner is TimeoutException) {
          return ApiTimeoutException(
            timeoutMessage,
            endpoint: where,
            cause: error,
            stackTrace: trace,
          );
        }
        if (response != null) {
          return ApiException.fromResponse(
            response,
            endpoint: where,
            cause: error,
            stackTrace: trace,
          );
        }
        return FetchDataException(
          noConnectionMessage,
          endpoint: where,
          cause: error,
          stackTrace: trace,
        );

      // ignore: unreachable_switch_default
      default:
        // Unreachable against the currently locked dio (5.9.0) — that is what
        // the lint is reporting, and it is the point. `pubspec.yaml` pins
        // `dio: ^5.8.0+1`, so a `pub upgrade` can add enum members this switch
        // has never seen: 5.11 added `transformTimeout`. Without this arm the
        // file stops compiling on the next minor bump. Anything whose name
        // reads as a timeout is treated as one; the rest fall back to the
        // generic message.
        if (error.type.name.toLowerCase().contains('timeout')) {
          return ApiTimeoutException(
            timeoutMessage,
            endpoint: where,
            cause: error,
            stackTrace: trace,
          );
        }
        return UnknownApiException(
          genericMessage,
          endpoint: where,
          statusCode: response?.statusCode,
          body: response?.data,
          cause: error,
          stackTrace: trace,
        );
    }
  }

  /// Builds the exception for a response that came back with a failing status.
  factory ApiException.fromResponse(
    Response<dynamic>? response, {
    String? endpoint,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    if (response == null) {
      return UnknownApiException(
        genericMessage,
        endpoint: endpoint,
        cause: cause,
        stackTrace: stackTrace,
      );
    }

    final status = response.statusCode ?? 0;
    final body = response.data;
    final serverMessage = messageFromBody(body);
    final serverCode = codeFromBody(body);

    String pick(String fallback) =>
        (serverMessage != null && serverMessage.trim().isNotEmpty)
            ? serverMessage.trim()
            : fallback;

    switch (status) {
      case 400:
      case 422:
        return BadRequestException(
          pick('The request could not be processed. Please check your input.'),
          statusCode: status,
          endpoint: endpoint,
          code: serverCode,
          body: body,
          cause: cause,
          stackTrace: stackTrace,
        );
      case 401:
        return UnauthorisedException(
          pick('Your session has expired. Please sign in again.'),
          statusCode: status,
          endpoint: endpoint,
          code: serverCode,
          body: body,
          cause: cause,
          stackTrace: stackTrace,
        );
      case 403:
        return ForbiddenException(
          pick('You do not have permission to perform this action.'),
          statusCode: status,
          endpoint: endpoint,
          code: serverCode,
          body: body,
          cause: cause,
          stackTrace: stackTrace,
        );
      case 404:
        // The old code did `return error["message"]` here with no guard at
        // all. On a 404 whose body is an HTML page, a bare array, or simply
        // has no `message` key, that threw a type error *inside the error
        // handler* — or returned null into a non-nullable String, which the
        // caller then null-asserted. Both crashed while already on the
        // failure path.
        return NotFoundException(
          pick('The requested resource was not found.'),
          statusCode: status,
          endpoint: endpoint,
          code: serverCode,
          body: body,
          cause: cause,
          stackTrace: stackTrace,
        );
      case 409:
        return ConflictException(
          pick('This action conflicts with the current state.'),
          statusCode: status,
          endpoint: endpoint,
          code: serverCode,
          body: body,
          cause: cause,
          stackTrace: stackTrace,
        );
      case 429:
        return TooManyRequestsException(
          pick('Too many requests. Please wait a moment and try again.'),
          statusCode: status,
          endpoint: endpoint,
          code: serverCode,
          body: body,
          cause: cause,
          stackTrace: stackTrace,
        );
    }

    if (status >= 500) {
      // 502/503/504 bodies are gateway HTML, never the API's JSON envelope.
      // Showing that markup to a user is worse than a generic line, so the
      // server's text is only used when the body actually parsed as a map.
      return InternalServerErrorException(
        (body is Map && serverMessage != null)
            ? serverMessage.trim()
            : (status == 502 || status == 503 || status == 504
                ? 'The server is temporarily unavailable. Please try again.'
                : 'Internal server error. Please try again.'),
        statusCode: status,
        endpoint: endpoint,
        code: serverCode,
        body: body,
        cause: cause,
        stackTrace: stackTrace,
      );
    }

    if (status >= 400) {
      return BadRequestException(
        pick(genericMessage),
        statusCode: status,
        endpoint: endpoint,
        code: serverCode,
        body: body,
        cause: cause,
        stackTrace: stackTrace,
      );
    }

    return UnknownApiException(
      pick(genericMessage),
      statusCode: status,
      endpoint: endpoint,
      code: serverCode,
      body: body,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Pulls a display message out of a body of unknown shape.
  ///
  /// Handles every shape this backend has been observed to return: a JSON
  /// object, a bare array (`POST medical-service/inventory`), a JSON string
  /// that was never decoded because the content-type was wrong, an HTML error
  /// page, raw bytes, and null. Returns null rather than throwing when there
  /// is nothing usable — this runs on the failure path, where a second throw
  /// is exactly what turns a handled error into a crash.
  static String? messageFromBody(dynamic body) {
    try {
      if (body == null) return null;

      if (body is Map) {
        for (final key in const ['message', 'msg', 'error_message', 'detail']) {
          final value = body[key];
          if (value is String && value.trim().isNotEmpty) return value;
          // Some endpoints answer `{"message": {"text": "..."}}`.
          if (value is Map) {
            final nested = messageFromBody(value);
            if (nested != null) return nested;
          }
          // ...and validation errors answer `{"message": ["too short"]}`.
          if (value is List && value.isNotEmpty) {
            final parts = value
                .map((e) => e is Map ? messageFromBody(e) : e?.toString())
                .whereType<String>()
                .where((e) => e.trim().isNotEmpty)
                .toList();
            if (parts.isNotEmpty) return parts.join('\n');
          }
        }
        final error = body['error'];
        if (error is String && error.trim().isNotEmpty) return error;
        if (error is Map) {
          final nested = messageFromBody(error);
          if (nested != null) return nested;
        }
        final errors = body['errors'];
        if (errors != null) {
          final nested = messageFromBody(errors);
          if (nested != null) return nested;
        }
        return null;
      }

      if (body is List) {
        for (final entry in body) {
          final nested = messageFromBody(entry);
          if (nested != null) return nested;
        }
        return null;
      }

      if (body is String) {
        final trimmed = body.trim();
        if (trimmed.isEmpty) return null;
        // An undecoded JSON payload — decode defensively and re-read it.
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          final decoded = tryDecodeJson(trimmed);
          if (decoded != null) return messageFromBody(decoded);
          return null;
        }
        // An HTML/XML error page. Never show markup to a user.
        if (trimmed.startsWith('<')) return null;
        // A long opaque blob is not a message either.
        if (trimmed.length > 300) return null;
        return trimmed;
      }

      return null;
    } catch (_) {
      // Nothing readable, and the failure path must not itself fail.
      return null;
    }
  }

  /// Pulls a machine-readable error code out of a body of unknown shape.
  static String? codeFromBody(dynamic body) {
    try {
      if (body is String) {
        final decoded = tryDecodeJson(body);
        return decoded == null ? null : codeFromBody(decoded);
      }
      if (body is! Map) return null;
      final direct = body['code'] ?? body['errorCode'] ?? body['error_code'];
      if (direct != null) return direct.toString();
      final error = body['error'];
      if (error is Map) {
        final nested = error['code'] ?? error['errorCode'];
        if (nested != null) return nested.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// `jsonDecode` that returns null instead of throwing.
  ///
  /// The most common uncaught crash in this layer was decoding a body that was
  /// not JSON — a Cloudflare/nginx 502 page, an empty 204 body, or a truncated
  /// response from a dropped connection.
  static dynamic tryDecodeJson(String source) {
    try {
      final trimmed = source.trim();
      if (trimmed.isEmpty) return null;
      if (!(trimmed.startsWith('{') ||
          trimmed.startsWith('[') ||
          trimmed.startsWith('"'))) {
        return null;
      }
      return jsonDecode(trimmed);
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static const String noConnectionMessage =
      'No internet connection. Please check your network and try again.';
  static const String timeoutMessage =
      'The server took too long to respond. Please try again.';
  static const String formatMessage =
      'We received an unexpected response from the server. Please try again.';
  static const String certificateMessage =
      'Could not establish a secure connection to the server.';
  static const String genericMessage =
      'Something went wrong. Please try again.';
}

/// No route to the server: airplane mode, DNS failure, refused connection,
/// captive portal, or a [SocketException] from any layer.
class FetchDataException extends ApiException {
  const FetchDataException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.noConnection;
}

/// Connect, send, receive or transform timeout.
///
/// Named `ApiTimeoutException` rather than `TimeoutException` so it does not
/// collide with `dart:async`'s, which this layer also catches and converts.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.timeout;
}

/// HTTP 400 / 422 and unclassified 4xx.
class BadRequestException extends ApiException {
  const BadRequestException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.badRequest;
}

/// HTTP 401 — the session is dead and must be torn down.
class UnauthorisedException extends ApiException {
  const UnauthorisedException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.unauthorised;
}

/// HTTP 403 — authenticated, but not allowed.
///
/// Kept distinct from 401 because it must NOT log the user out: this API
/// answers 403 for "you do not own this business/order", and treating that as
/// a dead session kicks a perfectly logged-in user back to the login screen.
class ForbiddenException extends ApiException {
  const ForbiddenException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.forbidden;
}

/// HTTP 404.
class NotFoundException extends ApiException {
  const NotFoundException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.notFound;
}

/// HTTP 409.
class ConflictException extends ApiException {
  const ConflictException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.conflict;
}

/// HTTP 429.
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.tooManyRequests;
}

/// HTTP 500 and above, including 502/503/504 gateway pages.
class InternalServerErrorException extends ApiException {
  const InternalServerErrorException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.serverError;
}

/// The body could not be decoded or did not have the expected shape.
///
/// Covers HTML gateway pages served as `application/json`, truncated payloads,
/// and `TypeError`s thrown out of model `fromJson` constructors.
class ResponseFormatException extends ApiException {
  const ResponseFormatException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.format;
}

/// The request was cancelled deliberately. Screens should stay silent for
/// these — a cancelled request is not a failure the user caused or needs to be
/// told about.
class RequestCancelledException extends ApiException {
  const RequestCancelledException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.cancelled;
}

/// TLS handshake failure.
class BadCertificateException extends ApiException {
  const BadCertificateException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.badCertificate;
}

/// Fallback when nothing else matched.
class UnknownApiException extends ApiException {
  const UnknownApiException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.code,
    super.body,
    super.cause,
    super.stackTrace,
  });

  @override
  ApiErrorKind get kind => ApiErrorKind.unknown;
}
