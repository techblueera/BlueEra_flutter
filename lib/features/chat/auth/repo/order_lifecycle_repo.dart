import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Every order-lifecycle HTTP call, one method per endpoint.
///
/// All thirteen action routes plus `/actions` and `/track` share the same
/// shape: `<service>/api/orders/:orderId/<verb>`. The [service] argument
/// selects the vertical (product today; grocery / food / medical once ported)
/// and defaults to `product-service`.
///
/// `showProgress: false` everywhere on purpose — these fire from a single card
/// inside a chat list, and a full-screen blocker would hide the very card the
/// user just tapped. Each card renders its own inline spinner instead
/// (guide §6).
///
/// Errors are NOT swallowed here. `ApiBaseHelper` returns a [ResponseModel]
/// carrying the 4xx body for a bad response and *throws a String* for a
/// transport failure, so [OrderLifecycleController] wraps every call and
/// normalises both into a typed code.
class OrderLifecycleRepo extends BaseService {
  static const String _defaultService = OrderServiceApi.defaultOrderService;

  /// `GET /actions` — authoritative buttons, deadlines, payment summary and
  /// role-scoped cancellation reasons.
  Future<ResponseModel> getActions(String orderId,
      {String service = _defaultService}) {
    return ApiBaseHelper().getHTTP(
      orderActions(orderId, service: service),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /track` — same envelope as `/actions` plus the order body.
  Future<ResponseModel> track(String orderId,
      {String service = _defaultService}) {
    return ApiBaseHelper().getHTTP(
      orderTrack(orderId, service: service),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ── Owner ──────────────────────────────────────────────────────────────

  /// `PUT /:orderId` — the direct status write, for a vertical that has no
  /// lifecycle route for the transition. Grocery's "Mark Collected" is the
  /// only caller today (§7 of the chat/steps edge-case doc).
  Future<ResponseModel> updateOrderStatus(String orderId,
      {required String orderStatus, String service = _defaultService}) {
    return ApiBaseHelper().putHTTP(
      orderUpdate(orderId, service: service),
      params: {'orderStatus': orderStatus},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> accept(String orderId,
      {int? prepEtaMinutes, String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderAccept(orderId, service: service),
      params: {
        if (prepEtaMinutes != null) 'prepEtaMinutes': prepEtaMinutes,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> reject(String orderId,
      {required String reasonCode,
      String? comment,
      String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderReject(orderId, service: service),
      params: {
        'reasonCode': reasonCode,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> setPrepEta(String orderId,
      {required int prepEtaMinutes, String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderPrepEta(orderId, service: service),
      params: {'prepEtaMinutes': prepEtaMinutes},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> markReady(String orderId,
      {String service = _defaultService}) {
    return ApiBaseHelper().putHTTP(
      orderReady(orderId, service: service),
      params: const <String, dynamic>{},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> verifyPayment(String orderId,
      {num? amountReceived, String? note, String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderPaymentVerify(orderId, service: service),
      params: {
        if (amountReceived != null) 'amountReceived': amountReceived,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> rejectPayment(String orderId,
      {required String reason, String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderPaymentReject(orderId, service: service),
      params: {'reason': reason},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `collectedCash` is sent for cash orders only — one tap records both the
  /// goods leaving and the money arriving, so a busy shop cannot forget half.
  Future<ResponseModel> handover(String orderId,
      {required String pickupCode,
      bool? collectedCash,
      String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderHandover(orderId, service: service),
      params: {
        'pickupCode': pickupCode,
        if (collectedCash != null) 'collectedCash': collectedCash,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> noShow(String orderId,
      {String? comment, String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderNoShow(orderId, service: service),
      params: {
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// The owner's claim that they returned the money. It does **not** close the
  /// refund — only the customer's `CONFIRM_REFUND_RECEIVED` (or an admin
  /// close-out) does. Guide §3.6.1.
  Future<ResponseModel> refundSent(String orderId,
      {required String refundReference,
      String? note,
      String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderRefundSent(orderId, service: service),
      params: {
        'refundReference': refundReference,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ── Customer ───────────────────────────────────────────────────────────

  Future<ResponseModel> submitPayment(String orderId,
      {required String utrNo,
      required num amountPaid,
      required String screenshotUrl,
      String? paymentQrId,
      String? upiId,
      String? transactionRef,
      String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderPaymentSubmit(orderId, service: service),
      params: {
        'utrNo': utrNo,
        'amountPaid': amountPaid,
        'screenshotUrl': screenshotUrl,
        if (paymentQrId != null && paymentQrId.isNotEmpty)
          'paymentQrId': paymentQrId,
        if (upiId != null && upiId.isNotEmpty) 'upiId': upiId,
        if (transactionRef != null && transactionRef.isNotEmpty)
          'transactionRef': transactionRef,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> pickupCode(String orderId,
      {String service = _defaultService}) {
    return ApiBaseHelper().getHTTP(
      orderPickupCode(orderId, service: service),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> refundReceived(String orderId,
      {String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderRefundReceived(orderId, service: service),
      params: const <String, dynamic>{},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ── Either party ───────────────────────────────────────────────────────

  Future<ResponseModel> cancel(String orderId,
      {required String reasonCode,
      String? comment,
      String service = _defaultService}) {
    return ApiBaseHelper().postHTTP(
      orderCancel(orderId, service: service),
      params: {
        'reasonCode': reasonCode,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ── Lists ──────────────────────────────────────────────────────────────

  /// `GET /orders/me` — every order this user placed, as a customer.
  ///
  /// Used by the Discover pending-order chip, which needs to answer "what of
  /// mine is still in flight" without a chat thread being open. §12 fact 3.
  Future<ResponseModel> myOrders({String service = _defaultService}) {
    return ApiBaseHelper().getHTTP(
      ordersMine(service: service),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ── Rider leg ──────────────────────────────────────────────────────────

  /// `GET /fare/chat-dispatch/quote`. Called before the customer commits, so
  /// the checkout sheet shows the real fee, the ETA range and the economics
  /// note. An out-of-radius address answers 200 with `feasible:false`.
  Future<ResponseModel> deliveryQuote({
    required double shopLat,
    required double shopLng,
    required double dropLat,
    required double dropLng,
    double? distanceInKm,
    num? orderValue,
  }) {
    return ApiBaseHelper().getHTTP(
      chatDispatchQuote,
      params: {
        'shopLat': shopLat,
        'shopLng': shopLng,
        'dropLat': dropLat,
        'dropLng': dropLng,
        if (distanceInKm != null) 'distance_in_km': distanceInKm,
        if (orderValue != null) 'orderValue': orderValue,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
