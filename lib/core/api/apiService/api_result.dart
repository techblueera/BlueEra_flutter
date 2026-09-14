import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_exceptions.dart';

/// A call that either produced a value or produced a typed [ApiException],
/// never both and never an escaping throw.
///
/// This is the `Either<Failure, T>` of this codebase, spelled with Dart 3
/// sealed classes so the compiler enforces exhaustiveness instead of a
/// third-party functional package. Because it is `sealed`, a `switch` over an
/// [ApiResult] that forgets the failure branch is a compile error — which is
/// the point: the old layer let the failure branch be forgotten 1,200 times
/// over, and each omission was a potential unhandled crash.
///
/// ```dart
/// final result = await repo.fetchProfile();
/// switch (result) {
///   case ApiSuccess(:final data):
///     profile.value = data;
///   case ApiFailure(:final error):
///     commonSnackBar(message: error.message);
/// }
/// ```
sealed class ApiResult<T> {
  const ApiResult();

  /// Wraps a body of work so nothing it throws can escape.
  ///
  /// Use it at the repository boundary around parsing as well as the call:
  /// a `fromJson` that throws a [TypeError] on an unexpected payload is just
  /// as fatal as a socket error, and this catches both.
  static Future<ApiResult<T>> guard<T>(
    Future<T> Function() body, {
    String? endpoint,
  }) async {
    try {
      return ApiSuccess<T>(await body());
    } catch (error, stackTrace) {
      return ApiFailure<T>(
        ApiException.from(error, stackTrace: stackTrace, endpoint: endpoint),
      );
    }
  }

  /// Synchronous [guard].
  static ApiResult<T> guardSync<T>(
    T Function() body, {
    String? endpoint,
  }) {
    try {
      return ApiSuccess<T>(body());
    } catch (error, stackTrace) {
      return ApiFailure<T>(
        ApiException.from(error, stackTrace: stackTrace, endpoint: endpoint),
      );
    }
  }

  bool get isSuccess => this is ApiSuccess<T>;

  bool get isFailure => this is ApiFailure<T>;

  /// The value, or null on failure. Prefer a `switch` — this exists for the
  /// call sites where a null is genuinely as good as an error.
  T? get dataOrNull => switch (this) {
        ApiSuccess<T>(:final data) => data,
        ApiFailure<T>() => null,
      };

  /// The error, or null on success.
  ApiException? get errorOrNull => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(:final error) => error,
      };

  /// Collapses both branches into one value.
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(ApiException error) onFailure,
  ) =>
      switch (this) {
        ApiSuccess<T>(:final data) => onSuccess(data),
        ApiFailure<T>(:final error) => onFailure(error),
      };

  /// Runs whichever side effect applies. Both branches are required, so a
  /// silent failure has to be written down deliberately rather than happening
  /// by omission.
  void when({
    required void Function(T data) success,
    required void Function(ApiException error) failure,
  }) =>
      fold<void>(success, failure);

  /// Transforms the success value, converting a throwing [transform] into an
  /// [ApiFailure] rather than letting it escape. This is where `fromJson`
  /// belongs.
  ApiResult<R> map<R>(R Function(T data) transform) => switch (this) {
        ApiSuccess<T>(:final data) => ApiResult.guardSync(() => transform(data)),
        ApiFailure<T>(:final error) => ApiFailure<R>(error),
      };

  /// The value, or [fallback] on failure.
  T getOrElse(T Function(ApiException error) fallback) =>
      fold<T>((data) => data, fallback);
}

/// The call succeeded and produced [data].
final class ApiSuccess<T> extends ApiResult<T> {
  final T data;

  const ApiSuccess(this.data);

  @override
  String toString() => 'ApiSuccess<$T>($data)';
}

/// The call failed with a classified [error].
final class ApiFailure<T> extends ApiResult<T> {
  final ApiException error;

  const ApiFailure(this.error);

  /// Convenience for UI: the message is always safe to display.
  String get message => error.message;

  @override
  String toString() => 'ApiFailure<$T>(${error.debugDescription})';
}
