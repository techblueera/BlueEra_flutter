/// Payload returned by `POST /recharge/initiate-order`. Carries the Razorpay
/// `order_id` + `key_id` to open checkout, plus the amount breakdown for the
/// summary UI. See `lib/docs/RECHARGE_FLUTTER_GUIDE.md` §3.2.
class InitiateRechargeResponse {
  final String orderId;
  final String keyId;
  final String currency;
  final int baseAmount;
  final int taxPercent;
  final int taxAmount;
  final int grossAmount;
  final int discountAmount;
  final int referralDiscountPercent;
  final int finalAmount;
  final String localRechargeId;

  const InitiateRechargeResponse({
    required this.orderId,
    required this.keyId,
    required this.currency,
    required this.baseAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.grossAmount,
    required this.discountAmount,
    required this.referralDiscountPercent,
    required this.finalAmount,
    required this.localRechargeId,
  });

  factory InitiateRechargeResponse.fromJson(Map<String, dynamic> json) {
    return InitiateRechargeResponse(
      orderId: (json['order_id'] ?? '').toString(),
      keyId: (json['key_id'] ?? '').toString(),
      currency: (json['currency'] ?? 'INR').toString(),
      baseAmount: _asInt(json['base_amount']),
      taxPercent: _asInt(json['tax_percent']),
      taxAmount: _asInt(json['tax_amount']),
      grossAmount: _asInt(json['gross_amount']),
      discountAmount: _asInt(json['discount_amount']),
      referralDiscountPercent: _asInt(json['referral_discount_percent']),
      finalAmount: _asInt(json['final_amount']),
      localRechargeId: (json['local_recharge_id'] ?? '').toString(),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
