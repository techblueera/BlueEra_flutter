import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FollowerRepo extends BaseService {
  ///GET FOLLOWER LIST...
  Future<ResponseModel> getFollowerList({
    required String userId,
  }) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      "${followersList}$userId",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET following LIST...
  Future<ResponseModel> getFollowingList({
    required String userId,
  }) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      "${followingList}$userId",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
