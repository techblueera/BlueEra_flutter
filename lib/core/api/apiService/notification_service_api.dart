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
}
