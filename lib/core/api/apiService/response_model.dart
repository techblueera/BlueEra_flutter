import 'package:dio/dio.dart';

class ResponseModel {
  int? statusCode;
  Response? response;

  ResponseModel({this.statusCode, this.response});

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

  get message => _key('message');

  bool get isSuccess => (response?.statusCode ?? 0) >= 200 && (response?.statusCode ?? 0) <= 299;

  getExtraData(String paramName) => _key(paramName);

  dynamic _key(String name) {
    final body = response?.data;
    if (body is Map) return body[name];
    return null;
  }
}
