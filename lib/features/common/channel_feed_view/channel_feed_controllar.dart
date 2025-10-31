import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_join_list_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';

class ChannelFeedController extends GetxController {
  var channelDataList = <ChannelFeedData>[].obs;
  final channelFeedModel = ChannelFeedModel().obs;
  var isLoading = false.obs;
  var hasMore = true.obs;
  int _page = 1;

  Future<void> fetchChannelData({bool loadMore = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    if (!loadMore) _page = 1;
    final fetchedData = await ChannelRepo().getChannelFollowingMeRepo(
        page: _page, limit: 10); // implement your API fetch
    final data = fetchedData.response?.data;

    late final Map<String, dynamic> json;

    if (data is String) {
      json = jsonDecode(data);
    } else if (data is Map<String, dynamic>) {
      json = data;
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }
    channelFeedModel.value = ChannelFeedModel.fromJson(json);
    final fetched = (json['data'] as List)
        .map((item) => ChannelFeedData.fromJson(item))
        .toList();
    if (fetched.isEmpty) {
      hasMore.value = false;
    } else {
      if (loadMore) {
        channelDataList.addAll(fetched);
      } else {
        channelDataList.assignAll(fetched);
      }
      _page++;
    }
    isLoading.value = false;
  }



  Rx<ApiResponse> followerResponse = ApiResponse.initial('Initial').obs;
  RxList<UserChannelData> userChannelList = <UserChannelData>[].obs;

  ///GET CHANNEL DETAILS...
  Future<void> getChannelMembersController({required String userID}) async {

    try {
      ResponseModel response = await ChannelRepo().getChannelJoinedUserRepo(userId: userID);

      if (response.isSuccess) {
        followerResponse.value = ApiResponse.complete(response);
        ChannelJoinListModel followerResModel = ChannelJoinListModel.fromJson(response.response?.data);
        userChannelList.value = followerResModel.data ?? [];
      }
    } catch (e) {
      followerResponse.value = ApiResponse.error('error');
    }finally{
      // isFollowerLoading.value = false;
    }
  }
}
