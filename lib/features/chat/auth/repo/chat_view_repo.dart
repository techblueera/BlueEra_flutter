import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ChatViewRepo extends BaseService {
  Future<ResponseModel> sendMessageToUser(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        sendMessage,
        isMultipart: true,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> sendGroupMessageToUser(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        sendGroupMessage,
        isMultipart: true,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> sendMessageToUserLargeFile(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        sendDownloadLargeFile,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> sendGroupMessageToUserLargeFile(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        sendDownloadGroupLargeFile,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> syncOfflineMessages(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        sync_offline_messages,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> forwardMessageApi(Map<String, dynamic> params) async {

    final response = await ApiBaseHelper().postHTTP(
        forwardMessage,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> groupForwardMessageApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        groupForwardMessage,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> createNewGroupApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        createGroup,
        isMultipart: true,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getGroupMembersApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        getGroupMembersChat,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> checkChatConnectionApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        checkChatConnection,
        showProgress: true,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> generateUploadUrlsApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        generateUploadUrls,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> generateGroupUploadUrlsApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        generateGroupUploadUrls,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel?> uploadVideoToS3({required Function(double progress) onProgress,required File file, required String fileType, required String preSignedUrl}) async {
    final response = await ApiBaseHelper().uploadVideoToS3(
      preSignedUrl,
      file: file,
      fileType: fileType,
      showProgress: false,
      onProgress: onProgress,
    );
    return response;
  }

  Future<ResponseModel> generateDownloadUrlsApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        generateDownloadUrls,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateSingleMessage(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        updateMessage,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateGroupSingleMessage(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        updateGroupMessage,
        isMultipart: false,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }


  Future<ResponseModel> getChatRequestList() async {
    final response = await ApiBaseHelper()
        .getHTTP(getChatRequest, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getDetailsChatRequestPerson(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper()
        .getHTTP(getChatRequest,
        params: params,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getConnectionsSync(List<Map<String,dynamic>> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(connectionsSync,
        params: jsonEncode(params),
        onError: (error) {}, onSuccess: (data) {},showProgress: false);
    return response;
  }
  Future<ResponseModel> getGroupConnectionsSync(Map<String, dynamic> query) async {
    final response = await ApiBaseHelper()
        .getHTTP(myconnectionsSync,
        params: query,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
    Future<ResponseModel> sendRequestForChat(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(requestForPersonalChat,
        params: params,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> acceptOrDeclineRequest(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(params: params,
        reactChatRequest, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getGroupMember(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .getHTTP(getGroupMembers, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> deleteChatListData(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .deleteHTTP(deleteChatList, onError: (error) {}, onSuccess: (data) {});
    return response;
  }


  Future<ResponseModel> clearAllChatData(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .deleteHTTP(clearAllChat, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> deleteSingleMessage(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .deleteHTTP(deleteMessage,
        params: params,
        showProgress: false,onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> deleteGroupSingleMessage(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .deleteHTTP(deleteGroupMessage,
        params: params,
        showProgress: false,onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> addToPinMultiMessage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(addToPinMessage, onError: (error) {}, onSuccess: (data) {});
    return response;
  }


  Future<ResponseModel> getPinMessageListData(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .getHTTP(getPinMessageList, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> addToStarSingleMessage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(addToStarMessage, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getStarMessageListData(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .getHTTP(getStarMessageList, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getOneToOneMediaMessage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .getHTTP(getOneToOneMedia,
        params: params,onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> addToArchiveChat(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(addToArchive, onError: (error) {}, onSuccess: (data) {});
    return response;
  }


  Future<ResponseModel> likeUnlikeSingleMessage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(messageLikeUnlike,params: params,showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> groupLikeUnlikeSingleMessage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(groupMessageLikeUnlike,params: params,showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
