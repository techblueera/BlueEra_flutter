import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_join_list_model.dart';
import 'package:BlueEra/features/common/ott/model/all_channel_res_model.dart';
import 'package:BlueEra/features/common/ott/model/ott_channel_video_res_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class ChannelFeedController extends GetxController {
  var channelDataList = <ChannelFeedData>[].obs;
  final channelFeedModel = ChannelFeedModel().obs;
  var isLoading = false.obs;
  var hasMore = true.obs;
  int _page = 1;

  clearList() {
    _page = 1;
    hasMore = true.obs;
    channelDataList.clear();
    unJoinHasMore = true.obs;
    _unJoinPage = 1;
    unJoinChannelDataList.clear();
  }

  Future<void> fetchChannelData({bool loadMore = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    if (!loadMore) _page = 1;
    final fetchedData = await ChannelRepo().getChannelFollowingMeRepo(
        page: _page, limit: 20); // implement your API fetch
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
      ResponseModel response =
          await ChannelRepo().getChannelJoinedUserRepo(userId: userID);

      if (response.isSuccess) {
        followerResponse.value = ApiResponse.complete(response);
        ChannelJoinListModel followerResModel =
            ChannelJoinListModel.fromJson(response.response?.data);
        userChannelList.value = followerResModel.data ?? [];
      }
    } catch (e) {
      followerResponse.value = ApiResponse.error('error');
    } finally {
      // isFollowerLoading.value = false;
    }
  }

  ///UN JOINED CHANNEL LISTING
  var unJoinChannelDataList = <ChannelFeedData>[].obs;
  final unJoinChannelFeedModel = ChannelFeedModel().obs;
  var isUnJoinLoading = false.obs;
  var unJoinHasMore = true.obs;
  int _unJoinPage = 1;

  Future<void> fetchUnJoinChannelData({bool loadMore = false}) async {
    if (isUnJoinLoading.value) return;
    isUnJoinLoading.value = true;

    if (!loadMore) _unJoinPage = 1;
    final fetchedData = await ChannelRepo().getChannelRecommendationsMeRepo(
        page: _unJoinPage, limit: 20); // implement your API fetch
    final data = fetchedData.response?.data;

    late final Map<String, dynamic> json;

    if (data is String) {
      json = jsonDecode(data);
    } else if (data is Map<String, dynamic>) {
      json = data;
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }
    unJoinChannelFeedModel.value = ChannelFeedModel.fromJson(json);
    final fetched = (json['data'] as List)
        .map((item) => ChannelFeedData.fromJson(item))
        .toList();
    if (fetched.isEmpty) {
      unJoinHasMore.value = false;
    } else {
      if (loadMore) {
        unJoinChannelDataList.addAll(fetched);
      } else {
        unJoinChannelDataList.assignAll(fetched);
      }
      _unJoinPage++;
    }
    isUnJoinLoading.value = false;
  }

  /// Toggle follow/unfollow locally (no API call)

  /// Optimistic Follow / Unfollow
  Future<void> toggleFollow({
    required String channelId,
  }) async {
    final index = unJoinChannelDataList.indexWhere((c) => c.id == channelId);
    if (index == -1) return;

    final current = unJoinChannelDataList[index];
    final previousValue = current.isFollowing;
    final newValue = !previousValue;

    // 🔹 1. Instantly update UI
    unJoinChannelDataList[index] = current.copyWith(isFollowing: newValue);

    try {
      // 🔹 2. Fire API silently
      if (newValue) {
        await followUserController(candidateResumeId: channelId);
      } else {
        await unFollowUserController(candidateResumeId: channelId);
      }
    } catch (e) {
      // 🔹 3. Rollback if API fails
      unJoinChannelDataList[index] =
          current.copyWith(isFollowing: previousValue);
      print('Follow/Unfollow API failed: $e');
    }
  }

  /// Actual API calls
  RxBool isChannelJoin = false.obs;

  Future<void> followUserController(
      {required String? candidateResumeId}) async {
    ResponseModel responseModel =
        await UserRepo().channelFollowUser(followUserId: candidateResumeId);
    if (responseModel.isSuccess) {
      isChannelJoin.value = true;
      clearList();

      await fetchChannelData(loadMore: true);

      await fetchUnJoinChannelData(loadMore: true);
    } else {
      isChannelJoin.value = false;
    }
  }

  Future<void> unFollowUserController(
      {required String? candidateResumeId}) async {
    ResponseModel responseModel =
        await UserRepo().channelUnfollowUser(followUserId: candidateResumeId);

    if (responseModel.isSuccess) {
      isChannelJoin.value = false;
      clearList();

      await fetchChannelData(loadMore: true);

      await fetchUnJoinChannelData(loadMore: true);
    } else {
      isChannelJoin.value = true;
    }
  }

  ///GET ALL CHANNEL....
  var allChannelDataList = <AllChannelData>[].obs;
  final allChannelResModel = AllChannelResModel().obs;
  var isAllChannelLoading = false.obs;
  var hasMoreAllChannel = true.obs;
  int _pageAllChannel = 1;

  Future<void> getAllChannelData({bool loadMore = false}) async {
    if (isAllChannelLoading.value) return;
    isAllChannelLoading.value = true;

    if (!loadMore) _pageAllChannel = 1;
    final fetchedData = await ChannelRepo().getAllChannelRepo(
        page: _pageAllChannel, limit: 20); // implement your API fetch
    final data = fetchedData.response?.data;

    late final Map<String, dynamic> json;

    if (data is String) {
      json = jsonDecode(data);
    } else if (data is Map<String, dynamic>) {
      json = data;
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }
    allChannelResModel.value = AllChannelResModel.fromJson(json);
    final fetched = (json['data'] as List)
        .map((item) => AllChannelData.fromJson(item))
        .toList();
    if (fetched.isEmpty) {
      hasMoreAllChannel.value = false;
    } else {
      if (loadMore) {
        allChannelDataList.addAll(fetched);
      } else {
        allChannelDataList.assignAll(fetched);
      }
      _pageAllChannel++;
    }
    isAllChannelLoading.value = false;
  }

  var allVideoChannelDataList = <VideoItems>[].obs;
  final allVideoChannelResModel = OttChannelVideoResModel().obs;
  var isAllVideoChannelLoading = false.obs;
  var hasMoreAllVideoChannel = true.obs;
  int _pageAllVideoChannel = 1;

  Future<void> getAllChannelVideoData({bool loadMore = false,required String channelId}) async {
    if (isAllVideoChannelLoading.value) return;
    isAllVideoChannelLoading.value = true;

    if (!loadMore) _pageAllVideoChannel = 1;
    final fetchedData = await ChannelRepo().getAllVideoChannelRepo(
        page: _pageAllVideoChannel, limit: 20, channelID: channelId); // implement your API fetch
        // page: _pageAllVideoChannel, limit: 20, channelID: "68ea37d8c86a4e2c382e2a4d"); // implement your API fetch
    final data = fetchedData.response?.data;

    late final Map<String, dynamic> json;

    if (data is String) {
      json = jsonDecode(data);
    } else if (data is Map<String, dynamic>) {
      json = data;
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }
    allVideoChannelResModel.value = OttChannelVideoResModel.fromJson(json);

    if (allVideoChannelResModel.value.videos?.items?.isEmpty ?? false) {
      hasMoreAllVideoChannel.value = false;
    } else {
      if (loadMore) {
        allVideoChannelDataList
            .addAll(allVideoChannelResModel.value.videos?.items ?? []);
      } else {
        allVideoChannelDataList
            .assignAll(allVideoChannelResModel.value.videos?.items ?? []);
      }
      _pageAllVideoChannel++;
    }
    isAllVideoChannelLoading.value = false;
  }
}
