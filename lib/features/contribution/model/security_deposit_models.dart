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
        currency = (j['currency'] ?? 'INR').toString(),
        active = j['active'] != false,
        mode = (j['mode'] ?? '').toString();

  /// paise → rupees, for display.
  double get depositRupees => depositAmount / 100.0;
  double get postpaidRupees => postpaidChargePerUnit / 100.0;
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
  final int finalAmount; // paise, payable (base − discount)
  final int refundAfterMonths;
  final String securityDepositId;
  final String status;

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
        status = (j['status'] ?? '').toString();

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
  final int finalAmount; // paise — amount actually paid AND refunded
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
