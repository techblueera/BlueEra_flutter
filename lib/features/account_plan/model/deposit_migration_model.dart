/// Models for the deposit → account-plan migration offer.
/// See docs/backend/DEPOSIT_MIGRATION_FLUTTER_GUIDE.md §1.
library;

/// `GET /account-plan/migration/eligibility`.
///
/// The popup is driven ENTIRELY by this: no offer is ever shown unless
/// [eligible] is true and both [deposit] and [plan] parsed, because every
/// figure on the sheet (the amount paid, the plan they get, the date the money
/// comes back) is quoted from it. Guessing any of those would be quoting money
/// at a user from a default value.
class DepositMigrationEligibility {
  final bool eligible;
  final bool alreadyMigrated;
  final bool hasActivePlan;

  /// `no_deposit` | `already_on_plan` | `no_matching_plan` when not eligible.
  final String? reason;

  final MigrationDeposit? deposit;
  final MigrationPlan? plan;

  /// Recorded by the backend against the acceptance; shown small on the T&C.
  final String? tncVersion;

  const DepositMigrationEligibility({
    required this.eligible,
    required this.alreadyMigrated,
    required this.hasActivePlan,
    this.reason,
    this.deposit,
    this.plan,
    this.tncVersion,
  });

  /// Everything the offer sheet needs is present. [eligible] alone is not
  /// enough — a true with a missing plan or deposit block would render a sheet
  /// full of blanks.
  bool get canOffer =>
      eligible && !alreadyMigrated && !hasActivePlan && deposit != null && plan != null;

  factory DepositMigrationEligibility.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return DepositMigrationEligibility(
      eligible: data['eligible'] == true,
      alreadyMigrated: data['already_migrated'] == true,
      hasActivePlan: data['has_active_plan'] == true,
      reason: data['reason']?.toString(),
      deposit: data['deposit'] is Map
          ? MigrationDeposit.fromJson(
              Map<String, dynamic>.from(data['deposit'] as Map))
          : null,
      plan: data['plan'] is Map
          ? MigrationPlan.fromJson(Map<String, dynamic>.from(data['plan'] as Map))
          : null,
      tncVersion: data['tnc_version']?.toString(),
    );
  }
}

/// The deposit the user already paid — and which they keep.
class MigrationDeposit {
  final String? depositId;
  final num amountInr;

  /// When the money returns automatically. Null if the backend didn't send a
  /// parseable date, in which case the UI says the deposit stays refundable
  /// without naming a day rather than inventing one.
  final DateTime? refundEligibleAt;
  final int? refundAfterMonths;
  final bool refundable;

  const MigrationDeposit({
    this.depositId,
    required this.amountInr,
    this.refundEligibleAt,
    this.refundAfterMonths,
    required this.refundable,
  });

  factory MigrationDeposit.fromJson(Map<String, dynamic> json) {
    return MigrationDeposit(
      depositId: json['deposit_id']?.toString(),
      amountInr: (json['amount_inr'] as num?) ?? 0,
      refundEligibleAt:
          DateTime.tryParse(json['refund_eligible_at']?.toString() ?? '')
              ?.toLocal(),
      refundAfterMonths: (json['refund_after_months'] as num?)?.toInt(),
      refundable: json['refundable'] != false,
    );
  }
}

/// `GET /account-plan/migration/upgrade-options` — what a user who already
/// holds a plan would pay to move up a tier.
///
/// See DEPOSIT_MIGRATION_FLUTTER_GUIDE.md §5a.
class UpgradeOptions {
  final bool hasActivePlan;

  /// Which tiers are above the active one, each with its own priced breakdown.
  final List<UpgradeOption> options;

  const UpgradeOptions({required this.hasActivePlan, required this.options});

  UpgradeOption? forCode(String optionCode) {
    for (final option in options) {
      if (option.optionCode == optionCode) return option;
    }
    return null;
  }

  factory UpgradeOptions.fromJson(Map<String, dynamic> json) {
    final list = json['options'];
    return UpgradeOptions(
      hasActivePlan: json['has_active_plan'] == true,
      options: list is List
          ? list
              .whereType<Map>()
              .map((e) => UpgradeOption.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class UpgradeOption {
  final String optionCode;
  final String label;

  /// Whether spending this credit needs the user's explicit consent — true
  /// only when the credit is a refundable DEPOSIT, which upgrading consumes.
  final bool requiresTnc;

  final UpgradePriceBreakdown? breakdown;

  const UpgradeOption({
    required this.optionCode,
    required this.label,
    required this.requiresTnc,
    this.breakdown,
  });

  factory UpgradeOption.fromJson(Map<String, dynamic> json) {
    final b = json['price_breakdown'];
    return UpgradeOption(
      optionCode: json['option_code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      requiresTnc: json['requires_tnc'] == true,
      breakdown: b is Map
          ? UpgradePriceBreakdown.fromJson(Map<String, dynamic>.from(b))
          : null,
    );
  }
}

/// The server's arithmetic for one upgrade, in RUPEES.
///
/// Every figure the confirmation shows comes from here. The app deliberately
/// computes none of it — the total the user is asked to approve has to be the
/// same number the order is created for, and only the backend knows how the
/// credit and the tax interact.
class UpgradePriceBreakdown {
  final num planPriceInr;
  final num creditAppliedInr;

  /// `current_plan` (normal proration) or `deposit` (spends refundable money).
  final String creditSource;

  final num taxableInr;
  final num gstPercent;
  final num gstInr;
  final num payTotalInr;

  const UpgradePriceBreakdown({
    required this.planPriceInr,
    required this.creditAppliedInr,
    required this.creditSource,
    required this.taxableInr,
    required this.gstPercent,
    required this.gstInr,
    required this.payTotalInr,
  });

  /// True when the credit came from the refundable security deposit — the one
  /// case where upgrading spends money that would otherwise have come back.
  bool get fromDeposit => creditSource == 'deposit';

  factory UpgradePriceBreakdown.fromJson(Map<String, dynamic> json) {
    num n(String key) => (json[key] as num?) ?? 0;
    return UpgradePriceBreakdown(
      planPriceInr: n('plan_price_inr'),
      creditAppliedInr: n('credit_applied_inr'),
      creditSource: json['credit_source']?.toString() ?? '',
      taxableInr: n('taxable_inr'),
      gstPercent: n('gst_percent'),
      gstInr: n('gst_inr'),
      payTotalInr: n('pay_total_inr'),
    );
  }
}

/// `POST /migration/upgrade` — either an order for the difference, an outright
/// activation when the credit covers it, or a demand for the deposit T&C.
class UpgradeOrder {
  /// The backend is asking for the deposit T&C before it will price this.
  final bool requiresTnc;

  /// The credit covered the whole thing — no Razorpay, already upgraded.
  final bool upgraded;

  final String orderId;
  final String keyId;

  /// PAISE, and the DIFFERENCE only — never the plan's full price.
  final int totalAmount;

  final String currency;
  final UpgradePriceBreakdown? breakdown;

  const UpgradeOrder({
    required this.requiresTnc,
    required this.upgraded,
    required this.orderId,
    required this.keyId,
    required this.totalAmount,
    required this.currency,
    this.breakdown,
  });

  bool get hasOrder => orderId.isNotEmpty && totalAmount > 0;

  factory UpgradeOrder.fromJson(Map<String, dynamic> json) {
    final b = json['price_breakdown'];
    return UpgradeOrder(
      requiresTnc: json['requires_tnc'] == true,
      upgraded: json['upgraded'] == true,
      orderId: json['order_id']?.toString() ?? '',
      keyId: json['key_id']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      breakdown: b is Map
          ? UpgradePriceBreakdown.fromJson(Map<String, dynamic>.from(b))
          : null,
    );
  }
}

/// The plan they are being given, free — the nearest tier at or above what
/// their deposit was worth.
class MigrationPlan {
  final String? optionCode;
  final String label;
  final String? sublabel;
  final String? archetype;
  final num? planValueInr;
  final num? depositPaidInr;
  final num? bonusValueInr;

  const MigrationPlan({
    this.optionCode,
    required this.label,
    this.sublabel,
    this.archetype,
    this.planValueInr,
    this.depositPaidInr,
    this.bonusValueInr,
  });

  factory MigrationPlan.fromJson(Map<String, dynamic> json) {
    return MigrationPlan(
      optionCode: json['option_code']?.toString(),
      label: json['label']?.toString() ?? '',
      sublabel: json['sublabel']?.toString(),
      archetype: json['archetype']?.toString(),
      planValueInr: json['plan_value_inr'] as num?,
      depositPaidInr: json['deposit_paid_inr'] as num?,
      bonusValueInr: json['bonus_value_inr'] as num?,
    );
  }
}
