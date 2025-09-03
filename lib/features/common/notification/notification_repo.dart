
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';


class NotificationListRepo extends BaseService {
  Future<ResponseModel> fetchNotification() async {
    final response = await ApiBaseHelper().getHTTP(
      notificationListApi,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> deleteNotification({required String notifyId,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "${clearNotificationWithId(notifyId)}",
      onError: (error) {},
      onSuccess: (res) {},

    );
    return response;
  }Future<ResponseModel> deleteAllNotification() async {
    final response = await ApiBaseHelper().deleteHTTP(
      clearAllNotification,
      onError: (error) {},
      onSuccess: (res) {},

    );
    return response;
  }

}
