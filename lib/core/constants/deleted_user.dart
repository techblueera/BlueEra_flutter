/// Support for **tombstoned** accounts — users whose account has been
/// hard-deleted.
///
/// The backend no longer drops the reference when an account goes: it keeps
/// answering for that id with a tombstone, so the other side of a chat, an old
/// order and every historical message still resolve. A tombstone looks like:
///
/// ```json
/// {
///   "id": "6a1fbcc215d42caef618aa0d",
///   "name": "Deleted User",
///   "is_deleted": true,
///   "account_type": "INDIVIDUAL",
///   "deleted_at": "2026-09-17T02:00:00.000Z",
///   "contact_no": "", "email": "", "profile_image": "", "username": ""
/// }
/// ```
///
/// Every field but `id` and `is_deleted` is blank — proto3 has no null, so
/// absent strings arrive as `""`, numbers as `0`, booleans as `false`.
///
/// Two rules the UI has to keep:
///
/// * **Never filter a deleted user out.** Hiding the row would make the whole
///   conversation vanish for the surviving participant, who did nothing wrong.
///   Render the tombstone and keep the history readable.
/// * **Never route on their id.** Profile, message, call, order and enquiry
///   actions all end at an account that belongs to nobody, so they are
///   disabled rather than left to fail somewhere deeper.
///
/// After the 365-day retention window the backend stops returning the user at
/// all (gRPC `NOT_FOUND`, or simply absent from a batch lookup). A *missing*
/// user should be treated exactly like `is_deleted: true` so the UI degrades
/// the same way.
///
/// See `docs/backend/FRONTEND_ACCOUNT_DELETION_BUGS.md` (bug 2).
library;

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:get/get.dart';

/// Reads the `is_deleted` flag off a user payload.
///
/// Defaults to `false` when the key is absent so responses from an older
/// backend — and the many endpoints that were never touched by this change —
/// keep working untouched. Accepts the bool/int/string shapes the gateways in
/// front of the services have been seen to emit.
bool parseIsDeleted(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final s = raw.toLowerCase().trim();
    return s == 'true' || s == '1';
  }
  return false;
}

/// The localised name every deleted account renders under.
///
/// The backend sends the literal "Deleted User" in `name`, but that string is
/// English regardless of the app's language, so the app supplies its own.
String get deletedUserName => AppStrings.deletedUser.tr;

/// True when a user field carries no usable text.
///
/// `""` is how proto3 spells an absent string, and `"null"` is what this
/// codebase has long stringified a missing name to, so both count as blank.
bool isBlankUserField(String? value) {
  final s = (value ?? '').trim();
  return s.isEmpty || s.toLowerCase() == 'null';
}

/// True when a **resolved** user payload should get the deleted treatment.
///
/// A tombstone announces itself with `is_deleted`, but an account past the
/// 365-day retention window leaves nothing to read that flag off: gRPC answers
/// `NOT_FOUND` and a batch lookup simply omits the user, so the row arrives
/// with every string blank and no flag at all. Both cases end in the same
/// place for the UI — an id that belongs to nobody — so a row carrying no
/// identity whatsoever is treated as gone rather than painted nameless and
/// left tappable. See §3 of `lib/docs/FRONTEND_DELETED_ACCOUNT_REMAINING.md`.
///
/// Only feed this payloads that have actually arrived. A screen still loading
/// its user has blank fields too, and that is not a tombstone.
///
/// [fallbacks] are the other identities the row could have shown instead of a
/// name — a phone number, a username, a business name. As long as one of them
/// survives, somebody is still behind the id.
bool isDeletedOrMissingUser({
  bool? isDeleted,
  String? name,
  Iterable<String?> fallbacks = const [],
}) {
  if (isDeleted == true) return true;
  return isBlankUserField(name) && fallbacks.every(isBlankUserField);
}

/// The name to paint for a user who may be a tombstone.
///
/// [name] is whatever the payload gave; [fallback] is what the caller would
/// normally show in its place (a phone number, a username). A deleted user
/// gets [deletedUserName] and neither — a tombstone's `contact_no` is `""`
/// anyway, so falling back would leave the row blank.
///
/// [blankMeansDeleted] extends that to the retention-window case: when the
/// payload has arrived and neither the name nor the fallback carries anything,
/// the row is a user who no longer exists, so it reads [deletedUserName]
/// rather than rendering as an empty line. Leave it `false` wherever blank can
/// still mean "not loaded yet" — a profile screen mid-fetch, say.
String displayUserName(
  String? name, {
  required bool isDeleted,
  String? fallback,
  bool blankMeansDeleted = false,
}) {
  if (isDeleted) return deletedUserName;
  if (!isBlankUserField(name)) return name!.trim();
  if (!isBlankUserField(fallback)) return fallback!.trim();
  return blankMeansDeleted ? deletedUserName : (fallback ?? '');
}

/// Guard for any action that routes on a deleted user's id — opening their
/// profile, starting a chat, placing a call, raising an order or an enquiry.
///
/// Returns `true` when the caller must stop, having already told the user why.
/// Reads at the call site as an early return:
///
/// ```dart
/// if (blockDeletedUserAction(sender?.isDeleted)) return;
/// ```
bool blockDeletedUserAction(bool? isDeleted, {String? message}) {
  if (isDeleted != true) return false;
  commonSnackBar(message: message ?? AppStrings.deletedUserUnavailable.tr);
  return true;
}
