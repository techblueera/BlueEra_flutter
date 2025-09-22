import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/services/local_strorage_helper.dart';
import '../../../../core/services/notification_utils.dart';
import '../../view/personal_chat/personal_chat_screen.dart';
import '../model/Generate_Upload_Ulr_Model.dart';
import '../model/GetChatListModel.dart';
import '../model/GetChatRequestListModel.dart';
import '../model/GetListOfMessageData.dart';
import '../model/contactListModel.dart';
import '../model/getChatRequestProfileDetailsModel.dart';
import '../model/getMediaMsgCommentsModel.dart' as cmdImport;
import '../model/getMediaMsgCommentsModel.dart';
import '../model/get_Group_List_Model.dart';
import '../model/view_group_members_model.dart';
import '../model/visit_chat_view_model.dart';
import '../repo/chat_view_repo.dart';
import '../socket/chat_socket.dart';

class ChatViewController extends GetxController {
  Rx<ApiResponse> chatMessageResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> personalChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groupChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfMessageResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getGroupMembersResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> generateUploadUrlResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> chatMessageRequestResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> viewContactsListResponse = ApiResponse.initial('Initial').obs;
  final chatSocket = ChatSocketService();
  Rx<GetChatRequestListModel>? getChatRequestListModel =
      GetChatRequestListModel().obs;
  Rx<GetChatRequestProfileDetailsModel>? getChatRequestProfileDetailsModel =
      GetChatRequestProfileDetailsModel().obs;
  Rx<GetChatListModel>? getPersonalChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getBusinessChatListModel = GetChatListModel().obs;
  Rx<GroupChatListModel>? getGroupChatListModel = GroupChatListModel().obs;
  Rx<GetChatListModel>? getPersonalFilteredChatListModel = GetChatListModel().obs;
  List<Messages>? get getListOfMessageData =>
      getListOfMessageResponse.value.data;
  Rx<ContactListModel>? contactsListModel = ContactListModel().obs;
  Rx<GetMediaMsgCommentsModel>? getMediaMsgCommentsModel =
      GetMediaMsgCommentsModel().obs;
  Rx<TextEditingController> sendMessageController = TextEditingController().obs;
  RxBool isTextFieldEmpty = false.obs;
  RxBool socketConnected = false.obs;
  RxBool socketConnectedCalled = false.obs;
  final ScrollController scrollController = ScrollController();
  Rx<Messages?>? replyMessage = Messages().obs;
  Rx<NewConvoContactVisitDetails?>? newVisitContactApiResponse =
      NewConvoContactVisitDetails().obs;

  // Rx<NewConvMessageData?>? newConvResponse = NewConvMessageData().obs;
  RxString userOnlineStatus = ''.obs;
  RxString userOpenConversationId = ''.obs;
  RxString userOpenUserId = ''.obs;
  RxString readMessageStatus = ''.obs;
  Rx<Messages> sendLoadingFile = Messages().obs;
  RxList selectedUserIds = <String>[].obs;
  RxList<ChatList?> selectedChatList = <ChatList?>[].obs;
  RxList<String> openedConversation = <String>[].obs;
  RxList<Map<String, dynamic>> groupConnections = <Map<String, dynamic>>[].obs;

  Rx<GenerateUploadUlrModel?>? generateUploadUlrModel =
      GenerateUploadUlrModel().obs;
  RxString VideoUploadProgress = ''.obs;
  RxInt selectedChatTabIndex = 0.obs;
  late TabController chatMainTabController;
  final localStorageHelper = LocalStorageHelper();

  void setReplyMessage(Messages? message) {
    replyMessage?.value = message;
  }
  void onSelectChatTab(int index) {
    selectedChatTabIndex.value = index;
  }

  void clearMessageControllerCommon() {
    sendMessageController.value.clear();
    isTextFieldEmpty.value = false;
  }

  Future<void> loadChatListFromLocal(String type) async {
    final localChats = await localStorageHelper.getChatListFromLocal(type);
    getPersonalChatListModel?.value = GetChatListModel(
      success: true,
      chatList: await localChats,
      archived: [],
    );
    personalChatListResponse.value = ApiResponse.complete(getPersonalChatListModel?.value);
  }
  void loadChatListWithType({required GetChatListModel chatListModel,Map<String,dynamic>? data}){
    if(chatListModel.type=="business"){
      getBusinessChatListModel?.value = chatListModel;
      businessChatListResponse.value = ApiResponse.complete(chatListModel);
    }else if (chatListModel.type=="personal"){
      getPersonalChatListModel?.value = chatListModel;
      personalChatListResponse.value = ApiResponse.complete(chatListModel);
    }else if (chatListModel.type=="group"){
      getGroupChatListModel?.value = GroupChatListModel.fromJson(data!);
      groupChatListResponse.value = ApiResponse.complete(getGroupChatListModel?.value);
    }
  }





  void onSearchChatList(String searchQuery) {

    if (selectedChatTabIndex.value == 0) {
      // ✅ Always search on the original full list (not filtered list)
      List<ChatList?>? fullChatList = getPersonalFilteredChatListModel?.value.chatList;

      if (searchQuery.isNotEmpty) {

        List<ChatList?> filteredList = fullChatList
            ?.where((e) => (e?.sender?.name?.toLowerCase().contains(searchQuery) ?? false))
            .toList() ?? [];
        getPersonalChatListModel?.value.chatList = filteredList;
        loadChatListWithType(chatListModel: getPersonalChatListModel!.value);
      } else {
        // if empty query, show full list
        loadChatListWithType(chatListModel: getPersonalFilteredChatListModel!.value);
      }
    } else if (selectedChatTabIndex.value == 1) {
      // same logic for tab 1
    } else if (selectedChatTabIndex.value == 2) {
      // same logic for tab 2
    }
  }

  Future<void> connectSocket() async {
    // if (socketConnectedCalled.value == false) {
      if (socketConnected.value == false) {
        await chatSocket.connectToSocket();
        socketConnected.value = true;
      }
      final connectivityResult = await NetworkUtils.isConnected();
      if (connectivityResult) {
        await loadChatListFromLocal("personal");
      }

      chatSocket.listenEvent('ChatList', (data) async {
        final parsedData = GetChatListModel.fromJson(data);
        loadChatListWithType(chatListModel: parsedData,data: data);
        getPersonalFilteredChatListModel?.value=parsedData;
        await localStorageHelper.saveChatList(parsedData.chatList ?? [],parsedData.type??'');
      });

      chatSocket.listenEvent('messageViewed', (data) {
        getMediaMsgCommentsModel?.value =
            GetMediaMsgCommentsModel.fromJson(data);
      });
      chatSocket.listenEvent('messageReceived', (data) async {


        final parsedData = GetListOfMessageData.fromJson(data);
        
              // Ensure myMessage field is properly set for all messages
      if (parsedData.messages != null) {
        for (var message in parsedData.messages!) {
          if (message.myMessage == null) {
            // Compare sender ID with current logged-in user ID to determine if it's the user's message
            final currentUserId = userId; // Global variable from shared_preference_utils.dart
            final senderId = message.senderId;
            message.myMessage = currentUserId == senderId;
          }
        }
      }
        
        if (parsedData.messages?.isNotEmpty ?? false) {
          final conversationId =
              parsedData.messages?.first.conversationId ?? '';
          if (parsedData.messages != null && conversationId.isNotEmpty) {
            getListOfMessageResponse.value =
                ApiResponse.complete(parsedData.messages);
            scrollDown();
            Future.delayed(Duration.zero, () {
              localStorageHelper.saveMessagesByConversationId(
                  userOpenConversationId.value, parsedData.messages!);
            });
          } else {
            getListOfMessageResponse.value =
                ApiResponse.complete(parsedData.messages);
          }
        } else {
          getListOfMessageResponse.value =
              ApiResponse.complete(parsedData.messages);
        }
      });
      chatSocket.listenEvent('newMessageReceived', (data) {
        Messages? message = Messages.fromJson(data['message']);
  log('personal Data: $message');
       
        if (message.myMessage == null) {
        
          final currentUserId = userId; // Global variable from shared_preference_utils.dart
          final senderId = message.senderId;
          message.myMessage = currentUserId == senderId;
        }

        if (message.conversation?.type == "personal") {
            log('personalMsg Data: $data');
          emitEvent("ChatList", {ApiKeys.type: "personal"}, true);
        } else {
          emitEvent("ChatList", {ApiKeys.type: "business"}, true);
        }
        String chekedConversationId = userOpenConversationId.value;
        if (chekedConversationId == message.conversationId) {
          getListOfMessageData?.add(message); // Add message to UI
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          saveSingleMessageToLocal(message.conversationId ?? '', message);
          scrollDown();
        }
      });
      chatSocket.listenEvent("isOnLine", (data) {
        if (userOpenUserId.value == data['user_id']) {
          if (data['is_online']) {
            userOnlineStatus.value = "Online";
          }
        } else {
          userOnlineStatus.value = "Offline";
        }
      });
      chatSocket.listenEvent("messageStatusUpdate", (data) {

        if (data['conversation_id'] == userOpenConversationId.value) {
          readMessageStatus.value = data['status'];
        }
      });
      chatSocket.listenEvent("update_data", (data) {
        emitEvent("messageReceived", {
          ApiKeys.conversation_id: data[ApiKeys.conversation_id],
          ApiKeys.page: 1,
          ApiKeys.is_online_user: userOpenUserId.value,
          ApiKeys.per_page_message: 30,
        });
      });
      socketConnectedCalled.value = true;
    // }
  }

  Future<void> saveSingleMessageToLocal(String conversationId, Messages msg,
      [Map<String, dynamic>? params]) async {
    final connectivityResult = await NetworkUtils.isConnected();
   
    Future.delayed(Duration.zero, () {
      if (connectivityResult) {
        msg.sendPendingMsgParams = params;
        localStorageHelper.saveSingleMessageToConversationId(
            conversationId, msg,
            sendStatus: "pending");
      } else {
        localStorageHelper.saveSingleMessageToConversationId(
            conversationId, msg);
      }
    });
  }

  Future<void> sendOfflineMessage(
    String conversationId,
  ) async {
    List<Map<String, dynamic>> data =
        await localStorageHelper.getUnsentMessages(conversationId);

    data.reversed;
    if (data.isNotEmpty) {
      Future.delayed(Duration.zero, () async {
        for (int i = 0; i < data.length; i++) {
          if ((data[i]["message_type"] == 'document' ||
                  data[i]["message_type"] == 'text' ||
                  data[i]["message_type"] == 'contact' ||
                  data[i]["message_type"] == 'location') &&
              data[i]['sendPendingMsgParams'] != null) {
            if (data[i]['_id'] != null) {
              sendOfflineMessageToServer(
                  data[i]['sendPendingMsgParams'], data[i]['_id']);
            }
          } else if ((data[i]["message_type"] == 'image' ||
                  data[i]["message_type"] == 'video') &&
              data[i]['sendPendingMsgParams'] != null) {
            List<File> listFiles = [];
            List<dynamic> pendingFilePaths = data[i]['pendingFilePaths'];
            listFiles = pendingFilePaths.map((e) => File(e)).toList();
            await generateUploadUrlsApi(
                params: data[i]['sendPendingMsgParams'],
                listFile: listFiles,
                isInitialMessage: false,
                userId: data[i]['userId'] ?? "",
                conversationId: data[i][ApiKeys.conversation_id],
                commands: data[i]["comments"],
                messageType: data[i]["message_type"],
                isPendingMessage: true,
                messageId: data[i]['_id']);
          }
        }
      });
    }
  }

  Future<bool?> sendOfflineMessageToServer(
      Map<String, dynamic> params, String messageId) async {
    try {
      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }

      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          Messages? msg = getListOfMessageData
              ?.firstWhere((element) => element.id == messageId);
          getListOfMessageData?.remove(msg);
          getListOfMessageData?.add(message);
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          await localStorageHelper.markMessageAsSent(
              params[ApiKeys.conversation_id], messageId);
        }
        scrollDown();
        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
    return null;
  }

  void listenUserNewMessages(
      {required String conversationId, required String userId}) {
    userOpenConversationId.value = conversationId;
    userOpenUserId.value = userId;
    emitEvent("screenRoom", {ApiKeys.conversation_id: "${conversationId}"});
    addConversationOnce(conversationId);
  }

  void addConversationOnce(String conversationId) {
    if (!openedConversation.contains(conversationId)) {
      openedConversation.add(conversationId);
    }
  }

  Future<void> scrollDown() async {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.minScrollExtent);
      }
    });
  }

  Future<void> loadOfflineMessages(String conversationId) async {
    final localMessages =
        await localStorageHelper.getMessagesByConversationId(conversationId);
    getListOfMessageResponse.value = ApiResponse.complete(localMessages);
    scrollDown();
  }

  Future<void> openAnyOneChatFunction(
      {required String conversationId,
      required String? userId,
      required String? type,
      String? profileImage,
      required String? contactName,
      required String? contactNo,
      required bool isInitialMessage,
       String? businessId,
      bool? isFromContactList}) async {

    await getLocalConversation(conversationId, userId);
    if (isFromContactList != null && isFromContactList) {
      Get.off(
        () => PersonalChatScreen(
          type: type,
          isInitialMessage: isInitialMessage,
          userId: userId,
          conversationId: conversationId,
          profileImage: profileImage,
          name: contactName,
          contactNo: contactNo,
          businessId:businessId ,
        ),
      );
    } else {
      Get.to(
        () => PersonalChatScreen(
          type: type,
          isInitialMessage: isInitialMessage,
          userId: userId,
          conversationId: conversationId,
          profileImage: profileImage,
          name: contactName,
          contactNo: contactNo,
          businessId: businessId,
        ),
      );
    }
  }
  Future<void> getLocalConversation(String conversationId, userId) async {
    final connectivityResult = await NetworkUtils.isConnected();
    getListOfMessageResponse.value = ApiResponse.initial('Initial');


    if (connectivityResult) {
      loadOfflineMessages(conversationId);
    }
    else if (openedConversation.contains(conversationId)) {
      loadOfflineMessages(conversationId);
    }
    else {
      emitEvent("messageReceived", {
        ApiKeys.conversation_id: conversationId,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: userId,
        ApiKeys.per_page_message: 30,
      });
    }


  }

  void emitEvent(String event, dynamic data,
      [bool? isFromInitial, String? conversationId]) async {
    if (event == "ChatList" && isFromInitial != true) {
      final connectivityResult = await NetworkUtils.isConnected();
      if (connectivityResult) {
        final localChats = await localStorageHelper.getChatListFromLocal(data[ApiKeys.type]);
        loadChatListWithType(chatListModel: GetChatListModel(
          type: data[ApiKeys.type],
          success: true,
          chatList: await localChats,
          archived: [],
        ));
        return;
      }
    }

    if(event=="messageReceived"&&(conversationId??"")!=userOpenConversationId){


      getListOfMessageResponse.value= ApiResponse.initial('Initial');
    }

    if(event=="ChatList"){
      Map<String,dynamic> dataParams={
        ApiKeys.type:(selectedChatTabIndex.value==0)?"personal":(selectedChatTabIndex.value==1)?"group":"business"
  };
      chatSocket.emitEvent("screenRoom", {ApiKeys.conversation_id: "online"});
      chatSocket.emitEvent(event, dataParams);
    }else{
      chatSocket.emitEvent(event, data);
    }


  }

  void disposeSocket() {
    socketConnectedCalled.value = false;
    chatSocket.disposeSocket();
  }

  List<Map<String, dynamic>>? paramsData;

  Future<void> uploadContacts(List<Map<String, dynamic>> params) async {
    try {
      paramsData = params;
      if(contactsListModel?.value.data==null){
        ResponseModel responseModel =
        await ChatViewRepo().getConnectionsSync(params);
        if (responseModel.isSuccess) {
          final data = responseModel.response?.data;
          contactsListModel?.value = ContactListModel.fromJson(data);
          viewContactsListResponse.value = ApiResponse.complete(responseModel);
        } else {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      }else{

  viewContactsListResponse.value = ApiResponse.complete(contactsListModel?.value);
  }

    } catch (e) {
      viewContactsListResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> loadGroupConnections({int limit = 20, int offset = 0, String? search}) async {
    try {
      viewContactsListResponse.value = ApiResponse.initial('Initial');
      final Map<String, dynamic> query = {
        'limit': limit,
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      ResponseModel responseModel =
          await ChatViewRepo().getGroupConnectionsSync(query);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        List<dynamic>? items;
        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic>) {
          final inner = data['data'];
          if (inner is List) items = inner;
        }
        groupConnections.value = (items ?? []).cast<Map<String, dynamic>>();
        viewContactsListResponse.value = ApiResponse.complete(groupConnections);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        viewContactsListResponse.value = ApiResponse.error(
            responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewContactsListResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> sendRequestForChat(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().sendRequestForChat(params);
      if (responseModel.isSuccess) {
        if (paramsData != null) {
          uploadContacts(paramsData!);
        }
        viewContactsListResponse.value = ApiResponse.complete(responseModel);
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      viewContactsListResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getChatRequestList() async {
    try {
      ResponseModel responseModel = await ChatViewRepo().getChatRequestList();
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        getChatRequestListModel?.value = GetChatRequestListModel.fromJson(data);
        chatMessageRequestResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      chatMessageRequestResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getDetailsChatRequestPerson(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().getDetailsChatRequestPerson(params);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        getChatRequestProfileDetailsModel?.value =
            GetChatRequestProfileDetailsModel.fromJson(data);
        chatMessageRequestResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      chatMessageRequestResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> acceptOrRejectRequest(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().acceptOrDeclineRequest(params);
      if (responseModel.isSuccess) {
        chatSocket.emitEvent("ChatList", {ApiKeys.type: "personal"});
        getChatRequestList();
        chatMessageRequestResponse.value = ApiResponse.complete(responseModel);
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      chatMessageRequestResponse.value = ApiResponse.error('error');
    }
  }

  Future<bool?> sendMessage(Map<String, dynamic> params,
      [List<File>? sendFiles, String? fileName]) async {

    try {
      clearMessageControllerCommon();
      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      if (sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video') {
        sendLoadingFile.value = Messages(
            sendLoadingFile: sendFiles,
            myMessage: true,
            messageType: params[ApiKeys.message_type]);
        getListOfMessageData?.add(sendLoadingFile.value);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
      }
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);
      if (responseModel.isSuccess) {
        if (sendFiles != null &&
            sendFiles.isNotEmpty &&
            params[ApiKeys.message_type] == 'video') {
          Future.delayed(Duration(milliseconds: 200), () {});
          getListOfMessageData?.remove(getListOfMessageData!.last);
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          Future.delayed(Duration(milliseconds: 200), () {});
        }

        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          getListOfMessageData?.add(message);
         
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          saveSingleMessageToLocal(
              params[ApiKeys.conversation_id], message, params);
        } else if (message.subType == 'comment') {
          getMediaMsgCommentsModel?.value.comments?.insert(
              0,
              Comments(
                message: message.message,
                likesCount: 0,
                sender: cmdImport.Sender(
                    name: message.sender?.name,
                    profileImage: message.sender?.profileImage),
                updatedAt: message.updatedAt,
                myComment: true,
              ));
        }

        scrollDown();

        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      clearMessageControllerCommon();
      if (e == "Something went wrong") {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        clearMessageControllerCommon();
        Messages message = Messages(
            docFileName: fileName,
            id: "${isoTime}_${params[ApiKeys.conversation_id]}",
            messageType: params[ApiKeys.message_type],
            sharedContactName: params[ApiKeys.message_type] == "contact"
                ? params[ApiKeys.shared_contact_name]
                : null,
            sharedContactNumber: params[ApiKeys.message_type] == "contact"
                ? params[ApiKeys.shared_contact_number]
                : null,
            sendStatus: "pending",
            message: params[ApiKeys.message],
            latitude: params[ApiKeys.message_type] == "location"
                ? params[ApiKeys.latitude]
                : null,
            longitude: params[ApiKeys.message_type] == "location"
                ? params[ApiKeys.longitude]
                : null,
            myMessage: true,
            conversationId: params[ApiKeys.conversation_id],
            createdAt: isoTime,
            sendPendingMsgParams: params);

        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        saveSingleMessageToLocal(
            params[ApiKeys.conversation_id], message, params);
      }
      if (sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video') {
        getListOfMessageData?.remove(getListOfMessageData!.last);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        Future.delayed(Duration(milliseconds: 200), () {});
      }
    }
    return null;
  }


  Future<bool> forwardMessageApi(
    Map<String, dynamic> params,
  ) async {
    ResponseModel responseModel =
        await ChatViewRepo().forwardMessageApi(params);
    clearMessageControllerCommon();
    if (responseModel.isSuccess) {
      clearMessageControllerCommon();
      return true;
    } else {
      clearMessageControllerCommon();
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return false;
    }
  }
  Future<bool> createGroupApi(
    Map<String, dynamic> params,
  ) async {
    ResponseModel responseModel =
        await ChatViewRepo().createNewGroupApi(params);

    if (responseModel.isSuccess) {
log('responseChat:${responseModel.data}}');
      return true;
    } else {

      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return false;
    }
  }
  Future<void> getGroupMembersApi(
      Map<String, dynamic> params,
      ) async {
    ResponseModel responseModel =
    await ChatViewRepo().getGroupMembersApi(params);

    if (responseModel.isSuccess) {

        // Ensure data is a List
        List dataList = responseModel.data as List;
log("AllMembers:$dataList");
      
        List<GroupMembersListModel> members = dataList
            .map((item) => GroupMembersListModel.fromJson(item))
            .toList();
        getGroupMembersResponse.value = ApiResponse.complete(members);;

    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);

    }
  }

  Future<void> checkChatConnection(Map<String, dynamic> params) async {
    ResponseModel responseModel =
        await ChatViewRepo().checkChatConnectionApi(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      // if (details.data?.conversationStatus== "business") {
      newVisitContactApiResponse?.value =
          NewConvoContactVisitDetails.fromJson(data);
      // } else {
      //   newConvResponse?.value = NewConvMessageData.fromJson(data);
      // }
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
    }
  }

  Future<bool> updateMessageApi(
    Map<String, dynamic> params,
  ) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().updateSingleMessage(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);

        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> sendInitialMessage(Map<String, dynamic> params) async {
    try {

      clearMessageControllerCommon();
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        scrollDown();
        saveSingleMessageToLocal(message.conversationId ?? '', message, params);
        emitEvent("ChatList", {ApiKeys.type: "personal"}, true);
        clearMessageControllerCommon();
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<void> deleteChatMessage(
      Map<String, dynamic> params, String userId) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().deleteSingleMessage(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }

  Future<bool> likeAndUnlikeMessage(
      Map<String, dynamic> params, String userId, String conversationId) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().likeUnlikeSingleMessage(params);
      clearMessageControllerCommon();

      if (responseModel.isSuccess) {
        emitEvent("messageReceived", {
          ApiKeys.conversation_id: conversationId,
          ApiKeys.page: 1,
          ApiKeys.is_online_user: userId,
          ApiKeys.per_page_message: 30,
        });
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> addToPinMessage(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().addToPinMultiMessage(params);
      clearMessageControllerCommon();

      if (responseModel.isSuccess) {
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> generateUploadUrlsApi({
    required Map<String, dynamic> params,
    required List<File> listFile,
    required bool isInitialMessage,
    required String userId,
    required String conversationId,
    required String? commands,
    required String messageType,
    bool? isPendingMessage,
    String? messageId,
  }) async {
    try {
      VideoUploadProgress.value = "0";
      final connectivityResult = await NetworkUtils.isConnected();
      if (listFile.isNotEmpty &&
          messageType == 'video' &&
          (!connectivityResult) &&
          isPendingMessage == null) {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        sendLoadingFile.value = Messages(
            url: listFile.map((e) => MessageMediaUrl(url: e.path)).toList(),
            sendLoadingFile: listFile,
            myMessage: true,
            messageType: messageType,
            createdAt: isoTime);
        getListOfMessageData?.add(sendLoadingFile.value);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
      }
      ResponseModel responseModel =
          await ChatViewRepo().generateUploadUrlsApi(params);
      clearMessageControllerCommon();

      if (!responseModel.isSuccess) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return;
      }

      final data = responseModel.response?.data;
      final uploadModel = GenerateUploadUlrModel.fromJson(data);
      generateUploadUlrModel?.value = uploadModel;

      final files = uploadModel.files;
      if (files?.isEmpty ?? true) return;

      // Parallel Uploads using Future.wait
      await Future.wait(List.generate(files!.length, (i) {
        final file = listFile[i];
        final url = files[i].uploadUrl ?? '';
        final type = files[i].fileType ?? '';
        return uploadFileToS3(file: file, fileType: type, preSignedUrl: url);
      }));

      // Build final URL map
      final List<Map<String, dynamic>> urlList = files.map((element) {
        return {
          "url": element.publicUrl,
          "type": element.fileType,
          "name": element.fileName,
          "size": 0,
          "mimetype": element.fileType,
        };
      }).toList();

      final Map<String, dynamic> messagePayload = {
        if (isInitialMessage)
          ApiKeys.other_user_id: userId
        else
          ApiKeys.conversation_id: conversationId,
        if (commands != null) ApiKeys.message: commands,
        ApiKeys.message_type: messageType,
        ApiKeys.url: urlList,
      };
      sendMessageLargeFile(
          messagePayload, listFile, isPendingMessage, messageId);
      generateUploadUrlResponse.value = ApiResponse.complete(uploadModel);
    } catch (e) {
      clearMessageControllerCommon();
      if (e == "Something went wrong") {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        clearMessageControllerCommon();
        List<String> filePathsList = [];
        listFile.forEach((e) {
          filePathsList.add(e.path);
        });
        Messages message = Messages(
            userId: userId,
            id: "${isoTime}_${params[ApiKeys.conversation_id]}",
            messageType: messageType,
            sendStatus: "pending",
            message: commands,
            myMessage: true,
            conversationId: conversationId,
            createdAt: isoTime,
            pendingFilePaths: filePathsList,
            url: filePathsList
                .map((e) => MessageMediaUrl(
                      url: e,
                    ))
                .toList(),
            sendPendingMsgParams: params);
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);

        saveSingleMessageToLocal(conversationId, message, params);
      }
    }
  }

  Future<bool?> sendMessageLargeFile(Map<String, dynamic> params,
      [List<File>? sendFiles,
      bool? isPendingMessage,
      String? messageId]) async {
    try {
      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUserLargeFile(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
        if (sendFiles != null &&
            sendFiles.isNotEmpty &&
            params[ApiKeys.message_type] == 'video' &&
            isPendingMessage == null) {
          Future.delayed(Duration(milliseconds: 200), () {});
          getListOfMessageData?.remove(getListOfMessageData!.last);
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
        }
        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        if (message.subType != "comment") {
          if (isPendingMessage != null && isPendingMessage) {
            Messages? msg = getListOfMessageData
                ?.firstWhere((element) => element.id == messageId);
            getListOfMessageData?.remove(msg);
            getListOfMessageData?.add(message);
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
            await localStorageHelper.markMessageAsSent(
                params[ApiKeys.conversation_id], messageId ?? "");
          } else {
            getListOfMessageData?.add(message);
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
            scrollDown();
            saveSingleMessageToLocal(
                message.conversationId ?? '', message, params);
          }
        } else if (message.subType == 'comment') {
          getMediaMsgCommentsModel?.value.comments?.insert(
              0,
              Comments(
                message: message.message,
                likesCount: 0,
                sender: cmdImport.Sender(
                    name: message.sender?.name,
                    profileImage: message.sender?.profileImage),
                updatedAt: message.updatedAt,
                myComment: true,
              ));
        }

        scrollDown();

        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      if (sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video') {
        getListOfMessageData?.remove(getListOfMessageData!.last);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        Future.delayed(Duration(milliseconds: 200), () {});
      }
    }
    return null;
  }

  Future<void> uploadFileToS3(
      {required File file,
      required String fileType,
      required String preSignedUrl}) async {
    try {
      ResponseModel? response = await ChatViewRepo().uploadVideoToS3(
          onProgress: (double progress) {
            VideoUploadProgress.value = (progress * 100).toStringAsFixed(2);
          },
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);
      if (response?.isSuccess ?? false) {
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> generateDownloadUrlsApi(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().generateDownloadUrlsApi(params);
      clearMessageControllerCommon();

      if (responseModel.isSuccess) {
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
  }
}
