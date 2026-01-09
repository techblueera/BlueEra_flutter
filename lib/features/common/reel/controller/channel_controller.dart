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
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../personal/auth/controller/view_personal_details_controller.dart';

class ChannelController extends GetxController{
  ApiResponse followUnFollowChannelResponse = ApiResponse.initial('Initial');
  ApiResponse viewChannelResponse = ApiResponse.initial('Initial');
  ApiResponse channelStatsResponse = ApiResponse.initial('Initial');
  ApiResponse videosResponse = ApiResponse.initial('Initial');
  ApiResponse postsResponse = ApiResponse.initial('Initial');
  ApiResponse ReportChannelResponse = ApiResponse.initial('Initial');
  ApiResponse blockUnBlockChannelResponse = ApiResponse.initial('Initial');
  ApiResponse muteUnMuteChannelResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> ownChannelProductsResponse =
      ApiResponse.initial('Initial').obs;
  ApiResponse socialLinksResponse = ApiResponse.initial('Initial');
  ApiResponse updateChannelResponse = ApiResponse.initial('Initial');
  Rx<ChannelData?> channelData =  Rx<ChannelData?>(null);
  Rx<ChannelStats?> channelStats =  Rx<ChannelStats?>(null);
  RxBool isLoading = true.obs;
  RxBool isCollapsed = false.obs;
  int limit = 20;
  RxBool isInitialLoading = true.obs;
  SortBy selectedFilter = SortBy.Latest;
  RxString channelLogo="".obs;
  RxBool isChannelFollow = false.obs;
  bool isMuteChannel = false;


  /// Channel Product data
  RxList<GetProductData> ownProductDataList = <GetProductData>[].obs;
  RxBool isOwnProductDataLoadingMore = false.obs;
  RxBool isOwnProductDataFirstLoading = false.obs;
  int ownProductDataPage = 1;
  bool ownProductDataHasMore = true;

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
  Future<void> updateChannel({
    required Map<String, dynamic> reqData,
    List<Map<String, String>>? socialLinkReqData,
  }) async {
    try {
      if (channelId.isEmpty) {
        commonSnackBar(message: "Channel ID not found");
        return;
      }

      ResponseModel response = await ChannelRepo().updateChannel(
        channelId: channelId,
        bodyRequest: reqData,
      );

      if (response.isSuccess) {
        updateChannelResponse = ApiResponse.complete(response);
        commonSnackBar(
            message: response.message ?? "Channel updated successfully");

        await socialLinksUpdate(id: channelId, reqData: socialLinkReqData);
        final viewProfileController = Get.find<ViewPersonalDetailsController>();
        viewProfileController.viewPersonalProfile();


      } else {
        updateChannelResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      updateChannelResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> socialLinksUpdate(
      {required String id, required List<Map<String, String>>? reqData}) async {
    if (reqData == null || reqData.isEmpty) {
      Get.back(result: true);
      return;
    }

    try {
      channelId = id;
      ResponseModel response =
      await ChannelRepo().updateSocialLinks(bodyRequest: reqData);

      if (response.isSuccess) {
        socialLinksResponse = ApiResponse.complete(response);
        Get.back();
      } else {
        socialLinksResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      socialLinksResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  ///GET CHANNEL DETAILS...
  Future<void> getChannelDetails({required String channelOrUserId}) async {
    try {
      ResponseModel response = await ChannelRepo().getChannelDetails(channelOrUserId: channelOrUserId);

      if (response.isSuccess) {
        ChannelModel channelModel = ChannelModel.fromJson(response.response?.data);
        channelData.value = channelModel.data;
        channelLogo.value=channelData.value?.logoUrl??"";
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

  ///fetchOwnChannelProducts...
  Future<void> fetchOwnChannelProducts({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isOwnProductDataLoadingMore.value || !ownProductDataHasMore) return;
      isOwnProductDataLoadingMore.value = true;
    } else {
      isOwnProductDataFirstLoading.value = true;
      ownProductDataPage = 1;
      ownProductDataHasMore = true;
      ownProductDataList.clear();
    }

    try {

      Map<String, dynamic> queryParams = {
        'DRAFT': false,
        'ownerId': channelId,
        'ownerType': ProviderType.channel.title,
      };


      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsRepo(queryParams: queryParams);
      if (response.isSuccess) {
        ownChannelProductsResponse.value = ApiResponse.complete(response);
        final getProductModel =
        GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData =
            getProductModel.data;

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            ownProductDataList.addAll(newData);
          } else {
            ownProductDataList.assignAll(newData);
          }
          ownProductDataPage++;
        }
      } else {
        ownProductDataHasMore = false;
        ownChannelProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
      ownChannelProductsResponse.value = ApiResponse.error('error');
    } finally {
      if (isLoadMore) {
        isOwnProductDataLoadingMore.value = false;
      } else {
        isOwnProductDataFirstLoading.value = false;
      }
    }
  }

}