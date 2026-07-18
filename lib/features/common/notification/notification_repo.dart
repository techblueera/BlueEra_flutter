import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class NotificationListRepo extends BaseService {
  Future<ResponseModel> fetchNotificationRepo({
    required String filterType,
    int? page,
    int? limit,
  }) async {
    final buffer = StringBuffer("${notificationListApi}?filter=${filterType}");
    if (page != null) buffer.write("&page=$page");
    if (limit != null) buffer.write("&limit=$limit");
    final response = await ApiBaseHelper().getHTTP(
      buffer.toString(),
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
