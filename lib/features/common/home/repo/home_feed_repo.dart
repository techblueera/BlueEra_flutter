import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HomeFeedRepo extends BaseService
{
  Future<ResponseModel> homeFeedRepo({Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().getHTTP(
      homeFeed,
      params:queryParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}