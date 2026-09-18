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

/// The name to paint for a user who may be a tombstone.
///
/// [name] is whatever the payload gave; [fallback] is what the caller would
/// normally show in its place (a phone number, a username). A deleted user
/// gets [deletedUserName] and neither — a tombstone's `contact_no` is `""`
/// anyway, so falling back would leave the row blank.
String displayUserName(String? name,
    {required bool isDeleted, String? fallback}) {
  if (isDeleted) return deletedUserName;
  final n = (name ?? '').trim();
  if (n.isEmpty || n == 'null') return fallback ?? '';
  return n;
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
