import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FollowingRepo {
  static Future<ResponseModel> getList({required int userId, required int limit, required int offset}) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      'profile/following/$userId?type=following&limit=$limit&offset=$offset', // TODO: Update this URL to the correct endpoint
      params: {},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
