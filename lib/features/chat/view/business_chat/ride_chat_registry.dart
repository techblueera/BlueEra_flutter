import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chat-card `message_type`s the ride/goods dispatch flow posts into a
/// conversation. A thread carrying any of them is a ride booking, whichever
/// route it was booked through (Discover transport, the Inquiry tab's rider
/// shortcut, a grocery/food order handed to a rider, or a fare call):
///   order_request — the booking request card
///   rider         — rider details + Track Order / Cancel Ride
///   rider_map     — the live-location card (suppressed inside the thread)
///   rider_otp     — the pickup / delivery handoff OTP card
const Set<String> kRideDispatchMessageTypes = {
  'order_request',
  'rider',
  'rider_map',
  'rider_otp',
};

/// Conversations identified as ride threads, remembered across relaunches.
///
/// A chat-list row only carries its LAST message type, so once either party
/// sends a plain message the ride card scrolls out of that field and the
/// thread stops looking like a ride. On a rider's device that is exactly what
/// pushed finished/chatted-in ride orders back into the Inquiry tab — rides
/// belong in the Order tab there (see `bucketChat`), and the rider works them
/// out of the dispatch screens, not out of Inquiry.
///
/// So every id we ever see carrying a dispatch card is latched here and
/// written to disk, keyed per user. The in-memory set answers synchronously
/// during list builds; [revision] lets those builds re-run once a late
/// hydration (or a newly-identified thread) changes the answer.
class RideChatRegistry {
  const RideChatRegistry._();

  static const String _keyPrefix = 'known_ride_chats_';

  static final Set<String> _ids = <String>{};

  /// Bumped whenever [_ids] changes, so `Obx` list bodies that bucket rows
  /// through `bucketChat` rebuild with the new classification.
  static final RxInt revision = 0.obs;

  /// User the in-memory set belongs to — a different id means the store has
  /// to be re-read (and the previous user's conversations dropped).
  static String? _hydratedFor;
  static Future<void>? _hydrating;

  static bool contains(String? id) => id != null && id.isNotEmpty && _ids.contains(id);

  /// Latch [id] as a ride thread. Safe to call from a build (it never bumps
  /// [revision] synchronously) and cheap to call repeatedly — a known id
  /// returns immediately without touching disk.
  static void register(String? id) {
    if (id == null || id.isEmpty) return;
    if (!_ids.add(id)) return;
    _bumpAfterFrame();
    _persist();
  }

  /// Latch [conversationId] when any of [messageTypes] is a dispatch card.
  /// Used when a conversation's full history arrives, which is the only place
  /// a ride thread can still be recognised after its last message is plain
  /// text.
  static void registerIfRideThread(
      String? conversationId, Iterable<String?> messageTypes) {
    if (conversationId == null || conversationId.isEmpty) return;
    if (_ids.contains(conversationId)) return;
    for (final type in messageTypes) {
      if (type != null && kRideDispatchMessageTypes.contains(type)) {
        register(conversationId);
        return;
      }
    }
  }

  /// Read the current user's latched ids back into memory. Called on entry to
  /// the business chat lists; repeat calls for the same user are no-ops, and a
  /// user switch drops the previous user's ids first.
  static Future<void> ensureHydrated() async {
    final uid = userId;
    if (uid.isEmpty || _hydratedFor == uid) return;
    _hydrating ??= _hydrate(uid);
    await _hydrating;
  }

  static Future<void> _hydrate(String uid) async {
    try {
      // Another user's conversations must not answer for this one.
      if (_hydratedFor != null && _hydratedFor != uid) _ids.clear();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('$_keyPrefix$uid') ?? const <String>[];
      final added = _ids.length;
      _ids.addAll(stored);
      _hydratedFor = uid;
      if (_ids.length != added) revision.value++;
    } catch (_) {
      // Never let a storage hiccup break the chat list — the last-message
      // check still classifies live ride threads.
    } finally {
      _hydrating = null;
    }
  }

  static Future<void> _persist() async {
    final uid = userId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_keyPrefix$uid', _ids.toList());
    } catch (_) {
      // In-memory latch still holds for this session.
    }
  }

  /// [register] can be reached from inside a build (list bucketing), where
  /// writing an `Rx` would mark widgets dirty mid-frame. The row is already
  /// classified correctly this frame, so the notification only has to reach
  /// the NEXT one.
  static void _bumpAfterFrame() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => revision.value = revision.value + 1);
  }
}
