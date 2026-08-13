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
  ///
  /// [buyerGstin] is **required for a `gst_track: "GST"` option** (every radius
  /// tier above 3 km, and all wide-reach). Without it the backend creates no
  /// order and answers 400 with `data.requires_gst: true` — see the guide §2.3.
  Future<ResponseModel> initiate({
    required String optionCode,
    String? tagId,
    bool? hasGst,
    String? buyerState,
    String? buyerGstin,
  }) {
    return ApiBaseHelper().postHTTP(
      accountPlanInitiate,
      params: <String, dynamic>{
        'option_code': optionCode,
        if (tagId != null && tagId.isNotEmpty) 'tag_id': tagId,
        if (hasGst != null) 'has_gst': hasGst,
        if (buyerState != null && buyerState.isNotEmpty)
          'buyer_state': buyerState,
        if (buyerGstin != null && buyerGstin.isNotEmpty)
          'buyer_gstin': buyerGstin,
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

  /// `GET /migration/eligibility` — whether this deposit holder can be moved
  /// onto a free account plan, and which plan that would be.
  ///
  /// `showProgress: false`: this runs unprompted on app open. A blocking
  /// spinner for a check the user never asked for would be worse than the
  /// offer arriving a moment later.
  Future<ResponseModel> migrationEligibility() {
    return ApiBaseHelper().getHTTP(
      accountPlanMigrationEligibility,
      showProgress: false,
    );
  }

  /// `GET /migration/upgrade-options` — the active plan, the credit it earns,
  /// and a server-computed `price_breakdown` for every higher tier.
  Future<ResponseModel> upgradeOptions() {
    return ApiBaseHelper().getHTTP(
      accountPlanUpgradeOptions,
      showProgress: false,
    );
  }

  /// `POST /migration/upgrade` — starts the upgrade for [optionCode].
  ///
  /// [tncAccepted] is sent only on the re-POST after the user has accepted the
  /// deposit T&C: the first call is what TELLS us the terms are needed
  /// (`requires_tnc: true`), so sending true up front would accept terms the
  /// user has not been shown.
  Future<ResponseModel> upgrade({
    required String optionCode,
    String? buyerState,
    bool? tncAccepted,
  }) {
    return ApiBaseHelper().postHTTP(
      accountPlanUpgrade,
      params: <String, dynamic>{
        'option_code': optionCode,
        if (buyerState != null && buyerState.isNotEmpty)
          'buyer_state': buyerState,
        if (tncAccepted == true) 'tnc_accepted': true,
      },
      showProgress: false,
    );
  }

  /// `POST /migration/upgrade/verify` — settles an upgrade order.
  Future<ResponseModel> verifyUpgrade({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    return ApiBaseHelper().postHTTP(
      accountPlanUpgradeVerify,
      params: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
      showProgress: false,
    );
  }

  /// `POST /migration/migrate` — accepts the T&C and activates the free plan.
  ///
  /// The sheet's own button carries the loader (and is disabled while the call
  /// is in flight), so this stays out of the global progress overlay too.
  Future<ResponseModel> migrate() {
    return ApiBaseHelper().postHTTP(
      accountPlanMigrate,
      params: {'tnc_accepted': true},
      showProgress: false,
    );
  }
}
