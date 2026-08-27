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
  ///
  /// [couponCode] unlocks campaigns the admin marked coupon-only
  /// (`auto_apply: false`); without it they are invisible. Auto-applied
  /// campaigns need nothing — the response carries them either way. The server
  /// decides validity: a wrong code simply comes back with no campaign, never
  /// an error, so the app writes no validity rules of its own.
  Future<ResponseModel> getPlans({
    String? tagId,
    bool? hasGst,
    String? accountType,
    String? couponCode,
  }) {
    final query = <String, dynamic>{
      if (tagId != null && tagId.isNotEmpty) 'tag_id': tagId,
      if (hasGst != null) 'has_gst': hasGst.toString(),
      if (accountType != null && accountType.isNotEmpty)
        'account_type': accountType,
      if (couponCode != null && couponCode.isNotEmpty)
        'coupon_code': couponCode,
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

  /// `GET /account-plan/sales/usage` — how much of an A1 sales plan's cap the
  /// shop has spent.
  ///
  /// **Call this ONLY for an A1 sales-shop that holds an active plan** — the
  /// guide (§2.2.1) is explicit that it is meaningless for every other
  /// archetype and must not join a generic load. The caller owns that gate;
  /// see [AccountPlanController.refreshSalesUsage].
  Future<ResponseModel> salesUsage() {
    return ApiBaseHelper().getHTTP(accountPlanSalesUsage, showProgress: false);
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
  ///
  /// [expectedTotalAmount] is the **overcharge guard** and must always be sent:
  /// it is the total the card promised, in paise, and the server refuses with
  /// 409 `price_changed` rather than charging more when a campaign ended while
  /// the buyer was deciding. Paying *less* than expected never errors. Omitting
  /// it means an expired offer silently charges the list price instead.
  Future<ResponseModel> initiate({
    required String optionCode,
    String? tagId,
    bool? hasGst,
    String? buyerState,
    String? buyerGstin,
    String? couponCode,
    int? expectedTotalAmount,
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
        if (couponCode != null && couponCode.isNotEmpty)
          'coupon_code': couponCode,
        if (expectedTotalAmount != null)
          'expected_total_amount': expectedTotalAmount,
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

  /// `POST /account-plan/{id}/refund-request` — ask for the plan fee back.
  ///
  /// `tnc_accepted` must be true, so the caller has to have shown the terms —
  /// the app never sends it without the confirm sheet having been accepted.
  /// A 400/403 (outside the window, already requested, refunds disabled) comes
  /// back with a `message` the UI shows verbatim.
  ///
  /// `showProgress: true`: unlike the reads on this repo, this is a deliberate
  /// one-shot action the user just tapped, and it must not look ignorable while
  /// it runs.
  Future<ResponseModel> requestRefund({
    required String accountPlanId,
    String? note,
  }) {
    return ApiBaseHelper().postHTTP(
      accountPlanRefundRequest(accountPlanId),
      params: {
        'tnc_accepted': true,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      showProgress: true,
    );
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
