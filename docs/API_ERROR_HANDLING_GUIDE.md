# API error handling — how to consume `ApiBaseHelper`

Reference for `lib/core/api/apiService/`. Covers the failure contract, the
three supported consumption patterns, and the crash classes each one closes.

---

## 1. The contract

**No `ApiBaseHelper` method throws for a network or HTTP failure.** Every one
returns a `ResponseModel`:

| on | `isSuccess` | `statusCode` | `message` | `exception` |
|---|---|---|---|---|
| 2xx | `true` | 200… | server's `message` | `null` |
| 4xx / 5xx | `false` | 400, 404, 500… | server's `message`, else a safe default | the classified `ApiException` |
| no internet / DNS / TLS / timeout | `false` | `null` | "No internet connection…" etc. | the classified `ApiException` |
| malformed body, failed `fromJson` | `false` | as received | "We received an unexpected response…" | `ResponseFormatException` |

`response` is **never null** on the failure path — a synthetic
`{success: false, message: …}` body stands in — so existing call sites that
reach into `res.response!.data['message']` keep working.

### What changed

The old layer ended its error path with:

```dart
throw DioExceptions.fromDioError(e).message!;   // a bare String
```

A `String` is not an `Exception`. `on Exception catch` never caught it, and the
~1,200 call sites with no `try` at all turned every flaky-network moment into
`Unhandled Exception: Connection timeout with API server`. That throw is gone.

---

## 2. Pattern A — `isSuccess`, for existing code

This already works everywhere, unchanged. Network failures now land in the
`else` branch instead of crashing or being swallowed by a `catch (e)` that
printed a raw Dart string at the user.

```dart
final res = await AuthRepo().authMobileOtpSendRepo(bodyRequest: body);

if (res.isSuccess) {
  otpResponse.value = ApiResponse.complete(res);
} else {
  // `message` falls back to the classified failure, so this shows
  // "No internet connection…" rather than the generic string.
  otpResponse.value = ApiResponse.error(res.message);
  commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
}
```

Branch on the failure when the distinction matters:

```dart
if (!res.isSuccess) {
  if (res.isTransportFailure) {
    showRetryBanner();              // the server may never have seen this
  } else if (res.exception is UnauthorisedException) {
    return;                         // the interceptor is already logging out
  } else {
    commonSnackBar(message: res.message!);
  }
}
```

> **Still wrap `fromJson` in a `try`.** The helper cannot guard a parse it does
> not perform. `PostResponse.fromJson(res.response?.data)` inside a controller
> can still throw a `TypeError` on an unexpected payload — that is the crash
> `feed_controller.dart` documents. Pattern B removes the need.

---

## 3. Pattern B — `ApiResult<T>`, for new code

`ApiResult<T>` is this codebase's `Either<Failure, T>`, built on Dart 3 sealed
classes so the compiler enforces both branches. **It covers the parse as well
as the call**, which is the point: a throwing `fromJson` becomes an
`ApiFailure`, not an unhandled crash.

### Repository

```dart
class OrdersRepo extends BaseService {
  Future<ApiResult<OrdersModel>> fetchOrders({required String userId}) {
    return ApiBaseHelper().request(
      () => ApiBaseHelper().getHTTP(
        orders,
        params: {'user_id': userId},
        showProgress: false,
      ),
      parse: (body) => OrdersModel.fromJson(body),
    );
  }
}
```

### Controller

```dart
Future<void> loadOrders() async {
  state.value = ApiResponse.loading();

  final result = await OrdersRepo().fetchOrders(userId: userIdGlobal!);

  switch (result) {
    case ApiSuccess(:final data):
      orders.value = data.items;
      state.value = ApiResponse.complete(data);

    case ApiFailure(:final error):
      state.value = ApiResponse.error(error.message);
      // Silence for a request the user themselves cancelled.
      if (error.kind != ApiErrorKind.cancelled) {
        commonSnackBar(message: error.message);
      }
      canRetry.value = error.isRetryable;
  }
}
```

Omit the `ApiFailure` arm and it does not compile. That is deliberate: the old
layer let the failure branch be forgotten a thousand times over, and every
omission was a latent crash.

### Other shapes

```dart
// Collapse to one value.
final label = result.fold((d) => '${d.items.length} orders', (e) => e.message);

// A default is genuinely fine.
final orders = result.getOrElse((_) => const OrdersModel.empty());

// Chain a second parse; a throw inside becomes a failure.
final ids = result.map((m) => m.items.map((i) => i.id).toList());

// Wrap any risky work, not just HTTP.
final decoded = await ApiResult.guard(() async => expensiveParse(raw));
```

### Bridging one call without changing the repo

```dart
final res = await SomeRepo().existingCall();
final result = res.toResult<ProfileModel>(ProfileModel.fromJson);
```

---

## 4. Pattern C — structured `try`/`catch`, when a throw is wanted

Pass `throwOnError: true`. You get a typed `ApiException`, never a `String`, so
`on Exception catch` works and each category can be handled separately.

```dart
try {
  final res = await ApiBaseHelper().postHTTP(
    payOrder,
    params: body,
    throwOnError: true,
  );
  applyPayment(PaymentModel.fromJson(res.data));
} on UnauthorisedException {
  return;                                   // logout already in flight
} on ApiTimeoutException catch (e) {
  // Non-idempotent: the server may have taken the payment. Never say "failed".
  showRetryDialog(e.message);
} on FetchDataException catch (e) {
  showOfflineBanner(e.message);
} on ApiException catch (e) {
  commonSnackBar(message: e.message);
  if (kDebugMode) log(e.debugDescription);
}
```

Catch the base `ApiException` last — it is the parent of every category above.

---

## 5. Choosing between them

| | use |
|---|---|
| Touching existing code | **A** — nothing to migrate; keep a `try` around `fromJson` |
| New repository or controller | **B** — the compiler enforces the failure branch, and the parse is guarded |
| Non-idempotent action needing per-category handling | **C** |

---

## 6. The exception hierarchy

All extend `ApiException` (`api_exceptions.dart`), all carry `message`,
`statusCode`, `endpoint`, `code`, `body`, `cause`, `stackTrace`.

| Class | Raised for |
|---|---|
| `FetchDataException` | DNS failure, refused connection, airplane mode, `SocketException` |
| `ApiTimeoutException` | connect / send / receive timeout, `dart:async` `TimeoutException` |
| `BadRequestException` | 400, 422, unclassified 4xx |
| `UnauthorisedException` | 401 — session dead, interceptor logs out |
| `ForbiddenException` | 403 — **no logout**; this API means "not your resource" |
| `NotFoundException` | 404 |
| `ConflictException` | 409 |
| `TooManyRequestsException` | 429 |
| `InternalServerErrorException` | 500+, including 502/503/504 gateway pages |
| `ResponseFormatException` | undecodable body, HTML error page, `TypeError` from `fromJson` |
| `RequestCancelledException` | cancelled deliberately — **stay silent** |
| `BadCertificateException` | TLS handshake rejected |
| `UnknownApiException` | nothing else matched |

Three helpers carry most of the decisions:

- `isTransport` — the request never reached the server, so whether it took
  effect is **unknown**. Non-idempotent actions must offer Retry, not "failed".
- `isRetryable` — transport, 5xx or 429.
- `isAuthFailure` — 401 only.

`toString()` returns the display message, so the many existing
`commonSnackBar(message: e.toString())` call sites are safe. Use
`debugDescription` for logs — it adds the kind, status, code and endpoint.

---

## 7. Rules

1. **Never `throw` a `String`.** Throw an `ApiException` subclass, or return a
   failure.
2. **Never index a body without checking its shape.** `body['message']` on a
   bare array throws `type 'String' is not a subtype of type 'int'`. Use
   `ApiException.messageFromBody(body)`, which handles maps, arrays, undecoded
   JSON strings, HTML and null.
3. **Never `jsonDecode` a response directly.** Use
   `ApiException.tryDecodeJson`, which returns null instead of throwing on a
   502 HTML page, an empty 204 or a truncated payload.
4. **Never treat 403 as a logout.**
5. **Never show a server body verbatim on a 5xx** — 502/503/504 bodies are
   gateway HTML.
6. **Keep `fromJson` inside a guard** — `ApiResult.guard`, `.map`, `request()`,
   or a `try`.

---

## 8. Known gap this layer works around

Dio 5.x applies `receiveTimeout` to `request.close()` — waiting for the
response **headers** — and arms its per-chunk timer only from inside the
stream's data callback (`response_stream_handler.dart`). A server that returns
headers and then goes silent before the first body byte is guarded by **no
timeout at any layer** and hangs until the OS drops the socket.

`ApiBaseHelper.requestDeadline` (90 s, cancelled through the request's
`CancelToken` so the socket and the progress dialog are both released) is the
backstop. File transfers opt out — a wall-clock cap would abort healthy uploads
on a slow connection.

Covered by `test/api_base_helper_integration_test.dart`, "a server that sends
headers then stalls hits the deadline instead of hanging forever". Without the
deadline that test runs until the suite's own 30 s timeout kills it.

---

## 9. Tests

- `test/api_error_handling_test.dart` — 32 tests: classification, safe parsing
  of non-object bodies, `ApiResult`, what user-facing code sees.
- `test/api_base_helper_integration_test.dart` — 20 tests driving the real
  interceptor stack against a loopback `HttpServer`: HTML 502s served as JSON,
  truncated bodies, empty 204s, unreachable hosts, stalled servers, malformed
  requests, callback isolation, in-flight accounting.
