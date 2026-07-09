import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';
import 'package:BlueEra/features/chat/auth/model/business_service_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/education_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/food_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/health_care_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/business_enquiry_model.dart';
import 'package:BlueEra/features/chat/auth/model/education_enquiry_model.dart';
import 'package:BlueEra/features/chat/auth/model/healthcare_enquiry_model.dart';
import 'package:BlueEra/features/chat/auth/model/hotel_enquiry_model.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:BlueEra/features/chat/auth/model/service_ask_ai_model.dart';
import 'package:BlueEra/features/chat/auth/model/travel_and_stay_ask_ai_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/check_internet_connectivity.dart';
import '../../../../core/services/chat_media_storage_service.dart';
import '../../../../core/services/local_strorage_helper.dart';
import '../../../../core/services/pending_message_drainer.dart';
import '../../../personal/personal_profile/model/check_chat_connection_model.dart';
import '../../view/business_chat/business_chat_screen_updated.dart';
import '../../view/group_chat/group_chat_screen.dart';
import '../../view/personal_chat/personal_chat_screen.dart';
import '../model/Generate_Upload_Ulr_Model.dart';
import '../model/GetChatListModel.dart';
import '../model/GetChatListModel.dart' as chatListModel;
import '../model/ChatRequestsListModel.dart';
import '../model/GetChatRequestListModel.dart';
import '../model/GetListOfMessageData.dart';
import '../model/GetListOfMessageData.dart' as messageModel;
import 'package:BlueEra/features/me/vehicle/model/vehicle_booking_models.dart';
import '../model/ai_chat_history_msg_model.dart';
import '../model/ai_chat_reply_msg_model.dart';
import '../model/chat_language.dart';
import 'ai_chat_profile_controller.dart';
import '../model/contactListModel.dart';
import '../model/find_service_by_contact_model.dart';
import '../model/user_by_phone_model.dart';
import '../../view/widget/phone_user_bottom_sheet.dart';
import '../model/getChatRequestProfileDetailsModel.dart';
import '../model/getMediaMsgCommentsModel.dart' as cmdImport;
import '../model/getMediaMsgCommentsModel.dart';
import '../model/group_details_model.dart';
import '../model/inventory_ask_ai_model.dart';
import '../repo/chat_view_repo.dart';
import 'payment_qr_controller.dart';
import '../socket/ai_socket.dart';
import '../socket/chat_socket.dart';
import '../socket/live_location_track_socket.dart';

class ChatViewController extends GetxController {
  Rx<ApiResponse> chatMessageResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> personalChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> businessChatListResponse = ApiResponse.initial('Initial').obs;
  // Conversations the server has aged out of `business` into `history` (12h
  // after creation). Fetched via ChatList { type: "history" }.
  Rx<ApiResponse> historyChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groupChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> orderChatListResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfMessageResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfAiMessageResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfInventoryAiMessageResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getGroupMembersResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getServiceByContactResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> generateUploadUrlResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> chatMessageRequestResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groupDetailsResponse =
      ApiResponse.initial('Initial').obs;
  RxInt personalTabSelectedIndex=0.obs;
  RxInt businessChatTabSelectedIndex=0.obs;
  Rx<ApiResponse> viewContactsListResponse = ApiResponse.initial('Initial').obs;
  final chatSocket      = ChatSocketService();
  final aiSocket        = AiSocketService();

  /// Whether the user has scrolled up away from the bottom of the chat.
  RxBool isUserScrolledUp = false.obs;

  /// Count of new messages that arrived while the user was scrolled up.
  RxInt unreadNewMessageCount = 0.obs;
  Rx<GetChatRequestListModel>? getChatRequestListModel =
      GetChatRequestListModel().obs;

  /// Symbol-reply chat requests — `GET chat-service/chat/requests`.
  ///
  /// Incoming view (default `role=incoming`) — caller is the **recipient**.
  Rx<ChatRequestsListModel> chatRequestsListModel =
      ChatRequestsListModel().obs;
  Rx<ApiResponse> chatRequestsListResponse =
      ApiResponse.initial('Initial').obs;

  /// Sent view (`role=sent`) — caller is the **initiator**, surfaces the
  /// durable list of outgoing requests they're still waiting on. Without
  /// this view there is no server-backed way for the initiator to recover
  /// their pending requests after a reload (they're filtered out of
  /// `latestChat`). See guide §2.2.
  Rx<ChatRequestsListModel> sentChatRequestsListModel =
      ChatRequestsListModel().obs;
  Rx<ApiResponse> sentChatRequestsListResponse =
      ApiResponse.initial('Initial').obs;
  Rx<GetChatRequestProfileDetailsModel>? getChatRequestProfileDetailsModel =
      GetChatRequestProfileDetailsModel().obs;
  RxBool showMentionList = false.obs;
  RxString mentionQuery = "".obs;
  RxList<GroupMembersListModel> filteredMembers = <GroupMembersListModel>[].obs;
  RxList<String> taggedUserIds = <String>[].obs;
  Rx<GroupDetailsModel> groupDetailsModel=GroupDetailsModel().obs;

  static final Map<String, dynamic> aiChatListModel = {
    "last_message": "Ask anything with friend",
    "last_message_type": "text",
    "sender": {
      "name": "BlueEra Friend",
      "contact_no": "BlueEra Friend",
      "profile_image":AppImageAssets.app_logo,
      "account_type": AppConstants.personal_Chat_Type,
    }
  };

  static final Map<String, dynamic> businessAiChatListModel = {
    "last_message": "Ask anything about business",
    "last_message_type": "text",
    "sender": {
      "name": "Ask BlueEra Ai",
      "contact_no": "BlueEra Friend",
      "profile_image":
          AppImageAssets.app_logo,
      "account_type": AppConstants.business_Chat_Type,
    }
  };
  static final Map<String, dynamic> aiChatSearch = {
    "last_message": "Ask anything with blueEra friend",
    "last_message_type": "text",
    "sender": {
      "name": "BlueEra Friend",
      "contact_no": "BlueEra Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.search_Chat_Type,
    }
  };
  static final Map<String, dynamic> inventoryAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Inventory Friend",
      "profile_image":
          AppImageAssets.app_logo,
      "account_type": AppConstants.askInventory_Chat_Type,
    }
  };
  static final Map<String, dynamic> foodAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Food Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askFood_Chat_Type,
    }
  };
  static final Map<String, dynamic> serviceAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Service Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askService_Chat_Type,
    }
  };
  static final Map<String, dynamic> healthCareAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Health Care Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askHealthCare_Chat_Type,
    }
  };
  static final Map<String, dynamic> educationAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Education Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askEducation_Chat_Type,
    }
  };
  static final Map<String, dynamic> homeServiceAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Home Service Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askHomeService_Chat_Type,
    }
  };
  static final Map<String, dynamic> travelAndStayAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Travel and Stay Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askTravelStay_Chat_Type,
    }
  };
  static final Map<String, dynamic> consultingTalkAiSearch = {
    "last_message": "Ask anything with Inventory Friend",
    "last_message_type": "text",
    "sender": {
      "name": "Sarthi Ai",
      "contact_no": "BlueEra Consulting Talk Friend",
      "profile_image":
      AppImageAssets.app_logo,
      "account_type": AppConstants.askConsultingTalk_Chat_Type,
    }
  };
  static final ChatList? personalAiChatModule =
      ChatList.fromJson(aiChatListModel);
  static final ChatList? businessAiChatModule =
      ChatList.fromJson(businessAiChatListModel);
  static final ChatList? aiChatListSearchModule =
      ChatList.fromJson(aiChatSearch);
  static final ChatList? inventoryAiChatListSearchModule =
      ChatList.fromJson(inventoryAiSearch);
  static final ChatList? foodAiChatListSearchModule =
      ChatList.fromJson(foodAiSearch);
  static final ChatList? serviceAiChatListSearchModule =
      ChatList.fromJson(serviceAiSearch);
  static final ChatList? healthCareAiChatListSearchModule =
      ChatList.fromJson(healthCareAiSearch);
  static final ChatList? educationAiChatListSearchModule =
     ChatList.fromJson(educationAiSearch);
  static final ChatList? homeServiceAiChatListSearchModule =
      ChatList.fromJson(homeServiceAiSearch);
  static final ChatList? travelAndStayAiChatListSearchModule =
     ChatList.fromJson(travelAndStayAiSearch);
  static final ChatList? consultingTalkAiChatListSearchModule =
     ChatList.fromJson(consultingTalkAiSearch);

  /// Synthetic row for the pinned "BlueEra" system chat that surfaces broadcast
  /// / system notifications (profile updates, admin announcements, etc.) as a
  /// chat thread. Client-side only — its preview/unread are driven live by
  /// [BlueEraNotificationController]. Mirrors the AI-row pattern above.
  static final Map<String, dynamic> blueEraNotificationChatModel = {
    "conversation_id": "blueera_notifications",
    "last_message": "Tap to view your BlueEra notifications",
    "last_message_type": "text",
    "sender": {
      "name": "BlueEra",
      "contact_no": "BlueEra",
      "profile_image": AppImageAssets.app_logo,
      "account_type": AppConstants.personal_Chat_Type,
    }
  };
  static final ChatList? blueEraNotificationModule =
      ChatList.fromJson(blueEraNotificationChatModel);

  Rx<GetChatListModel>? getPersonalChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getOrderChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getBusinessChatListModel = GetChatListModel().obs;
  // History bucket — business conversations older than 12h. Same payload
  // shape as [getBusinessChatListModel]; rendered in the Business "History"
  // sub-tab.
  Rx<GetChatListModel>? getHistoryChatListModel = GetChatListModel().obs;

  /// Type of the most recent `ChatList` socket emit (`personal` |
  /// `business` | `order` | `group`). Used as a fallback when the server
  /// response omits `type` so we can still route the payload into the
  /// correct Rx model. Set inside [emitEvent] right before the socket emit.
  String? _pendingChatListType;
  Rx<GetChatListModel>? getGroupChatListModel = GetChatListModel().obs;
  Rx<GetChatListModel>? getPersonalFilteredChatListModel =
      GetChatListModel().obs;

  List<Messages>? get getListOfMessageData =>
      getListOfMessageResponse.value.data;
  RxList<InventoryAskAiModel> getListOfInventoryAiMessages = <InventoryAskAiModel>[].obs;

  Rx<ContactListModel>? contactsListModel = ContactListModel().obs;
  Rx<GetMediaMsgCommentsModel>? getMediaMsgCommentsModel =
      GetMediaMsgCommentsModel().obs;
  RxList<ProfessionalContact> findProfessionalContactList = <ProfessionalContact>[].obs;
  Rx<TextEditingController> sendMessageController = TextEditingController().obs;

  /// The `route` lane to attach to outgoing 1:1 sends — `contact` (personal)
  /// or `discover` (business). Set whenever a chat screen is opened (see
  /// [_navigateToChatScreen] / [checkChatConnectionAndOpenChat] and the chat
  /// screens' initState). `null` means "send no route" → legacy backend
  /// inference. Attached to send params via [attachRouteParam].
  String? activeRoute;

  /// Inject [activeRoute] into a send-message param map (idempotent — never
  /// overwrites an explicit `route` already present, and no-ops when no lane
  /// is active so legacy sends stay route-less).
  void attachRouteParam(Map<String, dynamic> params) {
    final route = activeRoute;
    if (route != null && route.isNotEmpty && !params.containsKey(ApiKeys.route)) {
      params[ApiKeys.route] = route;
    }
  }

  RxBool isTextFieldEmpty = false.obs;
  RxBool isSending = false.obs;
  RxBool socketConnected = false.obs;
  RxBool chatFromBusinessProfile = false.obs;
  RxBool canPopBusiness = false.obs;
  RxBool socketConnectedCalled = false.obs;
  final ScrollController scrollController = ScrollController();
  Rx<Messages?>? replyMessage = Messages().obs;

  RxString userOnlineStatus = 'Offline'.obs;
  RxString userOpenConversationId = ''.obs;
  RxString userOpenUserId = ''.obs;
  RxString readMessageStatus = ''.obs;

  /// Pagination state for the currently-open conversation. The initial
  /// `messageReceived` emit asks the server for 30 messages; when the user
  /// scrolls to the top of the list we bump this by 30 and re-emit.
  RxInt currentMessagePageSize = 30.obs;
  RxBool isLoadingMoreMessages = false.obs;
  static const int _messagePageStep = 30;
  // Cached params so loadMoreMessages can rebuild the exact emit payload.
  String? _currentChatOtherUserId;

  /// The id of the person currently being chatted with (the conversation
  /// person), independent of message direction. Used e.g. to fetch their UPI
  /// details for the payment QR.
  String? get currentChatOtherUserId => _currentChatOtherUserId;
  String? _currentChatName;
  String? _currentChatUserIdForOnline;

  /// Cached set of online user IDs — survives chat list re-renders.
  RxSet<String> onlineUserIds = <String>{}.obs;

  /// Last-seen timestamps keyed by conversation ID.
  RxMap<String, String> lastSeenMap = <String, String>{}.obs;

  // Typing indicator state
  RxString typingText = ''.obs;
  Timer? _typingDebounceTimer;
  final Map<String, Timer> _typingHideTimers = {};

  /// Per-conversation typing indicator for the chat list.
  /// Key = conversation_id, Value = typer's name.
  RxMap<String, String> typingByConversation = <String, String>{}.obs;
  final Map<String, Timer> _chatListTypingTimers = {};
  RxInt selectedIndex =0.obs;

  Rx<Messages> sendLoadingFile = Messages().obs;
  RxList selectedUserIds = <String>[].obs;
  RxList<ChatList?> selectedChatList = <ChatList?>[].obs;
  RxList<String> openedConversation = <String>[].obs;
  // Conversations whose pending queue is currently being drained. The drainer
  // (on connectivity change) and getLocalConversation (on chat reopen) can both
  // fire sendOfflineMessage nearly simultaneously; without this guard the same
  // pending row gets retried twice, so the server receives each queued message
  // twice.
  final Set<String> _drainingConversations = <String>{};
  RxList<Map<String, dynamic>> groupConnections = <Map<String, dynamic>>[].obs;
  List<Messages>? getListOfAiMessageData = [];
  Rx<GenerateUploadUlrModel?>? generateUploadUlrModel =
      GenerateUploadUlrModel().obs;
  RxString VideoUploadProgress = ''.obs;
  RxInt selectedChatTabIndex = 0.obs;
  TabController? chatMainTabController;
  final localStorageHelper = LocalStorageHelper();
  RxInt businessTabIndexSelected = 0.obs;
  RxBool chatBotReading = false.obs;
  RxBool viewAllMembers = false.obs;

  // Chat list selection mode (WhatsApp-style long press)
  RxBool isChatListSelectionMode = false.obs;
  RxList<String> selectedConversationIds = <String>[].obs;
  RxList<ChatList?> selectedChatItems = <ChatList?>[].obs;

  void toggleChatListSelection(ChatList? chat) {
    final convId = chat?.conversationId ?? '';
    if (convId.isEmpty) return;
    if (selectedConversationIds.contains(convId)) {
      selectedConversationIds.remove(convId);
      selectedChatItems.removeWhere((c) => c?.conversationId == convId);
    } else {
      selectedConversationIds.add(convId);
      selectedChatItems.add(chat);
    }
    if (selectedConversationIds.isEmpty) {
      isChatListSelectionMode.value = false;
    }
  }

  void exitChatListSelectionMode() {
    isChatListSelectionMode.value = false;
    selectedConversationIds.clear();
    selectedChatItems.clear();
  }

  void selectAllChats(List<ChatList?> allChats) {
    selectedConversationIds.clear();
    selectedChatItems.clear();
    for (final chat in allChats) {
      if (chat?.conversationId != null) {
        selectedConversationIds.add(chat!.conversationId!);
        selectedChatItems.add(chat);
      }
    }
  }

  File? editedGroupFile;
  File? editedGroupCoverFile;
  RxBool isPublicGroup = false.obs;
  RxBool isDeleteBtnLoading = false.obs;
  RxBool isPinMessageLoading = false.obs;
  RxBool isEditGroupBtnLoading = false.obs;
  final groupNameController=TextEditingController();
  final groupDescriptionController=TextEditingController();

  RxInt groupChatScreenSelectedTab = 0.obs;
  final RxInt selectedDays = 1.obs;
  final List<String> tabs = [
    'Chat',
    'History',
    'Products',
    'Ourview',
    'Payments'
  ];

  /// Index of the "Payments" (payments-received) tab in [tabs].
  int get paymentsTabIndex => tabs.indexOf('Payments');

  /// Index of the "History" tab in [tabs] — aged-out (`type:"history"`)
  /// business threads with the currently-open business.
  int get historyTabIndex => tabs.indexOf('History');

  /// Index of the "Products" tab in [tabs].
  int get productsTabIndex => tabs.indexOf('Products');

  /// Index of the "Ourview" tab in [tabs].
  int get ourViewTabIndex => tabs.indexOf('Ourview');


  String productInitialMessage = 'Looking for the right product? Find TVs, refrigerators, washing machines & smartphones. Browse kitchen appliances, home essentials, electronics & gifts. All from trusted sellers near you. Just tell me what you’re looking for, and I’ll take care of the rest.';

  Future<void> disposeAiSocket() async {
    aiSocket.disposeSocket();
  }

  String formattedDate() {
    final now = DateTime.now().toUtc();
    return "${now.toIso8601String().substring(0, 23)}Z";
  }

  Future<bool?> clearChatHistory(Map<String, dynamic> params) async {
    try {
      isDeleteBtnLoading.value=true;
      ResponseModel responseModel =
      await ChatViewRepo().clearChatHistoryApi(params);

      if (responseModel.isSuccess) {
        isDeleteBtnLoading.value=false;
        getListOfMessageData?.clear();
         getListOfMessageResponse.value =ApiResponse.complete(getListOfMessageData);
        return true;
      } else {
        isDeleteBtnLoading.value=false;

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isDeleteBtnLoading.value=false;

      commonSnackBar(message: e.toString());
    }
    return null;
  }
  void parseAiChatHistory(List<dynamic> jsonList) {
    for (var item in jsonList) {
      final details = AiChatHistoryMessageModel.fromJson(item);
      getListOfAiMessageData?.add(
        Messages(
          sendStatus: AppStrings.PersonalChatAi,
          status: "read",
          messageRead: 1,
          message: details.content,
          // Use details.content for text
          conversationId: details.id,
          // Or details.conversationId if exists
          myMessage: details.role == "user",
          // Mark user's messages
          createdAt: details.timestamp,
          messageType: "text",
        ),
      );
    }

    getListOfAiMessageResponse.value =
        ApiResponse.complete(getListOfAiMessageData);
  }

  Future<void> sendMessageToAiSocket({
    String? conversationId,
    required String type,
    String? message,
    String? tag,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    chatBotReading.value = true;
    String? converId = await AiChatLocalStorage.getConversationId(
        type
    );
    aiSocket.sendMessage(
        message: message,
        conversationId: converId,
        imageBytes: imageBytes,
        mimeType: mimeType);
    getListOfAiMessageData?.add(Messages(
        sendStatus: AppStrings.PersonalChatAi,
        messageRead: 1,
        message: message,
        status: "read",
        conversationId: conversationId,
        myMessage: true,
        createdAt: formattedDate(),
        messageType: "text")); // Add message to UI

    getListOfAiMessageResponse.value =
        ApiResponse.complete(getListOfAiMessageData);
    sendMessageController.value.clear();
  }

  /// Select / switch the language the AI replies in for this [type]'s
  /// conversation. Sends the `language=<Label>` directive over the socket (no
  /// new endpoint needed) and optimistically updates the badge; the lock is
  /// confirmed by `language` on the next [AiReplyMessageModel] reply.
  Future<void> changeAiLanguage({
    required String type,
    required String label,
  }) async {
    // Optimistic badge update so the UI reflects the choice immediately.
    _syncAiLanguage(type, label);

    final String? converId = await AiChatLocalStorage.getConversationId(type);
    chatBotReading.value = true;
    aiSocket.sendMessage(
      message: languageDirective(label),
      conversationId: converId,
    );
  }

  /// Persist and reactively publish the active AI language for [type] so the
  /// AppBar badge stays in sync (from either a user selection or a server echo).
  void _syncAiLanguage(String type, String label) {
    final profileCtrl = Get.isRegistered<AiChatProfileController>()
        ? Get.find<AiChatProfileController>()
        : Get.put(AiChatProfileController());
    profileCtrl.setLanguage(type, label);
  }

  Future<void> connectAiSocket(String type) async {
    getListOfAiMessageData?.clear();
    aiSocket.disposeSocket();
    await aiSocket.connect();

    aiSocket.onMessage((data) {
      chatBotReading.value = false;
      AiReplyMessageModel details = AiReplyMessageModel.fromJson(data);
      saveAiConversationId(details.conversationId, type);
      // Backend echoes the active language lock; keep the badge in sync with it.
      if (details.language != null && details.language!.isNotEmpty) {
        _syncAiLanguage(type, details.language!);
      }
      getListOfAiMessageData?.add(Messages(
          sendStatus: AppStrings.PersonalChatAi,
          messageRead: 1,
          status: "read",
          message: details.reply,
          conversationId: details.conversationId,
          myMessage: false,
          createdAt: details.timestamp,
          messageType: "text"));
      getListOfAiMessageResponse.value =
          ApiResponse.complete(getListOfAiMessageData);
    });
    aiSocket.onHistory((data) {
      parseAiChatHistory(data);
    });
    String? converId = await AiChatLocalStorage.getConversationId(
        type
    );

    aiSocket.getHistory(converId ?? '');
    getListOfAiMessageResponse.value =
        ApiResponse.complete(getListOfAiMessageData);
  }

  /// Clears the local AI chat history for [type]: drops the stored
  /// conversation id (so a fresh thread starts) and reconnects the socket,
  /// which clears the on-screen messages and reloads an empty history.
  Future<void> clearAiChat(String type) async {
    try {
      await AiChatLocalStorage.clearConversationId(type);
    } catch (_) {}
    getListOfAiMessageData?.clear();
    getListOfAiMessageResponse.value =
        ApiResponse.complete(getListOfAiMessageData);
    await connectAiSocket(type);
  }

  Future<void> saveAiConversationId(String id, String type) async {
    await AiChatLocalStorage.saveConversationIdIfEmpty(
        id: id,
        type: type);
  }

  String _getInitialMessageText(String type) {
    switch (type) {
      case AppConstants.askInventory_Chat_Type:
        return AppStrings.aiChatInventory.tr;

      case AppConstants.askFood_Chat_Type:
        return AppStrings.aiChatFood.tr;

      case AppConstants.askService_Chat_Type:
        return AppStrings.aiChatService.tr;

      case AppConstants.askHealthCare_Chat_Type:
        return AppStrings.aiChatHealthCare.tr;

      case AppConstants.askEducation_Chat_Type:
        return AppStrings.aiChatEducation.tr;

      case AppConstants.askHomeService_Chat_Type:
        return AppStrings.aiChatHomeService.tr;

      case AppConstants.askTravelStay_Chat_Type:
        return AppStrings.aiChatTravelStay.tr;

      case AppConstants.askConsultingTalk_Chat_Type:
        return AppStrings.aiChatConsulting.tr;

      default:
        return AppStrings.aiChatDefault.tr;
    }
  }

  RxList<BaseAiChatModel> currentChatMessages = <BaseAiChatModel>[].obs;

  Future<void> connectSearchAiSocket(String type) async {
    chatBotReading.value = true;
    currentChatMessages.clear();
    aiSocket.disposeSocket();
    await aiSocket.connectSearchSocket();

    String? converId = await AiChatLocalStorage.getConversationId(type);

    // --- HISTORY LISTENER ---
    aiSocket.onHistory((data) {
      if (data is List) {
        List<BaseAiChatModel> history = data.map((jsonItem) {
          return _parseDataByType(type, jsonItem as Map<String, dynamic>);
        }).toList();

        currentChatMessages.assignAll(history);
      }
      // else if (data == null || (data is List && data.isEmpty)) {
      //   // 🟢 CASE 1: NO HISTORY -> Show Predefined Message
      //   BaseAiChatModel welcomeMsg = _createInitialModel(type);
      //   currentChatMessages.add(welcomeMsg);
      //
      //   log('➕ Added Initial Message for $type');
      // }

      chatBotReading.value = false;
    });

    // Listen for Live Messages
    aiSocket.onMessage((data) {
      chatBotReading.value = false;

      BaseAiChatModel msg = _parseDataByType(type, data);
      saveAiConversationId(msg.conversationId ?? '', type);

      currentChatMessages.add(msg);
      getListOfAiMessageResponse.value = ApiResponse.complete(currentChatMessages);
    });

    // --- FETCH HISTORY ---
    // aiSocket.getHistory(converId ?? '');

    if (converId != null) {
      aiSocket.getHistory(converId);
    } else {
      // NO HISTORY -> Show Predefined Message
      BaseAiChatModel welcomeMsg = _createInitialModel(type);
      currentChatMessages.add(welcomeMsg);

      chatBotReading.value = false;
    }
  }


  Future<void> sendMessageToAiSearchSocket({
    required String type,
    required String message,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {

    BaseAiChatModel userMsg = _createLocalUserMessage(type, message);
    currentChatMessages.add(userMsg);

    sendMessageController.value.clear();
    chatBotReading.value = true;

    String? converId = await AiChatLocalStorage.getConversationId(type);


    if (converId == null &&
        type != AppConstants.personal_Chat_Type &&
        type != AppConstants.business_Chat_Type) {
      aiSocket.joinConversation(type);
    }

    aiSocket.sendMessage(
        message: message,
        conversationId: converId,
        serviceType: type,
        imageBytes: imageBytes,
        mimeType: mimeType
    );
  }

  BaseAiChatModel _parseDataByType(String type, Map<String, dynamic> json) {
    try {
      switch (type) {
        case AppConstants.askInventory_Chat_Type:
          return InventoryAskAiModel.fromJson(json);

        case AppConstants.askFood_Chat_Type:
          return FoodAskAiModel.fromJson(json);

        case AppConstants.askService_Chat_Type:
          return BusinessServicesAskAiModel.fromJson(json);

        case AppConstants.askHealthCare_Chat_Type:
          return HealthCareAskAiModel.fromJson(json);

        case AppConstants.askEducation_Chat_Type:
          return EducationAskAiModel.fromJson(json);

        case AppConstants.askHomeService_Chat_Type:
          return ServiceAskAiModel.fromJson(json);

        case AppConstants.askTravelStay_Chat_Type:
          return TravelAndStayAskAiModel.fromJson(json);

        case AppConstants.askConsultingTalk_Chat_Type:
          return ServiceAskAiModel.fromJson(json);

        default:
          return InventoryAskAiModel.fromJson(json);
      }
    } catch (e, stackTrace) {
      // 🔴 Log the Error and Stack Trace
      print("❌ Error in _parseDataByType for type: $type");
      print("Error: $e");
      print("Stack Trace: $stackTrace");

      // Recommended: Rethrow the error so the UI knows something failed
      rethrow;
    }
  }

  BaseAiChatModel _createLocalUserMessage(String type, String text) {
    String time = formattedDate();

    switch (type) {
      case AppConstants.askInventory_Chat_Type:
        return InventoryAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askFood_Chat_Type:
        return FoodAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askService_Chat_Type:
        return BusinessServicesAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askHealthCare_Chat_Type:
        return HealthCareAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askEducation_Chat_Type:
        return EducationAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askHomeService_Chat_Type:
        return ServiceAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askTravelStay_Chat_Type:
        return TravelAndStayAskAiModel(message: text, role: "user", timestamp: time);
      case AppConstants.askConsultingTalk_Chat_Type:
        return ServiceAskAiModel(message: text, role: "user", timestamp: time);
      default:
        return InventoryAskAiModel(message: text, role: "user", timestamp: time);
    }
  }

  BaseAiChatModel _createInitialModel(String type) {
    String text = _getInitialMessageText(type); // Gets the welcome text we defined earlier

    final DateTime date = DateTime.parse(DateTime.now().toIso8601String()).toLocal(); // Convert to local time
    String time = DateFormat('h:mm a').format(date);

    switch (type) {
      case AppConstants.askInventory_Chat_Type:
        return InventoryAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askFood_Chat_Type:
        return FoodAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askService_Chat_Type:
        return BusinessServicesAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askHealthCare_Chat_Type:
        return HealthCareAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askEducation_Chat_Type:
        return EducationAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askHomeService_Chat_Type:
        return ServiceAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askTravelStay_Chat_Type:
        return TravelAndStayAskAiModel(
            message: text, role: "model", timestamp: time);

      case AppConstants.askConsultingTalk_Chat_Type:
        return ServiceAskAiModel(
            message: text, role: "model", timestamp: time);

      default:
        return InventoryAskAiModel(
            message: text, role: "model", timestamp: time);
    }
  }

  /// DIAGNOSTIC helper: inspects the raw `messageReceived` socket payload for a
  /// key named `link` and logs whether it exists (top level + per message). Used
  /// to confirm the BlueEra/admin conversation actually sends a `link` field,
  /// since the Messages model doesn't parse it. Safe to remove once verified.
  void _debugScanLinkKey(dynamic data) {
    try {
      if (data is! Map) {
        log("🔗 link-scan: payload is not a Map (${data.runtimeType})");
        return;
      }
      final topHasLink = data.containsKey('link');
      log("🔗 link-scan: top-level 'link' key exists = $topHasLink"
          "${topHasLink ? " → value: ${data['link']}" : ""}");

      final messages = data['messages'];
      if (messages is! List) {
        log("🔗 link-scan: no 'messages' list in payload");
        return;
      }
      int withLink = 0;
      for (var i = 0; i < messages.length; i++) {
        final m = messages[i];
        if (m is! Map) continue;
        if (m.containsKey('link')) {
          withLink++;
          log("🔗 link-scan: messages[$i] HAS 'link' = ${m['link']} "
              "(conversationId: ${m['conversation_id']}, "
              "messageType: ${m['message_type']}, senderId: ${m['senderId']})");
        }
      }
      log("🔗 link-scan: ${messages.length} message(s), $withLink carried a 'link' key");
    } catch (e) {
      log("🔗 link-scan error: $e");
    }
  }

  Future<void> connectSocket() async {
    // Always ensure socket is connected
    await chatSocket.connectToSocket();

    if (socketConnected.value == false) {
      socketConnected.value = true;
      chatSocket.listenEvent(ChatEmitEvents.ChatList, (data) async {

        final parsedData = GetChatListModel.fromJson(data);

        // The server doesn't always echo `type` back in the ChatList
        // response. When that happens, fall back to the type we asked for
        // in the most recent emit — otherwise `loadChatListWithType`
        // misroutes business/order data into the personal model and the
        // Inquiry / Orders tabs stay stuck on "No chats found" while their
        // data quietly lands in the personal Rx instead.
        if ((parsedData.type ?? '').isEmpty &&
            (_pendingChatListType ?? '').isNotEmpty) {
          parsedData.type = _pendingChatListType;
        }
        loadChatListWithType(chatListModel: parsedData);
        // Only mirror personal payloads into the filtered-personal Rx —
        // unconditionally assigning every list (business/order/group) here
        // used to clobber the personal tab whenever the user visited
        // another tab.
        if (parsedData.type == AppConstants.personal_Chat_Type) {
          getPersonalFilteredChatListModel?.value = parsedData;
        }
        // Persist server-authoritative chat list for offline render on next open.
        if ((parsedData.type ?? '').isNotEmpty) {
          await localStorageHelper.saveChatList(
              parsedData.chatList ?? [], parsedData.type ?? '');
        }
      });

      chatSocket.listenEvent(ChatEmitEvents.messageViewed, (data) {
        getMediaMsgCommentsModel?.value =
            GetMediaMsgCommentsModel.fromJson(data);
      });

      // Payment QR: a payer recorded a payment against one of my QRs. Route to
      // the PaymentQrController so the "Payments received" tab refreshes and an
      // incoming payment card is injected into the open conversation.
      chatSocket.listenEvent(ChatEmitEvents.paymentReceived, (data) {
        final controller = Get.isRegistered<PaymentQrController>()
            ? Get.find<PaymentQrController>()
            : Get.put(PaymentQrController(), permanent: true);
        controller.handlePaymentReceived(data);
      });

      // Payment image confirmed/rejected by the receiver: patch the matching
      // message's payment_status (fires for both participants).
      chatSocket.listenEvent(ChatEmitEvents.paymentStatusUpdate, (data) {
        handlePaymentStatusUpdate(data);
      });
      chatSocket.listenEvent(ChatEmitEvents.messageReceived, (data) async {
          log("📩 messageReceived (chat history) → $data");
          // DIAGNOSTIC: does the raw admin/BlueEra conversation payload carry a
          // "link" key? The Messages model doesn't parse `link`, so this checks
          // the raw socket JSON (top level + each message) as the convo opens.
          _debugScanLinkKey(data);
          final parsedData = GetListOfMessageData.fromJson(data);
          log("📩 messageReceived parsed: ${parsedData.messages?.length ?? 0} messages");

          if (parsedData.messages != null) {
            for (var message in parsedData.messages!) {
              if (message.myMessage == null) {
                final currentUserId = userId;
                final senderId = message.senderId;
                message.myMessage = currentUserId == senderId;
              }
            }
          }

          if (parsedData.messages?.isNotEmpty ?? false) {
            // The first entry is often a "date" separator with
            // conversation_id "0" — scan until we find a real message so the
            // Hive save key matches the actual conversationId the chat list
            // uses when loading offline. Otherwise every conversation's
            // messages would be stored under "0" and getMessagesByConversationId
            // would return empty for the real id.
            String conversationId = '';
            for (final m in parsedData.messages!) {
              if (m.messageType == 'date') continue;
              final id = m.conversationId ?? '';
              if (id.isEmpty || id == '0') continue;
              conversationId = id;
              break;
            }
            // Fall back to the open conversation id so sync still works for
            // edge cases where every message entry is a date separator.
            if (conversationId.isEmpty) {
              conversationId = userOpenConversationId.value;
            }
            if (parsedData.messages != null && conversationId.isNotEmpty) {
              // Deduplicate server messages by ID before setting
              final seen = <String>{};
              final deduped = <Messages>[];
              for (final m in parsedData.messages!) {
                final id = m.id ?? '';
                if (id.isEmpty || seen.add(id)) {
                  deduped.add(m);
                }
              }
              // Preserve locally-latched enquiry_status on the owner's
              // service+enquiry_only cards. The chat wire has no field for
              // it, so a fresh server payload would otherwise wipe an
              // Accept/Decline the owner just made and cause the buttons to
              // reappear. Keyed by message id → Hive replay stays in sync.
              final prevList = getListOfMessageData;
              if (prevList != null && prevList.isNotEmpty) {
                final prevStatusById = <String, String>{};
                for (final m in prevList) {
                  final id = m.id ?? '';
                  final s = m.metadata?.enquiryStatus;
                  if (id.isNotEmpty && s != null && s.isNotEmpty) {
                    prevStatusById[id] = s;
                  }
                }
                if (prevStatusById.isNotEmpty) {
                  for (final m in deduped) {
                    final id = m.id ?? '';
                    final carried = prevStatusById[id];
                    if (carried == null) continue;
                    m.metadata ??= MessageMetadata();
                    if ((m.metadata!.enquiryStatus ?? '').isEmpty) {
                      m.metadata!.enquiryStatus = carried;
                    }
                  }
                }
              }
              // Also preserve enquiry_status from the Hive snapshot — the
              // socket replay can run before `loadOfflineMessages` has
              // finished populating the in-memory list, in which case the
              // in-memory-diff above finds nothing to carry.
              final cached = await localStorageHelper
                  .getMessagesByConversationId(conversationId);
              if (cached.isNotEmpty) {
                final cachedStatusById = <String, String>{};
                for (final m in cached) {
                  final id = m.id ?? '';
                  final s = m.metadata?.enquiryStatus;
                  if (id.isNotEmpty && s != null && s.isNotEmpty) {
                    cachedStatusById[id] = s;
                  }
                }
                if (cachedStatusById.isNotEmpty) {
                  for (final m in deduped) {
                    final id = m.id ?? '';
                    final carried = cachedStatusById[id];
                    if (carried == null) continue;
                    m.metadata ??= MessageMetadata();
                    if ((m.metadata!.enquiryStatus ?? '').isEmpty) {
                      m.metadata!.enquiryStatus = carried;
                    }
                  }
                }
              }
              // Resolve local file paths for already-downloaded media
              // so images/videos show instantly from local storage
              await _resolveLocalMediaPaths(deduped);
              getListOfMessageResponse.value = ApiResponse.complete(deduped);
              scrollDown();
              // saveMessagesByConversationId REPLACES the full list — this is
              // the authoritative server data. The helper preserves any locally
              // pending messages that the server hasn't acked yet.
              localStorageHelper.saveMessagesByConversationId(
                  conversationId, deduped);
            } else {
              getListOfMessageResponse.value =
                  ApiResponse.complete(parsedData.messages);
            }
          } else {
            getListOfMessageResponse.value =
                ApiResponse.complete(parsedData.messages);
          }


      });
      chatSocket.listenEvent(ChatEmitEvents.newMessageReceived, (data) async {
        log("📨 newMessageReceived (single) → $data");

        Messages? message;
        if (data['message'] != null) {
          message = Messages.fromJson(data['message']);
        } else {
          message = null;
        }
        if (message == null) return;

        if (message.myMessage == null) {
          final currentUserId = userId;
          final senderId = message.senderId;
          message.myMessage = currentUserId == senderId;
        }

        // Always refresh the relevant chat list tab. `order` is merged into
        // `business` now, so legacy order rows seen during the migration window
        // refresh the business (Inquiry) tab rather than the removed Orders tab.
        final msgType = message.conversation?.type;
        if (msgType == AppConstants.business_Chat_Type ||
            msgType == AppConstants.order_Chat_Type) {
          emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.business_Chat_Type});
        } else if (msgType == AppConstants.group_Chat_Type) {
          emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.group_Chat_Type});
        } else {
          emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.personal_Chat_Type});
        }

        // Only add to currently open conversation
        String checkedConversationId = userOpenConversationId.value;
        if (checkedConversationId.isEmpty ||
            checkedConversationId != message.conversationId) {
          // Increment unread count locally for conversations the user is not viewing
          if (message.myMessage != true && message.conversationId != null) {
            _incrementChatListUnreadCount(message.conversationId!);
          }
          return;
        }

        // Deduplicate: skip if message with same ID already exists
        // This prevents doubles when sendMessage() already added it via API response
        final existingIds = getListOfMessageData
            ?.map((m) => m.id)
            .where((id) => id != null)
            .toSet() ?? {};
        if (message.id != null && existingIds.contains(message.id)) {
          return;
        }

        // Resolve local file paths for media so it shows from local storage instantly
        await _resolveLocalMediaPaths([message]);
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        saveSingleMessageToLocal(
            message.conversationId ?? '', message);

        // Auto-mark as read: user is viewing this conversation, so incoming
        // messages should be marked read immediately (guide §5.2)
        if (message.myMessage != true) {
          chatSocket.emitEvent(ChatEmitEvents.markConversationRead,
              {ApiKeys.conversation_id: checkedConversationId});
        }
        scrollDown();
      });
      // Chat-dispatch handoff OTP card (private pickup/delivery OTP). Arrives
      // like any other new message; append it to the open conversation. See
      // docs/backend/CHAT_DISPATCH_RIDER_FRONTEND_GUIDE.md.
      chatSocket.listenEvent(ChatEmitEvents.newRiderOtpReceived, (data) async {
        if (data is! Map || data['message'] == null) return;
        final message = Messages.fromJson(data['message']);
        if (message.myMessage == null) {
          message.myMessage = userId == message.senderId;
        }
        // Only append when the user is viewing this conversation; otherwise the
        // card flows in on the next history load.
        final openConvId = userOpenConversationId.value;
        if (openConvId.isEmpty || openConvId != message.conversationId) return;
        final existingIds = getListOfMessageData
                ?.map((m) => m.id)
                .where((id) => id != null)
                .toSet() ??
            {};
        if (message.id != null && existingIds.contains(message.id)) return;
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        saveSingleMessageToLocal(message.conversationId ?? '', message);
        scrollDown();
      });
      // Flip an existing OTP card to "consumed" once the rider verifies that
      // leg (pickup or delivery).
      chatSocket.listenEvent(ChatEmitEvents.riderOtpUpdated, (data) {
        _applyRiderOtpUpdate(data);
      });
      chatSocket.listenEvent(ChatEmitEvents.isOnLine, (data) {
        final uid = data['user_id'] as String?;
        final isOnline = data['is_online'] == true;
        if (uid != null) {
          if (isOnline) {
            onlineUserIds.add(uid);
          } else {
            onlineUserIds.remove(uid);
          }
        }
        if (uid == userOpenUserId.value) {
          userOnlineStatus.value = isOnline ? "Online" : "Offline";
        }
      });
      chatSocket.listenEvent(ChatEmitEvents.isOnlineFromChatList, (data) {
        final List<Map<String, dynamic>> datas =
        List<Map<String, dynamic>>.from(data);

        for (final update in datas) {
          final uid = update['user_id'] as String?;
          final isOnline = update['is_online'] == true;

          if (uid != null) {
            if (isOnline) {
              onlineUserIds.add(uid);
            } else {
              onlineUserIds.remove(uid);
            }
          }

          // Update the active chat screen
          if (uid == userOpenUserId.value) {
            userOnlineStatus.value = isOnline ? "Online" : "Offline";
          }
        }
      });

      // Last-seen timestamps
      chatSocket.listenEvent(ChatEmitEvents.userLastSeenList, (data) {
        if (data is List) {
          for (final item in data) {
            final conversationId = item['conversation_id'] as String?;
            final lastSeen = item['last_seen'] as String?;
            if (conversationId != null && lastSeen != null) {
              lastSeenMap[conversationId] = lastSeen;
            }
          }
        }
      });

      // Typing indicator listener
      chatSocket.listenEvent(ChatEmitEvents.isTyping, (data) {
        final conversationId = data['conversation_id'] as String?;
        final typingUserId = data['user_id'] as String?;
        final typingUser = data['user'];

        if (conversationId == null) return;
        if (typingUserId == null) return;

        final name = typingUser?['name'] ?? 'Someone';

        // Update chat list typing indicator for ALL conversations
        typingByConversation[conversationId] = name;
        _chatListTypingTimers[conversationId]?.cancel();
        _chatListTypingTimers[conversationId] =
            Timer(const Duration(seconds: 3), () {
          typingByConversation.remove(conversationId);
          _chatListTypingTimers.remove(conversationId);
        });

        // Update open chat screen typing indicator
        if (conversationId != userOpenConversationId.value) return;

        typingText.value = 'typing...';

        // Auto-hide after 3 seconds
        _typingHideTimers[typingUserId]?.cancel();
        _typingHideTimers[typingUserId] = Timer(const Duration(seconds: 3), () {
          _typingHideTimers.remove(typingUserId);
          if (_typingHideTimers.isEmpty) {
            typingText.value = '';
          }
        });
      });

      chatSocket.listenEvent(ChatEmitEvents.messageStatusUpdate, (data) {
        if (data['conversation_id'] == userOpenConversationId.value) {
          final newStatus = data['status'] as String? ?? '';
          // Status only goes forward: sent(0) → delivered(1) → read(2)
          const statusOrder = {'sent': 0, 'delivered': 1, 'read': 2};
          final currentRank = statusOrder[readMessageStatus.value] ?? -1;
          final newRank = statusOrder[newStatus] ?? -1;
          if (newRank > currentRank) {
            readMessageStatus.value = newStatus;
          }

          // Update per-message status for all outgoing messages in this conversation
          final messages = getListOfMessageData;
          if (messages != null) {
            for (final msg in messages) {
              if (msg.myMessage == true) {
                final msgRank = statusOrder[msg.status] ?? 0;
                if (newRank > msgRank) {
                  msg.status = newStatus;
                }
              }
            }
            getListOfMessageResponse.refresh();
          }
        }
      });

      // Unread count cleared listener
      chatSocket.listenEvent(ChatEmitEvents.unreadCountCleared, (data) {
        final conversationId = data['conversation_id'] as String?;
        if (conversationId != null) {
          _updateChatListUnreadCount(conversationId, 0);
        }
      });
      chatSocket.listenEvent(ChatEmitEvents.update_data, (data) {
        emitEvent(ChatEmitEvents.messageReceived, {
          ApiKeys.conversation_id: data[ApiKeys.conversation_id],
          ApiKeys.page: 1,
          ApiKeys.is_online_user: userOpenUserId.value,
          ApiKeys.per_page_message: 30,
        });
      });

      // Self-Pickup: New order received (business side)
      chatSocket.listenEvent(ChatEmitEvents.newSelfPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          // Refresh chat list
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Self-Pickup: Order marked as ready
      chatSocket.listenEvent(ChatEmitEvents.selfPickupOrderReady, (data) {

        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              msg.metadata?.selfPickupOrder?.isReady = true;
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      // Service Enquiry: New enquiry received (provider side)
      chatSocket.listenEvent(ChatEmitEvents.newServiceEnquiryReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          // Refresh chat list
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Service Enquiry: provider accepted / declined → update the card status
      chatSocket.listenEvent(ChatEmitEvents.serviceEnquiryStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.serviceEnquiry?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Property Enquiry: New enquiry received (owner side)
      chatSocket.listenEvent(ChatEmitEvents.newPropertyEnquiryReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          // Refresh chat list
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Property Enquiry: owner accepted / declined → update the card status
      chatSocket.listenEvent(ChatEmitEvents.propertyEnquiryStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.propertyEnquiry?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Healthcare Enquiry: new enquiry received (owner side, plus echoed to
      // the customer's other sessions — dedupe by message._id). One handler
      // covers every healthcare category since the wire shape is identical
      // regardless of the REST producer. See
      // lib/docs/healthcare-enquiry-ui-integration.md §5.
      chatSocket.listenEvent(ChatEmitEvents.newHealthcareEnquiryReceived,
          (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          // Refresh chat list so the conversation surfaces the new card.
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Healthcare Enquiry: owner accepted / declined → flip the card status
      // for both parties.
      chatSocket.listenEvent(ChatEmitEvents.healthcareEnquiryStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.healthcareEnquiry?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Hospital Appointment (doc `healthcare-appointment-ui-integration.md`):
      // new appointment received (owner side, echoed to the customer's other
      // sessions — dedupe by message._id).
      chatSocket.listenEvent(ChatEmitEvents.newHealthcareBookingReceived,
          (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Hospital Appointment: owner accept / decline OR customer cancel —
      // same PUT endpoint handles all three transitions, so this single
      // event flips the card for both sides regardless of who acted.
      chatSocket.listenEvent(ChatEmitEvents.healthcareBookingStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.healthcareBooking?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Hotel Enquiry: new enquiry received (owner side, echoed to the
      // customer's other sessions — dedupe by message._id).
      chatSocket.listenEvent(ChatEmitEvents.newHotelEnquiryReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Hotel Enquiry: owner accepted / declined → flip the card status.
      chatSocket.listenEvent(ChatEmitEvents.hotelEnquiryStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.hotelEnquiry?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Hotel Booking (§2b): new booking request received (owner side, echoed
      // to the buyer's other sessions — dedupe by message._id).
      chatSocket.listenEvent(ChatEmitEvents.newHotelBookingReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Hotel Booking (§2b): owner accept / decline OR buyer cancel — the
      // status endpoint accepts all three transitions, so this single
      // event flips the card for both sides regardless of who acted.
      chatSocket.listenEvent(ChatEmitEvents.hotelBookingStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.hotelBooking?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Vehicle Booking: new booking request received (seller side, echoed
      // to the buyer's other sessions — dedupe by message._id).
      chatSocket.listenEvent(ChatEmitEvents.newVehicleBookingReceived,
          (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Vehicle Booking: status flipped — accepted / declined by the seller
      // OR cancelled by the buyer. Same socket event for all three.
      chatSocket.listenEvent(ChatEmitEvents.vehicleBookingStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              final parsed = VehicleBookingStatusWire.parse(status);
              msg.metadata?.booking?.status = parsed;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Education Enquiry: new enquiry received (owner side, echoed to
      // the customer's other sessions — dedupe by message._id).
      chatSocket.listenEvent(ChatEmitEvents.newEducationEnquiryReceived,
          (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Education Enquiry: owner accepted / declined → flip the card status.
      chatSocket.listenEvent(ChatEmitEvents.educationEnquiryStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.educationEnquiry?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // "Other" Business Enquiry: new enquiry received (owner side, echoed
      // to the customer's other sessions — dedupe by message._id). See
      // lib/docs/other-enquiry-ui-integration.md §6.
      chatSocket.listenEvent(ChatEmitEvents.newBusinessEnquiryReceived,
          (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty &&
              conversationId == userOpenConversationId.value) {
            final currentMessages =
                getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value =
                  ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // "Other" Business Enquiry: owner accepted / declined → flip the card
      // status for both parties.
      chatSocket.listenEvent(ChatEmitEvents.businessEnquiryStatusUpdated,
          (data) {
        final messageId = data['messageId']?.toString() ?? '';
        final status = data['status']?.toString();
        if (messageId.isNotEmpty && status != null) {
          final currentMessages =
              getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.businessEnquiry?.status = status;
              break;
            }
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(currentMessages);
        }
      });

      // Food Self-Pickup: New order received (restaurant side)
      chatSocket.listenEvent(ChatEmitEvents.newFoodPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Food Self-Pickup: Order marked as ready
      chatSocket.listenEvent(ChatEmitEvents.foodPickupOrderReady, (data) {
        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              if (msg.metadata?.foodPickupOrder != null) {
                msg.metadata?.foodPickupOrder?.isReady = true;
              }
              if (msg.metadata?.selfPickupOrder != null) {
                msg.metadata?.selfPickupOrder?.isReady = true;
              }
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      // Product Self-Pickup: New order received (seller side)
      chatSocket.listenEvent(ChatEmitEvents.newProductPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Product Self-Pickup: Order marked as ready
      chatSocket.listenEvent(ChatEmitEvents.productPickupOrderReady, (data) {
        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              if (msg.metadata?.productPickupOrder != null) {
                msg.metadata?.productPickupOrder?.isReady = true;
              }
              if (msg.metadata?.selfPickupOrder != null) {
                msg.metadata?.selfPickupOrder?.isReady = true;
              }
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      // Home-Made Food Self-Pickup: New order received (cook side)
      chatSocket.listenEvent(
          ChatEmitEvents.newHomeMadeFoodPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Home-Made Food Self-Pickup: Order marked as ready
      chatSocket.listenEvent(
          ChatEmitEvents.homeMadeFoodPickupOrderReady, (data) {
        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              if (msg.metadata?.homeMadeFoodPickupOrder != null) {
                msg.metadata?.homeMadeFoodPickupOrder?.isReady = true;
              }
              if (msg.metadata?.selfPickupOrder != null) {
                msg.metadata?.selfPickupOrder?.isReady = true;
              }
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      // Tiffin Self-Pickup: New order received (cook side)
      chatSocket.listenEvent(
          ChatEmitEvents.newTiffinPickupOrderReceived, (data) {
        if (data['message'] != null) {
          final message = Messages.fromJson(data['message']);
          final conversationId = message.conversationId ?? '';
          if (conversationId.isNotEmpty && conversationId == userOpenConversationId.value) {
            final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
            final exists = currentMessages.any((m) => m.id == message.id);
            if (!exists) {
              currentMessages.add(message);
              getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
              scrollDown();
            }
          }
          emitEvent(ChatEmitEvents.ChatList, {
            ApiKeys.page: 1,
            ApiKeys.per_page_message: 30,
          });
        }
      });

      // Tiffin Self-Pickup: Order marked as ready
      chatSocket.listenEvent(
          ChatEmitEvents.tiffinPickupOrderReady, (data) {
        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.orderStatus = true;
              if (msg.metadata?.tiffinPickupOrder != null) {
                msg.metadata?.tiffinPickupOrder?.isReady = true;
              }
              if (msg.metadata?.selfPickupOrder != null) {
                msg.metadata?.selfPickupOrder?.isReady = true;
              }
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      // Tiffin Self-Pickup: Order cancelled by the customer (while 'placed').
      chatSocket.listenEvent(
          ChatEmitEvents.tiffinPickupOrderCancelled, (data) {
        final messageId = data['messageId']?.toString() ?? '';
        if (messageId.isNotEmpty) {
          final currentMessages = getListOfMessageResponse.value.data as List<Messages>? ?? [];
          for (var msg in currentMessages) {
            if (msg.id == messageId) {
              msg.metadata?.is_cancelled = true;
              break;
            }
          }
          getListOfMessageResponse.value = ApiResponse.complete(currentMessages);
        }
      });

      socketConnectedCalled.value = true;
    }
    try {
      // openedConversation.value = await localStorageHelper.getConversation();
      // await loadAllChatListFromLocal();
    } catch (e) {
      debugPrint('connectSocket local storage init error: $e');
    }
    // final connectivityResult = await NetworkUtils.isConnected();
    // if (connectivityResult) {
    //   await loadChatListFromLocal(AppConstants.personal_Chat_Type);
    // }

    // }
  }

  void changeBusinessInsideTab(int index) {
    businessTabIndexSelected.value = index;
  }

  /// Appends a locally-constructed [message] to the open conversation and
  /// refreshes the list. Used by features (e.g. Payment QR) that render a chat
  /// card immediately after a REST/socket action without a round-trip send.
  /// De-dupes by id so a socket echo of an already-injected row is ignored.
  void appendLocalMessage(Messages message) {
    final list = getListOfMessageData;
    if (list == null) {
      getListOfMessageResponse.value =
          ApiResponse.complete(<Messages>[message]);
    } else {
      if (message.id != null && list.any((m) => m.id == message.id)) return;
      list.add(message);
      getListOfMessageResponse.value = ApiResponse.complete(list);
    }
    scrollDown();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Payment screenshot flow (see image-is-payment-flutter-integration-guide.md)
  //
  // The payer uploads a payment screenshot sent as an image message carrying
  // the top-level `is_payment: true` flag. The backend stores & echoes it
  // (HTTP + socket) alongside a `payment_status` lifecycle field that starts
  // at 'pending'.
  //
  // The receiver (owner) confirms/rejects via PUT /chat/payment-status, moving
  // the status to 'success' or 'failed'. The backend then pushes a
  // `paymentStatusUpdate` socket event to BOTH participants, so each device
  // re-renders the bubble (waiting → accepted/rejected).
  // ─────────────────────────────────────────────────────────────────────────

  // Backend payment_status values.
  static const String kPaymentPending = 'pending';
  static const String kPaymentSuccess = 'success';
  static const String kPaymentFailed = 'failed';

  /// Sends [screenshot] as an image message with `is_payment: true` into the
  /// open conversation. Shows an optimistic uploading placeholder, then swaps
  /// in the server message on success. Returns true when accepted by the server.
  Future<bool> sendPaymentScreenshot({
    required File screenshot,
    String? conversationId,
    String? note,
  }) async {
    if (isSending.value) return false;
    if ((conversationId ?? '').isEmpty) {
      commonSnackBar(message: 'Unable to send payment screenshot');
      return false;
    }
    isSending.value = true;

    // Optimistic uploading card so the payer sees progress immediately.
    final now = DateTime.now().toUtc().toIso8601String();
    sendLoadingFile.value = Messages(
      url: [MessageMediaUrl(url: screenshot.path)],
      sendLoadingFile: [screenshot],
      myMessage: true,
      messageType: 'image',
      message: note,
      isPayment: true,
      paymentStatus: kPaymentPending,
      createdAt: now,
    );
    getListOfMessageData?.add(sendLoadingFile.value);
    getListOfMessageResponse.value =
        ApiResponse.complete(getListOfMessageData);
    scrollDown();

    try {
      final name = screenshot.path.split('/').last;
      final part =
          await dio.MultipartFile.fromFile(screenshot.path, filename: name);

      final params = <String, dynamic>{
        ApiKeys.conversation_id: conversationId,
        ApiKeys.message_type: 'image',
        // Multipart values arrive as strings; backend coerces "true" → true.
        ApiKeys.is_payment: true,
        if ((note ?? '').isNotEmpty) ApiKeys.message: note,
        ApiKeys.files: [part],
      };
      attachRouteParam(params);

      final ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);

      _removeUploadingPlaceholder();

      if (!responseModel.isSuccess) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }

      final data = responseModel.response?.data?['data'];
      final raw = data is List ? (data.isNotEmpty ? data.first : null) : data;
      if (raw == null) return false;
      Messages message = Messages.fromJson(raw);
      // Carry the payment fields even if the server echo omitted them, so the
      // bubble renders the awaiting-approval footer at once.
      message.isPayment = true;
      message.paymentStatus ??= kPaymentPending;

      final alreadyExists = message.id != null &&
          (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
      if (!alreadyExists) {
        getListOfMessageData?.add(message);
      }
      getListOfMessageResponse.value =
          ApiResponse.complete(getListOfMessageData);
      saveSingleMessageToLocal(conversationId!, message);
      _updateChatListLastMessage(
        conversationId,
        note,
        'image',
        message.updatedAt ?? message.createdAt,
        sendStatus: "",
      );
      scrollDown();
      return true;
    } catch (e) {
      _removeUploadingPlaceholder();
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isSending.value = false;
    }
  }

  /// Owner action: confirm ('success') or reject ('failed') the payment image
  /// [messageId] via PUT /chat/payment-status. Applies an optimistic local
  /// patch for snappy feedback; the `paymentStatusUpdate` socket then
  /// reconciles both participants (idempotent).
  Future<void> updatePaymentStatus({
    required String messageId,
    required String status,
  }) async {
    if (messageId.isEmpty) return;
    _applyPaymentStatus(messageId, status);
    try {
      final res = await ChatViewRepo().updatePaymentStatusApi({
        ApiKeys.messageId: messageId,
        ApiKeys.payment_status: status,
      });
      if (!res.isSuccess) {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (_) {
      // Best-effort: the socket event remains the source of truth.
    }
  }

  /// Handles the `paymentStatusUpdate` socket event (fires for both payer and
  /// receiver). Patches the referenced message's [Messages.paymentStatus].
  void handlePaymentStatusUpdate(dynamic data) {
    if (data is! Map) return;
    final messageId =
        (data['messageId'] ?? data['message_id'])?.toString();
    final status = data['payment_status']?.toString();
    _applyPaymentStatus(messageId, status);
  }

  /// Patches the in-memory + persisted payment_status of the message with
  /// [messageId]. No-op when the conversation isn't currently loaded — the
  /// backend value flows in on the next history load.
  void _applyPaymentStatus(String? messageId, String? status) {
    if (messageId == null || messageId.isEmpty) return;
    if (status == null || status.isEmpty) return;
    final list = getListOfMessageData;
    if (list == null) return;
    final target = list.firstWhereOrNull((m) => m.id == messageId);
    if (target == null) return;
    target.isPayment = true;
    target.paymentStatus = status;
    getListOfMessageResponse.value = ApiResponse.complete(list);
    final convId = target.conversationId ?? '';
    if (convId.isNotEmpty) {
      localStorageHelper.saveMessagesByConversationId(convId, list);
    }
  }

  /// Handles the `riderOtpUpdated` socket event — payload
  /// `{ messageId, rideOrderId, kind, status }`. Flips the matching OTP card's
  /// status (e.g. → "consumed") in-memory and in local storage. Matches by
  /// messageId first, then falls back to rideOrderId + kind so the card still
  /// updates if the server omits the messageId.
  void _applyRiderOtpUpdate(dynamic data) {
    if (data is! Map) return;
    final messageId = (data['messageId'] ?? data['message_id'])?.toString();
    final rideOrderId =
        (data['rideOrderId'] ?? data['ride_order_id'])?.toString();
    final kind = data['kind']?.toString();
    final status = data['status']?.toString();
    if (status == null || status.isEmpty) return;
    final list = getListOfMessageData;
    if (list == null) return;
    final target = list.firstWhereOrNull((m) {
      if (m.messageType != 'rider_otp') return false;
      if (messageId != null && messageId.isNotEmpty) return m.id == messageId;
      final otp = m.metadata?.riderOtp;
      return otp != null &&
          rideOrderId != null &&
          otp.rideOrderId == rideOrderId &&
          (kind == null || otp.kind == kind);
    });
    if (target == null) return;
    target.metadata?.riderOtp?.status = status;
    getListOfMessageResponse.value = ApiResponse.complete(list);
    final convId = target.conversationId ?? '';
    if (convId.isNotEmpty) {
      localStorageHelper.saveMessagesByConversationId(convId, list);
    }
  }

  void setReplyMessage(Messages? message) {
    replyMessage?.value = message;
  }

  void onSelectChatTab(int index) {
    selectedChatTabIndex.value = index;
    if (chatMainTabController == null) {
      // Tab controller not yet created — selectedChatTabIndex is stored so
      // that initState in OrderMainChatScreen picks it up as initialIndex.
      return;
    }
    chatMainTabController!.animateTo(index);
  }

  /// Refresh the business/inquiry chat list right after a self-pickup order is
  /// placed. The freshly-created order conversation is frequently not yet
  /// indexed on the server at the instant the place-order API returns, so a
  /// single emit races the backend and the new order thread only appears after
  /// a manual pull-to-refresh. Emitting immediately plus a couple of short
  /// delayed re-emits lets the new order surface on the Inquiry tab on its own,
  /// without any user action. Safe to call from any place-order flow.
  void refreshBusinessChatListAfterOrder() {
    void emit() => emitEvent(
          ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.business_Chat_Type},
        );
    emit(); // immediate — catches orders the backend has already indexed
    Future.delayed(const Duration(milliseconds: 1200), emit);
    Future.delayed(const Duration(seconds: 3), emit);
  }

  void isChatFromBusinessProfile(bool value) {
    chatFromBusinessProfile.value = value;
  }

  void clearMessageControllerCommon() {
    sendMessageController.value.clear();
    isTextFieldEmpty.value = false;
  }

  //
  // Future<void> loadChatListFromLocal(String type) async {
  //   List<ChatList> localChats =
  //       await localStorageHelper.getChatListFromLocal(type);
  //   getPersonalChatListModel?.value = GetChatListModel(
  //     success: true,
  //     chatList: localChats,
  //     archived: [],
  //   );
  //   personalChatListResponse.value =
  //       ApiResponse.complete(getPersonalChatListModel?.value);
  // }

  void loadChatListWithType({required GetChatListModel chatListModel}) {
    if (chatListModel.type == AppConstants.business_Chat_Type) {
      getBusinessChatListModel?.value = chatListModel;
      businessChatListResponse.value = ApiResponse.complete(chatListModel);
    } else if (chatListModel.type == AppConstants.history_Chat_Type) {
      getHistoryChatListModel?.value = chatListModel;
      historyChatListResponse.value = ApiResponse.complete(chatListModel);
    } else if (chatListModel.type == AppConstants.personal_Chat_Type) {
      getPersonalChatListModel?.value = chatListModel;
      personalChatListResponse.value = ApiResponse.complete(chatListModel);
    } else if (chatListModel.type == AppConstants.group_Chat_Type) {
      getGroupChatListModel?.value = chatListModel;
      groupChatListResponse.value =
          ApiResponse.complete(getGroupChatListModel?.value);
    } else if (chatListModel.type == AppConstants.order_Chat_Type) {
      getOrderChatListModel?.value = chatListModel;
      orderChatListResponse.value =
          ApiResponse.complete(getOrderChatListModel?.value);
    } else {
      getPersonalChatListModel?.value = chatListModel;
      personalChatListResponse.value = ApiResponse.complete(chatListModel);
    }
  }

  /// Locally update the last message in all chat list models so the chat list
  /// reflects the sent message immediately (without waiting for a server round-trip).
  void _updateChatListLastMessage(
    String? conversationId,
    String? lastMessage,
    String? lastMessageType,
    String? updatedAt, {
    String? sendStatus,
  }) {
    if (conversationId == null) return;

    void _patchList(Rx<GetChatListModel>? model, {String? persistAsType}) {
      final list = model?.value.chatList;
      if (list == null) return;
      final idx = list.indexWhere((c) => c?.conversationId == conversationId);
      if (idx == -1) {
        model?.refresh();
        return;
      }
      final chat = list[idx];
      chat?.lastMessage = lastMessage;
      chat?.lastMessageType = lastMessageType;
      if (updatedAt != null) chat?.updatedAt = updatedAt;
      // Pass `sendStatus: "pending"` to show a clock icon in the list while
      // the message is queued offline; pass `""` (or anything non-null) from
      // the online success branch to clear it once the server has accepted
      // the message.
      if (sendStatus != null) {
        chat?.lastMessageSendStatus =
            sendStatus.isEmpty ? null : sendStatus;
      }
      // Move this conversation to the top of the list so the most recent
      // activity surfaces immediately — matches the native chat-list order
      // the server returns on the next refresh.
      if (idx > 0) {
        list.removeAt(idx);
        list.insert(0, chat);
      }
      model?.refresh();
      // Persist the patched list to Hive. Back-navigation re-emits the
      // ChatList event, which hydrates the Rx model from Hive first — if we
      // skip this save, the in-memory patch (including the pending clock
      // and the top-of-list reorder) gets blown away the instant the user
      // leaves the chat screen.
      if (persistAsType != null) {
        unawaited(localStorageHelper.saveChatList(
            list.toList(), persistAsType));
      }
    }

    _patchList(getPersonalChatListModel,
        persistAsType: AppConstants.personal_Chat_Type);
    _patchList(getPersonalFilteredChatListModel);
    _patchList(getBusinessChatListModel,
        persistAsType: AppConstants.business_Chat_Type);
    _patchList(getGroupChatListModel,
        persistAsType: AppConstants.group_Chat_Type);
    _patchList(getOrderChatListModel);
  }

  void onSearchChatList(String searchQuery) {
    if (selectedChatTabIndex.value == 0) {
      List<ChatList?>? fullChatList =
          getPersonalFilteredChatListModel?.value.chatList;

      if (searchQuery.isNotEmpty) {
        List<ChatList?> filteredList = fullChatList
                ?.where((e) =>
                    (e?.sender?.name?.toLowerCase().contains(searchQuery) ??
                        false))
                .toList() ??
            [];
        getPersonalChatListModel?.value.chatList = filteredList;
        loadChatListWithType(chatListModel: getPersonalChatListModel!.value);
      } else {
        // if empty query, show full list
        loadChatListWithType(
            chatListModel: getPersonalFilteredChatListModel!.value);
      }
    } else if (selectedChatTabIndex.value == 1) {
    } else if (selectedChatTabIndex.value == 2) {}
  }

  Future<void> saveSingleMessageToLocal(String conversationId, Messages msg,
      [Map<String, dynamic>? params]) async {
    if (conversationId.isEmpty) return;
    if (params != null) {
      // Outgoing message with send params — mark as pending for offline retry.
      msg.sendPendingMsgParams = params;
      await localStorageHelper.saveSingleMessageToConversationId(
          conversationId, msg,
          sendStatus: "pending");
    } else {
      // Received message or already-sent message — save without pending status.
      await localStorageHelper.saveSingleMessageToConversationId(
          conversationId, msg);
    }
  }

  /// Re-send locally queued pending messages for a conversation. Typically
  /// called when the user reopens a chat that had messages stuck in pending
  /// (e.g. media that couldn't be uploaded last time). Text-like messages
  /// are also drained by PendingMessageDrainer on connectivity change.
  Future<void> sendOfflineMessage(
    String conversationId,
  ) async {
    if (conversationId.isEmpty) return;
    if (_drainingConversations.contains(conversationId)) return;
    _drainingConversations.add(conversationId);
    try {
      await _sendOfflineMessageInternal(conversationId);
    } finally {
      _drainingConversations.remove(conversationId);
    }
  }

  Future<void> _sendOfflineMessageInternal(String conversationId) async {
    List<Map<String, dynamic>> data =
        await localStorageHelper.getUnsentMessages(conversationId);

    if (data.isEmpty) return;

    // Iterate oldest-first so each retry gets a server createdAt in the same
    // order the user queued them offline. Reversing here made the last item
    // hit the server first, inverting the visible chronological order once
    // the pending rows were replaced by server-authoritative ones.
    for (int i = 0; i < data.length; i++) {
      final String type = data[i]["message_type"]?.toString() ?? '';
      final bool hasFilePaths = data[i]['pendingFilePaths'] is List &&
          (data[i]['pendingFilePaths'] as List).isNotEmpty;
      final bool hasParams = data[i]['sendPendingMsgParams'] != null;
      if (!hasParams) continue;

      // Audio / document queued offline save their local paths so the
      // drainer can rebuild MultipartFile parts on retry. Without this
      // branch these types silently fell back to the plain text retry
      // path, which does a JSON POST and so delivered no file.
      if ((type == 'audio' || type == 'document') && hasFilePaths) {
        final List<String> paths = (data[i]['pendingFilePaths'] as List)
            .map((e) => e.toString())
            .toList();
        final String tempId = data[i]['_id']?.toString() ?? '';
        localStorageHelper.markPendingInFlight(tempId);
        try {
          await _retryPendingFileMessage(
            params:
                Map<String, dynamic>.from(data[i]['sendPendingMsgParams']),
            filePaths: paths,
            messageId: tempId,
            fileName: data[i]['docFileName']?.toString(),
          );
        } finally {
          localStorageHelper.clearPendingInFlight(tempId);
        }
      } else if (type == 'document' ||
          type == 'text' ||
          type == 'contact' ||
          type == 'location' ||
          type == 'live_location') {
        if (data[i]['_id'] != null) {
          // Awaited so the per-conversation drain guard is only released
          // after the HTTP ack + Hive replace lands. Otherwise a second
          // drain event could fire during the in-flight window and resend.
          await sendOfflineMessageToServer(
              Map<String, dynamic>.from(data[i]['sendPendingMsgParams']),
              data[i]['_id'].toString());
        }
      } else if ((type == 'image' || type == 'video') && hasFilePaths) {
        final List<File> listFiles = (data[i]['pendingFilePaths'] as List)
            .map((e) => File(e.toString()))
            .toList();
        final String tempId = data[i]['_id']?.toString() ?? '';
        // Block concurrent pagination saves from re-preserving this pending
        // row while the retry is in flight. Cleared after retry + Hive
        // replace completes (or the call throws).
        localStorageHelper.markPendingInFlight(tempId);
        try {
          await generateUploadUrlsApi(
              params:
                  Map<String, dynamic>.from(data[i]['sendPendingMsgParams']),
              listFile: listFiles,
              userId: [data[i]['userId']?.toString() ?? ""],
              conversationId: data[i][ApiKeys.conversation_id]?.toString(),
              // The caption was saved into the Messages.message field
              // (JSON key "message"). Reading "comments" here dropped the
              // caption on every retry, so the receiver only saw the media.
              commands: data[i]["message"]?.toString(),
              messageType: type,
              isPendingMessage: true,
              messageId: tempId);
        } finally {
          localStorageHelper.clearPendingInFlight(tempId);
        }
      }
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
          final drainConvId =
              params[ApiKeys.conversation_id]?.toString() ?? '';
          // Only touch the in-memory message list when the drained message
          // belongs to the conversation the user currently has open. If the
          // user queued this offline in chat A and is now viewing chat B,
          // mutating `getListOfMessageData` would inject A's message into
          // B's screen (and leave A with a pending row that never gets
          // replaced in-memory).
          final isForOpenConv = drainConvId.isNotEmpty &&
              drainConvId == userOpenConversationId.value;

          if (isForOpenConv) {
            Messages? msg = getListOfMessageData
                ?.firstWhereOrNull((element) => element.id == messageId);
            if (msg != null) {
              getListOfMessageData?.remove(msg);
            }
            // Dedup: the newMessageReceived socket echo may have already
            // inserted this server message while the HTTP ack was in flight.
            final alreadyExists = message.id != null &&
                (getListOfMessageData
                        ?.any((m) => m.id == message.id) ??
                    false);
            if (!alreadyExists) {
              getListOfMessageData?.add(message);
            }
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
          }

          // Always persist to Hive keyed by the drain's own conversation id
          // so the original conversation shows the server-authoritative
          // message next time it is opened — independent of which chat is
          // currently on screen.
          await localStorageHelper.replacePendingWithServerMessage(
              drainConvId, messageId, message);
        }
        if (message.subType != "comment" &&
            (params[ApiKeys.conversation_id]?.toString() ?? '') ==
                userOpenConversationId.value) {
          scrollDown();
        }
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
    // Set current user's online status from cache
    userOnlineStatus.value =
        onlineUserIds.contains(userId) ? "Online" : "Offline";
    // Paint cached history immediately (WhatsApp-style offline-first).
    // Always fire-and-forget — cheap Hive read, and calling it on every
    // entry keeps the screen in sync with disk even when the caller did
    // not run getLocalConversation first, or when leaveConversation never
    // ran between opens. loadOfflineMessages publishes a complete() with
    // the cached list, so the UI renders history instantly — even when
    // offline and the socket emit below never gets a reply.
    if (conversationId.isNotEmpty) {
      unawaited(loadOfflineMessages(conversationId));
    }
    emitEvent(ChatEmitEvents.screenRoom,
        {ApiKeys.conversation_id: "${conversationId}"});
    // Mark conversation as read on the server
    chatSocket.emitEvent(ChatEmitEvents.markConversationRead,
        {ApiKeys.conversation_id: conversationId});
    addConversationOnce(conversationId);
    // Reset message status for new conversation (avoid stale ticks)
    readMessageStatus.value = '';
    // Reset typing indicator for new conversation
    typingText.value = '';
    _typingHideTimers.forEach((_, timer) => timer.cancel());
    _typingHideTimers.clear();
  }

  /// Call this when the user leaves a conversation (back button, dispose, etc.).
  /// Tells the server the user is no longer viewing any conversation so new
  /// incoming messages get "delivered" status instead of "read".
  void leaveConversation() {
    debugPrint('[CHAT_DEBUG] leaveConversation() called — emitting screenRoom: online');
    userOpenConversationId.value = '';
    userOpenUserId.value = '';
    readMessageStatus.value = '';
    typingText.value = '';
    userOnlineStatus.value = '';
    _typingHideTimers.forEach((_, timer) => timer.cancel());
    _typingHideTimers.clear();
    // Tell the server the user is online but not in any conversation
    chatSocket.emitEvent(
        ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
  }

  /// Check if a user is currently online (for chat list dots).
  bool isUserOnline(String? userId) =>
      userId != null && onlineUserIds.contains(userId);

  /// Emit typing indicator (debounced — max once per second per guide)
  void emitTyping(String conversationId) {
    if (_typingDebounceTimer?.isActive ?? false) return;
    chatSocket.emitEvent(ChatEmitEvents.isTyping,
        {ApiKeys.conversation_id: conversationId});
    _typingDebounceTimer = Timer(const Duration(seconds: 1), () {});
  }

  /// Increment unread count by 1 for a conversation in all chat list models
  void _incrementChatListUnreadCount(String conversationId) {
    for (final model in [
      getPersonalChatListModel,
      getBusinessChatListModel,
      getGroupChatListModel,
      getOrderChatListModel,
    ]) {
      final chatList = model?.value.chatList;
      if (chatList == null) continue;
      for (final chat in chatList) {
        if (chat?.conversationId == conversationId) {
          chat?.unreadCount = (chat.unreadCount ?? 0) + 1;
        }
      }
      model?.refresh();
    }
  }

  /// Update unread count in chat list models
  void _updateChatListUnreadCount(String conversationId, num count) {
    for (final model in [
      getPersonalChatListModel,
      getBusinessChatListModel,
      getGroupChatListModel,
      getOrderChatListModel,
    ]) {
      final chatList = model?.value.chatList;
      if (chatList == null) continue;
      for (final chat in chatList) {
        if (chat?.conversationId == conversationId) {
          chat?.unreadCount = count;
        }
      }
      model?.refresh();
    }
  }

  void addConversationOnce(String conversationId) {
    // localStorageHelper.putConversation(conversationId);
    if (!openedConversation.contains(conversationId)) {
      openedConversation.add(conversationId);
    }
  }
  /// Check if the scroll position is near the bottom (within 150px).
  bool get _isNearBottom {
    if (!scrollController.hasClients) return true;
    if (scrollController.positions.length != 1) return true;
    // In a reversed list, minScrollExtent is the bottom (newest messages)
    return scrollController.offset <= 150;
  }

  /// Scroll to bottom if user is near bottom, otherwise increment unread badge.
  Future<void> scrollDown({bool force = false}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!scrollController.hasClients) return;
    if (scrollController.positions.length != 1) return;

    if (force || _isNearBottom) {
      unreadNewMessageCount.value = 0;
      isUserScrolledUp.value = false;
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // User is reading old messages — don't interrupt, just show badge
      unreadNewMessageCount.value++;
    }
  }

  /// Force scroll to bottom and clear badge — called from scroll-to-bottom FAB.
  /// Scroll the open conversation to its newest message. Normal chats render
  /// with `reverse: true`, so the bottom (newest) is at `minScrollExtent`. The
  /// BlueEra/Admin thread renders with `reverse: false`, where the newest sits
  /// at the END of the list — so [reversed] must be false there to land at
  /// `maxScrollExtent` instead of scrolling up to the top.
  void jumpToBottom({bool reversed = true}) {
    if (!scrollController.hasClients) return;
    if (scrollController.positions.length != 1) return;
    unreadNewMessageCount.value = 0;
    isUserScrolledUp.value = false;
    scrollController.animateTo(
      reversed
          ? scrollController.position.minScrollExtent
          : scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }


  Future<List<Messages>> loadOfflineMessages(String conversationId) async {
    if (conversationId.isEmpty) return [];
    // Snapshot the current in-memory list and conversation BEFORE the
    // async Hive read. `listenUserNewMessages` fires this method
    // unawaited, so server `messageReceived` / socket `newMessageReceived`
    // can populate the in-memory list while this future is in flight —
    // we must not clobber that fresher state with stale cache.
    final openConvId = userOpenConversationId.value;
    final currentInMemory = List<Messages>.from(getListOfMessageData ?? []);

    final localMessages =
        await localStorageHelper.getMessagesByConversationId(conversationId);
    // Deduplicate by message ID from local storage (may contain duplicates
    // from previous sessions where send + socket both saved the same message).
    final seen = <String>{};
    final deduped = <Messages>[];
    for (final m in localMessages) {
      final id = m.id ?? '';
      if (id.isEmpty || seen.add(id)) {
        deduped.add(m);
      }
    }
    if (deduped.isNotEmpty) {
      await _resolveLocalMediaPaths(deduped);
    }

    // If the user has moved on to a different conversation while we
    // were reading Hive, don't paint anything into the now-open one.
    if (openConvId.isNotEmpty &&
        userOpenConversationId.value.isNotEmpty &&
        openConvId != userOpenConversationId.value) {
      return deduped;
    }

    // Merge with whatever the in-memory list contains right now. Anything
    // added by socket events while we were on disk (server fetch reply,
    // newMessageReceived, or an outgoing send echo) MUST win — disk lag
    // would otherwise erase it. Messages without an id (pending temps)
    // are kept as-is from both sides.
    final byId = <String, Messages>{};
    final noIdFromCache = <Messages>[];
    final noIdFromMemory = <Messages>[];
    for (final m in deduped) {
      final id = m.id ?? '';
      if (id.isEmpty) {
        noIdFromCache.add(m);
      } else {
        byId[id] = m;
      }
    }
    for (final m in currentInMemory) {
      final id = m.id ?? '';
      if (id.isEmpty) {
        noIdFromMemory.add(m);
      } else {
        // In-memory wins: the socket / server / send path is the
        // authoritative source for the live session.
        byId[id] = m;
      }
    }
    final merged = <Messages>[
      ...byId.values,
      ...noIdFromCache,
      ...noIdFromMemory,
    ];

    // Always settle the response — even when the cache is empty — so the
    // chat screen doesn't stay stuck on its "Initial"-state spinner while
    // offline (the server pagination call will never come back).
    // getListOfMessageData reads from the response's .data list, so we
    // install the fresh list through the observable.
    getListOfMessageResponse.value = ApiResponse.complete(merged);
    if (merged.isNotEmpty) scrollDown();
    return merged;
  }

  Future<bool?> sendProductMessages(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUserLargeFile(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {

        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        // Enquiry / booking cards are fabricated on the client (see
        // Docs/backend/*-enquiry-card.md). The chat backend may not echo
        // our custom `metadata` blob back, so the parsed `message.metadata`
        // would be empty and the shared EnquiryCardView would render blank.
        // Overlay the sent metadata onto the returned message whenever the
        // parsed message is missing it — same pattern as the payment-
        // screenshot overlay in `sendMessageLargeFile` (line ~4661).
        _overlayFabricatedEnquiryMetadata(message, params);
        if (message.subType != "comment") {
          final alreadyExists = message.id != null &&
              (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
          if (!alreadyExists) {
            getListOfMessageData?.add(message);
          }
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          scrollDown();
          saveSingleMessageToLocal(
              message.conversationId ?? '', message);
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

        if (chatFromBusinessProfile.value) {
          canPopBusiness.value = true;
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
      commonSnackBar(message: e.toString());
    }
    return null;
  }

  /// Re-hydrates enquiry / booking metadata on a just-sent message from
  /// the params we sent, when the backend response didn't echo it. Only
  /// touches metadata that's still missing after `Messages.fromJson` —
  /// so if the backend does echo, this is a no-op.
  ///
  /// See Docs/backend/vehicle-enquiry-card.md §4, hotel/education/
  /// healthcare-enquiry-card.md — all four flows fabricate the card
  /// client-side and rely on `metadata.<x>Enquiry` / `metadata.booking`
  /// being present on the returned message so the shared
  /// `EnquiryCardView` renders on the sender's side without waiting for
  /// the recipient socket echo.
  void _overlayFabricatedEnquiryMetadata(
      Messages message, Map<String, dynamic> params) {
    final rawMeta = params[ApiKeys.metadata];
    if (rawMeta is! Map) return;
    final sentMeta = Map<String, dynamic>.from(rawMeta);
    message.metadata ??= MessageMetadata();
    final md = message.metadata!;

    switch (message.messageType) {
      case 'vehicle_booking':
        md.vehicleBookingId ??= sentMeta['vehicleBookingId']?.toString();
        if (md.booking == null && sentMeta['booking'] is Map) {
          md.booking = VehicleBooking.fromJson(
              Map<String, dynamic>.from(sentMeta['booking'] as Map));
        }
        break;
      case 'hotel_enquiry':
        md.hotelEnquiryId ??= sentMeta['hotelEnquiryId']?.toString();
        if (md.hotelEnquiry == null && sentMeta['hotelEnquiry'] is Map) {
          md.hotelEnquiry = HotelEnquiryModel.fromJson(
              Map<String, dynamic>.from(sentMeta['hotelEnquiry'] as Map));
        }
        break;
      case 'education_enquiry':
        md.educationEnquiryId ??= sentMeta['educationEnquiryId']?.toString();
        if (md.educationEnquiry == null &&
            sentMeta['educationEnquiry'] is Map) {
          md.educationEnquiry = EducationEnquiryModel.fromJson(
              Map<String, dynamic>.from(sentMeta['educationEnquiry'] as Map));
        }
        break;
      case 'healthcare_enquiry':
        md.healthcareEnquiryId ??= sentMeta['healthcareEnquiryId']?.toString();
        if (md.healthcareEnquiry == null &&
            sentMeta['healthcareEnquiry'] is Map) {
          md.healthcareEnquiry = HealthcareEnquiryModel.fromJson(
              Map<String, dynamic>.from(sentMeta['healthcareEnquiry'] as Map));
        }
        break;
      case 'business_enquiry':
        md.businessEnquiryId ??= sentMeta['businessEnquiryId']?.toString();
        if (md.businessEnquiry == null &&
            sentMeta['businessEnquiry'] is Map) {
          md.businessEnquiry = BusinessEnquiryModel.fromJson(
              Map<String, dynamic>.from(sentMeta['businessEnquiry'] as Map));
        }
        break;
    }
  }

  Future<void> getLocalConversation(String conversationId, userId,
      [String? otherUserId, String? name]) async {
    // Clear previous conversation data to prevent stale messages from mixing in.
    getListOfMessageResponse.value = ApiResponse.initial('Initial');
    // Load cached messages first for instant UI. Awaiting here means the
    // screen either paints the cached list or settles on an empty-complete
    // state before the async socket emit runs — so we never strand the UI
    // on the loading spinner when the network is down.
    await loadOfflineMessages(conversationId);

    // Reset pagination for the newly-opened conversation and cache the
    // params so loadMoreMessages can re-emit with the same identifiers.
    currentMessagePageSize.value = _messagePageStep;
    isLoadingMoreMessages.value = false;
    _currentChatUserIdForOnline = userId?.toString();
    _currentChatOtherUserId = otherUserId;
    _currentChatName = name;

    _emitFetchMessages(conversationId);
    // Drain any pending messages for this conversation in the background —
    // text-like ones will be retried via repo, media via generateUploadUrlsApi.
    // Fire and forget; errors are handled inside the drainer/offline methods.
    if (conversationId.isNotEmpty) {
      unawaited(PendingMessageDrainer.instance.drainNow());
      unawaited(sendOfflineMessage(conversationId));
    }
    return;
  }

  /// Builds and emits the `messageReceived` fetch payload for the currently
  /// open conversation using the cached identifiers + current page size.
  ///
  /// When the group-chat screen is on the "Mentioned" (tab 1) or "Assigned"
  /// (tab 2) tab, the corresponding filter flag is forwarded so pagination /
  /// load-more stays inside the same filtered set (see
  /// `lib/docs/filtered-messages-integration-guide.md`). Tab 0 omits both
  /// flags → byte-identical to the pre-filter behaviour.
  void _emitFetchMessages(String conversationId) {
    final groupTab = groupChatScreenSelectedTab.value;
    final params = <String, dynamic>{
      if (conversationId.isEmpty)
        ApiKeys.other_user_id: _currentChatOtherUserId
      else
        ApiKeys.conversation_id: conversationId,
      ApiKeys.page: 1,
      ApiKeys.is_online_user: _currentChatUserIdForOnline,
      ApiKeys.per_page_message: currentMessagePageSize.value,
      if (_currentChatName != null && _currentChatName == "BlueEra Orders")
        ApiKeys.orders_conversation: true,
      if (groupTab == 1) ApiKeys.mentioned: true,
      if (groupTab == 2) ApiKeys.assigned: true,
    };
    emitEvent(ChatEmitEvents.messageReceived, params);
  }

  /// Bumps [currentMessagePageSize] by 30 and re-emits so the server returns
  /// the extended window. Called from the chat screen's scroll listener when
  /// the user reaches the top of the (reversed) list. Guarded so rapid
  /// scrolls can't queue multiple in-flight fetches.
  Future<void> loadMoreMessages() async {
    if (isLoadingMoreMessages.value) return;
    final conversationId = userOpenConversationId.value;
    if (conversationId.isEmpty && (_currentChatOtherUserId ?? '').isEmpty) {
      return;
    }
    isLoadingMoreMessages.value = true;
    currentMessagePageSize.value += _messagePageStep;
    _emitFetchMessages(conversationId);
    // No success callback in the socket layer — release the guard after a
    // short delay so the next top-reach can bump again.
    Future.delayed(const Duration(seconds: 2), () {
      isLoadingMoreMessages.value = false;
    });
  }

  void emitEvent(String event, dynamic data,
      [ String? conversationId]) async {
    if (event == ChatEmitEvents.messageReceived &&
        (conversationId ?? "").isNotEmpty &&
        conversationId != userOpenConversationId.value) {
      // Only clear when we're explicitly switching to a different conversation.
      // Bare calls (no conversationId arg) must NOT wipe the cached list —
      // that would strand the offline UI on the spinner after loadOfflineMessages
      // just populated it. The pre-.value comparison also compared a String to
      // an RxString object, which was always unequal.
      getListOfMessageResponse.value = ApiResponse.initial('Initial');
    }
    if (event == ChatEmitEvents.ChatList) {
      final type = data[ApiKeys.type];
      // Stash the requested type so the listener can fall back to it when
      // the server response omits `type` — otherwise business/order
      // payloads silently get routed into the personal Rx and the
      // Inquiry / Orders tabs stay on "No chats found".
      if (type is String && type.isNotEmpty) {
        _pendingChatListType = type;
      }
      // Local-first: paint cached chat list instantly so offline users still
      // see their history. The socket response will overwrite this once it
      // arrives with authoritative data.
      try {
        if (type is String && type.isNotEmpty) {
          final List<ChatList> localChats =
              await localStorageHelper.getChatListFromLocal(type);

          if (localChats.isNotEmpty) {
            loadChatListWithType(
                chatListModel: GetChatListModel(
              type: type,
              success: true,
              chatList: List<ChatList?>.from(localChats),
              archived: [],
            ));
          }
        }
      } catch (e) {
        debugPrint('emitEvent getChatListFromLocal error: $e');
      }

      Map<String, dynamic> dataParams = {ApiKeys.type: data[ApiKeys.type]};
      chatSocket.emitEvent(event, dataParams);
      chatSocket.emitEvent(
          ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
    } else {
      chatSocket.emitEvent(event, data);
    }
  }

  // Future<void> loadAllChatListFromLocal() async {
  //   try {
  //     final allChats = await localStorageHelper.getAllChatListsFromLocal();
  //
  //     for (final entry in allChats.entries) {
  //       loadChatListWithType(
  //           chatListModel: GetChatListModel(
  //         type: entry.key,
  //         success: true,
  //         chatList: List<ChatList?>.from(entry.value),
  //         archived: [],
  //       ));
  //     }
  //   } catch (e) {
  //     debugPrint('loadAllChatListFromLocal error: $e');
  //   }
  // }

  void disposeSocket() {
    socketConnected.value = false;
    socketConnectedCalled.value = false;
    chatSocket.disposeSocket();
  }

  List<Map<String, dynamic>>? contactListParamsData;
  String? findServiceByContactParamsType;

  void loadContactsFromLocalStorage(Map<String, dynamic> value) {
    contactsListModel?.value = ContactListModel.fromJson(value);
    viewContactsListResponse.value = ApiResponse.complete(value);
  }

  /// Try to hydrate the contacts model from Hive without hitting the network.
  /// Returns true when cache was found and the UI was pointed at it.
  Future<bool> hydrateContactsFromCache() async {
    if (contactsListModel?.value.data != null) {
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return true;
    }
    final cached = await localStorageHelper.getContacts();
    if (cached == null) return false;
    contactsListModel?.value = ContactListModel.fromJson(cached);
    viewContactsListResponse.value =
        ApiResponse.complete(contactsListModel?.value);
    return true;
  }

  /// Upload contacts to API and save response to Hive.
  /// Memory → Hive → API, in that order.
  Future<void> uploadContacts(List<Map<String, dynamic>> params) async {
    contactListParamsData = params;

    // Already loaded in memory — skip everything
    if (contactsListModel?.value.data != null) {
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return;
    }

    // Hive cache — lets us render the contact list offline after the first
    // successful sync. Callers who want a fresh snapshot use refreshContacts.
    final cached = await localStorageHelper.getContacts();
    if (cached != null) {
      contactsListModel?.value = ContactListModel.fromJson(cached);
      viewContactsListResponse.value =
          ApiResponse.complete(contactsListModel?.value);
      return;
    }

    // No cache yet — hit the API and persist the response for next time.
    ResponseModel responseModel =
        await ChatViewRepo().getConnectionsSync(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      if (data is Map<String, dynamic>) {
        await localStorageHelper.saveContacts(data);
      }
      contactsListModel?.value = ContactListModel.fromJson(data);
      viewContactsListResponse.value = ApiResponse.complete(responseModel);
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
    }
  }

  /// Force refresh contacts from API (called by refresh button).
  /// Always hits the network; updates the Hive cache on success.
  Future<void> refreshContacts(List<Map<String, dynamic>> params) async {
    contactListParamsData = params;
    viewContactsListResponse.value = ApiResponse.initial('Initial');

    ResponseModel responseModel =
        await ChatViewRepo().getConnectionsSync(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      if (data is Map<String, dynamic>) {
        await localStorageHelper.saveContacts(data);
      }
      contactsListModel?.value = ContactListModel.fromJson(data);
      viewContactsListResponse.value = ApiResponse.complete(responseModel);
    } else {
      // Fallback to whatever we already have so the list doesn't blank out.
      if (contactsListModel?.value.data != null) {
        viewContactsListResponse.value =
            ApiResponse.complete(contactsListModel?.value);
      } else {
        final cached = await localStorageHelper.getContacts();
        if (cached != null) {
          contactsListModel?.value = ContactListModel.fromJson(cached);
          viewContactsListResponse.value =
              ApiResponse.complete(contactsListModel?.value);
        } else {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      }
    }
  }

  Future<void> setContact(String type,List<Map<String, dynamic>> params)async{
    contactListParamsData=params;
    await findServiceByContacts(type, params);
  }
  Future<void> reloadContact()async{

    await findServiceByContacts(findServiceByContactParamsType??'',null);
  }
  Future<void> findServiceByContacts(String type,List<Map<String, dynamic>>? contactList) async {
    getServiceByContactResponse.value=ApiResponse.initial("Initial");

    findServiceByContactParamsType=type;
    final params={
      ApiKeys.profile_type: type,
      ApiKeys.contact_list:contactList??contactListParamsData
    };
      ResponseModel responseModel =
          await ChatViewRepo().findServiceByContactApi(params);
      if (responseModel.isSuccess) {
        final List<dynamic> listOf = responseModel.data ?? [];

        findProfessionalContactList.value = listOf
            .map((e) => ProfessionalContact.fromJson(e as Map<String, dynamic>))
            .toList();

        getServiceByContactResponse.value=ApiResponse.complete(findProfessionalContactList);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        getServiceByContactResponse.value=ApiResponse.error(responseModel.message ?? AppStrings.somethingWentWrong);

      }
  }

  Future<void> loadGroupConnections(
      {int limit = 20, int offset = 0, String? search}) async {
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

  Future<void> getLatestChat() async {
    try {
      ResponseModel responseModel = await ChatViewRepo().getLatestChatRepo();
      if (responseModel.isSuccess) {
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {}
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

  /// Fetch symbol-reply chat requests from `GET chat-service/chat/requests`.
  ///
  /// [role] selects the view:
  ///   • `"incoming"` (default) — populates [chatRequestsListModel] with
  ///     requests where the caller is the recipient (Accept/Decline).
  ///   • `"sent"` — populates [sentChatRequestsListModel] with the
  ///     initiator's outgoing pending requests (Cancel-only).
  Future<void> getChatRequestsList(
      {int limit = 20, String? nextCursor, String role = 'incoming'}) async {
    final isSent = role == 'sent';
    final responseRx =
        isSent ? sentChatRequestsListResponse : chatRequestsListResponse;
    final modelRx = isSent ? sentChatRequestsListModel : chatRequestsListModel;
    try {
      responseRx.value = ApiResponse.loading();
      final responseModel = await ChatViewRepo().getChatRequestsListApi(
          limit: limit, nextCursor: nextCursor, role: isSent ? 'sent' : null);
      if (responseModel.isSuccess) {
        modelRx.value =
            ChatRequestsListModel.fromJson(responseModel.response!.data);
        responseRx.value = ApiResponse.complete(responseModel);
      } else {
        responseRx.value = ApiResponse.error(
            responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      responseRx.value = ApiResponse.error('error');
    }
  }

  /// Recipient-only: accept or decline a pending request.
  /// Returns true on 2xx so the caller can optimistically remove the row.
  /// On accept, the conversation type flips to `personal` server-side and
  /// history is preserved; the initiator can then send freely. On decline,
  /// the conversation + messages are deleted server-side.
  Future<bool> respondToChatRequest({
    required String conversationId,
    required String action,
    bool blockInitiator = false,
  }) async {
    try {
      final responseModel = await ChatViewRepo().respondChatRequestApi(
        conversationId: conversationId,
        action: action,
        blockInitiator: blockInitiator,
      );
      if (responseModel.isSuccess) {
        // Drop the row from the in-memory incoming list immediately —
        // socket reconnect will reconcile if anything is stale.
        final list = chatRequestsListModel.value.data;
        if (list != null) {
          list.removeWhere((r) => r.conversationId == conversationId);
          chatRequestsListModel.refresh();
        }
        return true;
      }
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }

  /// Initiator-only: withdraw a still-pending request before the recipient
  /// acts. Server deletes the conversation and emits `requestDeclined` to
  /// the recipient with `reason: "cancelled_by_initiator"`.
  Future<bool> cancelChatRequest(String conversationId) async {
    try {
      final responseModel =
          await ChatViewRepo().cancelChatRequestApi(conversationId);
      if (responseModel.isSuccess) {
        final list = sentChatRequestsListModel.value.data;
        if (list != null) {
          list.removeWhere((r) => r.conversationId == conversationId);
          sentChatRequestsListModel.refresh();
        }
        return true;
      }
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }

  /// One-time hydration of every conversation + its message history into
  /// local storage. Runs on the very first app open after install (guarded by
  /// [SharedPreferenceUtils.hasInitialChatExport]) and never again. After it
  /// completes, each chat screen's local-first load can render its full
  /// history offline without hitting the per-conversation messages API.
  Future<void> getChatExportAll() async {
    try {
      // One-time guard — flip to "true" on success, short-circuit next time.
      final alreadyDone = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.hasInitialChatExport);
      if (alreadyDone == 'true') {
        debugPrint('[CHAT_EXPORT_ALL] already synced — skipping');
        return;
      }

      final responseModel = await ChatViewRepo().getChatExportAllApi();
      if (!responseModel.isSuccess) {
        debugPrint(
            '[CHAT_EXPORT_ALL] failed: ${responseModel.message} | status: ${responseModel.response?.statusCode}');
        return;
      }

      final data = responseModel.response?.data;
      if (data is! Map) return;

      final currentUserId = (data['user_id']?.toString().isNotEmpty ?? false)
          ? data['user_id'].toString()
          : userId;
      final conversations = data['conversations'];
      if (conversations is! List) return;

      final personalList = <ChatList>[];
      final businessList = <ChatList>[];
      final groupList = <ChatList>[];

      for (final convo in conversations) {
        if (convo is! Map) continue;
        final map = Map<String, dynamic>.from(convo);
        final conversationId = map['conversation_id']?.toString() ?? '';
        if (conversationId.isEmpty) continue;

        // ── Messages: parse + save per conversation ────────────────────────
        final rawMessages = map['messages'];
        if (rawMessages is List) {
          final parsed = <messageModel.Messages>[];
          for (final m in rawMessages) {
            if (m is Map) {
              try {
                parsed.add(messageModel.Messages.fromJson(
                    Map<String, dynamic>.from(m)));
              } catch (e) {
                debugPrint('[CHAT_EXPORT_ALL] message parse skip: $e');
              }
            }
          }
          if (parsed.isNotEmpty) {
            await localStorageHelper.saveMessagesByConversationId(
                conversationId, parsed);
          }
        }

        // ── Chat-list entry for this conversation ──────────────────────────
        final type =
            (map['type']?.toString() ?? AppConstants.personal_Chat_Type)
                .toLowerCase();
        final isGroup = type == AppConstants.group_Chat_Type;

        chatListModel.Sender? sender;
        if (!isGroup) {
          // 1:1 chat → pick the "other" participant so the row shows their
          // name and photo instead of the current user's.
          final participants = map['participants'];
          if (participants is List) {
            for (final p in participants) {
              if (p is! Map) continue;
              final pid = p['user_id']?.toString() ?? '';
              if (pid.isEmpty || pid == currentUserId) continue;
              final user = p['user'];
              if (user is Map) {
                sender = chatListModel.Sender.fromJson(
                    Map<String, dynamic>.from(user));
              }
              break;
            }
          }
        }

        final chat = ChatList(
          conversationId: conversationId,
          isGroup: isGroup,
          lastMessage: map['last_message']?.toString(),
          lastMessageType: map['last_message_type']?.toString(),
          createdAt: map['created_at']?.toString(),
          updatedAt: map['updated_at']?.toString(),
          groupName: map['group_name']?.toString(),
          groupProfileImage: map['group_profile_image']?.toString(),
          publicGroup:
              map['public_group'] is bool ? map['public_group'] as bool : false,
          unreadCount: 0,
          sender: sender,
        );

        switch (type) {
          case AppConstants.business_Chat_Type:
            businessList.add(chat);
            break;
          case AppConstants.group_Chat_Type:
            groupList.add(chat);
            break;
          default:
            personalList.add(chat);
        }
      }

      // Merge with whatever the socket/prior sessions already cached so we
      // don't clobber unrelated entries.
      await _mergeAndSaveExportedChatList(
          personalList, AppConstants.personal_Chat_Type);
      await _mergeAndSaveExportedChatList(
          businessList, AppConstants.business_Chat_Type);
      await _mergeAndSaveExportedChatList(
          groupList, AppConstants.group_Chat_Type);

      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.hasInitialChatExport, 'true');
      debugPrint(
          '[CHAT_EXPORT_ALL] stored personal=${personalList.length} business=${businessList.length} group=${groupList.length}');

      // Pre-warm flutter_cache_manager with every chat-list avatar URL so
      // CachedNetworkImage can serve them on later offline launches. Without
      // this, the cache is empty until the user opens a chat while online
      // and images render blank in the list.
      final avatarUrls = <String>{};
      for (final c in [...personalList, ...businessList]) {
        final url = c.sender?.profileImage;
        if (url != null && url.startsWith('http')) avatarUrls.add(url);
      }
      for (final c in groupList) {
        final url = c.groupProfileImage;
        if (url != null && url.startsWith('http')) avatarUrls.add(url);
      }
      // Fire-and-forget: this can run for a while on slow networks but
      // shouldn't block the chat-list UI.
      unawaited(_prefetchToImageCache(avatarUrls));
    } catch (e, st) {
      debugPrint('[CHAT_EXPORT_ALL] error: $e\n$st');
    }
  }

  Future<void> _prefetchToImageCache(Iterable<String> urls) async {
    final mgr = DefaultCacheManager();
    for (final url in urls) {
      try {
        await mgr.downloadFile(url);
      } catch (e) {
        debugPrint('[CHAT_EXPORT_ALL] prefetch fail $url: $e');
      }
    }
    debugPrint('[CHAT_EXPORT_ALL] prefetched ${urls.length} avatars');
  }

  Future<void> _mergeAndSaveExportedChatList(
      List<ChatList> fresh, String type) async {
    if (fresh.isEmpty) return;
    final existing = await localStorageHelper.getChatListFromLocal(type);
    final byId = <String, ChatList>{
      for (final c in existing)
        if ((c.conversationId ?? '').isNotEmpty) c.conversationId!: c,
    };
    for (final c in fresh) {
      final id = c.conversationId;
      if (id == null || id.isEmpty) continue;
      byId[id] = c;
    }
    await localStorageHelper.saveChatList(byId.values.toList(), type);
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
        chatSocket.emitEvent(ChatEmitEvents.ChatList,
            {ApiKeys.type: AppConstants.personal_Chat_Type});
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

  Future<void> startLiveLocationTracking(Duration duration) async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) return;
    Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
    );
    await LiveTrackingSocketService().connectToSocket(LatLng(pos.latitude, pos.longitude));

     Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // 🔥 10 meters move = update
      ),
    ).listen((Position pos) {
      LiveTrackingSocketService().emitEvent(
        LiveTrackEmitEvents.updateLocation,
        {
          ApiKeys.coordinates: [pos.longitude, pos.latitude],
          ApiKeys.availabilityStatus: "OPEN",
        },
      );
    });
    Timer(duration, (){
      LiveTrackingSocketService().disconnectSocket();
    });
  }

  //
  void stopLiveLocationTracking() {
    LiveTrackingSocketService().disconnectSocket();
  }
  Duration labelToDuration(String label) {
    switch (label) {
      case "15min":
        return const Duration(minutes: 15);
      case "1h":
        return const Duration(hours: 1);
      case "8h":
        return const Duration(hours: 8);
      default:
      // fallback: "30min", "45min" madhiri iruntha
        if (label.endsWith("min")) {
          final mins = int.tryParse(label.replaceAll("min", ""));
          return Duration(minutes: mins ?? 0);
        }
        if (label.endsWith("h")) {
          final hrs = int.tryParse(label.replaceAll("h", ""));
          return Duration(hours: hrs ?? 0);
        }
        return Duration.zero;
    }
  }
  List<String> getMentionedUserIds({
    required String message,
    required List<GroupMembersListModel> members,
  }) {
    final RegExp mentionRegExp = RegExp(r'@(\w+)');

    final matches = mentionRegExp.allMatches(message);

    List<String> mentionedIds = [];

    for (final match in matches) {
      final mentionedName = match.group(1)?.toLowerCase().trim();

      if (mentionedName == null) continue;

      final user = members.firstWhereOrNull(
            (member) => member.name?.toLowerCase().trim() == mentionedName,
      );

      if (user?.id != null) {
        mentionedIds.add(user!.id!);
      }
    }

    return mentionedIds;
  }
  /// Build a local pending-message stand-in for a message that can't be sent
  /// right now (offline or API failure). Persists to Hive with sendStatus
  /// "pending" and its retry params so the drainer can re-fire it later.
  Messages _buildPendingMessage(
      Map<String, dynamic> params, String? fileName) {
    final now = DateTime.now().toUtc();
    final isoTime = now.toIso8601String();
    // Populate senderId + sender from the signed-in user so the pending card
    // renders identically to a server-returned message. Without these, the
    // fallback in MessageCard (currentUserId != senderId) flips the bubble
    // to the receiver side whenever myMessage gets lost across a Hive
    // round-trip, and tick marks / avatar / name stay blank until the
    // server response overwrites the entry.
    return Messages(
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
        status: "sent",
        message: params[ApiKeys.message],
        latitude: params[ApiKeys.message_type] == "location"
            ? params[ApiKeys.latitude]
            : null,
        longitude: params[ApiKeys.message_type] == "location"
            ? params[ApiKeys.longitude]
            : null,
        myMessage: true,
        senderId: userId,
        sender: messageModel.Sender(
          id: userId,
          name: userNameGlobal,
          profileImage: userProfileGlobal,
        ),
        conversationId: params[ApiKeys.conversation_id],
        createdAt: isoTime,
        sendPendingMsgParams: params);
  }

  /// Optimistically show a pending message in the open conversation, persist
  /// it to Hive, and patch the chat list preview. Returns the temp message.
  Future<Messages> _enqueuePendingMessage(
      Map<String, dynamic> params, String? fileName) async {
    final message = _buildPendingMessage(params, fileName);
    getListOfMessageData?.add(message);
    getListOfMessageResponse.value =
        ApiResponse.complete(getListOfMessageData);
    await saveSingleMessageToLocal(
        params[ApiKeys.conversation_id] ?? '', message, params);
    _updateChatListLastMessage(
      params[ApiKeys.conversation_id],
      message.message,
      message.messageType,
      message.createdAt,
      sendStatus: "pending",
    );
    return message;
  }

  /// Queue an audio / document message for offline retry.
  ///
  /// MultipartFile objects can't be JSON-encoded into Hive, so the offline
  /// path in sendMessage used to silently lose these messages. This helper
  /// stores the raw local file path list in `pendingFilePaths` and a clean
  /// params map (no MultipartFile) in `sendPendingMsgParams`, mirroring
  /// the image/video offline flow. The drainer rebuilds MultipartFile
  /// objects from the paths when it retries.
  Future<void> enqueuePendingFileMessage({
    required String messageType,
    required List<String> filePaths,
    String? conversationId,
    String? otherUserId,
    String? caption,
    String? fileName,
    bool isInitial = false,
  }) async {
    final now = DateTime.now().toUtc();
    final isoTime = now.toIso8601String();
    final convKey = conversationId ?? '';
    final String tempId = "${isoTime}_$convKey";

    final Map<String, dynamic> params = {
      if (isInitial)
        ApiKeys.other_user_id: otherUserId
      else
        ApiKeys.conversation_id: conversationId,
      if (caption != null && caption.isNotEmpty) ApiKeys.message: caption,
      ApiKeys.message_type: messageType,
    };

    final message = Messages(
      docFileName: fileName,
      id: tempId,
      messageType: messageType,
      sendStatus: "pending",
      status: "sent",
      message: caption,
      myMessage: true,
      senderId: userId,
      sender: messageModel.Sender(
        id: userId,
        name: userNameGlobal,
        profileImage: userProfileGlobal,
      ),
      conversationId: conversationId,
      createdAt: isoTime,
      pendingFilePaths: filePaths,
      url: filePaths.map((p) => MessageMediaUrl(url: p)).toList(),
      sendPendingMsgParams: params,
    );

    getListOfMessageData?.add(message);
    getListOfMessageResponse.value =
        ApiResponse.complete(getListOfMessageData);
    await saveSingleMessageToLocal(convKey, message, params);
    _updateChatListLastMessage(
      conversationId,
      caption,
      messageType,
      isoTime,
      sendStatus: "pending",
    );
  }

  /// Retry an audio / document pending row by rebuilding MultipartFile parts
  /// from its saved local paths, then calling the standard send endpoint.
  Future<void> _retryPendingFileMessage({
    required Map<String, dynamic> params,
    required List<String> filePaths,
    required String messageId,
    String? fileName,
  }) async {
    try {
      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      final List<dio.MultipartFile> parts = [];
      for (final p in filePaths) {
        if (p.isEmpty) continue;
        final name = p.split('/').last;
        parts.add(await dio.MultipartFile.fromFile(p, filename: name));
      }
      if (parts.isEmpty) return;
      final retryParams = Map<String, dynamic>.from(params)
        ..[ApiKeys.files] = parts;

      final ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(retryParams);
      if (!responseModel.isSuccess) return;

      final data = responseModel.response?.data;
      if (data == null) return;
      final Messages message = Messages.fromJson(data['data']);
      if (message.subType == "comment") return;

      Messages? oldPending = getListOfMessageData
          ?.firstWhereOrNull((element) => element.id == messageId);
      if (oldPending != null) getListOfMessageData?.remove(oldPending);
      final alreadyExists = message.id != null &&
          (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
      if (!alreadyExists) getListOfMessageData?.add(message);
      getListOfMessageResponse.value =
          ApiResponse.complete(getListOfMessageData);
      await localStorageHelper.replacePendingWithServerMessage(
          params[ApiKeys.conversation_id]?.toString() ?? '',
          messageId,
          message);
    } catch (e) {
      debugPrint('_retryPendingFileMessage failed: $e');
    }
  }

  Future<bool?> sendMessage(Map<String, dynamic> params,
      [List<File>? sendFiles, String? fileName]) async {
    if (isSending.value) return null;
    isSending.value = true;
    try {
      attachRouteParam(params);
      params[ApiKeys.tagged_users] = taggedUserIds.join(',');
      taggedUserIds.clear();
      if(params[ApiKeys.message_type]=="live_location"){
       await startLiveLocationTracking(labelToDuration(params[ApiKeys.live_location_validity]));
      }

      clearMessageControllerCommon();

      if (replyMessage?.value?.id != null) {
        replyMessage?.value = Messages();
      }
      final isVideoSend = sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video';

      // Offline branch — skip the network call entirely, queue locally,
      // and let PendingMessageDrainer flush when connectivity returns.
      // Media (image/video) skips this branch: generateUploadUrlsApi owns
      // its own retry path with the pending file list.
      if (!isVideoSend &&
          (sendFiles == null || sendFiles.isEmpty) &&
          !await checkInternetStatus()) {
        await _enqueuePendingMessage(params, fileName);
        return true;
      }

      if (isVideoSend) {
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
        // For video: swap loading placeholder with real message in a single update
        if (isVideoSend) {
          if (getListOfMessageData != null && getListOfMessageData!.isNotEmpty) {
            getListOfMessageData!.removeLast();
          }
          // Don't reassign getListOfMessageResponse here — batch with the add below
        }

        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);

        if (message.subType != "comment") {
          // Reset conversation-level status to match the new message's actual
          // status from the server. Without this, a stale 'read' value from a
          // previous messageStatusUpdate would make new messages show blue ticks
          // even when the receiver has already left the conversation.
          if (message.status != null) {
            readMessageStatus.value = message.status!;
          }

          // Deduplicate: newMessageReceived socket event may have already added this

          final alreadyExists = message.id != null &&
              (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
     if (!alreadyExists) {
    getListOfMessageData?.add(message);
    }
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
          saveSingleMessageToLocal(
              params[ApiKeys.conversation_id], message);
          // Update chat list locally so last message is visible immediately.
          // Pass an empty sendStatus so any prior "pending" clock icon is
          // cleared now that the server accepted the message.
          _updateChatListLastMessage(
            params[ApiKeys.conversation_id],
            message.message,
            message.messageType,
            message.updatedAt ?? message.createdAt,
            sendStatus: "",
          );
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
        if (chatFromBusinessProfile.value) {
          canPopBusiness.value = true;
        }
        scrollDown();

        clearMessageControllerCommon();
        return true;
      } else {
        clearMessageControllerCommon();
        // Non-success response (network error, 5xx, etc.): for non-media
        // messages, persist as pending so the drainer can retry. Media
        // messages fall through with a snackbar because their upload path
        // is separate.
        final isMediaPayload = (sendFiles != null && sendFiles.isNotEmpty) ||
            params[ApiKeys.message_type] == 'video' ||
            params[ApiKeys.message_type] == 'image';
        if (!isMediaPayload) {
          await _enqueuePendingMessage(params, fileName);
          return true;
        }
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      clearMessageControllerCommon();
      final isMediaPayload = (sendFiles != null && sendFiles.isNotEmpty) ||
          params[ApiKeys.message_type] == 'video' ||
          params[ApiKeys.message_type] == 'image';
      if (!isMediaPayload) {
        await _enqueuePendingMessage(params, fileName);
      }
      if (sendFiles != null &&
          sendFiles.isNotEmpty &&
          params[ApiKeys.message_type] == 'video') {
        if (getListOfMessageData != null && getListOfMessageData!.isNotEmpty) {
          getListOfMessageData!.removeLast();
        }
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
      }
    } finally {
      isSending.value = false;
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

  Future<bool> createGroupApi(Map<String, dynamic> params,
      {bool? isFromFile,
      Map<String, dynamic>? fileParams,
      File? fileSended}) async {
    if (isFromFile != null) {
      ResponseModel responseModel =
          await ChatViewRepo().generateUploadUrlsApi(fileParams!);
      clearMessageControllerCommon();

      if (!responseModel.isSuccess) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }

      final data = responseModel.response?.data;
      final uploadModel = GenerateUploadUlrModel.fromJson(data);
      generateUploadUlrModel?.value = uploadModel;

      final files = uploadModel.files;

      // Parallel Uploads using Future.wait
      await Future.wait(List.generate(files!.length, (i) {
        final file = fileSended;
        final url = files[i].uploadUrl ?? '';
        final type = files[i].fileType ?? '';
        return uploadFileToS3(file: file!, fileType: type, preSignedUrl: url);
      }));
      List<String> sharedFile = uploadModel.files?.map((element) {
            return element.publicUrl ?? '';
          }).toList() ??
          [];
      params.addAll({
        ApiKeys.group_profile_image: sharedFile,
      });
      ResponseModel responseModelCreas =
          await ChatViewRepo().createNewGroupApi(params);
      if (responseModelCreas.isSuccess) {
        emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: "group"});
        return true;
      } else {
        commonSnackBar(
            message:
                responseModelCreas.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } else {
      ResponseModel responseModel =
          await ChatViewRepo().createNewGroupApi(params);

      if (responseModel.isSuccess) {
        emitEvent(ChatEmitEvents.ChatList,
            {ApiKeys.type: AppConstants.group_Chat_Type});
        return true;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
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
      List<GroupMembersListModel> members =
          dataList.map((item) => GroupMembersListModel.fromJson(item)).toList();


      getGroupMembersResponse.value = ApiResponse.complete(members);
      ;
    } else {
      commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong);
    }
  }
  /// Open a chat directly from the chat list without an API call.
  /// All required data is already available from the ChatList object.
  Future<void> openChatFromChatList({
    required String userId,
    required String conversationId,
    required String type,
    String? contactName,
    String? contactNo,
    String? profileImage,
  }) async {

    businessTabIndexSelected.value = 0;
    await getLocalConversation(
        conversationId, userId, userId, contactName ?? '');

    _navigateToChatScreen(
      type: type,
      userId: userId,
      conversationId: conversationId,
      profileImage: profileImage ?? '',
      contactName: contactName ?? '',
      contactNo: contactNo ?? '',
      isFromContactList: false,
    );
  }

  /// Open a group conversation tapped from a chat list. Group rows can surface
  /// inside the personal/business list payloads (`type:"group"`), so this routes
  /// them to the dedicated [GroupChatScreen] instead of the 1:1 chat screens.
  /// Mirrors [openChatFromChatList]: resets the inner tab and hydrates the
  /// cached messages before navigating.
  Future<void> openGroupFromChatList(ChatList? chat) async {
    if (chat == null) return;
    final conversationId = chat.conversationId ?? '';
    businessTabIndexSelected.value = 0;
    await getLocalConversation(conversationId, '', '', chat.groupName ?? '');
    Get.to(
      () => GroupChatScreen(
        isGroupPrivate: chat.publicGroup ?? false,
        type: AppConstants.group_Chat_Type,
        conversationId: conversationId,
        profileImage: chat.groupProfileImage,
        name: chat.groupName,
      ),
    );
  }

  /// Guards against double-tapping a phone number while a lookup is in flight.
  RxBool isFetchingUserByPhone = false.obs;

  /// Resolve a phone number tapped inside a chat message to a BlueEra user via
  /// `user-service/user/by-phone/{phone}` and, on success, surface a bottom
  /// sheet with their details + a "Chat" button. Accepts any raw string the
  /// user tapped (may contain spaces / +91 / dashes) and normalizes it to the
  /// last 10 digits the API expects.
  Future<void> openUserDetailsByPhone(String rawPhone) async {
    String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    // Strip a leading country code (e.g. 91XXXXXXXXXX) — keep the last 10.
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    if (digits.length != 10) {
      commonSnackBar(message: 'Invalid mobile number');
      return;
    }
    if (isFetchingUserByPhone.value) return;
    isFetchingUserByPhone.value = true;
    try {
      final ResponseModel responseModel =
          await ChatViewRepo().getUserByPhoneApi(digits);
      log('openUserDetailsByPhone($digits) response: ${responseModel.response?.data}');

      final dynamic userJson = responseModel.getExtraData('user');
      if (responseModel.isSuccess && userJson is Map) {
        final dynamic businessJson = responseModel.getExtraData('business');
        final user = UserByPhoneModel.fromJson(
          Map<String, dynamic>.from(userJson),
          business: businessJson is Map
              ? Map<String, dynamic>.from(businessJson)
              : null,
        );
        if (user.id.isEmpty) {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          return;
        }
        showUserByPhoneBottomSheet(user);
      } else {
        // No BlueEra user for this number — offer to save it as a new contact.
        showAddNewContactBottomSheet(digits);
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
    } finally {
      isFetchingUserByPhone.value = false;
    }
  }

  /// Resolve [rawPhone] to a BlueEra user via `user-service/user/by-phone/{phone}`
  /// and return the matched user, or `null` when there is no BlueEra account for
  /// the number (or the number/lookup is invalid).
  ///
  /// Unlike [openUserDetailsByPhone] this performs NO UI of its own — callers
  /// decide what to do with the result. Used by the shared-contact card so its
  /// Call / Chat buttons route BlueEra contacts to an in-app call / chat and
  /// non-BlueEra numbers to the native dialer / SMS app.
  Future<UserByPhoneModel?> resolveBlueEraUserByPhone(String rawPhone) async {
    String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    if (digits.length != 10) {
      commonSnackBar(message: 'Invalid mobile number');
      return null;
    }
    if (isFetchingUserByPhone.value) return null;
    isFetchingUserByPhone.value = true;
    try {
      final ResponseModel responseModel =
          await ChatViewRepo().getUserByPhoneApi(digits);
      final dynamic userJson = responseModel.getExtraData('user');
      if (responseModel.isSuccess && userJson is Map) {
        final dynamic businessJson = responseModel.getExtraData('business');
        final user = UserByPhoneModel.fromJson(
          Map<String, dynamic>.from(userJson),
          business: businessJson is Map
              ? Map<String, dynamic>.from(businessJson)
              : null,
        );
        return user.id.isEmpty ? null : user;
      }
      return null;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return null;
    } finally {
      isFetchingUserByPhone.value = false;
    }
  }

  /// Cache of phone-number → BlueEra user lookups so message bubbles can render
  /// an inline user preview (DP + name) without re-hitting the API on every
  /// rebuild. A key present with a non-null value means a BlueEra user exists;
  /// a key present with `null` means "checked, no BlueEra account". Observable
  /// so the inline preview widgets rebuild when a lookup completes.
  final RxMap<String, UserByPhoneModel?> phoneUserCache =
      <String, UserByPhoneModel?>{}.obs;
  final Set<String> _phoneLookupInFlight = {};

  /// Normalise a raw phone string (may carry `+91`, spaces, dashes) to the
  /// 10-digit national number the API expects, or null when it isn't a valid
  /// 10-digit mobile number.
  String? normalizePhone(String rawPhone) {
    String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) digits = digits.substring(digits.length - 10);
    return digits.length == 10 ? digits : null;
  }

  /// Already-resolved BlueEra user for [rawPhone], or null when the number is
  /// invalid, not yet looked up, or has no BlueEra account. Pair with
  /// [isPhoneChecked] to tell "not yet looked up" from "checked, none".
  UserByPhoneModel? cachedPhoneUser(String rawPhone) {
    final digits = normalizePhone(rawPhone);
    if (digits == null) return null;
    return phoneUserCache[digits];
  }

  bool isPhoneChecked(String rawPhone) {
    final digits = normalizePhone(rawPhone);
    if (digits == null) return false;
    return phoneUserCache.containsKey(digits);
  }

  /// Looks up [rawPhone] against BlueEra exactly once and records the result in
  /// [phoneUserCache]. Silent — no UI of its own. Safe to call on every build;
  /// it short-circuits when the number is cached or a lookup is already in
  /// flight.
  Future<void> ensurePhoneUserLoaded(String rawPhone) async {
    final digits = normalizePhone(rawPhone);
    if (digits == null) return;
    if (phoneUserCache.containsKey(digits)) return;
    if (_phoneLookupInFlight.contains(digits)) return;
    _phoneLookupInFlight.add(digits);
    try {
      final ResponseModel responseModel =
          await ChatViewRepo().getUserByPhoneApi(digits);
      final dynamic userJson = responseModel.getExtraData('user');
      if (responseModel.isSuccess && userJson is Map) {
        final dynamic businessJson = responseModel.getExtraData('business');
        final user = UserByPhoneModel.fromJson(
          Map<String, dynamic>.from(userJson),
          business: businessJson is Map
              ? Map<String, dynamic>.from(businessJson)
              : null,
        );
        phoneUserCache[digits] = user.id.isEmpty ? null : user;
      } else {
        phoneUserCache[digits] = null;
      }
    } catch (_) {
      // Leave uncached so a later render can retry the lookup.
    } finally {
      _phoneLookupInFlight.remove(digits);
    }
  }

  Future<void> checkChatConnectionAndOpenChat(
      {required String userId,bool? isFromContactList,
        bool? isWithProductSend,
        Map<String, dynamic>? shareProductParams,
        String? name,
        String? conductNo,
        String? profile,
        // Which conversation lane this entry point belongs to —
        // [AppConstants.route_contact] (personal) or
        // [AppConstants.route_discover] (business). When set it both forces
        // the destination chat screen into that lane (so e.g. a Discover tap
        // always lands on the business thread, even if a personal one exists)
        // and is attached to every send as the `route` param. `null` keeps the
        // legacy behaviour of opening whatever the backend reports.
        String? route,
        // When non-empty, the destination chat screen seeds its input field
        // with this text so the user starts a new conversation with a
        // pre-written intro (e.g. "Hi, I'm Alice — I'd like to know more
        // about your service"). The user can edit before sending.
        String? prefilledMessage,
      }) async {
    // Set the send lane up-front so any fire-and-forget send below
    // (e.g. sendProductMessages) already carries the right route.
    activeRoute = route;
    Map<String, dynamic> params = {
      ApiKeys.user_id: userId
    };
    ResponseModel responseModel =
    await ChatViewRepo().checkChatConnectionApi(params);

    if (responseModel.isSuccess) {
      final data = responseModel.response?.data;
      CheckChatConversationModel details =
      CheckChatConversationModel.fromJson(data);
      String conversationId=details.data?.conversationId??'';
      String otherUserId=details.data?.otherUserId??'';
      String chatPersonUserId=userId;
      String contactNo=conductNo??details.data?.sender?.contact??'';
      String contactName=name??details.data?.sender?.name??'';
      String profileImage=profile??details.data?.sender?.profileImage??'';
      final String backendType=details.data?.conversation?.type??'';
      String type=backendType;
      // The send lane wins over the backend-reported type: a `discover` tap
      // always opens the business thread and a `contact` tap the personal one.
      // checkChatConnection only reports one conversation for the pair, so when
      // the lane we want differs from what it returned we open in "initial"
      // mode (blank conversationId). The first routed send then looks up — or
      // creates — that lane's own thread by other_user_id + route, instead of
      // mistakenly writing into the other lane's conversation.
      if (route == AppConstants.route_discover) {
        type = AppConstants.business_Chat_Type;
        if (backendType.toLowerCase() != AppConstants.business_Chat_Type) {
          conversationId = '';
        }
      } else if (route == AppConstants.route_contact) {
        type = AppConstants.personal_Chat_Type;
        if (backendType.toLowerCase() != AppConstants.personal_Chat_Type) {
          conversationId = '';
        }
      }
      businessTabIndexSelected.value = 0;
      await getLocalConversation(
          conversationId, chatPersonUserId, otherUserId, contactName);

      if (isWithProductSend == true) {
        // Inject the resolved conversation identifiers here so callers no
        // longer need a separate checkChatConnection round-trip just to bake
        // them into shareProductParams. conversationId is already lane-correct
        // (it was blanked above when the requested route differs from the
        // backend-reported thread), so a send for a not-yet-existing lane
        // correctly falls back to other_user_id.
        final productParams =
            Map<String, dynamic>.from(shareProductParams ?? {});
        if (conversationId.isNotEmpty) {
          productParams[ApiKeys.conversation_id] = conversationId;
        } else {
          productParams[ApiKeys.other_user_id] = otherUserId;
        }
        await sendProductMessages(productParams);
      }

      _navigateToChatScreen(
        type: type,
        userId: userId,
        conversationId: conversationId,
        profileImage: profileImage,
        contactName: contactName,
        contactNo: contactNo,
        isFromContactList: isFromContactList,
        prefilledMessage: prefilledMessage,
      );
    } else {
      // Offline fallback: try to open from local cache
      final opened = await _tryOpenChatFromLocalCache(
        userId: userId,
        isFromContactList: isFromContactList,
      );
      if (!opened) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    }
  }

  /// Try to open a chat from locally cached chat list data.
  /// Returns true if a cached conversation was found and opened.
  Future<bool> _tryOpenChatFromLocalCache({
    required String userId,
    bool? isFromContactList,
  }) async {
    // First search in-memory chat lists (already loaded)
    ChatList? cachedChat = _findChatInMemory(userId);

    // // If not in memory, search Hive cache
    // cachedChat ??= await localStorageHelper.findChatByUserId(userId);

    if (cachedChat == null || (cachedChat.conversationId ?? '').isEmpty) {
      return false;
    }

    final conversationId = cachedChat.conversationId ?? '';
    final contactName = cachedChat.sender?.name ?? '';
    final profileImage = cachedChat.sender?.profileImage ?? '';
    final contactNo = cachedChat.sender?.contactNo ?? '';
    final chatPersonUserId = cachedChat.sender?.id ?? '';

    businessTabIndexSelected.value = 0;

    // Load cached messages for instant display (no server fetch)
    getListOfMessageResponse.value = ApiResponse.initial('Initial');
    await loadOfflineMessages(conversationId);
    listenUserNewMessages(conversationId: conversationId, userId: chatPersonUserId);

    // Determine type from cached data — default to personal
    String type = AppConstants.personal_Chat_Type;
    if (cachedChat.isGroup == true) {
      type = AppConstants.group_Chat_Type;
    } else {
      // Check in-memory business chat list
      final businessChats = getBusinessChatListModel?.value.chatList ?? [];
      final isBusiness = businessChats.any(
              (c) => c?.conversationId == conversationId);
      if (isBusiness) type = AppConstants.business_Chat_Type;
    }

    _navigateToChatScreen(
      type: type,
      userId: userId,
      conversationId: conversationId,
      profileImage: profileImage,
      contactName: contactName,
      contactNo: contactNo,
      isFromContactList: isFromContactList,
    );
    return true;
  }

  /// Search in-memory chat lists for a conversation with this userId.
  ChatList? _findChatInMemory(String userId) {
    final allLists = [
      getPersonalChatListModel?.value.chatList,
      getBusinessChatListModel?.value.chatList,
      getGroupChatListModel?.value.chatList,
    ];
    for (final chatList in allLists) {
      if (chatList == null) continue;
      for (final chat in chatList) {
        if (chat?.sender?.id == userId) return chat;
      }
    }
    return null;
  }

  /// Navigate to the appropriate chat screen (personal or business).
  void _navigateToChatScreen({
    required String type,
    required String userId,
    required String conversationId,
    required String profileImage,
    required String contactName,
    required String contactNo,
    bool? isFromContactList,
    String? prefilledMessage,
  }) {
    // `order` is merged into `business`; route legacy order conversations to
    // the business screen too (BusinessChatScreenUpdated tags sends as
    // `discover`), instead of falling through to the personal screen.
    final lane = type.toLowerCase();
    if (lane == AppConstants.business_Chat_Type ||
        lane == AppConstants.order_Chat_Type) {
      if (isFromContactList != null && isFromContactList) {
        Get.off(
              () => BusinessChatScreenUpdated(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
            prefilledMessage: prefilledMessage,
          ),
        );
      } else {
        Get.to(
              () => BusinessChatScreenUpdated(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
            prefilledMessage: prefilledMessage,
          ),
        );
      }
    } else {
      if (isFromContactList != null && isFromContactList) {
        Get.off(
              () => PersonalChatScreen(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
            prefilledMessage: prefilledMessage,
          ),
        );
      } else {
        Get.to(
              () => PersonalChatScreen(
            type: type,
            isInitialMessage: conversationId=='',
            userId: userId,
            conversationId: conversationId,
            profileImage: profileImage,
            name: contactName,
            contactNo: contactNo,
            prefilledMessage: prefilledMessage,
          ),
        );
      }
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

  Future<bool> updateGroupInfo(
    Map<String, dynamic> params,
  {
  bool? isFromFile,
  bool? isFromCoverImage,
  Map<String, dynamic>? fileParams,
  File? fileSended
  }
  ) async {
    try {
      isEditGroupBtnLoading.value=true;
      if (isFromFile != null||isFromCoverImage!=null) {
        ResponseModel responseModel =
        await ChatViewRepo().generateUploadUrlsApi(fileParams!);
        clearMessageControllerCommon();

        if (!responseModel.isSuccess) {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
          return false;
        }

        final data = responseModel.response?.data;
        final uploadModel = GenerateUploadUlrModel.fromJson(data);
        generateUploadUlrModel?.value = uploadModel;

        final files = uploadModel.files;

        // Parallel Uploads using Future.wait
        await Future.wait(List.generate(files!.length, (i) {
          final file = fileSended;
          final url = files[i].uploadUrl ?? '';
          final type = files[i].fileType ?? '';
          return uploadFileToS3(file: file!, fileType: type, preSignedUrl: url);
        }));
        List<String> sharedFile = uploadModel.files?.map((element) {
          return element.publicUrl ?? '';
        }).toList() ??
            [];
        params.addAll({
          if(isFromCoverImage!=null)
            ApiKeys.group_cover_image: sharedFile
            else
          ApiKeys.group_profile_image: sharedFile,
        });
        ResponseModel responseModelCreas =
        await ChatViewRepo().updateGroupApi(params);
        if (responseModelCreas.isSuccess) {

          groupDetailsModel.value.copyWith(
              groupProfileImage:responseModelCreas.data['group_profile_image'],
            groupCoverImage: responseModelCreas.data['group_cover_image'],
            groupName: responseModelCreas.data['group_name'],
            publicGroup: responseModelCreas.data['public_group'],
          );
          emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});
          isEditGroupBtnLoading.value=false;
          return true;
        } else {
          isEditGroupBtnLoading.value=false;

          commonSnackBar(
              message:
              responseModelCreas.message ?? AppStrings.somethingWentWrong);
          return false;
        }
      }else{
        ResponseModel responseModelCreas =
        await ChatViewRepo().updateGroupApi(params);
        clearMessageControllerCommon();
        emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});

        if (responseModelCreas.isSuccess) {

          clearMessageControllerCommon();
          emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.group_Chat_Type});

          groupDetailsModel.value.copyWith(
            groupProfileImage:responseModelCreas.data['group_profile_image'],
            groupCoverImage: responseModelCreas.data['group_cover_image'],
            groupName: responseModelCreas.data['group_name'],
            publicGroup: responseModelCreas.data['public_group'],
          );
          isEditGroupBtnLoading.value=false;

          return true;
        } else {
          clearMessageControllerCommon();
          commonSnackBar(
              message: responseModelCreas.message ?? AppStrings.somethingWentWrong);
          isEditGroupBtnLoading.value=false;

          return false;
      }

      }

    } catch (e) {
      isEditGroupBtnLoading.value=false;

      return false;
    }
  }

  String getCurrentIsoTime() {
    return DateTime.now().toUtc().toIso8601String();
  }
  Future<void> getGroupDetailsApi(Map<String, dynamic> params) async {
    // try {

      ResponseModel responseModel =
          await ChatViewRepo().getGroupDetailsApi(params);

      if (responseModel.isSuccess) {
        final data = responseModel.data;
        groupDetailsModel.value=GroupDetailsModel.fromJson(data);
        groupDetailsResponse.value=ApiResponse.complete(groupDetailsModel.value);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        groupDetailsResponse.value=ApiResponse.error( responseModel.message ?? AppStrings.somethingWentWrong);

      }
    // } catch (e) {
    //   groupDetailsResponse.value=ApiResponse.error(AppStrings.somethingWentWrong);
    //
    // }
  }
  Future<void> sendInitialMessage(Map<String, dynamic> params) async {
    if (isSending.value) return;
    isSending.value = true;
    try {
      attachRouteParam(params);
      clearMessageControllerCommon();
      ResponseModel responseModel =
          await ChatViewRepo().sendMessageToUser(params);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;

        Messages? message = Messages.fromJson(data['data']);
        if (message.status != null) {
          readMessageStatus.value = message.status!;
        }
        getListOfMessageData?.add(message);
        getListOfMessageResponse.value =
            ApiResponse.complete(getListOfMessageData);
        if (chatFromBusinessProfile.value) {
          canPopBusiness.value = true;
        }
        scrollDown();
        saveSingleMessageToLocal(message.conversationId ?? '', message);
        // Refresh the list for whichever lane this new conversation landed in.
        // A `discover` route creates a business conversation, so refreshing the
        // personal list would leave the new thread invisible until a tab switch.
        emitEvent(
          ChatEmitEvents.ChatList,
          {
            ApiKeys.type: activeRoute == AppConstants.route_discover
                ? AppConstants.business_Chat_Type
                : AppConstants.personal_Chat_Type
          },
        );
        clearMessageControllerCommon();
      } else {
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
    } finally {
      isSending.value = false;
    }
  }

  /// Inquiry (business) lane delete lock: a message or conversation can only
  /// be deleted once it is at least 48 hours old. The personal Chat tab is
  /// exempt — this only gates the Inquiry tab and the business chat screen.
  static const Duration inquiryDeleteLockWindow = Duration(hours: 48);

  /// True when an item created at [createdAt] (ISO-8601) is old enough to be
  /// deleted in the Inquiry lane. Fail-open (returns true) when the timestamp
  /// is missing or unparseable so a legitimate delete is never permanently
  /// trapped.
  bool isInquiryDeleteUnlocked(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return true;
    final created = DateTime.tryParse(createdAt)?.toLocal();
    if (created == null) return true;
    return DateTime.now().difference(created) >= inquiryDeleteLockWindow;
  }

  /// `createdAt` of the business/history conversation row matching
  /// [conversationId], or null when not found in either bucket.
  String? businessConversationCreatedAt(String? conversationId) {
    if (conversationId == null || conversationId.isEmpty) return null;
    final buckets = [
      getBusinessChatListModel?.value.chatList,
      getHistoryChatListModel?.value.chatList,
    ];
    for (final list in buckets) {
      if (list == null) continue;
      for (final c in list) {
        if (c == null) continue;
        if (c.conversationId == conversationId) return c.createdAt;
      }
    }
    return null;
  }

  Future<void> deleteChatMessage(
      Map<String, dynamic> params, String userId) async {
    try {
      ResponseModel responseModel =
          await ChatViewRepo().deleteSingleMessage(params);
      clearMessageControllerCommon();
      if (responseModel.isSuccess) {
     emitEvent(ChatEmitEvents.messageReceived, {
      ApiKeys.conversation_id: params[ApiKeys.conversation_id],
      ApiKeys.page: 1,
      ApiKeys.is_online_user: userId,
      ApiKeys.per_page_message: 30,
    });
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
        emitEvent(ChatEmitEvents.messageReceived, {
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
      isPinMessageLoading.value=true;
      ResponseModel responseModel =
          await ChatViewRepo().addToPinMultiMessage(params);
      if (responseModel.isSuccess) {
        isPinMessageLoading.value=false;
        commonSnackBar(
            message:responseModel.message?? AppStrings.messagePinnedSuccessfully.tr);
        return true;
      } else {
        isPinMessageLoading.value=false;
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      isPinMessageLoading.value=false;
      commonSnackBar(
          message: AppStrings.somethingWentWrong);
      return false;
    }
  }
  Future<bool> getPinMessageListDataApi(Map<String, dynamic> params) async {
    // try {

      ResponseModel responseModel =
          await ChatViewRepo().getPinMessageListData(params);
      if (responseModel.isSuccess) {
        getListOfMessageData?.clear();
        List<dynamic> details=responseModel.response?.data['messages'];
        getListOfMessageData?.addAll(details.map((e) => Messages.fromJson(e)).toList());
        getListOfMessageResponse.value =ApiResponse.complete(getListOfMessageData);
        return true;
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    // } catch (e) {
    //
    //   commonSnackBar(
    //       message: AppStrings.somethingWentWrong);
    //   return false;
    // }
  }

  /// Resolve remote URLs to local file paths for media messages.
  /// For each message with media URLs, checks if the file was already downloaded
  /// locally and replaces the remote URL with the local path so widgets show
  /// the file instantly without network loading.
  ///
  Future<void> _resolveLocalMediaPaths(List<Messages> messages) async {
    final mediaTypes = {'image', 'video', 'audio', 'document'};
    for (final msg in messages) {
      if (msg.url == null || msg.url!.isEmpty) continue;
      if (!mediaTypes.contains(msg.messageType)) continue;
      for (final media in msg.url!) {
        final url = media.url;
        if (url == null || url.isEmpty || !url.contains('http')) continue;
        final localFile = await ChatMediaStorageService.findExistingFile(
          url: url,
          messageType: msg.messageType ?? 'image',
          fileName: media.name,
        );
        if (localFile != null) {
          media.url = localFile.path;
        }
      }
    }
  }

  /// Remove the uploading placeholder card from the message list.
  void _removeUploadingPlaceholder() {
    if (sendLoadingFile.value.sendLoadingFile != null) {
      getListOfMessageData?.remove(sendLoadingFile.value);
      getListOfMessageResponse.value =
          ApiResponse.complete(getListOfMessageData);
      sendLoadingFile.value = Messages();
    }
  }

  Future<void> generateUploadUrlsApi({
    required Map<String, dynamic> params,
    required List<File> listFile,
    required List<String?>? userId,
    String? conversationId,
    String? commands,
    required String messageType,
    bool? isPendingMessage,
    String? messageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      VideoUploadProgress.value = "0";

      // Show uploading card immediately so the user sees progress right away
      if (listFile.isNotEmpty &&
          (messageType == 'video' || messageType == 'image') &&
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
        scrollDown();
      }

      ResponseModel responseModel =
          await ChatViewRepo().generateUploadUrlsApi(params);
      clearMessageControllerCommon();

      if (!responseModel.isSuccess) {
        _removeUploadingPlaceholder();
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
        if (conversationId==null)
          ApiKeys.other_user_id: userId
        else
          ApiKeys.conversation_id: conversationId,
        if (commands != null) ApiKeys.message: commands,
        ApiKeys.message_type: messageType,
        if (metadata != null) ApiKeys.metadata: metadata,
        ApiKeys.url: urlList,
      };
      attachRouteParam(messagePayload);
      // Await the final send + Hive write so callers (e.g. sendOfflineMessage)
      // can clear their in-flight pending guard only after the replacement of
      // the temp row by the server row has actually hit Hive.
      await sendMessageLargeFile(
          messagePayload, listFile, isPendingMessage, messageId);
      generateUploadUrlResponse.value = ApiResponse.complete(uploadModel);
    } catch (e) {
      _removeUploadingPlaceholder();
      clearMessageControllerCommon();
      // A retry of an already-pending message that fails again must not
      // create a second pending entry — the original one is still in Hive
      // and will be drained by the next reopen/connectivity tick. Without
      // this guard every offline reopen duplicates the message.
      if (isPendingMessage == true) {
        return;
      }
      // Save a pending placeholder whenever the device is offline so the
      // message waits and is re-sent when connectivity returns. Skipping the
      // pending entry for actual server errors prevents an infinite retry.
      final bool isOffline = !await checkInternetStatus();
      if (isOffline || e == "Something went wrong") {
        final now = DateTime.now().toUtc();
        final isoTime = now.toIso8601String();
        List<String> filePathsList =
            listFile.map((f) => f.path).toList();
        final String tempId = "${isoTime}_${conversationId ?? ''}";
        final bool alreadyExists =
            getListOfMessageData?.any((m) => m.id == tempId) ?? false;
        Messages message = Messages(
            userId: userId?.first,
            id: tempId,
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
        if (!alreadyExists) {
          getListOfMessageData?.add(message);
          getListOfMessageResponse.value =
              ApiResponse.complete(getListOfMessageData);
        }
        saveSingleMessageToLocal(conversationId ?? '', message, params);
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
        // Remove the uploading placeholder (shown for both image & video)
        _removeUploadingPlaceholder();

        final data = responseModel.response?.data;
        Messages? message = Messages.fromJson(data['data']);
        // Payment-screenshot approval is managed locally: the server may not
        // echo our metadata, so carry the flag from the send params onto the
        // local message copy that gets rendered + persisted to Hive.
        final sentMeta = params[ApiKeys.metadata];
        if (sentMeta is Map && sentMeta['is_payment_screenshot'] == true) {
          message.metadata ??= MessageMetadata();
          message.metadata!.isPaymentScreenshot = true;
          message.metadata!.approvalStatus = message.metadata!.approvalStatus ??
              sentMeta['approval_status']?.toString() ??
              'pending';
        }
        if (message.subType != "comment") {
          if (message.status != null) {
            readMessageStatus.value = message.status!;
          }
          if (isPendingMessage != null && isPendingMessage) {
            Messages? msg = getListOfMessageData
                ?.firstWhereOrNull((element) => element.id == messageId);
            if (msg != null) {
              getListOfMessageData?.remove(msg);
            }
            // Deduplicate: the newMessageReceived socket echo may have
            // already inserted this server message while the HTTP response
            // was in flight. Without this guard, retried pending media show
            // up twice in the conversation.
            // if (!alreadyExists) {
            //   getListOfMessageData?.add(message);
            // }
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
            await localStorageHelper.replacePendingWithServerMessage(
                params[ApiKeys.conversation_id]?.toString() ?? '',
                messageId ?? "",
                message);
          } else {
            final alreadyExists = message.id != null &&
                (getListOfMessageData?.any((m) => m.id == message.id) ?? false);
            if (!alreadyExists) {

              getListOfMessageData?.add(message);
            }
            getListOfMessageResponse.value =
                ApiResponse.complete(getListOfMessageData);
            scrollDown();
            saveSingleMessageToLocal(
                message.conversationId ?? '', message);
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
        _removeUploadingPlaceholder();
        clearMessageControllerCommon();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      _removeUploadingPlaceholder();
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

  Future<void> addGroupMember({required Map<String, dynamic> params}) async {
    try {
      ResponseModel? response = await ChatViewRepo().addGroupMembers(params);
      if (response.isSuccess) {
        commonSnackBar(message: AppStrings.groupMemberAdded.tr);
        Map<String, dynamic> data = {
          ApiKeys.conversation_id: params[ApiKeys.conversation_id]
        };
        getGroupMembersApi(data);
        Get.back();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
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
  Future<bool> checkTrackOrderStatusApi(
      String orderId) async {
    try {
      ResponseModel responseModel =
      await ChatViewRepo().checkTrackOrderStatusApi(orderId);
      if (responseModel.isSuccess) {
        var details=responseModel.response?.data;
        if(details["status"]=="rejected"||details["status"]=="cancelled"){
        // if(details["status"]=="completed"||details["status"]=="rejected"||details["status"]=="cancelled"){
          return false;
        }else{
          return true;
        }

      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
