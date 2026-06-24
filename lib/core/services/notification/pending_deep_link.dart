// Canonical deep-link value object for notification fast-open.
//
// See docs/backend/notification_fast_open_design.md (Phase 1).
//
// One data shape across all FCM pushes. Backward-compatible: the parser reads
// the new `dl_*` fields when the backend sends them, and otherwise derives the
// target from the existing `operation` / `type` string so old payloads keep
// routing exactly as before.

/// Stable set of deep-link targets. Routing/boot decisions branch on these
/// instead of mapping every individual `operation` string.
class DeepLinkTarget {
  static const String chat = 'chat';
  static const String call = 'call';
  static const String post = 'post';
  static const String reel = 'reel';
  static const String connection = 'connection';
  static const String ride = 'ride';
  static const String riderOrder = 'rider_order';
  static const String notificationHub = 'notification_hub';
}

class PendingDeepLink {
  /// dl_target (or derived from `operation`).
  final String target;

  /// conversationId | postId | orderId | callId | senderId ...
  final String entityId;

  /// optional secondary id (repost_id, room_id, message_id ...).
  final String? secondaryId;

  /// The raw FCM data payload, untouched — the existing per-type openers still
  /// read their legacy fields off this map.
  final Map<String, dynamic> raw;

  const PendingDeepLink({
    required this.target,
    required this.entityId,
    this.secondaryId,
    required this.raw,
  });

  /// Chat & call targets need the chat socket connected even when the home
  /// boot is deferred — used by main()'s essential/background split.
  bool get needsSocket =>
      target == DeepLinkTarget.chat || target == DeepLinkTarget.call;

  /// Maps legacy `operation` strings to a [DeepLinkTarget]. Mirrors the switch
  /// in `AppNotificationHandler._onTapNotificationFromStatusBar` so deriving a
  /// target never changes where a notification actually routes. Unknown
  /// operations fall through to the notification hub.
  static String deriveTarget(String operation) {
    switch (operation) {
      // Calls
      case 'incoming_call':
        return DeepLinkTarget.call;

      // Chat / message-like (all open a chat thread)
      case 'missed_call':
      case 'sent_message':
      case 'encrypted_message':
      case 'message_reminder':
      case 'tagged_in_message':
      case 'commented_on_message':
      case 'liked_message':
      case 'rider_otp':
      case 'selfpickup_order':
      case 'selfpickup_order_ready':
      case 'homemade_food_pickup_order':
      case 'homemade_food_pickup_order_ready':
      case 'send_morning_greeting':
      case 'send_nightly_greeting':
        return DeepLinkTarget.chat;

      // Posts
      case 'created_post':
      case 'liked_post':
      case 'commented_on_post':
      case 'reposted_post':
      case 'tagged_on_post':
      case 'reacted_to_post':
      case 'reacted_to_comment':
      case 'replied_on_comment':
        return DeepLinkTarget.post;

      // Reels (currently routed to the hub, kept here for the contract)
      case 'liked_reel':
      case 'commented_on_reel':
      case 'reposted_reel':
      case 'tagged_in_reel':
        return DeepLinkTarget.reel;

      // Rider order surfaced on an active route / fare-ride incoming
      case 'fare_ride_incoming_call':
      case 'route_order_available':
        return DeepLinkTarget.riderOrder;

      // Ride lifecycle
      case 'ride_order_created':
      case 'ride_order_received':
      case 'ride_order_accepted':
      case 'ride_order_picked_up':
      case 'ride_started':
      case 'ride_order_completed':
      case 'ride_completed':
      case 'ride_order_rejected':
      case 'ride_order_all_rejected':
      case 'ride_order_cancelled':
      case 'ride_cancelled_by_rider':
      case 'ride_payment_confirmed':
      case 'rider_onboarding_complete':
        return DeepLinkTarget.ride;

      // Connections / follows
      case 'sent_connection_request':
      case 'received_connection_request':
      case 'accepted_connection_request':
      case 'followed_profile':
      case 'user_enrolled':
        return DeepLinkTarget.connection;

      default:
        return DeepLinkTarget.notificationHub;
    }
  }

  /// Build a [PendingDeepLink] from an FCM data payload. Returns `null` for an
  /// empty payload. Never throws — a malformed payload still yields a hub
  /// target so callers degrade safely.
  static PendingDeepLink? fromData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;

    final dlTarget = (data['dl_target'] ?? '').toString();
    final operation =
        (data['operation'] ?? data['type'] ?? '').toString().toLowerCase();

    final target =
        dlTarget.isNotEmpty ? dlTarget : deriveTarget(operation);

    final entityId = (data['dl_entity_id'] ??
            data['senderId'] ??
            data['post_id'] ??
            data['orderId'] ??
            data['callId'] ??
            '')
        .toString();

    final secondaryId = data['dl_secondary_id']?.toString();

    return PendingDeepLink(
      target: target,
      entityId: entityId,
      secondaryId: (secondaryId != null && secondaryId.isNotEmpty)
          ? secondaryId
          : null,
      raw: data,
    );
  }

  @override
  String toString() =>
      'PendingDeepLink(target: $target, entityId: $entityId, secondaryId: $secondaryId)';
}
