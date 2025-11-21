import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class NotificationListRepo extends BaseService {
  Future<ResponseModel> fetchNotificationRepo({required String filterType}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${notificationListApi}?filter=${filterType}",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> deleteNotification({
    required String notifyId,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "${clearNotificationWithId(notifyId)}",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteAllNotification() async {
    final response = await ApiBaseHelper().deleteHTTP(
      clearAllNotification,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> notificationReadRepo(
      {required String notificationId}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${notificationRead}${notificationId}/read",
        params: {
            ApiKeys.notificationId: notificationId
        },
        onError: (error) {},
        onSuccess: (res) {},
        showProgress: false);
    return response;
  }
}
