// Single entry point for notification deep-link routing.
//
// See docs/backend/notification_fast_open_design.md (Phase 1).
//
// This is intentionally a thin delegator: the per-type routing logic still
// lives in `AppNotificationHandler` (the big switch over `operation`), which is
// already battle-tested. The router exists so that:
//   1. there is ONE place that records the "currently routing" deep link
//      (`AppNotificationHandler.pendingDeepLink`) for the cold-start boot
//      decisions in main.dart, and
//   2. future work can move per-type openers here incrementally without
//      changing call sites.

import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/notification/pending_deep_link.dart';

class NotificationRouter {
  /// Route a parsed deep link to its target screen. Delegates to the existing
  /// `AppNotificationHandler` switch so behaviour is unchanged.
  static Future<void> route(
    PendingDeepLink link, {
    required bool fromColdStart,
  }) {
    AppNotificationHandler.pendingDeepLink = link;
    return AppNotificationHandler.routeNotificationData(
      link.raw,
      fromColdStart: fromColdStart,
    );
  }
}
