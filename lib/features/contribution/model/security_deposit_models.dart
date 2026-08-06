/// Models for the Security Deposit ("contribution v2") flow.
///
/// Field names match the backend exactly — see
/// docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md. Money is in
/// **paise** (₹1 = 100); use the `*Rupees` getters for display.

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// A purchasable Security Deposit plan (catalog entry).
class SecurityDepositPlan {
  final String id;
  final String uiTab;
  final String uiCategoryGroup;
  final String name;
  final String tagId;
  final String accountType;
  final int depositAmount; // paise
  final String baseMetric;
  final String firstDayFreeText;
  final int? firstDayFreeLimit; // null = unlimited
  final bool firstDayFreeUnlimited;
  final int postpaidChargePerUnit; // paise
  final String activationCondition;
  final int refundAfterMonths;
  final List<String> termsAndConditions;

  /// Reasons explaining *why* the deposit / refund-lock exists. Shown as
  /// bullet points in the "Why?" dialog next to the Refund lock line.
  final List<String> why;
  final String currency;
  final bool active;
  final String mode; // live / test

  SecurityDepositPlan.fromJson(Map<String, dynamic> j)
      : id = (j['_id'] ?? '').toString(),
        uiTab = (j['ui_tab'] ?? '').toString(),
        uiCategoryGroup = (j['ui_category_group'] ?? '').toString(),
        name = (j['name'] ?? '').toString(),
        tagId = (j['tag_id'] ?? '').toString(),
        accountType = (j['account_type'] ?? '').toString(),
        depositAmount = _asInt(j['deposit_amount']),
        baseMetric = (j['base_metric'] ?? '').toString(),
        firstDayFreeText = (j['first_day_free_text'] ?? '').toString(),
        firstDayFreeLimit =
            j['first_day_free_limit'] == null ? null : _asInt(j['first_day_free_limit']),
        firstDayFreeUnlimited = j['first_day_free_unlimited'] == true,
        postpaidChargePerUnit = _asInt(j['postpaid_charge_per_unit']),
        activationCondition = (j['activation_condition'] ?? '').toString(),
        refundAfterMonths =
            j['refund_after_months'] == null ? 6 : _asInt(j['refund_after_months']),
        termsAndConditions = (j['terms_and_conditions'] is List)
            ? (j['terms_and_conditions'] as List).map((e) => e.toString()).toList()
            : const <String>[],
        why = (j['why'] is List)
            ? (j['why'] as List).map((e) => e.toString()).toList()
            : const <String>[],
        currency = (j['currency'] ?? 'INR').toString(),
        active = j['active'] != false,
        mode = (j['mode'] ?? '').toString();

  /// paise → rupees, for display.
  double get depositRupees => depositAmount / 100.0;
  double get postpaidRupees => postpaidChargePerUnit / 100.0;
}

/// An explainer video for the security-deposit screen
/// (`GET /security-deposit/videos`). Only `active` videos are surfaced.
class SecurityDepositVideo {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final String mimeType;
  final String status;

  SecurityDepositVideo.fromJson(Map<String, dynamic> j)
      : id = (j['_id'] ?? '').toString(),
        title = (j['title'] ?? '').toString(),
        description = (j['description'] ?? '').toString(),
        fileUrl = (j['fileUrl'] ?? '').toString(),
        fileName = (j['fileName'] ?? '').toString(),
        mimeType = (j['mimeType'] ?? '').toString(),
        status = (j['status'] ?? '').toString();

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasUrl => fileUrl.isNotEmpty;
}

/// Response of `POST /security-deposit/initiate` — the Razorpay order to open
/// checkout with. A **zero-deposit** tag returns [orderId] = null,
/// [finalAmount] = 0 and [status] = `held` (already active, no payment needed).
class InitiateSecurityDepositResponse {
  final String? orderId;
  final String keyId;
  final String currency;
  final int baseAmount; // paise, pre-discount
  final int discountAmount; // paise
  final int referralDiscountPercent;

  /// paise — THE amount to charge: `(base − discount) + GST`.
  ///
  /// The GST term is new; this was `(base − discount)` before tax shipped. It
  /// has always meant "what to hand Razorpay" and still does — the number is
  /// simply larger now. Never recompute it client-side: it is frozen server-side
  /// against the Razorpay order, and any drift is a failed payment.
  final int finalAmount;
  final int refundAfterMonths;
  final String securityDepositId;
  final String status;

  // ── Tax breakup (additive; all zero/empty before GST was enabled) ───────
  /// paise — deposit after discount, BEFORE tax.
  final int taxableAmount;

  /// The rate this order was frozen at. On a resumed order this is the rate at
  /// creation time, which may differ from today's `/gst` — render what came
  /// back rather than "correcting" it.
  final int gstPercent;

  /// paise — tax on [taxableAmount]. Zero for every pre-GST and legacy user;
  /// render no tax row at all in that case.
  final int gstAmount;

  /// Ready-made breakup string, e.g. `"200 + 36"`. Empty when absent.
  final String amountDisplay;

  InitiateSecurityDepositResponse.fromJson(Map<String, dynamic> j)
      : orderId = (j['order_id'] == null || j['order_id'].toString().isEmpty)
            ? null
            : j['order_id'].toString(),
        keyId = (j['key_id'] ?? '').toString(),
        currency = (j['currency'] ?? 'INR').toString(),
        baseAmount = _asInt(j['base_amount']),
        discountAmount = _asInt(j['discount_amount']),
        referralDiscountPercent = _asInt(j['referral_discount_percent']),
        finalAmount = _asInt(j['final_amount']),
        refundAfterMonths =
            j['refund_after_months'] == null ? 6 : _asInt(j['refund_after_months']),
        securityDepositId = (j['security_deposit_id'] ?? '').toString(),
        status = (j['status'] ?? '').toString(),
        taxableAmount = _asInt(j['taxable_amount']),
        gstPercent = _asInt(j['gst_percent']),
        gstAmount = _asInt(j['gst_amount']),
        amountDisplay = (j['amount_display'] ?? '').toString();

  /// True when no payment is needed — the deposit is already `held`.
  bool get isZeroDeposit => orderId == null || finalAmount <= 0;
}

/// The user's deposit record. On `current` / `my-deposits` / `details` the
/// `securityDepositPlanId` is populated with the full plan object, surfaced
/// here as [plan].
class UserSecurityDeposit {
  final String id;
  final String userId;
  final String tagId;
  final String accountType;
  final int depositAmount; // paise — catalog snapshot
  final int baseAmount; // paise — pre-discount base
  final int discountAmount; // paise — referral discount

  /// paise — the amount actually PAID. **Not** the amount refunded.
  ///
  /// It once was both. Since GST shipped it includes tax, and tax is remitted
  /// to the government rather than returned: a refund pays back the deposit
  /// only. Any refund figure must read [refundableAmount], never this.
  final int finalAmount;

  /// paise — what a refund would actually return (deposit, excluding GST).
  ///
  /// Falls back to [finalAmount] when the backend doesn't send it, which is the
  /// correct equivalence for every pre-GST deposit: no tax was charged, so the
  /// whole payment is refundable.
  ///
  /// Nothing renders a refund figure today. This exists so that whatever
  /// eventually does has the right field sitting there to reach for.
  final int refundableAmount;
  final String referralCode;
  final int referralDiscountPercent;
  final String currency;
  final String status;
  final bool isActive;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpayRefundId;
  final String heldAt;
  final int refundAfterMonths;
  final String refundEligibleAt;
  final String refundRequestedAt;
  final String refundedAt;
  final String mode;
  final String createdAt;
  final String updatedAt;

  /// Populated plan (when the backend returns it), else null.
  final SecurityDepositPlan? plan;

  UserSecurityDeposit.fromJson(Map<String, dynamic> j)
      : id = (j['_id'] ?? '').toString(),
        userId = (j['user_id'] ?? '').toString(),
        tagId = (j['tag_id'] ?? '').toString(),
        accountType = (j['account_type'] ?? '').toString(),
        depositAmount = _asInt(j['deposit_amount']),
        baseAmount = _asInt(j['base_amount']),
        discountAmount = _asInt(j['discount_amount']),
        finalAmount = _asInt(j['final_amount']),
        refundableAmount = j['refundable_amount'] == null
            ? _asInt(j['final_amount'])
            : _asInt(j['refundable_amount']),
        referralCode = (j['referralCode'] ?? '').toString(),
        referralDiscountPercent = _asInt(j['referral_discount_percent']),
        currency = (j['currency'] ?? 'INR').toString(),
        status = (j['status'] ?? '').toString(),
        isActive = j['isActive'] == true,
        razorpayOrderId = (j['razorpay_order_id'] ?? '').toString(),
        razorpayPaymentId = (j['razorpay_payment_id'] ?? '').toString(),
        razorpayRefundId = (j['razorpay_refund_id'] ?? '').toString(),
        heldAt = (j['held_at'] ?? '').toString(),
        refundAfterMonths =
            j['refund_after_months'] == null ? 6 : _asInt(j['refund_after_months']),
        refundEligibleAt = (j['refund_eligible_at'] ?? '').toString(),
        refundRequestedAt = (j['refund_requested_at'] ?? '').toString(),
        refundedAt = (j['refunded_at'] ?? '').toString(),
        mode = (j['mode'] ?? '').toString(),
        createdAt = (j['created_at'] ?? '').toString(),
        updatedAt = (j['updated_at'] ?? '').toString(),
        plan = (j['securityDepositPlanId'] is Map<String, dynamic>)
            ? SecurityDepositPlan.fromJson(
                j['securityDepositPlanId'] as Map<String, dynamic>)
            : null;

  double get depositRupees => depositAmount / 100.0;

  /// The amount actually paid (and refunded later). Falls back to the catalog
  /// snapshot when [finalAmount] isn't present (e.g. older records).
  int get paidAmount => finalAmount > 0 ? finalAmount : depositAmount;
  double get paidRupees => paidAmount / 100.0;

  /// `isActive == true` only when `status == 'held'`.
  bool get isHeld => status == 'held';
}
