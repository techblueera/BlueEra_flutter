/// The `409 deletion_blocked` body of `POST /user/account/deletion/init`.
///
/// `/init` answers 409 for two unrelated reasons and the only thing that tells
/// them apart is the `code` field:
///
/// | `code`                     | meaning                                        |
/// |----------------------------|------------------------------------------------|
/// | `already_pending_deletion` | a deletion is genuinely in progress             |
/// | `deletion_blocked`         | wallet balance / live order / active plan, etc. |
///
/// Branching on the status code alone told a user holding money in their wallet
/// that "a deletion request is already in progress" — wrong, and it hid the
/// per-blocker messages the backend already writes.
///
/// See `docs/backend/FRONTEND_ACCOUNT_DELETION_BUGS.md` (bug 1) and
/// `be_user_service/docs/ACCOUNT_DELETION_CROSS_SERVICE.md`.
class DeletionBlockedResponse {
  DeletionBlockedResponse({this.code, this.message, this.blockers = const []});

  /// Server `code`. Null when the body had none (older builds, or a proxy
  /// error page), which callers treat as "unknown 409" and fall back on.
  final String? code;

  /// The server's headline line. Display-ready but NOT localised, so it is
  /// only used as a fallback behind the app's own string.
  final String? message;

  /// Always non-empty when [isBlocked]; every entry carries its own
  /// human-readable [DeletionBlocker.message].
  final List<DeletionBlocker> blockers;

  static const String codeAlreadyPending = 'already_pending_deletion';
  static const String codeBlocked = 'deletion_blocked';

  bool get isAlreadyPending => code == codeAlreadyPending;

  bool get isBlocked => code == codeBlocked;

  /// Tolerates a `Map`, or anything else (→ empty model, which the caller
  /// reads as "unknown 409" and answers with the legacy snackbar).
  factory DeletionBlockedResponse.fromJson(dynamic json) {
    if (json is! Map) return DeletionBlockedResponse();
    final raw = json['blockers'];
    return DeletionBlockedResponse(
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      blockers: raw is List
          ? raw
              .map(DeletionBlocker.fromJson)
              .where((b) => b.message.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

/// One reason the account can't be deleted yet.
class DeletionBlocker {
  DeletionBlocker({
    required this.type,
    required this.message,
    this.amount,
    this.count,
    this.service,
  });

  /// One of: `wallet_balance`, `pending_balance`, `pending_withdrawal`,
  /// `active_order_buyer`, `active_order_seller`, `active_subscription`,
  /// `active_account_plan`, `check_unavailable`.
  ///
  /// Kept as a raw string rather than an enum so a ninth type added
  /// server-side still renders — the message is what the user reads.
  final String type;

  /// Human-readable, already written for the user by the backend.
  final String message;

  /// `wallet_balance` / `pending_balance` / `pending_withdrawal` only.
  final num? amount;

  /// `active_order_*` only.
  final num? count;

  /// `check_unavailable` only — which dependency couldn't be reached.
  final String? service;

  /// True when this isn't the user's fault: a backend dependency was
  /// unreachable, so "try again in a few minutes" is the right tone and the
  /// UI must not tell them to go and withdraw money.
  bool get isTransient => type == 'check_unavailable';

  factory DeletionBlocker.fromJson(dynamic json) {
    if (json is! Map) return DeletionBlocker(type: '', message: '');
    final amount = json['amount'];
    final count = json['count'];
    return DeletionBlocker(
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      amount: amount is num ? amount : null,
      count: count is num ? count : null,
      service: json['service']?.toString(),
    );
  }
}
