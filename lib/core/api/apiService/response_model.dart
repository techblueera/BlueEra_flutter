import 'package:BlueEra/core/api/apiService/api_exceptions.dart';
import 'package:BlueEra/core/api/apiService/api_result.dart';
import 'package:dio/dio.dart';

/// What every `ApiBaseHelper` method returns, success or failure.
///
/// The shape is unchanged — `statusCode`, `response`, `data`, `message`,
/// `isSuccess` all behave exactly as before for successful and for HTTP-error
/// responses — with one addition: [exception].
///
/// Transport failures (no internet, timeout, DNS, TLS) used to be reported by
/// **throwing a raw String** out of `ApiBaseHelper.handleError`. Now they come
/// back here like any other failure, with [isSuccess] false, [message] set to
/// a display-ready line and [exception] carrying the classification. Call
/// sites that already branch on `isSuccess` handle them correctly with no
/// change; call sites that want the detail read [exception].
class ResponseModel {
  int? statusCode;
  Response? response;

  /// Set when the call failed. Null on success.
  ///
  /// Read this rather than the status code when the distinction matters: a
  /// request that timed out may or may not have been executed by the server,
  /// which is why [ApiException.isTransport] exists and why non-idempotent
  /// actions must not report a flat "failed" for it.
  final ApiException? exception;

  ResponseModel({this.statusCode, this.response, this.exception});

  /// Body keys are read defensively because not every endpoint answers with a
  /// JSON **object**.
  ///
  /// `POST medical-service/inventory` returns a bare array, and the old
  /// `response?.data['data']` form threw `type 'String' is not a subtype of
  /// type 'int'` on it — a List only accepts integer indices. That throw
  /// landed in a caller's bare `catch`, which silently skipped the rest of the
  /// success path (cart clear + list refresh) with nothing in the log. Any
  /// array-returning endpoint hit the same trap, so the guard lives here
  /// rather than at each call site.
  ///
  /// A non-object body simply yields null now; object bodies behave exactly as
  /// before.
  get data => _key('data');

  /// The server's message when there is one, otherwise the failure message.
  ///
  /// The fallback matters: on a transport failure there is no body at all, and
  /// the extremely common `commonSnackBar(message: response.message ?? ...)`
  /// pattern would otherwise show the generic string for every network problem
  /// instead of "No internet connection".
  get message => _key('message') ?? exception?.message;

  bool get isSuccess =>
      exception == null &&
      (response?.statusCode ?? 0) >= 200 &&
      (response?.statusCode ?? 0) <= 299;

  /// True when the request never reached the server, so whether it took effect
  /// is unknown. Non-idempotent calls should offer Retry rather than declare
  /// failure.
  bool get isTransportFailure => exception?.isTransport ?? false;

  /// True when a retry is worth offering.
  bool get isRetryable => exception?.isRetryable ?? false;

  getExtraData(String paramName) => _key(paramName);

  dynamic _key(String name) {
    final body = response?.data;
    if (body is Map) return body[name];
    return null;
  }

  /// Bridges this model into the typed [ApiResult] world for new code.
  ///
  /// ```dart
  /// final result = (await repo.fetchOrders()).toResult(OrdersModel.fromJson);
  /// ```
  ///
  /// [parse] runs inside the guard, so a `fromJson` that throws a `TypeError`
  /// on an unexpected payload becomes an [ApiFailure] instead of an unhandled
  /// crash.
  ApiResult<T> toResult<T>(T Function(dynamic body) parse) {
    final failure = exception;
    if (failure != null) return ApiFailure<T>(failure);
    if (!isSuccess) {
      return ApiFailure<T>(ApiException.fromResponse(response));
    }
    return ApiResult.guardSync(
      () => parse(response?.data),
      endpoint: response == null
          ? null
          : '${response!.requestOptions.method} ${response!.requestOptions.uri}',
    );
  }
}
