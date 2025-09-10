import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/reel/models/follow_following_res_model.dart';
import 'package:BlueEra/features/common/reel/repo/follower_repo.dart';
import 'package:get/get.dart';

class FollowerController extends GetxController {
  Rx<ApiResponse> followerResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> followingResponse = ApiResponse.initial('Initial').obs;
  RxList<FollowerData> followerList = <FollowerData>[].obs;
  RxList<FollowingData> followingList = <FollowingData>[].obs;

  RxBool isFollowerLoading = true.obs;
  RxBool isFollowingLoading = true.obs;

  ///GET CHANNEL DETAILS...
  Future<void> getFollowerController({required String userID}) async {

    try {
      ResponseModel response = await FollowerRepo().getFollowerList(userId: userID);

      if (response.isSuccess) {
        followerResponse.value = ApiResponse.complete(response);
        FollowerResModel followerResModel = FollowerResModel.fromJson(response.response?.data);
        followerList.value = followerResModel.data ?? [];
      }
    } catch (e) {
      followerResponse.value = ApiResponse.error('error');
    }finally{
      isFollowerLoading.value = false;
    }
  }

  ///GET CHANNEL DETAILS...
  Future<void> getFollowingController({required String userID}) async {
    try {
      ResponseModel response = await FollowerRepo().getFollowingList(userId: userID);

      if (response.isSuccess) {
        followingResponse.value = ApiResponse.complete(response);
        FollowingResModel followingResModel = FollowingResModel.fromJson(response.response?.data);
        followingList.value = followingResModel.data ?? [];
      }
    } catch (e, s) {
      print('s-- $s');
      followingResponse.value = ApiResponse.error('error');
    } finally{
      isFollowingLoading.value = false;
    }
  }
}
