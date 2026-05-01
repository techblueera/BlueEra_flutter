/// Plan returned by `GET /recharge/plans`. All amount fields are in **paise**
/// (divide by 100 to display ₹). See `lib/docs/RECHARGE_FLUTTER_GUIDE.md` §3.1.
class RechargePlan {
  final String id;
  final String name;
  final String? description;
  final int amount;
  final int taxPercent;
  final int taxAmount;
  final int totalAmount;
  final int? amountBeforeDiscount;
  final String currency;
  final String tier;
  final String entityType;
  final String perkType;
  final int perkValue;
  final int perkBonus;
  final List<String> perks;
  final bool active;

  const RechargePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    required this.amountBeforeDiscount,
    required this.currency,
    required this.tier,
    required this.entityType,
    required this.perkType,
    required this.perkValue,
    required this.perkBonus,
    required this.perks,
    required this.active,
  });

  factory RechargePlan.fromJson(Map<String, dynamic> json) {
    final perksRaw = json['perks'];
    return RechargePlan(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      amount: _asInt(json['amount']),
      taxPercent: _asInt(json['tax_percent']),
      taxAmount: _asInt(json['tax_amount']),
      totalAmount: _asInt(json['total_amount']),
      amountBeforeDiscount: json['amountBeforeDiscount'] != null
          ? _asInt(json['amountBeforeDiscount'])
          : null,
      currency: (json['currency'] ?? 'INR').toString(),
      tier: (json['tier'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
      perkType: (json['perk_type'] ?? '').toString(),
      perkValue: _asInt(json['perk_value']),
      perkBonus: _asInt(json['perk_bonus']),
      perks: perksRaw is List
          ? perksRaw.map((e) => e.toString()).toList()
          : const <String>[],
      active: json['active'] == true,
    );
  }

  /// Display: ₹{amount/100}
  double get rupees => amount / 100.0;
  double get totalRupees => totalAmount / 100.0;
  int get totalPerks => perkValue + perkBonus;
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
