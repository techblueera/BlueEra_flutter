/// Models for the one-time "change my profile category" flow.
///
/// See `docs/backend/FLUTTER_PROFILE_CATEGORY_CHANGE_GUIDE.md`. Two endpoints:
/// `GET /user/me/profile-category` reads the state (§5) and
/// `POST /user/me/profile-category/change` performs it (§7). The change stays
/// INSIDE the account type — an individual picks another profession, a
/// business another category — and each account gets exactly one.
library;

/// The category the account is on right now.
///
/// [tagId] is always the canonical catalog `tag_id`, whichever convention the
/// underlying record uses. `User.profession` exists in the live data both as a
/// display name ("Bike Rider", from the older onboarding path) and as a tag
/// ("BIKE_RIDER"); this endpoint resolves both, which is why the picker must
/// compare against THIS and never against the raw `profession` field from
/// `GET /user/get`.
class ProfileCategoryCurrent {
  const ProfileCategoryCurrent({
    this.tagId,
    this.name,
    this.categoryType,
    this.subCategoryId,
    this.profileType,
    this.designation,
  });

  /// Canonical catalog tag — `GROCERY_STORE`, `BIKE_RIDER`.
  final String? tagId;

  /// Display name for the subtitle under the Settings row — "Grocery Store".
  final String? name;

  /// BUSINESS only — the `BusinessType` bucket ("Grocery", "Food").
  final String? categoryType;

  /// BUSINESS only. Null after a change that didn't carry a new one: the old
  /// sub-category belonged to the old category's tree.
  final String? subCategoryId;

  /// INDIVIDUAL only — the catalog's spelling ("GigWork"), NOT the app's enum.
  /// Pass it through `normalizeProfileType` before storing it in a global.
  final String? profileType;

  /// INDIVIDUAL only. Cleared by a change that didn't re-send it.
  final String? designation;

  factory ProfileCategoryCurrent.fromJson(Map<dynamic, dynamic> json) {
    return ProfileCategoryCurrent(
      tagId: json['tag_id'] as String?,
      name: json['name'] as String?,
      categoryType: json['category_type'] as String?,
      subCategoryId: json['sub_category_id'] as String?,
      profileType: json['profile_type'] as String?,
      designation: json['designation'] as String?,
    );
  }
}

/// Answer to "should I show this row at all, and is the change still
/// available?" — the whole of §5.
class ProfileCategoryState {
  const ProfileCategoryState({
    required this.accountType,
    required this.supported,
    required this.canChange,
    required this.changesUsed,
    required this.changesRemaining,
    this.current,
    this.lastChangedAt,
    this.lastChangedBy,
    this.optionsEndpoint,
  });

  /// `INDIVIDUAL` / `BUSINESS` / `GUEST` / `BLUEFLY`.
  final String accountType;

  /// False for GUEST and BLUEFLY, which have no category. **Hide the row
  /// entirely** — not disabled, hidden.
  final bool supported;

  /// False once the one allowance is spent. Row stays VISIBLE but disabled,
  /// with the contact-support line: a row that vanishes after being used looks
  /// like a bug to someone who saw it yesterday.
  final bool canChange;

  final int changesUsed;
  final int changesRemaining;

  final ProfileCategoryCurrent? current;
  final DateTime? lastChangedAt;

  /// Who made the last change — `null`, `"user"`, or an admin id when support
  /// did it on the user's behalf.
  final String? lastChangedBy;

  /// Which catalog to load for the picker — `/individual-professions` or
  /// `/business/getAllcategories`. Drive the picker off THIS rather than
  /// branching on [accountType]: the endpoint is the contract, and it means a
  /// future account type routes itself.
  final String? optionsEndpoint;

  /// True when the picker should show the professions catalog.
  ///
  /// Matched on the endpoint rather than on [accountType] for the reason
  /// above, with the account type as the fallback for a response that omits
  /// it.
  bool get usesProfessionsCatalog =>
      optionsEndpoint?.contains('individual-professions') ??
      accountType.toUpperCase() == 'INDIVIDUAL';

  factory ProfileCategoryState.fromJson(Map<dynamic, dynamic> json) {
    final rawCurrent = json['current'];
    final rawLastChanged = json['last_changed_at'];
    return ProfileCategoryState(
      accountType: json['account_type'] as String? ?? '',
      // Default FALSE, not true: an unreadable response must hide the row
      // rather than offer a change the backend may refuse.
      supported: json['supported'] == true,
      canChange: json['can_change'] == true,
      changesUsed: _asInt(json['changes_used']),
      changesRemaining: _asInt(json['changes_remaining']),
      current: rawCurrent is Map
          ? ProfileCategoryCurrent.fromJson(rawCurrent)
          : null,
      lastChangedAt:
          rawLastChanged is String ? DateTime.tryParse(rawLastChanged) : null,
      lastChangedBy: json['last_changed_by'] as String?,
      optionsEndpoint: json['options_endpoint'] as String?,
    );
  }

  /// The state a change response leaves behind, so the screen updates without
  /// a second GET (§7). Everything the change response doesn't carry —
  /// account type, options endpoint — is kept from this instance.
  ProfileCategoryState afterChange(ProfileCategoryChangeResult result) {
    return ProfileCategoryState(
      accountType: accountType,
      supported: supported,
      canChange: result.canChange,
      changesUsed: result.changesUsed,
      changesRemaining: result.changesRemaining,
      current: result.current ?? current,
      lastChangedAt: DateTime.now(),
      lastChangedBy: lastChangedBy,
      optionsEndpoint: optionsEndpoint,
    );
  }

  /// Placeholder for "we haven't asked yet" — hides the row, which is the
  /// right default while the GET is in flight.
  static const ProfileCategoryState unknown = ProfileCategoryState(
    accountType: '',
    supported: false,
    canChange: false,
    changesUsed: 0,
    changesRemaining: 0,
  );
}

/// A successful change (§7). [from] and [to] are canonical `tag_id`s whichever
/// form was sent.
class ProfileCategoryChangeResult {
  const ProfileCategoryChangeResult({
    this.from,
    this.to,
    this.current,
    required this.canChange,
    required this.changesUsed,
    required this.changesRemaining,
  });

  final String? from;
  final String? to;
  final ProfileCategoryCurrent? current;
  final bool canChange;
  final int changesUsed;
  final int changesRemaining;

  factory ProfileCategoryChangeResult.fromJson(Map<dynamic, dynamic> json) {
    final rawCurrent = json['current'];
    final rawState = json['state'];
    final state = rawState is Map ? rawState : const {};
    return ProfileCategoryChangeResult(
      from: json['from'] as String?,
      to: json['to'] as String?,
      current: rawCurrent is Map
          ? ProfileCategoryCurrent.fromJson(rawCurrent)
          : null,
      // A 200 always spends the allowance, so these default to "spent" rather
      // than to "still available" if the state block is ever missing.
      canChange: state['can_change'] == true,
      changesUsed: _asInt(state['changes_used'], fallback: 1),
      changesRemaining: _asInt(state['changes_remaining']),
    );
  }
}

/// The stable `code` values from §8. **Switch on these, never on the message
/// text** — the messages are not part of the contract.
class ProfileCategoryErrorCode {
  const ProfileCategoryErrorCode._();

  static const String missingTagId = 'missing_tag_id';
  static const String licenseRequired = 'license_required';
  static const String unauthenticated = 'unauthenticated';
  static const String userNotFound = 'user_not_found';
  static const String sameCategory = 'same_category';
  static const String changeLimitReached = 'change_limit_reached';
  static const String unknownCategory = 'unknown_category';
  static const String unsupportedAccountType = 'unsupported_account_type';
  static const String businessNotFound = 'business_not_found';
  static const String earnProfileSyncFailed = 'earn_profile_sync_failed';
  static const String serverError = 'server_error';

  /// Not from the backend — raised locally when the request never reached it
  /// (airplane mode, timeout). Retryable for the same reason as the 5xx codes:
  /// nothing was spent because nothing ran.
  static const String networkError = 'network_error';

  /// Also local: the request was rejected on its content (4xx) but carried no
  /// `code`. Deliberately NOT retryable and deliberately not mapped onto one
  /// of the named codes — a guess here would send the UI down the wrong path.
  /// Show the generic failure message.
  static const String unspecified = 'unspecified';

  /// Failures worth offering a Retry button for.
  ///
  /// Safe because the one-time allowance is claimed BEFORE the backend does
  /// any work and handed back if that work fails — so a 502/500 costs the user
  /// nothing (§8, "Retry is safe").
  static const Set<String> retryable = {
    earnProfileSyncFailed,
    serverError,
    networkError,
  };
}

/// A failed change, carrying the machine-readable [code] the UI switches on.
class ProfileCategoryException implements Exception {
  const ProfileCategoryException({
    required this.code,
    this.message,
    this.errors = const [],
    this.statusCode,
  });

  final String code;

  /// Server-supplied text. Useful for logs; prefer your own copy per [code]
  /// for anything the user reads.
  final String? message;

  /// Field-level detail — populated for `license_required`.
  final List<String> errors;

  final int? statusCode;

  bool get isRetryable => ProfileCategoryErrorCode.retryable.contains(code);

  @override
  String toString() =>
      'ProfileCategoryException($code, status=$statusCode, message=$message)';
}

/// Tolerates the numeric fields arriving as `int`, `num` or a numeric string.
int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
