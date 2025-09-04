import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/models/channel_stats_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ChannelController extends GetxController{
  ApiResponse followUnFollowChannelResponse = ApiResponse.initial('Initial');
  ApiResponse viewChannelResponse = ApiResponse.initial('Initial');
  ApiResponse channelStatsResponse = ApiResponse.initial('Initial');
  ApiResponse videosResponse = ApiResponse.initial('Initial');
  ApiResponse postsResponse = ApiResponse.initial('Initial');
  ApiResponse ReportChannelResponse = ApiResponse.initial('Initial');
  ApiResponse blockUnBlockChannelResponse = ApiResponse.initial('Initial');
  ApiResponse muteUnMuteChannelResponse = ApiResponse.initial('Initial');
  Rx<ChannelData?> channelData =  Rx<ChannelData?>(null);
  Rx<ChannelStats?> channelStats =  Rx<ChannelStats?>(null);
  RxBool isLoading = true.obs;
  RxBool isCollapsed = false.obs;
  int limit = 20;
  RxBool isInitialLoading = true.obs;
  SortBy selectedFilter = SortBy.Latest;

  RxBool isChannelFollow = false.obs;
  bool isMuteChannel = false;

  Future<void> launchSmartUrl(String url) async {
    Uri uri = Uri.parse(url);

    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final Uri youtubeAppUri = Uri.parse(
        url.contains('youtu.be')
            ? url
            : url.replaceFirst('https://', 'youtube://'),
      );

      if (await canLaunchUrl(youtubeAppUri)) {
        await launchUrl(youtubeAppUri);
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } else if (url.contains('linkedin.com')) {
      final Uri linkedinAppUri = Uri.parse(url.replaceFirst('https://', 'linkedin://'));
      if (await canLaunchUrl(linkedinAppUri)) {
        await launchUrl(linkedinAppUri);
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } else if (url.contains('twitter.com')) {
      final username = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final Uri twitterAppUri = Uri.parse("twitter://user?screen_name=$username");

      if (await canLaunchUrl(twitterAppUri)) {
        await launchUrl(twitterAppUri);
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } else if (url.contains('instagram.com')) {
      final username = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      final Uri instagramAppUri = Uri.parse("instagram://user?username=$username");

      if (await canLaunchUrl(instagramAppUri)) {
        await launchUrl(instagramAppUri);
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } else {
      // Fallback to browser
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  ///GET CHANNEL DETAILS...
  Future<void> getChannelDetails({required String channelOrUserId}) async {
    try {
      ResponseModel response = await ChannelRepo().getChannelDetails(channelOrUserId: channelOrUserId);

      if (response.isSuccess) {
        ChannelModel channelModel = ChannelModel.fromJson(response.response?.data);
        channelData.value = channelModel.data;
        isChannelFollow.value = channelData.value?.isFollowing ?? false;
        // isMuteChannel = channelData.value?.isFollowing ?? false;
        SharedPreferenceUtils.setSecureValue(channelId, channelData.value?.id);
        viewChannelResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewChannelResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      isLoading.value = false;
    }
  }

  ///GET CHANNEL STATS...
  Future<void> getChannelStats({required String channelId}) async {
    try {
      ResponseModel response = await ChannelRepo().getChannelStats(channelId: channelId);

      if (response.isSuccess) {
        channelStatsResponse = ApiResponse.complete(response);
        ChannelStatsModel channelStatsModel = ChannelStatsModel.fromJson(response.response?.data);
        channelStats.value = channelStatsModel.data;
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      channelStatsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      isLoading.value = false;
    }
  }

  ///FOLLOW UNFOLLOW CHANNEL...
  Future<void> followUnfollowChannel({required String channelId, required bool isFollowing}) async {
    try {

      ResponseModel response;
      if(isFollowing) {
        response = await ChannelRepo().unFollowChannel(channelId: channelId);
      }else{
        response = await ChannelRepo().followChannel(channelId: channelId);
      }

      if (response.isSuccess) {
        followUnFollowChannelResponse = ApiResponse.complete(response);
        isChannelFollow.value = !(isChannelFollow.value);
      } else {
        followUnFollowChannelResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      followUnFollowChannelResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///REPORT CHANNEL...
  Future<void> reportChannel({required String channelId, required String reason}) async {
    try {
      Map<String, dynamic> params = {ApiKeys.reason : reason};
      ResponseModel response = await ChannelRepo().channelReport(channelId: channelId, params: params);;

      if (response.isSuccess) {
        ReportChannelResponse = ApiResponse.complete(response);
      } else {
        ReportChannelResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      ReportChannelResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///BLOCK UNBLOCK CHANNEL...
  // Future<void> blockUnblockChannel({required String channelId}) async {
  //   try {
  //
  //     ResponseModel response;
  //     if(!isBlockChannel) {
  //       Map<String, dynamic> params = {ApiKeys.userIdToBlock : channelId};
  //       response = await ChannelRepo().channelBlock(channelId: channelId, params: params);
  //     }else{
  //       Map<String, dynamic> params = {ApiKeys.userIdToUnblock : channelId};
  //       response = await ChannelRepo().channelUnBlock(channelId: channelId, params: params);
  //     }
  //
  //     if (response.isSuccess) {
  //       blockUnBlockChannelResponse = ApiResponse.complete(response);
  //       isBlockChannel = !(isBlockChannel);
  //     } else {
  //       blockUnBlockChannelResponse =  ApiResponse.error('error');
  //       commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     blockUnBlockChannelResponse =  ApiResponse.error('error');
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   }
  // }

  ///MUTE UNMUTE CHANNEL...
  Future<void> muteUnMuteChannel({required String channelId}) async {
    try {

      ResponseModel response;
      if(!isMuteChannel) {
        Map<String, dynamic> params = {ApiKeys.userIdToMute : channelId};
        response = await ChannelRepo().channelMute(channelId: channelId, params: params);
      }else{
        Map<String, dynamic> params = {ApiKeys.userIdToUnmute : channelId};
        response = await ChannelRepo().channelUnMute(channelId: channelId, params: params);
      }

      if (response.isSuccess) {
        muteUnMuteChannelResponse = ApiResponse.complete(response);
        isMuteChannel= !(isMuteChannel);
      } else {
        muteUnMuteChannelResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      muteUnMuteChannelResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

}