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

  /// PUT /chat/payment-status — confirm/reject a payment image's status.
  /// See image-is-payment-flutter-integration-guide.md → Updating payment status.
  Future<ResponseModel> updatePaymentStatusApi(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        paymentStatus,
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

  Future<ResponseModel> createNewGroupApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        createGroup,
        isMultipart: true,
        // showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateGroupApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        updateGroup,
        isMultipart: true,
        showProgress: true,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getGroupDetailsApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        getGroupDetails,
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
  Future<ResponseModel> addGroupMembers(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        addGroupMember,
        showProgress: false,
        params: params, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getUserByPhoneApi(String phone) async {
    final response = await ApiBaseHelper().getHTTP(
        getUserByPhone(phone),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> checkChatConnectionApi(Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        checkChatConnection,
        showProgress: false,
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


  Future<ResponseModel?> uploadVideoToS3({required Function(double progress) onProgress, required File file, required String fileType, required String preSignedUrl}) async {
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

  Future<ResponseModel> getChatRequestList() async {
    final response = await ApiBaseHelper()
        .getHTTP(getChatRequest, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  /// `GET chat-service/chat/requests` — symbol-reply originated chat requests.
  ///
  /// [role]: `"incoming"` (default — caller is the recipient) or `"sent"`
  /// (caller is the initiator and wants their durable Sent view). v1.1+.
  Future<ResponseModel> getChatRequestsListApi(
      {int limit = 20, String? nextCursor, String? role}) async {
    final response = await ApiBaseHelper().getHTTP(
      getChatRequestsList,
      showProgress: false,
      params: {
        'limit': limit,
        if (nextCursor != null && nextCursor.isNotEmpty)
          'next_cursor': nextCursor,
        if (role != null && role.isNotEmpty) 'role': role,
      },
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `POST chat-service/chat/requests/respond` — recipient-only.
  /// [action] is `"accept"` or `"decline"`. When declining, optionally
  /// pass [blockInitiator] = true to silently drop future requests from
  /// the same sender (`block_initiator`).
  Future<ResponseModel> respondChatRequestApi({
    required String conversationId,
    required String action,
    bool? blockInitiator,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      chatRequestRespond,
      params: {
        'conversation_id': conversationId,
        'action': action,
        if (blockInitiator == true) 'block_initiator': true,
      },
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `POST chat-service/chat/requests/cancel` — initiator-only. Withdraws
  /// a still-pending request before the recipient acts.
  Future<ResponseModel> cancelChatRequestApi(String conversationId) async {
    final response = await ApiBaseHelper().postHTTP(
      chatRequestCancel,
      params: {'conversation_id': conversationId},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `GET chat-service/chat/requests/{id}` — fetches a single request and
  /// its message history. Either party (initiator OR recipient) can read
  /// while the request is still pending.
  Future<ResponseModel> getChatRequestByIdApi(String conversationId) async {
    final response = await ApiBaseHelper().getHTTP(
      chatRequestById(conversationId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getChatExportAllApi() async {
    final response = await ApiBaseHelper().getHTTP(
      getChatExportAll,
      showProgress: false,
      params: const {'message_limit': 30},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getLatestChatRepo() async {
    final response = await ApiBaseHelper()
        .getHTTP(getLatestChat, onError: (error) {}, onSuccess: (data) {});
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
  Future<ResponseModel> findServiceByContactApi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(findServiceByContact,
        params: params,
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

  Future<ResponseModel> addToPinMultiMessage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(addToPinMessage, onError: (error) {}, onSuccess: (data) {});
    return response;
  }


  Future<ResponseModel> getPinMessageListData(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .getHTTP(getPinMessageList,
        showProgress: true,
        onError: (error) {}, onSuccess: (data) {});
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
  Future<ResponseModel> clearChatHistoryApi(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .deleteHTTP(clearChatHistory,
        params: params,
        showProgress: true,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addPinMessage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .deleteHTTP(clearChatHistory,
        params: params,
        showProgress: true,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> setReminderApi(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper()
        .postHTTP(setReminder,
        params: params,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> checkTrackOrderStatusApi(
     String orderId) async {
    final response = await ApiBaseHelper()
        .getHTTP(
        checkTrackOrderStatus(orderId),
        showProgress: true,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// Same as [checkTrackOrderStatusApi] but without the blocking progress
  /// dialog — used for the silent ongoing-ride restore check on app launch.
  Future<ResponseModel> checkTrackOrderStatusSilentApi(String orderId) async {
    final response = await ApiBaseHelper().getHTTP(
        checkTrackOrderStatus(orderId),
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// Customer-side 10s poll for the rider's live position on an active order.
  /// Silent (no progress dialog) — it fires every 10s. See
  /// docs/backend/RIDER_LOCATION_POLLING_GUIDE.md.
  Future<ResponseModel> getRiderLiveLocationApi(String orderId) async {
    final response = await ApiBaseHelper().getHTTP(
        riderLiveLocationForOrder(orderId),
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

}
