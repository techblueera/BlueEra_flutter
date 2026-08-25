/// All `order-service/*` endpoint constants used by the app, plus the
/// **order-lifecycle** endpoint family that every vertical's order service
/// exposes under `<service>/api/orders/:orderId/...`.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// ## Why the lifecycle paths take a `service` argument
///
/// The lifecycle contract (accept / reject / prep-eta / ready / payment /
/// handover / no-show / cancel / refund / actions) is **identical** across
/// product, grocery, food, medical and home-made orders — only the service
/// prefix differs, exactly as `message_type` does on the chat card. Rather
/// than copy thirteen constants per vertical, each path is a function whose
/// first positional argument is the order id and whose named `service`
/// argument defaults to `product-service` (the one vertical that is ported
/// today).
///
/// The prefix is deliberately `<service>/api/orders/...` and NOT
/// `inventory-service/orders/...`: the app already reaches
/// `product-service/api/orders` successfully for order creation
/// ([ProductServiceApi.placeProductOrder]), so the new sibling routes resolve
/// through the same gateway rewrite. The legacy
/// `inventory-service/orders/:id/ready` constant is kept untouched in
/// [InventoryServiceApi] so old callers keep working.
///
/// See `lib/docs/FLUTTER_ORDER_FLOW_UI_GUIDE.md` §9 for the full table.
mixin OrderServiceApi {
  /// Legacy constant. No live caller — kept so an old build's import keeps
  /// compiling. Payment verification now goes through [orderPaymentVerify].
  final String verifyPaymentApi = "order-service/api/orders/verify-payment";

  /// Default vertical for the lifecycle endpoints.
  static const String defaultOrderService = 'product-service';

  /// Service prefix for each ported vertical. Pass one of these as `service`
  /// when the card is not a product card.
  static const String productOrderService = 'product-service';
  static const String groceryOrderService = 'grocery-service';
  static const String foodOrderService = 'food-service';
  static const String medicalOrderService = 'medical-service';

  String _orderBase(String service, String orderId) =>
      '$service/api/orders/$orderId';

  /// `GET  <service>/api/orders/:orderId/actions` — authoritative button list,
  /// deadlines, payment summary and role-scoped cancellation reasons.
  String orderActions(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/actions';

  /// `POST <service>/api/orders/:orderId/accept` — business. `{ prepEtaMinutes? }`
  String orderAccept(String orderId, {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/accept';

  /// `POST <service>/api/orders/:orderId/reject` — business. `{ reasonCode, comment? }`
  String orderReject(String orderId, {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/reject';

  /// `POST <service>/api/orders/:orderId/prep-eta` — business. `{ prepEtaMinutes }`
  String orderPrepEta(String orderId, {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/prep-eta';

  /// `PUT  <service>/api/orders/:orderId/ready` — business. No body.
  String orderReady(String orderId, {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/ready';

  /// `POST <service>/api/orders/:orderId/payment/submit` — customer.
  /// `{ utrNo, amountPaid, screenshotUrl, paymentQrId?, upiId?, transactionRef? }`
  String orderPaymentSubmit(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/payment/submit';

  /// `POST <service>/api/orders/:orderId/payment/verify` — business/admin.
  /// `{ amountReceived?, note? }`
  String orderPaymentVerify(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/payment/verify';

  /// `POST <service>/api/orders/:orderId/payment/reject` — business/admin.
  /// `{ reason }`
  String orderPaymentReject(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/payment/reject';

  /// `GET  <service>/api/orders/:orderId/pickup-code` — customer.
  String orderPickupCode(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/pickup-code';

  /// `POST <service>/api/orders/:orderId/handover` — business.
  /// `{ pickupCode, collectedCash? }`
  String orderHandover(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/handover';

  /// `POST <service>/api/orders/:orderId/no-show` — business. `{ comment? }`
  String orderNoShow(String orderId, {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/no-show';

  /// `POST <service>/api/orders/:orderId/cancel` — any party.
  /// `{ reasonCode, comment? }`
  String orderCancel(String orderId, {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/cancel';

  /// `POST <service>/api/orders/:orderId/refund/sent` — business.
  /// `{ refundReference, note? }`
  String orderRefundSent(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/refund/sent';

  /// `POST <service>/api/orders/:orderId/refund/received` — customer. No body.
  String orderRefundReceived(String orderId,
          {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/refund/received';

  /// `GET  <service>/api/orders/:orderId/track` — any party. Now also returns
  /// `availableActions`, `paymentSummary`, `cancellation` and `deadlines`.
  String orderTrack(String orderId, {String service = defaultOrderService}) =>
      '${_orderBase(service, orderId)}/track';
}
