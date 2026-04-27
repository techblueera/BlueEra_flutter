import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ChatClickRepo extends BaseService {
  /// Records a Chat-button tap against a business.
  ///
  /// Fire-and-forget per the integration guide — callers should not await
  /// nor surface errors from this call. `showProgress: false` keeps the
  /// global loader hidden.
  Future<ResponseModel> recordChatClick({
    required String businessId,
    required Map<String, dynamic> body,
  }) async {
    final url = chatClickRecord(businessId);
    final response = await ApiBaseHelper().postHTTP(
      url,
      params: body,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
    return response;
  }
}
