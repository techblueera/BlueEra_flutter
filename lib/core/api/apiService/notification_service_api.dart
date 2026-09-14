/// All `notification-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin NotificationServiceApi {
  final String notificationListApi = "/notification-service/notifications";
  String clearNotificationWithId(String notifyId) =>
      '/notification-service/notifications/$notifyId';
  final String clearAllNotification = '/notification-service/notifications/all';
  final String notificationRead = 'notification-service/notifications/';
  final String notificationSettingsApi =
      'notification-service/notifications/settings';

  /// Campaign engagement reporting (open / click / convert).
  ///
  /// Idempotent server-side — a repeat answers `counted:false` — so the client
  /// never has to de-duplicate. Until this is called, `opened`, `clicked` and
  /// `converted` read zero for every campaign on the admin dashboard.
  final String notificationTrackApi =
      'notification-service/notifications/track';
}
