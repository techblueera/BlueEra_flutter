import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_exceptions.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_result.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/logger_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getxObj;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:BlueEra/permissionCentralize/permission_queue.dart';

class AuthManager {
  static bool isLoggingOut = false;

  static Future<void> handleLogout(Response<dynamic>? response) async {
    if (isLoggingOut) return;
    isLoggingOut = true;

    try {
      // Clear the in-memory token first so any request already queued in
      // the interceptor stops re-using the dead credential and producing
      // more 401s.
      authTokenGlobal = '';

      try {
        deleteIfRegistered<ChatViewController>();
      } catch (_) {}
      try {
        deleteIfRegistered<FeedController>();
      } catch (_) {}
      try {
        deleteIfRegistered<LanguageControllerNew>();
      } catch (_) {}
      lastHomeFetchTime = null;

      try {
        LiveLocationService().stop();
      } catch (_) {}
      try {
        await SharedPreferenceUtils.clearPreference();
      } catch (_) {}
      try {
        await LogoutHelper.clearAllLocalData();
      } catch (_) {}
      try {
        await LocalizationService().init();
      } catch (_) {}
      // Guarantee FCM rotation regardless of whether clearPreference's
      // internal try/on-Exception swallowed the refresh call. Idempotent
      // on iOS; on Android it forces a delete + re-issue.
      try {
        await AppNotificationHandler.refreshFcmToken();
      } catch (_) {}
    } catch (_) {
      // Swallow — navigation in finally must run no matter what.
    } finally {
      // Always navigate to login, even if a cleanup step threw. Reset the
      // re-entrancy flag so a future session that hits 401 can log out again.
      try {
        getxObj.Get.offAllNamed(RouteHelper.getMobileNumberLoginRoute());
      } catch (_) {}
      isLoggingOut = false;
    }
  }
}

/// The app's HTTP entry point.
///
/// ## Failure contract
///
/// **No method here throws for a network or HTTP failure.** Every method
/// returns a [ResponseModel]; on failure `isSuccess` is false, `message`
/// carries a display-ready line and `exception` carries the classified
/// [ApiException]. Pass `throwOnError: true` at a call site that would rather
/// catch than branch — it then throws a typed [ApiException], never a String.
///
/// This replaces the previous contract, where `handleError` ended with
/// `throw DioExceptions.fromDioError(e).message!` — a bare [String] throw for
/// every timeout, DNS failure and airplane-mode request. A String is not an
/// [Exception]: `on Exception catch` did not catch it, and the ~1,200 call
/// sites without a `try` turned every flaky-network moment into
/// `Unhandled Exception: Connection timeout with API server`.
class ApiBaseHelper {
  /// Number of requests currently in flight. Kept public because other code
  /// reads it; it is now clamped at zero (see [_releaseProgress]) so a stray
  /// decrement can no longer pin it negative and wedge the progress dialog
  /// open for the rest of the session.
  static int numberOfReq = 0;

  /// Default for [showProgress] when a call site does not pass one.
  ///
  /// It used to be *the* switch: every method assigned this static and the
  /// interceptor read it for whatever request happened to arrive next. Two
  /// concurrent calls with different `showProgress` values therefore fought
  /// over one field, and the loser either raised a blocking dialog over a
  /// screen that had its own spinner or suppressed the dialog entirely. The
  /// decision now travels with the request in `options.extra`, so it can no
  /// longer be read off the wrong request.
  static bool showProgressDialog = true;

  // ───────────────────── the gap these three close ─────────────────────
  //
  // dio 5.x makes exactly three `.timeout()` calls in its IO adapter:
  // `connectTimeout` on `openUrl`, `sendTimeout` on the body write, and
  // `receiveTimeout` on `request.close()` — which is only *waiting for the
  // response headers*. The body stream is then handed over raw
  // (`ResponseBody(responseStream.cast(), …)`): no Timer, no Stopwatch, no
  // stream timeout. A server that returns headers and then goes quiet is
  // guarded by nothing at any layer and hangs until the OS drops the socket.
  //
  // Worse, dio's own `options.dart` documents `receiveTimeout` as "the duration
  // during data transfer of each byte event" — a per-chunk guarantee the IO
  // adapter never implements. That mismatch is why this reaches production:
  // anyone reading the docs believes they are already covered.
  //
  // Verified against dio 5.9.0, and reproduced in
  // `test/api_base_helper_integration_test.dart`.

  /// Wall-clock ceiling for a request a user is sitting in front of.
  ///
  /// Shorter than [backgroundDeadline] on purpose: someone watching a spinner
  /// for 90 seconds has already decided the app is broken, so a ceiling that
  /// only protects the process is no use to them. 45 s still clears the
  /// worst legitimate case by a wide margin (20 s connect + a JSON body), and
  /// anything slower is a failure worth reporting as one.
  static Duration interactiveDeadline = const Duration(seconds: 45);

  /// Wall-clock ceiling for a request nobody is watching — a WorkManager post,
  /// an upload-init handshake. Nothing on screen depends on it, so the only job
  /// here is to stop a wedged socket living forever.
  static Duration backgroundDeadline = const Duration(seconds: 90);

  /// Retained for source compatibility; prefer the two above.
  @Deprecated('Use interactiveDeadline or backgroundDeadline')
  static Duration get requestDeadline => backgroundDeadline;

  @Deprecated('Use interactiveDeadline or backgroundDeadline')
  static set requestDeadline(Duration value) => backgroundDeadline = value;

  /// How long a TRANSFER may make no progress before it is treated as wedged.
  ///
  /// File transfers cannot take a wall-clock deadline — a legitimate upload on
  /// a slow connection would be killed mid-flight — but opting them out
  /// entirely restores the unguarded behaviour for exactly the requests holding
  /// the most resources: an open socket, a file handle, a progress dialog and
  /// (for uploads) a buffer. So instead of capping duration, transfers are
  /// watched for *silence*: [_StallWatchdog] is reset by every progress
  /// callback and fires only when nothing has moved for this long.
  ///
  /// This is deliberately the same value as the request's own
  /// `receiveTimeout` — it implements the per-byte-event contract dio's docs
  /// promise and its adapter does not, rather than inventing a second,
  /// stricter budget nobody configured.
  ///
  /// ## What it actually protects — measured, not assumed
  ///
  /// `onSendProgress` is a genuine liveness signal: it ticks as the body goes
  /// out, so a large upload that stalls mid-flight is caught while a slow one
  /// is not. That is the case this exists for.
  ///
  /// `onReceiveProgress` is **not**. Probed against dart:io's HttpClient with a
  /// server dribbling a response over 4s: every receive callback arrived in one
  /// burst at ~4020 ms, at the END, in all three configurations tried (bare
  /// Dio, with `receiveTimeout`, with an interceptor). It reports how much
  /// arrived, not when. It is still wired below because it costs nothing and is
  /// correct wherever a stack does deliver it incrementally — but nothing here
  /// may depend on it.
  ///
  /// So in practice this bounds:
  ///   • an upload that stops moving mid-body — true stall detection;
  ///   • a body fully sent and then server silence — the wedged-upload case;
  ///   • a download, as an N-second ceiling on the whole response rather than a
  ///     stall detector. Weaker than intended, still far better than the
  ///     unbounded wait it replaced.
  static Duration transferStallTimeout = const Duration(seconds: 60);

  /// Key under which a request carries its own progress-dialog decision.
  static const String _kShowProgress = 'be.showProgress';

  /// Identity hashes of in-flight requests that asked for the dialog. The
  /// dialog is up while this is non-empty and comes down when it drains.
  static final Set<int> _progressRequests = <int>{};

  static BaseOptions opts = BaseOptions(
      baseUrl: baseUrl ?? "",
      responseType: ResponseType.json,

      // ── Timeouts ──
      //
      // Only `receiveTimeout` was set here. That is the least important of the
      // three, and its absence was not the problem — the missing
      // `connectTimeout` was.
      //
      // `receiveTimeout` only starts counting once a connection exists and
      // bytes are flowing. If the server is unreachable, the port is
      // blackholed, or the user is on a captive-portal wifi that accepts the
      // TCP handshake and then goes silent, Dio never reaches the receive
      // phase — so it falls back to the OS socket timeout, which on Android
      // can be minutes and on iOS is ~60–75 s. The user sees the global
      // progress dialog spin with no way out, and `numberOfReq` stays pinned
      // above zero so the dialog does not dismiss even when they navigate away.
      //
      // 20 s to establish a connection is generous on a 3G-class network and
      // still bounded. Anything slower is not going to succeed.
      connectTimeout: const Duration(seconds: 20),

      // Guards the REQUEST body going out. Matters for the JSON posts here;
      // large uploads use their own Dio with longer values (see
      // uploadVideoToS3 / workManagerPostHTTP), so this does not cap them.
      sendTimeout: const Duration(seconds: 60),

      // Time allowed between response bytes once connected.
      receiveTimeout: const Duration(seconds: 60),

      // Take EVERY status code as a normal response instead of letting Dio
      // throw for non-2xx.
      //
      // This is what makes the layer's error handling uniform. Previously a
      // 404 arrived as a thrown `DioException`, a 200 arrived as a return
      // value, and the two were reconciled by catching the exception and
      // rebuilding a `ResponseModel` from it — which is where the null
      // assertions (`e.response!.statusCode!`) and the unguarded
      // `error["message"]` lookup lived. Now every response that came back at
      // all, including 4xx and 5xx, flows down one path and gets classified in
      // one place; only genuine transport failures raise a `DioException`.
      validateStatus: (_) => true,
      headers: {
        // NOTE: the Authorization header is set per-request in the interceptor,
        // not here. This map is built once at static-initialisation time —
        // before login — so a token baked in here is always the empty one, and
        // stays empty for the life of the isolate.
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Device-Type': 'mobile',
        // Or 'desktop'
        'X-Device-OS': '${Platform.operatingSystem} $deviceOsVersionGlobal',
        // e.g., 'android 14'
        'X-Browser-Name': AppConstants.appName,
        // Or your app name
      });

  static Dio createDio() {
    return Dio(opts);
  }

  ///CREATE DIO OBJECT
  static final dio = createDio();
  static final baseAPI = addInterceptors(dio);

  ///DIO INTERCEPTOR...
  static Dio addInterceptors(Dio dio) {
    ///For Show Hide Progress Dialog
    return dio
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, handler) async {
            _acquireProgress(options);

            final isFormData = options.data is FormData;

            if (kDebugMode) {
              // ====== 🌟 Beautified Request Log ======
              // Wrapped: `JsonEncoder.convert` throws
              // `JsonUnsupportedObjectError` on any value it cannot encode (a
              // DateTime, a File, a model object someone passed straight
              // through). Thrown from inside `onRequest`, that aborts the
              // request itself — a debug-only logging line was able to fail
              // the call it was describing.
              try {
                if (isFormData) {
                  final formData = options.data as FormData;
                  log("🔹 FormData Fields:");
                  for (final field in formData.fields) {
                    log("    ${field.key}: ${field.value}");
                  }
                  log("🔹 FormData Files:");
                  for (final file in formData.files) {
                    log("    ${file.key}: ${file.value.filename}");
                  }
                } else if (options.data != null) {
                  log("🔹 Body: ${const JsonEncoder.withIndent('  ').convert(options.data)}");
                } else {
                  log("🔹 Body: null");
                }
              } catch (_) {
                log("🔹 Body: <not printable>");
              }
            }

            final token = authTokenGlobal;
            if (token != null && token.isNotEmpty) {
              options.headers[ApiKeys.authorization] = "Bearer $token";
            } else {
              // Logout cleared the token. Strip the header rather than sending
              // a bare `Bearer `, which some gateways answer with a 400 instead
              // of the 401 the app knows how to handle.
              options.headers.remove(ApiKeys.authorization);
            }
            // Multipart requests set their own boundary-bearing content type;
            // overwriting it with `application/json` makes the server read the
            // body as JSON and reject every field.
            if (options.data is! FormData) {
              options.headers[ApiKeys.contentType] = "application/json";
            }
            // Logged AFTER the header is set, so what prints is what actually
            // goes out rather than what the global happened to hold.
            logAuthToken(options.method, options.uri,
                options.headers[ApiKeys.authorization]?.toString());
            return requestInterceptor(options, handler);
          },
          onResponse: (response, handler) {
            _releaseProgress(response.requestOptions);

            // Normalise EVERY map in the tree to `Map<String, dynamic>`.
            //
            // The old code converted the top level only. Nested objects stayed
            // `_Map<dynamic, dynamic>`, so the very common
            // `Map<String, dynamic>.from(json['data'])` /
            // `SomeModel.fromJson(json['user'])` pattern threw
            // `type '_Map<dynamic, dynamic>' is not a subtype of type
            // 'Map<String, dynamic>'` one level down. Doing it once here is
            // cheaper than the defensive casts it removes from every model.
            response.data = _normalizeBody(response.data);

            // Full resolved URL (baseUrl + path + query) this response came
            // from, so the success/warning log can be matched to its endpoint.
            final responseUrl =
                '${response.requestOptions.method} ${response.requestOptions.uri}';

            // `statusCode` was null-asserted here. An adapter that completes a
            // response without a status (mocked transports, some proxy
            // failures) made that assertion throw inside the interceptor,
            // converting a delivered response into a DioException.
            final status = response.statusCode ?? 0;
            if (status >= 100 && status <= 199) {
              if (kDebugMode) {
                Logger.printLog(
                    tag: 'WARNING CODE $status : ',
                    printLog: '🌐 $responseUrl\n${_previewForLog(response.data)}',
                    logIcon: Logger.warning);
              }
            } else if (status >= 400) {
              logs('ERROR CODE $status : 🌐 $responseUrl\n'
                  '${_previewForLog(response.data)}');
            } else {
              log('SUCCESS CODE $status : 🌐 $responseUrl\n'
                  '${_previewForLog(response.data)}');
            }

            // 401 now arrives here rather than in `onError`, because
            // `validateStatus` accepts every code. 403 is deliberately NOT
            // treated as a logout: this API answers 403 for "not your
            // business/order", and logging out on it ejects a perfectly valid
            // session.
            if (status == 401) {
              logs("ERROR CODE 401 ==== $responseUrl");
              AuthManager.handleLogout(response);
            }

            return handler.next(response);
          },
          onError: (DioException err, handler) async {
            // With `validateStatus` accepting everything, reaching here means a
            // genuine transport failure: no socket, no DNS, no TLS, or a
            // timeout. There is no response to inspect.
            logs("err====1 ${err.requestOptions.uri} ${err.type}");
            _releaseProgress(err.requestOptions);

            if (err.response?.statusCode == 401) {
              logs("ERROR CODE 401 ====");
              await AuthManager.handleLogout(err.response);
            }
            return handler.next(err);
          },
        ),
      );
  }

  static dynamic requestInterceptor(
      RequestOptions options, RequestInterceptorHandler handler) async {
    return handler.next(options);
  }

  // ───────────────────────── progress dialog ──────────────────────────

  /// Registers a request and raises the dialog if this request asked for it.
  static void _acquireProgress(RequestOptions options) {
    numberOfReq++;
    final wants = options.extra[_kShowProgress] == true;
    if (!wants) return;
    _progressRequests.add(identityHashCode(options));
    ProgressDialog.showProgressDialog(true, apiPath: options.path);
  }

  /// Deregisters a request and lowers the dialog once nothing is waiting.
  ///
  /// Both the decrement and the set removal are idempotent-safe: a request can
  /// only be released once because its identity hash is removed on the first
  /// call, and `numberOfReq` is clamped so it can never go negative. The old
  /// `numberOfReq == 0` test meant a single stray decrement left the counter
  /// at -1, after which the equality never held again and the dialog stayed up
  /// permanently.
  static void _releaseProgress(RequestOptions options) {
    if (numberOfReq > 0) numberOfReq--;
    final removed = _progressRequests.remove(identityHashCode(options));
    if (!removed) return;
    if (_progressRequests.isEmpty) {
      log('close dialog');
      ProgressDialog.showProgressDialog(false);
    }
  }

  /// Per-request [Options], carrying the progress decision and any extra
  /// headers, so nothing about this call is read off a shared static.
  static Options _options({
    bool showProgress = true,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) {
    return Options(
      headers: headers,
      responseType: responseType,
      extra: {_kShowProgress: showProgress},
    );
  }

  // ───────────────────────── body handling ──────────────────────────

  /// Recursively converts every `Map` in a decoded body to
  /// `Map<String, dynamic>` and every `List` to `List<dynamic>`, and rescues
  /// a JSON payload that arrived as an undecoded [String].
  ///
  /// The String case is not theoretical: Dio only runs its JSON transformer
  /// when the response's content-type says JSON. Services behind a proxy that
  /// rewrites the header — and this app's S3 and file paths, which set
  /// `ResponseType.plain` — hand back a String that every caller then treats
  /// as a Map. Decoding it here, and only when it actually parses, keeps the
  /// rest of the app on one body shape.
  static dynamic _normalizeBody(dynamic body, [int depth = 0]) {
    // Cheap guard against a pathological or self-referential structure.
    if (depth > 32) return body;
    try {
      if (body is Map) {
        return body.map(
          (key, value) =>
              MapEntry(key.toString(), _normalizeBody(value, depth + 1)),
        );
      }
      if (body is List) {
        return body.map((e) => _normalizeBody(e, depth + 1)).toList();
      }
      if (body is String) {
        final decoded = ApiException.tryDecodeJson(body);
        // Only take the decoded form when it is structured. A plain quoted
        // string decodes to a String and is better left exactly as the server
        // sent it.
        if (decoded is Map || decoded is List) {
          return _normalizeBody(decoded, depth + 1);
        }
        return body;
      }
      return body;
    } catch (_) {
      // Normalisation is an optimisation, never a failure point.
      return body;
    }
  }

  /// A bounded, always-safe rendering of a body for the log.
  ///
  /// The previous log did `jsonEncode(response.data)` unconditionally. Two
  /// problems: on a `ResponseType.bytes` download it serialised every byte as
  /// a decimal integer — megabytes of text formatted on the UI isolate, which
  /// is an ANR, not a log line — and on anything non-encodable it threw
  /// `JsonUnsupportedObjectError` from inside the interceptor and failed the
  /// request.
  static String _previewForLog(dynamic body, {int limit = 4000}) {
    try {
      if (body == null) return 'null';
      if (body is List<int>) return '<${body.length} bytes>';
      if (body is ResponseBody) return '<stream>';
      final text = body is String ? body : jsonEncode(body);
      return text.length <= limit
          ? text
          : '${text.substring(0, limit)}… (${text.length} chars)';
    } catch (_) {
      return '<unprintable ${body.runtimeType}>';
    }
  }

  /// Logs the bearer credential a request is going out with.
  ///
  /// **Debug builds only.** The body and response logs around it are noisy but
  /// harmless; a bearer token is not a payload, it is a working session key, and
  /// writing one into logcat on a release build hands it to anything that can
  /// read logs on a rooted device. `kDebugMode` is compile-time, so this call
  /// and the string it builds are tree-shaken out of release entirely.
  ///
  /// Prints the token in FULL, deliberately: the whole point is to paste it into
  /// Postman or curl, which a masked one cannot do. It also prints `<none>`
  /// rather than staying silent when there is no token — "the request went out
  /// unauthenticated" is the answer you are usually looking for.
  static void logAuthToken(String method, dynamic uri, String? authHeader) {
    if (!kDebugMode) return;
    final token = (authHeader ?? '').replaceFirst('Bearer ', '').trim();
    log('🔑 $method $uri\n   token: ${token.isEmpty ? '<none>' : token}');
  }

  // ───────────────────────── requests ──────────────────────────

  ///POST...
  Future<ResponseModel> postHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _run(
      url,
      showProgress: showProgress,
      throwOnError: throwOnError,
      deadline: isMultipart ? null : interactiveDeadline,
      stallTimeout: isMultipart ? transferStallTimeout : null,
      callerToken: cancelToken,
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) async {
        if (isMultipart) {
          return baseAPI.post(
            url,
            data: _buildFormData(params),
            cancelToken: token,
            onSendProgress: _beating(beat, onSendProgress),
            onReceiveProgress: _beating(beat, null),
            options: _options(
              showProgress: showProgress,
              headers: {"Content-Type": "multipart/form-data"},
            ),
          );
        }
        return baseAPI.post(
          url,
          data: params,
          cancelToken: token,
          onSendProgress: _beating(beat, onSendProgress),
          onReceiveProgress: _beating(beat, null),
          options: _options(
            showProgress: showProgress,
            headers: {'Content-Type': 'application/json'},
          ),
        );
      },
    );
  }

  /// Builds the multipart body.
  ///
  /// Extracted and guarded because it runs *before* the request and used to
  /// throw straight out of `postHTTP`: `params.forEach` on a null or non-Map
  /// `params` raises `NoSuchMethodError`, which the `on DioException catch`
  /// below did not catch. Any such failure is now a [BadRequestException]
  /// reported through the normal path.
  static FormData _buildFormData(dynamic params) {
    if (params is FormData) return params;
    if (params is! Map) {
      throw BadRequestException(
        'Could not build the upload request.',
        cause: ArgumentError.value(
            params, 'params', 'multipart request needs a Map or FormData'),
      );
    }
    final formData = FormData();
    params.forEach((key, value) {
      final name = key.toString();
      if (name == ApiKeys.websites && value is List<String>) {
        for (final site in value) {
          formData.fields.add(MapEntry(ApiKeys.websites, site));
        }
      }
      // ✅ Add support for multiple files
      else if (value is List<MultipartFile>) {
        for (final file in value) {
          formData.files.add(MapEntry(name, file));
        }
      } else if (value is MultipartFile) {
        formData.files.add(MapEntry(name, value));
      } else if (value == null) {
        // `value.toString()` on a null wrote the literal text "null" into the
        // field, which the server stores as the four-character string. Omit it.
      } else {
        formData.fields.add(MapEntry(name, value.toString()));
      }
    });
    return formData;
  }

  ///POST...
  Future<ResponseModel> workManagerPostHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) {
    return _run(
      url,
      showProgress: false,
      throwOnError: throwOnError,
      stallTimeout: const Duration(minutes: 5),
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) async {
        final authToken = await SharedPreferenceUtils.getSecureValue(
            SharedPreferenceUtils.authToken);
        final dio = Dio(BaseOptions(
          responseType: ResponseType.json,
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 5),
          validateStatus: (_) => true,
          headers: {
            if ((authToken ?? '').isNotEmpty)
              ApiKeys.authorization: 'Bearer $authToken',
          },
        ));
        logAuthToken('POST', url, 'Bearer $authToken');
        logs("------URL----$url");
        final response = await dio.post(
          url,
          data: params,
          onSendProgress: _beating(beat, onSendProgress),
          onReceiveProgress: _beating(beat, null),
        );
        response.data = _normalizeBody(response.data);
        return response;
      },
    );
  }

  ///POST...
  Future<ResponseModel> postMultiImage(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isArrayReq = false,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _run(
      url,
      showProgress: showProgress,
      throwOnError: throwOnError,
      stallTimeout: transferStallTimeout,
      callerToken: cancelToken,
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) async {
        logs("------URL----$url");
        final formData = _buildFormData(params);
        logs("------URL files----${formData.files}");
        logs("------URL fields ----${formData.fields}");
        return baseAPI.post(
          url,
          data: formData,
          cancelToken: token,
          onSendProgress: _beating(beat, onSendProgress),
          onReceiveProgress: _beating(beat, null),
          options: _options(
            showProgress: showProgress,
            headers: {"Content-Type": "multipart/form-data"},
          ),
        );
      },
    );
  }

  Future<ResponseModel> postFileDownloadHTTP(
    String url, {
    required String? containerName,
    bool showProgress = true,
    required bool? isGetReq,
    Map<String, dynamic>? reqParam,
    required String? successMessage,
    required String? fileExtensions,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) async {
    final result = await _run(
      url,
      showProgress: showProgress,
      throwOnError: throwOnError,
      stallTimeout: transferStallTimeout,
      // The write-to-disk step runs between the response and the callbacks, so
      // the callbacks are invoked by hand below rather than by `_run`.
      onSuccess: null,
      onError: onError,
      send: (token, beat) async {
        // `onReceiveProgress` is what feeds the watchdog on a DOWNLOAD: the
        // request body is trivial here, so send-progress fires once and then
        // never again. Without this the watchdog would treat every download
        // longer than the stall timeout as wedged and cancel a healthy one.
        if (isGetReq ?? false) {
          return baseAPI.get(
            url,
            queryParameters: reqParam,
            cancelToken: token,
            onReceiveProgress: _beating(beat, null),
            options: _options(
              showProgress: showProgress,
              responseType: ResponseType.bytes,
            ),
          );
        }
        return baseAPI.post(
          url,
          data: {ApiKeys.template: containerName},
          cancelToken: token,
          onSendProgress: _beating(beat, onSendProgress),
          onReceiveProgress: _beating(beat, null),
          options: _options(
            showProgress: showProgress,
            responseType: ResponseType.bytes,
          ),
        );
      },
    );

    if (!result.isSuccess) {
      commonSnackBar(message: result.message ?? AppStrings.somethingWentWrong);
      onSuccess?.call(result);
      return result;
    }

    try {
      Directory? directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');

        final plugin = DeviceInfoPlugin();
        final android = await plugin.androidInfo;
        final androidVersion = android.version.sdkInt;
        final storageStatus = androidVersion < 33
            ? await PermissionQueue.request(Permission.storage)
            : PermissionStatus.granted;
        if (storageStatus == PermissionStatus.granted) {
          if (!(await directory.exists())) {
            await directory.create(
                recursive: true); // Create folder if it doesn't exist
          }
        }
        if (storageStatus == PermissionStatus.denied) {
          commonSnackBar(message: AppStrings.storagePermissionDenied);
          onSuccess?.call(result);
          return result;
        }
        if (storageStatus == PermissionStatus.permanentlyDenied) {
          openAppSettings();
          onSuccess?.call(result);
          return result;
        }
      }

      logs("fileExtensions=====$fileExtensions");
      if (directory != null) {
        // `response.businessCategory` — a property that does not exist on
        // `Response`. It only compiled because the variable was declared
        // `var`/dynamic, and it threw `NoSuchMethodError` on every single
        // download, caught by the bare `catch` below and reported to the user
        // as "Something went wrong". The downloaded bytes live in `data`.
        final bytes = result.response?.data;
        if (bytes is! List<int>) {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          onSuccess?.call(result);
          return result;
        }
        final filePath =
            '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.$fileExtensions';
        logs("filePath====== $filePath");
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        commonSnackBar(message: successMessage ?? "Download successfully");
        logs("filePath 2222====== ${file.path}");
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("---Error while downloading file: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }

    onSuccess?.call(result);
    return result;
  }

  ///GET...
  Future<ResponseModel> getHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    CancelToken? cancelToken,
  }) {
    return _run(
      url,
      showProgress: showProgress,
      throwOnError: throwOnError,
      deadline: interactiveDeadline,
      callerToken: cancelToken,
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) => baseAPI.get(
        url,
        queryParameters: params,
        cancelToken: token,
        options: _options(showProgress: showProgress),
      ),
    );
  }

  ///PUT
  Future<ResponseModel> putHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _run(
      url,
      showProgress: showProgress,
      throwOnError: throwOnError,
      deadline: isMultipart ? null : interactiveDeadline,
      stallTimeout: isMultipart ? transferStallTimeout : null,
      callerToken: cancelToken,
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) async {
        logs("------URL----$url");
        if (isMultipart) {
          final formData = _buildFormData(params);
          logs("FORM DATA ${formData.fields}");
          logs("FORM DATA ${formData.files}");
          return baseAPI.put(
            url,
            data: formData,
            cancelToken: token,
            onSendProgress: _beating(beat, onSendProgress),
            onReceiveProgress: _beating(beat, null),
            options: _options(
              showProgress: showProgress,
              headers: {"Content-Type": "multipart/form-data"},
            ),
          );
        }
        return baseAPI.put(
          url,
          data: params,
          cancelToken: token,
          onSendProgress: _beating(beat, onSendProgress),
          onReceiveProgress: _beating(beat, null),
          options: _options(
            showProgress: showProgress,
            headers: {'Content-Type': 'application/json'},
          ),
        );
      },
    );
  }

  ///PATCH
  Future<ResponseModel> patchHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _run(
      url,
      showProgress: showProgress,
      throwOnError: throwOnError,
      deadline: isMultipart ? null : interactiveDeadline,
      stallTimeout: isMultipart ? transferStallTimeout : null,
      callerToken: cancelToken,
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) async {
        logs("------URL----$url");
        if (isMultipart) {
          return baseAPI.patch(
            url,
            data: _buildFormData(params),
            cancelToken: token,
            onSendProgress: _beating(beat, onSendProgress),
            onReceiveProgress: _beating(beat, null),
            options: _options(
              showProgress: showProgress,
              headers: {"Content-Type": "multipart/form-data"},
            ),
          );
        }
        return baseAPI.patch(
          url,
          data: params,
          cancelToken: token,
          onSendProgress: _beating(beat, onSendProgress),
          onReceiveProgress: _beating(beat, null),
          options: _options(
            showProgress: showProgress,
            headers: {'Content-Type': 'application/json'},
          ),
        );
      },
    );
  }

  ///DELETE ...
  Future<ResponseModel> deleteHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    CancelToken? cancelToken,
  }) {
    return _run(
      url,
      showProgress: showProgress,
      throwOnError: throwOnError,
      deadline: interactiveDeadline,
      callerToken: cancelToken,
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) async {
        logs("------URL----$url");
        return baseAPI.delete(
          url,
          data: params,
          cancelToken: token,
          options: _options(showProgress: showProgress),
        );
      },
    );
  }

  /// Upload File To S3
  ///
  /// Returns null only when the upload could not be attempted at all; every
  /// other outcome is a [ResponseModel] whose `exception` describes it.
  Future<ResponseModel?> uploadVideoToS3(
    String url, {
    required File file,
    required String fileType,
    Function(double)? onProgress,
    bool showProgress = true,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    CancelToken? cancelToken,
  }) {
    return _run(
      url,
      showProgress: false,
      throwOnError: throwOnError,
      stallTimeout: const Duration(seconds: 120),
      callerToken: cancelToken,
      onSuccess: onSuccess,
      onError: onError,
      send: (token, beat) async {
        final fileLength = await file.length();

        final dio = Dio(
          BaseOptions(
            // Give generous timeouts for large file uploads on slow networks
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 120),
            sendTimeout: const Duration(seconds: 120), // Crucial for uploads
            validateStatus: (_) => true,
          ),
        );

        if (kDebugMode) {
          dio.interceptors.add(
            LogInterceptor(request: true, error: true, responseHeader: true),
          );
        }

        return dio.put(
          url,
          data: file.openRead(),
          cancelToken: token,
          options: Options(
            headers: {
              'Content-Type': fileType, // or your actual video MIME type
              'Content-Length': fileLength,
            },
            responseType: ResponseType.plain, // important for AWS S3
          ),
          // S3 answers a PUT with a near-empty body, so receive-progress adds
          // little here — but it costs nothing and closes the window between
          // the last byte sent and the response arriving, which is exactly
          // where a wedged upload sits.
          onReceiveProgress: _beating(beat, null),
          onSendProgress: (int sent, int total) {
            // Feed the stall watchdog FIRST, and unconditionally — a caller
            // that passed no `onProgress` still has a transfer worth watching,
            // and this is the only signal that it is alive.
            beat();
            if (onProgress != null) {
              // When streaming via file.openRead(), Dio can report total = -1
              // (unknown) or 0 on the first tick → sent/total becomes NaN or
              // Infinity and crashes LinearProgressIndicator. Fall back to the
              // known file length and clamp.
              final int effectiveTotal = total > 0 ? total : fileLength;
              final double progress =
                  effectiveTotal > 0 ? (sent / effectiveTotal) : 0.0;
              onProgress(progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0);
            }
          },
        );
      },
    );
  }

  /// Upload File To S3
  Future<ResponseModel?> uploadInitGet(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
  }) {
    return _run(
      url,
      showProgress: false,
      throwOnError: throwOnError,
      onSuccess: onSuccess,
      deadline: backgroundDeadline,
      onError: onError,
      send: (token, beat) async {
        final authToken = await SharedPreferenceUtils.getSecureValue(
            SharedPreferenceUtils.authToken);
        final dio = Dio(BaseOptions(
          responseType: ResponseType.json,
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 5),
          validateStatus: (_) => true,
          headers: {
            if ((authToken ?? '').isNotEmpty)
              ApiKeys.authorization: 'Bearer $authToken',
          },
        ));
        logAuthToken('GET', url, 'Bearer $authToken');

        final response = await dio.get(url, queryParameters: params);
        response.data = _normalizeBody(response.data);
        return response;
      },
    );
  }

  // ───────────────────────── the one error path ──────────────────────────

  /// Runs [send] and turns every possible outcome into a [ResponseModel].
  ///
  /// This is the single place the layer converts failure into a value. It
  /// catches [DioException] *and* everything else — a `FormatException` from a
  /// decoder, a `TypeError` from a cast, a `NoSuchMethodError` from building a
  /// request out of the wrong shape — because the previous `on DioException
  /// catch` caught only the first kind and let the rest escape as unhandled
  /// crashes.
  ///
  /// Exactly one of [deadline] and [stallTimeout] should be set.
  ///
  /// [deadline] is a wall-clock ceiling, for requests with a bounded legitimate
  /// duration (see [interactiveDeadline] / [backgroundDeadline]).
  ///
  /// [stallTimeout] is for transfers, whose legitimate duration is NOT bounded:
  /// it watches for silence instead of elapsed time, so a slow-but-moving
  /// upload runs as long as it needs while a wedged one still dies. [send] must
  /// then wire `beat` into its progress callbacks — a transfer that reports no
  /// progress at all is indistinguishable from a stalled one.
  Future<ResponseModel> _run(
    String url, {
    required Future<Response> Function(CancelToken token, void Function() beat)
        send,
    required bool showProgress,
    required bool throwOnError,
    Duration? deadline,
    Duration? stallTimeout,
    CancelToken? callerToken,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
  }) async {
    // One token per request, owned here. Both the deadline and the stall
    // watchdog cancel through it so the socket is actually released and the
    // interceptor's `onError` runs — which is what brings `numberOfReq` back
    // down and the progress dialog with it. A bare `Future.timeout` would free
    // the caller while leaving the request, the counter and the dialog hanging
    // behind it.
    final token = CancelToken();
    callerToken?.whenCancel.then((_) {
      if (!token.isCancelled) token.cancel(callerToken.cancelError);
    });

    _StallWatchdog? watchdog;
    if (stallTimeout != null) {
      watchdog = _StallWatchdog(stallTimeout, () {
        logs('transfer stalled for ${stallTimeout.inSeconds}s — cancelling $url');
        if (!token.isCancelled) token.cancel('transfer stalled');
      });
      // Armed before the request starts: a transfer that never produces a
      // first byte is the case this exists for.
      watchdog.beat();
    }

    try {
      final pending = send(token, watchdog == null ? _noBeat : watchdog.beat);
      final response = deadline == null
          ? await pending
          : await pending.timeout(
              deadline,
              onTimeout: () {
                if (!token.isCancelled) token.cancel('request deadline');
                throw TimeoutException(
                    'Request exceeded the ${deadline.inSeconds}s deadline',
                    deadline);
              },
            );
      return handleResponse(response, onError ?? (_) {}, onSuccess ?? (_) {});
    } catch (error, stackTrace) {
      // A stall cancels the token, so dio reports `DioExceptionType.cancel` —
      // which maps to RequestCancelledException, the one kind screens stay
      // SILENT for. A wedged upload is not a cancellation the user asked for,
      // so it is reclassified here as what it actually is.
      final exception = (watchdog?.fired ?? false)
          ? ApiTimeoutException(
              ApiException.timeoutMessage,
              endpoint: url,
              cause: error,
              stackTrace: stackTrace,
            )
          : ApiException.from(error, stackTrace: stackTrace, endpoint: url);
      return _fail(
        exception,
        requestOptions: error is DioException ? error.requestOptions : null,
        throwOnError: throwOnError,
        onError: onError,
        onSuccess: onSuccess,
      );
    } finally {
      watchdog?.cancel();
    }
  }

  /// The no-op `beat` handed to requests that are not transfers.
  static void _noBeat() {}

  /// Wraps a caller's progress callback so the stall watchdog is fed by the
  /// same events the UI is.
  ///
  /// Returns null when there is nothing to do, because Dio treats a non-null
  /// `onSendProgress` / `onReceiveProgress` as a request to compute and emit
  /// progress — handing it an always-present wrapper would turn progress
  /// reporting on for every call that never asked for it.
  static ProgressCallback? _beating(
    void Function() beat,
    ProgressCallback? inner,
  ) {
    if (identical(beat, _noBeat) && inner == null) return null;
    return (int count, int total) {
      beat();
      inner?.call(count, total);
    };
  }

  /// Builds the failure [ResponseModel] and fires the legacy callbacks.
  static ResponseModel _fail(
    ApiException exception, {
    RequestOptions? requestOptions,
    required bool throwOnError,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
  }) {
    logs('API FAILURE :: ${exception.debugDescription}');

    // A synthetic body so the many call sites that reach straight into
    // `response!.data['message']` on the failure path find a Map there instead
    // of a null, and so `res.response` is never null when the caller
    // null-asserts it. `statusCode` stays null for transport failures —
    // "the server never answered" is the honest value, and `isSuccess`
    // already reports false through `exception`.
    final synthetic = Response<dynamic>(
      requestOptions: requestOptions ??
          RequestOptions(path: exception.endpoint ?? '', baseUrl: baseUrl ?? ''),
      statusCode: exception.statusCode,
      data: <String, dynamic>{
        'success': false,
        'message': exception.message,
        if (exception.code != null) 'code': exception.code,
      },
    );

    final model = ResponseModel(
      statusCode: exception.statusCode,
      response: synthetic,
      exception: exception,
    );

    // `onError` keeps its original meaning: transport-level trouble. HTTP
    // error statuses continue to arrive through `onSuccess`, as they always
    // have, so existing callbacks behave identically.
    if (exception.isTransport ||
        exception.kind == ApiErrorKind.cancelled ||
        exception.kind == ApiErrorKind.format ||
        exception.kind == ApiErrorKind.unknown) {
      _safeCallback(() => onError?.call(DioExceptions.fromApiException(exception)));
    } else {
      _safeCallback(() => onSuccess?.call(model));
    }

    if (throwOnError) throw exception;
    return model;
  }

  /// A caller-supplied callback must not be able to take the app down from
  /// inside the networking layer — that is how a failed request becomes a
  /// crash report about `ApiBaseHelper`.
  static void _safeCallback(void Function() body) {
    try {
      body();
    } catch (e, s) {
      logs('API callback threw: $e\n$s');
    }
  }

  /// Classifies a delivered response and fires the legacy callbacks.
  ///
  /// Because `validateStatus` accepts everything, this now sees 4xx and 5xx
  /// too. They are reported exactly as before — through `onSuccess`, with
  /// `isSuccess` false — but they additionally carry a classified
  /// [ResponseModel.exception].
  ResponseModel handleResponse(
    Response response,
    Function(DioExceptions dioExceptions) onError,
    Function(ResponseModel res) onSuccess,
  ) {
    final status = response.statusCode ?? 0;

    if (status >= 200 && status <= 299) {
      final model =
          ResponseModel(statusCode: response.statusCode, response: response);
      _safeCallback(() => onSuccess(model));
      return model;
    }

    final exception = ApiException.fromResponse(
      response,
      endpoint: '${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    final model = ResponseModel(
      statusCode: response.statusCode,
      response: response,
      exception: exception,
    );
    _safeCallback(() => onSuccess(model));
    return model;
  }

  /// Retained for source compatibility.
  ///
  /// Nothing in the app calls this directly any more — [_run] owns the error
  /// path — but the symbol is referenced from comments and could be called by
  /// code outside this repo. It no longer throws a String.
  static ResponseModel handleError(
    DioException e,
    Function(DioExceptions dioExceptions) onError,
    Function(ResponseModel res) onSuccess, {
    bool throwOnError = false,
  }) {
    return _fail(
      ApiException.from(e, stackTrace: e.stackTrace),
      requestOptions: e.requestOptions,
      throwOnError: throwOnError,
      onError: onError,
      onSuccess: onSuccess,
    );
  }

  // ───────────────────────── typed entry point ──────────────────────────

  /// [ApiResult]-returning wrapper for new code.
  ///
  /// Combines the call and the parse under one guard, so a malformed payload
  /// is an [ApiFailure] rather than a `TypeError` thrown out of `fromJson`
  /// halfway through a controller's success path:
  ///
  /// ```dart
  /// Future<ApiResult<OrdersModel>> fetchOrders() => ApiBaseHelper().request(
  ///       () => ApiBaseHelper().getHTTP(orders, showProgress: false),
  ///       parse: OrdersModel.fromJson,
  ///     );
  /// ```
  Future<ApiResult<T>> request<T>(
    Future<ResponseModel> Function() call, {
    required T Function(dynamic body) parse,
  }) async {
    final result = await ApiResult.guard<ResponseModel>(call);
    return switch (result) {
      ApiSuccess<ResponseModel>(:final data) => data.toResult<T>(parse),
      ApiFailure<ResponseModel>(:final error) => ApiFailure<T>(error),
    };
  }
}

/// Backwards-compatible view of an [ApiException].
///
/// Every repository in the app types its `onError:` callback as
/// `Function(DioExceptions)`, so the name and the `message` field have to
/// survive. The classification behind it is now [ApiException]'s — reachable
/// through [exception] when a call site wants the kind, the status or the
/// server's error code rather than a display string.
/// Fires when a transfer has made no progress for [timeout].
///
/// The alternative for uploads and downloads is a wall-clock deadline, which
/// cannot work: the legitimate duration of a 40 MB upload on a train is
/// genuinely unbounded, so any cap either kills real work or is set so high it
/// protects nothing. Silence is the signal that actually distinguishes the two
/// — a moving transfer resets this on every progress callback, a wedged one
/// never does.
///
/// One-shot: once [fired] it stays fired, so a late progress callback arriving
/// after cancellation cannot re-arm a request that is already being torn down.
class _StallWatchdog {
  _StallWatchdog(this.timeout, this.onStall);

  final Duration timeout;
  final void Function() onStall;

  Timer? _timer;
  bool _fired = false;

  bool get fired => _fired;

  /// Records progress and restarts the clock.
  void beat() {
    if (_fired) return;
    _timer?.cancel();
    _timer = Timer(timeout, () {
      _fired = true;
      _timer = null;
      onStall();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

class DioExceptions implements Exception {
  String? message;

  /// The real, classified failure.
  final ApiException? exception;

  DioExceptions._(this.exception, this.message);

  factory DioExceptions.fromApiException(ApiException exception) =>
      DioExceptions._(exception, exception.message);

  factory DioExceptions.fromDioError(DioException? dioError) {
    if (dioError == null) {
      return DioExceptions._(null, ApiException.genericMessage);
    }
    final exception = ApiException.from(dioError, stackTrace: dioError.stackTrace);
    logs("dioError.type==== ${dioError.type} → ${exception.runtimeType}");
    return DioExceptions._(exception, exception.message);
  }

  /// Category of the failure, for call sites that want to branch.
  ApiErrorKind get kind => exception?.kind ?? ApiErrorKind.unknown;

  /// True when the request never reached the server.
  bool get isTransport => exception?.isTransport ?? false;

  /// True when offering a retry makes sense.
  bool get isRetryable => exception?.isRetryable ?? false;

  int? get statusCode => exception?.statusCode;

  @override
  String toString() => message ?? ApiException.genericMessage;
}
