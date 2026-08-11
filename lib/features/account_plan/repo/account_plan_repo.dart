import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Repository for the Account Plan flow (dynamic paid plans → Razorpay → GST
/// invoice). Mirrors [SecurityDepositRepo], which is the closest precedent.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
class AccountPlanRepo extends BaseService {
  /// `GET /account-plan/plans` — the dynamic catalog.
  ///
  /// BUSINESS must send both [tagId] (category tag) and [hasGst] — the latter
  /// selects the GST vs no-GST radius track, and a no-GST shop that omits it
  /// would be offered plans it cannot buy. INDIVIDUAL may omit [tagId]; the
  /// backend falls back to the profile's profession.
  Future<ResponseModel> getPlans({
    String? tagId,
    bool? hasGst,
    String? accountType,
  }) {
    final query = <String, dynamic>{
      if (tagId != null && tagId.isNotEmpty) 'tag_id': tagId,
      if (hasGst != null) 'has_gst': hasGst.toString(),
      if (accountType != null && accountType.isNotEmpty)
        'account_type': accountType,
    };
    return ApiBaseHelper().getHTTP(
      accountPlanPlans,
      params: query.isEmpty ? null : query,
      showProgress: false,
    );
  }

  /// `GET /account-plan/my-plans` — what the user already owns.
  Future<ResponseModel> myPlans({String? status, String? archetype}) {
    final query = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (archetype != null && archetype.isNotEmpty) 'archetype': archetype,
    };
    return ApiBaseHelper().getHTTP(
      accountPlanMyPlans,
      params: query.isEmpty ? null : query,
      showProgress: false,
    );
  }

  /// `POST /account-plan/initiate` — creates (or resumes) a Razorpay order.
  ///
  /// The price is re-computed server-side from [optionCode]; nothing the
  /// client believes about the amount is sent or trusted. [buyerState]
  /// improves the CGST/SGST-vs-IGST split on the invoice.
  Future<ResponseModel> initiate({
    required String optionCode,
    String? tagId,
    bool? hasGst,
    String? buyerState,
  }) {
    return ApiBaseHelper().postHTTP(
      accountPlanInitiate,
      params: <String, dynamic>{
        'option_code': optionCode,
        if (tagId != null && tagId.isNotEmpty) 'tag_id': tagId,
        if (hasGst != null) 'has_gst': hasGst,
        if (buyerState != null && buyerState.isNotEmpty)
          'buyer_state': buyerState,
      },
      showProgress: false,
    );
  }

  /// `POST /account-plan/verify-payment` — the client-side fallback.
  ///
  /// The webhook is the source of truth and performs the same idempotent
  /// activation; this only buys instant UI feedback, so the caller must
  /// re-fetch rather than treat the answer as final.
  Future<ResponseModel> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    return ApiBaseHelper().postHTTP(
      accountPlanVerifyPayment,
      params: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
      showProgress: false,
    );
  }

  /// `GET /account-plan/invoices` — `[{ invoice_number, invoice_url, status }]`.
  ///
  /// The invoice is auto-delivered to chat + email, so this is optional. The
  /// URL is unauthenticated and short-lived: open it as-is, never with the
  /// auth header, and never log it.
  Future<ResponseModel> invoices() {
    return ApiBaseHelper().getHTTP(accountPlanInvoices, showProgress: false);
  }

  /// `GET /account-plan/{id}/invoice` — one purchase's invoice.
  Future<ResponseModel> invoiceFor(String accountPlanId) {
    return ApiBaseHelper()
        .getHTTP(accountPlanInvoiceById(accountPlanId), showProgress: false);
  }
}
