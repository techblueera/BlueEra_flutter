import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/reel/models/follow_following_res_model.dart';
import 'package:BlueEra/features/common/reel/repo/follower_repo.dart';
import 'package:get/get.dart';

class FollowerController extends GetxController {
  Rx<ApiResponse> followerResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> followingResponse = ApiResponse.initial('Initial').obs;
  RxList<FollowFollowingData>? followerList = <FollowFollowingData>[].obs;
  RxList<FollowFollowingData>? followingList = <FollowFollowingData>[].obs;

  ///GET CHANNEL DETAILS...
  Future<void> getFollowerController({required String userID}) async {
    try {
      followerList?.clear();
      ResponseModel response =
          await FollowerRepo().getFollowerList(userId: userID);

      if (response.isSuccess) {
        FollowFollowingResModel followerResModel =
            FollowFollowingResModel.fromJson(response.response?.data);
        followerList?.addAll(followerResModel.data ?? []);
        followerResponse.value = ApiResponse.complete(response);
      }
    } catch (e) {
      followerResponse.value = ApiResponse.error('error');
    }
  }

  ///GET CHANNEL DETAILS...
  Future<void> getFollowingController({required String userID}) async {
    try {
      followingList?.clear();
      ResponseModel response =
          await FollowerRepo().getFollowingList(userId: userID);

      if (response.isSuccess) {
        FollowFollowingResModel followerResModel =
            FollowFollowingResModel.fromJson(response.response?.data);
        followingList?.addAll(followerResModel.data ?? []);
        followingResponse.value = ApiResponse.complete(response);
      }
    } catch (e) {
      followingResponse.value = ApiResponse.error('error');
    }
  }
}
