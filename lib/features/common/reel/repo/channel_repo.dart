import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';

class ChannelRepo extends BaseService {
  ///CREATE CHANNEL...
  Future<ResponseModel> createChannel(
      {Map<String, dynamic>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(
      channels,
      params: bodyRequest,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SOCIAL LINKS...
  Future<ResponseModel> updateSocialLinks(
      {List<Map<String, String>>? bodyRequest}) async {
    final response = await ApiBaseHelper().postHTTP(
      socialLinks,
      params: bodyRequest,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get Channel details...
  Future<ResponseModel> getChannelDetails(
      {required String channelOrUserId}) async {
    String getChannelProfile = viewChannelProfile(channelOrUserId);
    final response = await ApiBaseHelper().getHTTP(
      getChannelProfile,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get Channel stats...
  Future<ResponseModel> getChannelStats({required String channelId}) async {
    String stats = channelStats(channelId);
    final response = await ApiBaseHelper().getHTTP(
      stats,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UPLOAD INIT...
  Future<ResponseModel?> uploadInit(
      {required Map<String, dynamic> queryParams, required String? url}) async {
// logs("url=== ${url}");
    print("url=== ${url}");
    // final url="https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/${initUpload}";
    final response = await ApiBaseHelper().getHTTP(
    // final response = await ApiBaseHelper().uploadInitGet(
      url!,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }///UPLOAD INIT...
  Future<ResponseModel?> workmanagerUploadInit(
      {required Map<String, dynamic> queryParams, required String? url}) async {
    final response = await ApiBaseHelper().uploadInitGet(
      url!,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /* ///UPLOAD INIT...
  Future<ResponseModel?> uploadInit({required Map<String, dynamic> queryParams,required String? url }) async {
// logs("url=== ${url}");
print("url=== ${url}");
    // final url="https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/${initUpload}";
    final response = await ApiBaseHelper().getHTTP(
      url!,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }*/

  ///UPLOAD TO S3...
  Future<ResponseModel?> uploadVideoToS3(
      {required Function(double progress) onProgress,
      required File file,
      required String fileType,
      required String preSignedUrl}) async {
    final response = await ApiBaseHelper().uploadVideoToS3(
      preSignedUrl,
      file: file,
      fileType: fileType,
      showProgress: false,
      onProgress: onProgress,
    );
    return response;
  }

  ///UPLOAD VIDEO...
  Future<ResponseModel?> uploadVideo(
      {required Map<String, dynamic> bodyRequest, String? url}) async {
    final response = await ApiBaseHelper().postHTTP(
    // final response = await ApiBaseHelper().workManagerPostHTTP(
      url ?? videoUpload,
      // isMultipart: true,
      showProgress: false,
      params: bodyRequest,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  ///UPLOAD VIDEO...
  Future<ResponseModel?> workManagerUploadVideo(
      {required Map<String, dynamic> bodyRequest, String? url}) async {
    final response = await ApiBaseHelper().workManagerPostHTTP(
      url ??"",
      // isMultipart: true,
      showProgress: false,
      params: bodyRequest,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UPDATE VIDEO DETAILS...
  Future<ResponseModel> updateVideoDetails(
      {required String videoId, required Map<String, dynamic> params}) async {
    String video = videos(videoId);
    final response = await ApiBaseHelper().putHTTP(
      video,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get All users...
  Future<ResponseModel> getAllUsers() async {
    final response = await ApiBaseHelper().getHTTP(
      allUsers,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL Songs...
  Future<ResponseModel> getAllSongs(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      songs,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET FAVOURITE Songs...
  Future<ResponseModel> getAllFavouriteSongs(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      favourite,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///ADD SONG IN FAVOURITE...
  Future<ResponseModel> addSongInFavourite(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      favourite,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///REMOVE SONG FROM FAVOURITE...
  Future<ResponseModel> removeSongFromFavourite(
      {required String songId}) async {
    Map<String, dynamic> params = {
      ApiKeys.songId: songId,
    };
    final response = await ApiBaseHelper().deleteHTTP(
      favourite + '/$songId',
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///CHECK SONG FAVOURITE BY USER...
  Future<ResponseModel> checkSongFavouriteByUser(
      {required String songId}) async {
    // Map<String, dynamic> params = {
    //   'songId' : songId,
    // };
    final response = await ApiBaseHelper().getHTTP(
      checkFavourite + '/$songId',
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SEARCH SONGS...
  Future<ResponseModel> searchSongs(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      songsSearch,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SEARCH FAVOURITE SONGS...
  Future<ResponseModel> searchFavouriteSongs(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      favouriteSearch,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Get Video Categories...
  Future<ResponseModel> getVideoCategories() async {
    final response = await ApiBaseHelper().getHTTP(
      videoCategories,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///ADD SONG IN FAVOURITE...
  Future<ResponseModel> followChannel({required String channelId}) async {
    String followChannel = channelFollow(channelId);
    final response = await ApiBaseHelper().postHTTP(
      followChannel,
      params: {ApiKeys.channelId: channelId},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UnFollow Channel...
  Future<ResponseModel> unFollowChannel({required String channelId}) async {
    String unFollowChannel = channelUnFollow(channelId);
    final response = await ApiBaseHelper().deleteHTTP(
      unFollowChannel,
      params: {ApiKeys.channelId: channelId},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///UPDATE CHANNEL...
  // Future<ResponseModel> updateChannel({
  //   required String channelId,
  //   Map<String, dynamic>? bodyRequest
  // }) async {
  //   final response = await ApiBaseHelper().putHTTP(
  //     '$channels/$channelId',
  //     params: bodyRequest,
  //     isMultipart: true,
  //     onError: (error) {},
  //     onSuccess: (data) {},
  //   );
  //   return response;
  // }

  Future<ResponseModel> updateChannel({
    required String channelId,
    required Map<String, dynamic> bodyRequest,
  }) async {
    return await ApiBaseHelper().putHTTP(
      "${channels}/$channelId",
      params: bodyRequest,
      isArrayReq: true,
    );
  }

  ///GET ALL Channel Videos...
  Future<ResponseModel> getVisitingChannelVideos(
      {required String channelOrUserId,
      required Map<String, dynamic> queryParams}) async {
    String videosChannel = channelVideos(channelOrUserId);
    final response = await ApiBaseHelper().getHTTP(
      videosChannel,
      params: queryParams,
      showProgress: false,
      // showProgress: page == 1 ? true : false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL own Users/Channel Videos...
  Future<ResponseModel> getOwnChannelVideos(
      {required String authorId,
      required Map<String, dynamic> queryParams}) async {
    String videosOwnChannel = ownChannelVideos(authorId);
    final response = await ApiBaseHelper().getHTTP(
      videosOwnChannel,
      params: queryParams,
      showProgress: false,
      // showProgress: page == 1 ? true : false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Fetch Channel Posts...
  Future<ResponseModel> getChannelAllPosts(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      getFilteredPosts,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Channel Report...
  Future<ResponseModel> channelReport(
      {required String channelId, required Map<String, dynamic> params}) async {
    String reportChannel = channelReports(channelId);
    final response = await ApiBaseHelper().postHTTP(
      reportChannel,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Channel User Block...
  Future<ResponseModel> channelBlock(
      {required String channelId, required Map<String, dynamic> params}) async {
    String blockUser = channelBlockUser(channelId);
    final response = await ApiBaseHelper().postHTTP(
      blockUser,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Channel User UnBlock...
  Future<ResponseModel> channelUnBlock(
      {required String channelId, required Map<String, dynamic> params}) async {
    String unBlockUser = channelUnBlockUser(channelId);
    final response = await ApiBaseHelper().postHTTP(
      unBlockUser,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Channel Mute User...
  Future<ResponseModel> channelMute(
      {required String channelId, required Map<String, dynamic> params}) async {
    String muteUser = channelMuteUser(channelId);
    final response = await ApiBaseHelper().postHTTP(
      muteUser,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Channel UnMute User...
  Future<ResponseModel> channelUnMute(
      {required String channelId, required Map<String, dynamic> params}) async {
    String unMuteUser = channelUnMuteUser(channelId);
    final response = await ApiBaseHelper().postHTTP(
      unMuteUser,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Delete VIDEO...
  Future<ResponseModel> deleteVideo({required String videoId}) async {
    String video = videos(videoId);
    final response = await ApiBaseHelper().deleteHTTP(
      video,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET VIDEO DETAILS...
  Future<ResponseModel> getVideoDetails({required String videoId}) async {
    String videoMetaData = videosMetaData(videoId);
    final response = await ApiBaseHelper().getHTTP(
      videoMetaData,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
