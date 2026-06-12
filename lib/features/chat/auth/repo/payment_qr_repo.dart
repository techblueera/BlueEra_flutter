import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// REST wrapper for the Payment QR & Transactions endpoints described in
/// `lib/docs/payment-qr-integration-guide.md`. All calls require the auth
/// Bearer token, which [ApiBaseHelper]'s interceptor injects automatically.
class PaymentQrRepo extends BaseService {
  // ── Payment QR ───────────────────────────────────────────────────────────

  /// POST /payment-qr — register a UPI payment QR.
  /// Required: `upi_id`, `qr_image_url`. Optional: `upi_phone_number`,
  /// `qr_image_key`.
  Future<ResponseModel> createPaymentQr(Map<String, dynamic> params) {
    return ApiBaseHelper().postHTTP(
      paymentQr,
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// GET /payment-qr — list the authenticated user's QRs (newest first).
  Future<ResponseModel> getMyPaymentQrs() {
    return ApiBaseHelper().getHTTP(
      paymentQr,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// GET /payment-qr/{id} — fetch a single QR you own.
  Future<ResponseModel> getPaymentQrById(String id) {
    return ApiBaseHelper().getHTTP(
      paymentQrById(id),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// PUT /payment-qr/{id} — update any subset of the updatable fields.
  Future<ResponseModel> updatePaymentQr(
      String id, Map<String, dynamic> params) {
    return ApiBaseHelper().putHTTP(
      paymentQrById(id),
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// DELETE /payment-qr/{id} — remove a QR (recorded transactions are kept).
  Future<ResponseModel> deletePaymentQr(String id) {
    return ApiBaseHelper().deleteHTTP(
      paymentQrById(id),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  /// POST /payment-qr/transactions — record a payment (caller = payer).
  /// Required: `payment_qr_id`, `utr_no`, `amount` (>0), `screenshot_url`.
  Future<ResponseModel> recordTransaction(Map<String, dynamic> params) {
    return ApiBaseHelper().postHTTP(
      paymentQrTransactions,
      isMultipart: false,
      showProgress: false,
      params: params,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// GET /payment-qr/transactions/received — payments made to my QRs.
  /// Optional query: `page`, `limit`, `payment_qr_id`.
  Future<ResponseModel> getReceivedTransactions({
    int page = 1,
    int limit = 20,
    String? paymentQrId,
  }) {
    return ApiBaseHelper().getHTTP(
      paymentQrTransactionsReceived,
      showProgress: false,
      params: {
        'page': page,
        'limit': limit,
        if (paymentQrId != null && paymentQrId.isNotEmpty)
          'payment_qr_id': paymentQrId,
      },
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// GET /payment-qr/{id}/transactions — payments for one of my QRs.
  Future<ResponseModel> getTransactionsForQr(String id) {
    return ApiBaseHelper().getHTTP(
      paymentQrTransactionsForQr(id),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// GET /payment-qr/user/{userId} — resolve the QR registered by a given
  /// owner (the receiver) so a payer can record a payment against it.
  /// TODO(backend): not in the public guide — confirm this endpoint exists.
  Future<ResponseModel> getPaymentQrByUser(String userId) {
    return ApiBaseHelper().getHTTP(
      paymentQrByUser(userId),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
